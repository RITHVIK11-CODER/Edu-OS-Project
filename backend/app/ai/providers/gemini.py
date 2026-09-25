"""Optional Gemini adapter with strict structured-output validation."""
from __future__ import annotations
import json
from pathlib import Path
from typing import Any
from ..models import MindTraceInput, MindTraceResult

class GeminiProvider:
    name = "gemini"
    prompt_version = "mindtrace_v1"
    def __init__(self, api_key: str, model_name: str = "gemini-1.5-flash"):
        if not api_key:
            raise ValueError("Gemini API key is required")
        self.api_key = api_key
        self.model_name = model_name
    def analyze_mindtrace(self, data: MindTraceInput) -> MindTraceResult:
        try:
            import google.generativeai as genai
        except ImportError as exc:
            raise RuntimeError("google-generativeai is not installed") from exc
        path = Path(__file__).resolve().parents[4] / "ai" / "prompts" / "mindtrace" / "v1.txt"
        prompt = path.read_text(encoding="utf-8").format(grade=data.grade, subject=data.subject, concept=data.concept, question=data.question, correct_answer=data.correct_answer, student_answer=data.student_answer, reasoning=data.reasoning or "Not provided")
        genai.configure(api_key=self.api_key)
        response = genai.GenerativeModel(self.model_name).generate_content(prompt)
        raw = getattr(response, "text", "").strip()
        if not raw:
            raise ValueError("Gemini returned an empty response")
        raw = raw.replace("json\\n", "", 1).strip()
        try:
            parsed: dict[str, Any] = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise ValueError("Gemini returned invalid JSON") from exc
        return MindTraceResult.model_validate(parsed).model_copy(update={"model_name": self.model_name, "prompt_version": self.prompt_version})
