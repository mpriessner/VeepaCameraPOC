# Auto Commit and Push

Automatically commit all changes and push to GitHub without user intervention.

## Instructions

Execute the following steps immediately WITHOUT asking for confirmation:

1. Stage all changes: `git add -A`
2. Check if there are changes to commit with `git status`
3. If there are staged changes:
   - Analyze the changes with `git diff --staged`
   - Generate a conventional commit message based on the changes
   - Commit with the generated message (include Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>)
   - Push to the remote repository
4. If no changes, report "Nothing to commit"

## Commit Message Format

Use conventional commits format:
- `feat:` for new features
- `fix:` for bug fixes
- `refactor:` for code refactoring
- `test:` for test changes
- `docs:` for documentation
- `chore:` for maintenance

## Story Completion Format

When completing a story, use this enhanced format:

```
<type>(epic-<N>): <description> - Story <N.N>

Story: <story-id>
Acceptance Criteria:
- [x] AC1: <criteria>
- [x] AC2: <criteria>
...

Test Results:
- Unit tests: X passed, 0 failed
- Integration tests: X passed, 0 failed (if applicable)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

## Important

- Do NOT ask for user confirmation
- Do NOT wait for approval
- Execute all git commands automatically
- Report the result when done
