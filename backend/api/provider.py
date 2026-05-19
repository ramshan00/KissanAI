from fastapi import APIRouter, HTTPException
from typing import List
from ..database import get_connection

router = APIRouter()

@router.get("/list", response_model=List[dict])
async def list_providers(service_type: str = None):
    """Return a list of providers, optionally filtered by service_type."""
    conn = get_connection()
    cur = conn.cursor()
    if service_type:
        cur.execute("SELECT * FROM providers WHERE service_type = ?", (service_type,))
    else:
        cur.execute("SELECT * FROM providers")
    rows = cur.fetchall()
    return [dict(row) for row in rows]

@router.post("/toggle_availability/{provider_id}")
async def toggle_availability(provider_id: int, available: bool):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE providers SET availability = ? WHERE id = ?", (1 if available else 0, provider_id))
    conn.commit()
    return {"provider_id": provider_id, "availability": available}
