# EduOS Student App

Flutter mobile MVP for the EduOS Grade 10 Mathematics learning loop.

## Run

```bash
flutter pub get
flutter run
```

Stage 1 uses controlled mock services so the complete student journey is demonstrable before backend APIs are available.

## Demo flow

Login → Dashboard → Mathematics → Topic → SmartAssess → MindTrace → PathAI → Practice → Reassess → EduTwin progress.

Backend integration must follow `docs/10_API_CONTRACT.md`. The UI does not invent backend endpoints.
