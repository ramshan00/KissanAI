import asyncio
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict, List
from backend.database import get_connection

router = APIRouter()

class ConnectionManager:
    """Manages active WebSockets connections and broadcasts real-time GPS coordinates."""
    def __init__(self):
        # Maps booking_id -> list of listening farmer websockets
        self.farmer_connections: Dict[int, List[WebSocket]] = {}
        # Maps booking_id -> provider websocket (optional tracker check)
        self.provider_connections: Dict[int, WebSocket] = {}
        # Maps booking_id -> last known GPS coordinates {latitude, longitude}
        self.gps_cache: Dict[int, dict] = {}

    async def connect_farmer(self, booking_id: int, websocket: WebSocket):
        await websocket.accept()
        if booking_id not in self.farmer_connections:
            self.farmer_connections[booking_id] = []
        self.farmer_connections[booking_id].append(websocket)
        
        # If we have cached GPS coordinates, send them immediately on connect
        if booking_id in self.gps_cache:
            await websocket.send_json(self.gps_cache[booking_id])

    def disconnect_farmer(self, booking_id: int, websocket: WebSocket):
        if booking_id in self.farmer_connections:
            if websocket in self.farmer_connections[booking_id]:
                self.farmer_connections[booking_id].remove(websocket)
            if not self.farmer_connections[booking_id]:
                del self.farmer_connections[booking_id]

    async def connect_provider(self, booking_id: int, websocket: WebSocket):
        await websocket.accept()
        self.provider_connections[booking_id] = websocket

    def disconnect_provider(self, booking_id: int):
        if booking_id in self.provider_connections:
            del self.provider_connections[booking_id]

    async def broadcast_gps(self, booking_id: int, gps_data: dict):
        """Sends the GPS updates to all active farmers subscribed to this booking."""
        self.gps_cache[booking_id] = gps_data
        
        if booking_id in self.farmer_connections:
            # Gather tasks for parallel broadcast
            tasks = []
            for ws in self.farmer_connections[booking_id]:
                tasks.append(ws.send_json(gps_data))
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)

manager = ConnectionManager()

@router.websocket("/ws/track/provider/{booking_id}")
async def ws_track_provider(websocket: WebSocket, booking_id: int):
    """
    WebSocket endpoint for Providers to stream their live GPS coordinates.
    Data format expected: {"latitude": 31.5204, "longitude": 74.3587, "provider_id": 1}
    """
    await manager.connect_provider(booking_id, websocket)
    try:
        while True:
            # Wait for coordinates from Provider mobile app
            data = await websocket.receive_text()
            gps_data = json.loads(data)
            
            lat = gps_data.get("latitude")
            lng = gps_data.get("longitude")
            provider_id = gps_data.get("provider_id")
            
            if lat is not None and lng is not None:
                # Update last known GPS cache
                payload = {
                    "booking_id": booking_id,
                    "latitude": lat,
                    "longitude": lng,
                    "status": "active"
                }
                
                # 1. Broadcast to all listening farmers
                await manager.broadcast_gps(booking_id, payload)
                
                # 2. Async save tracking log to Postgres/SQLite
                try:
                    conn = get_connection()
                    cur = conn.cursor()
                    
                    import os
                    is_postgres = os.getenv("DATABASE_URL") and os.getenv("DATABASE_URL").startswith("postgresql://")
                    
                    query = """
                        INSERT INTO tracking_logs (booking_id, provider_id, latitude, longitude)
                        VALUES (%s, %s, %s, %s)
                    """ if is_postgres else """
                        INSERT INTO tracking_logs (booking_id, provider_id, latitude, longitude)
                        VALUES (?, ?, ?, ?)
                    """
                    
                    cur.execute(query, (booking_id, provider_id or 1, lat, lng))
                    conn.commit()
                    conn.close()
                except Exception as e:
                    print(f"Error saving GPS log to DB: {e}")
                    
    except WebSocketDisconnect:
        manager.disconnect_provider(booking_id)
        print(f"Provider disconnected tracking for booking {booking_id}")
    except Exception as e:
        print(f"Error in tracking broadcast: {e}")
        manager.disconnect_provider(booking_id)

@router.websocket("/ws/track/farmer/{booking_id}")
async def ws_track_farmer(websocket: WebSocket, booking_id: int):
    """
    WebSocket endpoint for Farmers to listen to live GPS updates for their active booking.
    """
    await manager.connect_farmer(booking_id, websocket)
    try:
        while True:
            # Just keep the connection alive. We mostly push data down.
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect_farmer(booking_id, websocket)
        print(f"Farmer disconnected tracking for booking {booking_id}")
    except Exception as e:
        print(f"Error in farmer tracking subscriber: {e}")
        manager.disconnect_farmer(booking_id, websocket)
