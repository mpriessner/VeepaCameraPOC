# Commit Workflow

Create a well-formatted git commit for staged changes.

## Steps

1. Run `git status` to see current changes
2. Run `git diff --staged` to see what will be committed
3. If nothing staged, ask user what to stage
4. Analyze changes and determine commit type:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `style:` - Code style (formatting, no logic change)
   - `refactor:` - Code refactoring
   - `test:` - Adding/updating tests
   - `chore:` - Maintenance tasks
5. Write a concise commit message following conventional commits
6. Create the commit

## Verification

Before committing:
- Flutter: Run `flutter analyze` in flutter_veepa_module/
- iOS: Ensure Xcode build succeeds (Phase 2)
- Tests: Run `flutter test` for Flutter code

## Example

```bash
git add -A
git commit -m "feat(epic-2): implement camera discovery UI - Story 2.1

Story: 2.1-camera-discovery-ui
Acceptance Criteria:
- [x] AC1: Discovery screen displays
- [x] AC2: Start scan button functional
- [x] AC3: Results list updates

Test Results:
- Unit tests: 5 passed, 0 failed

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```
