# Lib Structure

This project is being migrated from a single large `main.dart` file into a
feature-based Flutter structure.

Current entrypoints:

- `main.dart`: thin app entrypoint
- `app/skinsafe_frontend.dart`: current working full app implementation during migration
- `app/frontend_pages.dart`: central export map for separated frontend screens
- `features/.../presentation/screens/`: screen-by-screen frontend structure for auth, scan, history, learn, profile, and home flows

Target structure:

```text
lib/
  app/
  core/
    theme/
    utils/
    widgets/
  features/
    auth/
    onboarding/
    dashboard/
    scan/
    history/
    learn/
    profile/
    doctors/
    reports/
  services/
    ai/
    firebase/
    notifications/
    storage/
  shared/
    models/
    widgets/
```

The app still runs exactly as before while we gradually move screens,
controllers, widgets, and services into these folders.
