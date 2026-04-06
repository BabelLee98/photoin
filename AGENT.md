# AGENTS.md

## Project overview
This is a Swift iOS app built with SwiftUI.
Prefer minimal, reviewable changes that match existing patterns.
Do not introduce new frameworks or architectural patterns without a clear reason.

## Repo map
- `App/`: app entry, app lifecycle, dependency wiring
- `Features/`: feature modules, grouped by feature
- `Shared/UI/`: reusable UI components and design-system wrappers
- `Shared/Infrastructure/`: networking, persistence, logging
- `Domain/`: business models and use cases
- `Tests/`: unit tests
- `UITests/`: UI tests

When changing a user-facing screen, first inspect the matching folder in `Features/`.
When changing business rules, prefer `Domain/` or feature-local domain code over putting logic in SwiftUI views.

## Engineering rules
- Keep SwiftUI `View` types focused on rendering and simple event forwarding.
- Do not put core business logic directly in SwiftUI views.
- Prefer async/await over introducing new callback-based APIs.
- UI state updates must happen on the main actor.
- Avoid blocking work on the main thread.
- Reuse existing components from `Shared/UI/` before creating new ones.
- Keep DTO / API response models separate from domain models when the boundary matters.
- Prefer extending existing feature modules over adding cross-cutting utility files.
- Add clear comment when adding any new functions.

## Testing expectations
- Add or update unit tests for business logic changes.
- Add regression coverage for bug fixes when practical.
- For small UI copy or layout tweaks, tests are optional unless existing tests need updating.
- Do not delete failing tests without explaining the reason in the summary.

## Change policy
- Prefer the smallest change that fully solves the task.
- Avoid unrelated refactors.
- Preserve public interfaces unless the task requires changing them.
- Summarize user-visible behavior changes, risk areas, and test status in the final response.

## Review notes
Check for:
- main-thread violations
- retain cycles / lifetime issues
- state updates that can race
- duplicated networking or mapping logic
- missing error handling
- missing test coverage for changed business behavior
