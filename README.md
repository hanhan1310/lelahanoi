# Le La Hanoi

Flutter app for customer ordering and manager operations.

## Architecture

The app follows feature-first Clean Architecture with MVVM responsibilities:

```text
lib/
  core/
    data/          Firebase data sources
    models/        Shared domain models
    l10n/          LanguageCubit and translations
    theme/         App theme values
    widgets/       Reusable UI widgets
  features/
    <feature>/
      data/        Repositories and local storage
      presentation/
        bloc/      Cubit/ViewModel and immutable state
        pages/     Flutter views
```

Views render state and dispatch user actions. Cubits own screen state and use
repositories; repositories/data sources own Firebase and local persistence.

Current ViewModels include `AuthCubit`, `NavigationCubit`, `MenuCubit`,
`CartCubit`, `OrderCubit`, `LoyaltyCubit`, `ProfileCubit`, and
`ManagerSettingsCubit`.

Feature files and model names use lower snake case. The old `view/`, `model/`,
`utils/`, and `public/` buckets were removed so each feature has a clear owner.

## Verification

```bash
flutter pub get
flutter analyze
flutter test
```
