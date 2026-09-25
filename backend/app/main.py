from fastapi import FastAPI

from app.api.classpulse import router as classpulse_router\nfrom app.api.auth import router as auth_router\nfrom app.api.student import router as student_router\nfrom app.api.assessments import router as assessment_router\nfrom app.api.ai import router as ai_router


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


app.include_router(auth_router, prefix="/api/v1")\napp.include_router(student_router, prefix="/api/v1")\napp.include_router(assessment_router, prefix="/api/v1")\napp.include_router(ai_router, prefix="/api/v1")\napp.include_router(classpulse_router, prefix="/api/v1")
