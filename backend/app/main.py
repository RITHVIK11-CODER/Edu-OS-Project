from fastapi import FastAPI

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
    return {
        "status": "healthy"
    }