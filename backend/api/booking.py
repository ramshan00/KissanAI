import os
import requests
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from typing import List, Optional
from pydantic import BaseModel
class TextCommand(BaseModel):
    user_id: int
    text: str
from ..schemas import BookingCreate, BookingOut, BookingResponse
from ..database import get_connection
from ..antigravity.orchestrator import antigravity

router = APIRouter()

class DisputeRequest(BaseModel):
    reason: str

async def transcribe_audio_whisper(audio_bytes: bytes, filename: str) -> str:
    """
    Calls the OpenAI Whisper API to transcribe Urdu / Roman Urdu speech.
    """
    openai_api_key = os.getenv("OPENAI_API_KEY")
    if not openai_api_key:
        raise Exception("OPENAI_API_KEY is not configured in .env")

    url = "https://api.openai.com/v1/audio/transcriptions"
    headers = {"Authorization": f"Bearer {openai_api_key}"}
    
    # Pack files and data for Whisper multipart form-data
    files = {"file": (filename or "audio.wav", audio_bytes, "audio/wav")}
    data = {"model": "whisper-1", "language": "ur"}
    
    try:
        # Perform synchronous HTTP request inside FastAPI worker pool
        response = requests.post(url, headers=headers, files=files, data=data, timeout=30.0)
        if response.status_code == 200:
            text = response.json().get("text", "")
            print(f"Whisper API (Online Mode): Transcribed speech: '{text}'")
            return text
        else:
            raise Exception(f"Whisper API returned error: {response.text}")
    except Exception as e:
        raise Exception(f"Whisper API connection error: {e}")

@router.post("/create", response_model=BookingResponse)
async def create_booking(booking: BookingCreate):
    """Create a new booking using Antigravity orchestration.
    Returns booking data and the full reasoning trace.
    """
    try:
        result = await antigravity.orchestrate_booking(
            raw_input=f"{booking.service_type} at {booking.location} urgency {booking.urgency or 'normal'}",
            user_id=booking.user_id,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/voice-match", response_model=BookingResponse)
async def voice_match(
    user_id: int = Form(...),
    audio: UploadFile = File(...)
):
    """
    Production voice booking endpoint. Receives raw voice command,
    transcribes it via Whisper, and triggers Antigravity AI Orchestrator.
    """
    try:
        # Read uploaded voice file
        audio_bytes = await audio.read()
        
        # 1. Transcribe via Whisper
        transcription = await transcribe_audio_whisper(audio_bytes, audio.filename)
        
        # 2. Feed transcription into multi-agent orchestration
        result = await antigravity.orchestrate_booking(
            raw_input=transcription,
            user_id=user_id
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice matching failed: {str(e)}")

@router.post("/text-match", response_model=BookingResponse)
async def text_match(payload: TextCommand):
    """
    Direct text command endpoint for dashboard shortcuts.
    """
    try:
        result = await antigravity.orchestrate_booking(
            raw_input=payload.text,
            user_id=payload.user_id
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Text matching failed: {str(e)}")

@router.get("/list", response_model=List[BookingOut])
async def list_bookings(user_id: Optional[int] = None):
    """List all bookings, optionally filtered by user_id."""
    conn = get_connection()
    cur = conn.cursor()
    
    from backend.database import IS_POSTGRES
    is_postgres = IS_POSTGRES
    
    if user_id is not None:
        query = "SELECT * FROM bookings WHERE user_id = %s ORDER BY id DESC" if is_postgres else "SELECT * FROM bookings WHERE user_id = ? ORDER BY id DESC"
        cur.execute(query, (user_id,))
    else:
        query = "SELECT * FROM bookings ORDER BY id DESC"
        cur.execute(query)
        
    rows = cur.fetchall()
    conn.close()
    return [dict(row) for row in rows]

@router.get("/{booking_id}", response_model=BookingOut)
async def get_booking(booking_id: int):
    """Get details of a specific booking by ID."""
    conn = get_connection()
    cur = conn.cursor()
    
    from backend.database import IS_POSTGRES
    is_postgres = IS_POSTGRES
    
    query = "SELECT * FROM bookings WHERE id = %s" if is_postgres else "SELECT * FROM bookings WHERE id = ?"
    cur.execute(query, (booking_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Booking not found")
    return dict(row)

@router.post("/{booking_id}/dispute", response_model=BookingResponse)
async def dispute_booking(booking_id: int, dispute: DisputeRequest):
    """Trigger the ResolveAI dispute resolution workflow for a booking."""
    try:
        result = await antigravity.resolve_dispute(
            booking_id=booking_id,
            reason=dispute.reason
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
