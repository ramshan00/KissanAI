from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from ..antigravity.orchestrator import antigravity

router = APIRouter()

class OrchestrateRequest(BaseModel):
    raw_input: str
    user_id: int

@router.post("/process", summary="Run Antigravity orchestration for a booking")
async def process_request(req: OrchestrateRequest):
    try:
        result = await antigravity.orchestrate_booking(req.raw_input, req.user_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
