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

from fastapi.responses import HTMLResponse, FileResponse
from fastapi import HTTPException
import os

# Health check first to make sure it doesn't get caught by catchall
@app.get("/health")
async def health_check():
    return {"status": "ok"}

# Setup directories
backend_dir = os.path.dirname(__file__)
web_dir = os.path.join(backend_dir, "web")

# Serve the breathtaking glassmorphic marketplace simulator or Flutter app
if os.path.exists(web_dir):
    # Serve index.html at root
    @app.get("/")
    async def serve_flutter_root():
        return FileResponse(os.path.join(web_dir, "index.html"))

    # Serve the simulator at /simulator
    @app.get("/simulator", response_class=HTMLResponse)
    async def serve_simulator():
        html_path = os.path.join(backend_dir, "index.html")
        with open(html_path, "r", encoding="utf-8") as f:
            html_content = f.read()
        return HTMLResponse(content=html_content)
else:
    # Fallback to serving the simulator at root if web build doesn't exist yet
    @app.get("/")
    async def serve_index():
        html_path = os.path.join(backend_dir, "index.html")
        with open(html_path, "r", encoding="utf-8") as f:
            html_content = f.read()
        return HTMLResponse(content=html_content)

# SPA fallback handler at the very end of main.py
@app.get("/{catchall:path}")
async def serve_flutter_spa(catchall: str):
    # Pass through standard endpoints
    if catchall.startswith("api/") or catchall.startswith("docs") or catchall.startswith("redoc") or catchall.startswith("openapi.json"):
        raise HTTPException(status_code=404, detail="Not Found")
    
    if os.path.exists(web_dir):
        file_path = os.path.join(web_dir, catchall)
        if os.path.exists(file_path) and os.path.isfile(file_path):
            return FileResponse(file_path)
        # Fallback to index.html for SPA routing
        return FileResponse(os.path.join(web_dir, "index.html"))
    
    raise HTTPException(status_code=404, detail="Not Found")

