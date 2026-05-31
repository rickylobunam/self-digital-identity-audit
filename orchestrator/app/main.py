from fastapi import FastAPI
from contextlib import asynccontextmanager

# Lifespan context
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("Orchestrator starting up...")
    yield
    # Shutdown
    print("Orchestrator shutting down...")

app = FastAPI(title="SDIA Orchestrator", lifespan=lifespan)

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "ok"}

@app.on_event("startup")
async def startup():
    """Initialize orchestrator on startup"""
    print("Orchestrator health endpoint ready")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
