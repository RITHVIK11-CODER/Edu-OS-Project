from fastapi import FastAPI

from app.api.classpulse import router as classpulse_router


app = FastAPI(
    title="EduOS API",
    description="AI-powered Education Operating System",
    version="1.0.0",
)


@app.get("/")
async def root():
    return {
        "name": "EduOS",
        "status": "running",
        "version": "1.0.0",
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}


app.include_router(classpulse_router, prefix="/api/v1")
