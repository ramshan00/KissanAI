from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.antigravity.orchestrator import antigravity
from backend.api import auth, booking, provider, tracking, admin
from backend.antigravity import router as antigravity_router

app = FastAPI(title="KissanAI Backend", version="0.1.0")

# Allow all origins for demo purposes
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(booking.router, prefix="/api/booking", tags=["booking"])
app.include_router(provider.router, prefix="/api/provider", tags=["provider"])
app.include_router(tracking.router, prefix="/api/tracking", tags=["tracking"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])
app.include_router(antigravity_router.router, prefix="/api/antigravity", tags=["antigravity"])

from fastapi.responses import HTMLResponse
import os

# Serve the breathtaking glassmorphic marketplace simulator
@app.get("/", response_class=HTMLResponse)
async def serve_index():
    html_path = os.path.join(os.path.dirname(__file__), "index.html")
    with open(html_path, "r", encoding="utf-8") as f:
        html_content = f.read()
    return HTMLResponse(content=html_content)

@app.get("/health")
async def health_check():
    return {"status": "ok"}
