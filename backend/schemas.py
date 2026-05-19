from pydantic import BaseModel, Field
from typing import Optional, List

class UserCreate(BaseModel):
    phone: str = Field(..., pattern=r"^\+?\d{10,15}$")
    name: Optional[str]

class UserOut(BaseModel):
    id: int
    phone: str
    name: Optional[str]
    created_at: str

    class Config:
        from_attributes = True

class ProviderCreate(BaseModel):
    name: str
    service_type: str
    latitude: Optional[float]
    longitude: Optional[float]

class ProviderOut(BaseModel):
    id: int
    name: str
    service_type: str
    latitude: Optional[float]
    longitude: Optional[float]
    availability: int
    rating: float
    completed_jobs: int
    created_at: str

    class Config:
        from_attributes = True

class BookingCreate(BaseModel):
    user_id: int
    service_type: str
    location: str
    urgency: Optional[str]
    scheduled_time: Optional[str]

class BookingOut(BaseModel):
    id: int
    user_id: int
    provider_id: Optional[int]
    service_type: str
    location: str
    urgency: Optional[str]
    scheduled_time: Optional[str]
    status: str
    price: Optional[float]
    created_at: str

    class Config:
        from_attributes = True

class TraceStep(BaseModel):
    step: str
    details: dict

class BookingResponse(BaseModel):
    booking: BookingOut
    trace: List[TraceStep]
