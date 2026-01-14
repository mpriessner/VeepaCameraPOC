# CLAUDE.md - VeepaCameraPOC

## Project Overview

Flutter/SwiftUI proof-of-concept for validating Veepa IP camera integration. This POC de-risks SciSymbioLens Phase 4 (External Camera Support).

**Current Phase**: 1 - Pure Flutter Validation
**Methodology**: BMAD + RALPH
**Parent Project**: SciSymbioLens

## Development Phases

| Phase | Focus | Status |
|-------|-------|--------|
| **Phase 1** | Pure Flutter POC (camera connection, streaming) | 📋 Planned |
| **Phase 2** | Flutter Add-to-App with SwiftUI host | ⏳ Future |

## Project Structure

```
VeepaCameraPOC/
├── .bmad-core/          # BMAD methodology files
├── .ralph/              # RALPH automation scripts
├── .claude/commands/    # Claude Code workflows
├── docs/
│   ├── brief.md         # Product brief
│   ├── prd.md           # Product requirements
│   ├── stories/         # User stories for RALPH
│   └── LEARNINGS.md     # Integration learnings for SciSymbioLens
├── flutter_veepa_module/ # Flutter POC app (Phase 1)
└── ios_host_app/        # SwiftUI host app (Phase 2)
```

## Tech Stack

### Phase 1 (Flutter POC)
- **Framework**: Flutter >=3.0.0
- **Language**: Dart >=2.17.0
- **SDK**: Veepa SDK (from /Users/mpriessner/windsurf_repos/Veepaisdk)
- **Testing**: Flutter test

### Phase 2 (SwiftUI Host)
- **Framework**: SwiftUI (iOS 17+)
- **Language**: Swift 5.9+
- **Integration**: Flutter Add-to-App
- **Bridge**: Platform Channels

## SDK Source Location

The Veepa SDK files are at:
- **Flutter SDK**: `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/`
- **iOS Native Library**: `/Users/mpriessner/windsurf_repos/Veepaisdk/ios库/libVSTC.a`
- **Documentation**: `/Users/mpriessner/windsurf_repos/Veepaisdk/SDK_ANALYSIS.md`

## Quality Standards

- **Test coverage**: Unit tests for connection logic
- **Verification**: Manual testing with real Veepa camera
- **Documentation**: Capture all learnings in LEARNINGS.md

## Anti-Patterns (Project-Specific)

- Do NOT attempt direct native integration (headers are Flutter-only)
- Do NOT skip camera hardware testing
- Do NOT hardcode camera credentials
- Do NOT ignore P2P connection error states

---

# Master Workflow Guide (Inherited)

This section provides universal guidance for Claude Code across all projects in this workspace.

## Core Principle: Verification-First

**Never implement without a verification strategy.** Before writing any code:
1. State HOW you will verify the work (tests, linter, screenshots, manual check)
2. Write tests FIRST when possible (TDD)
3. For UI changes: use screenshots or browser verification
4. Never mark a task complete without verification passing

This feedback loop is what separates good results from mediocre ones.

## Workflow Pattern

### For Non-Trivial Tasks:
1. **Plan Mode First** - Switch to plan mode, discuss approach, validate the plan
2. **All Back-and-Forth in Planning** - Resolve ambiguity before implementation
3. **Execute in Auto-Accept Mode** - Once plan is solid, implement efficiently
4. **Verify Before Complete** - Run tests/linters, confirm success

### For Simple Tasks:
- Skip planning, implement directly, but still verify

### NEVER:
- Use `--dangerously-skip-permissions` in production environments
- Skip verification steps to "save time"
- Mark tasks complete without confirmation they work

## Anti-Patterns (Learned from Errors)

*Update this section whenever Claude makes a mistake worth remembering.*

- Do not create new files when editing existing ones would suffice
- Do not add extensive comments or docstrings unless explicitly requested
- Do not over-engineer solutions - implement exactly what's asked
- Do not guess at file paths - verify they exist first
- Do not make assumptions about project structure - explore first
- Do not batch multiple unrelated changes into one commit

## Model Selection Guidance

**Opus 4.5 with thinking** for:
- Complex multi-file changes
- Architecture decisions
- Debugging difficult issues
- Tasks where errors are costly

**Sonnet** for:
- Standard implementation work
- Code reviews
- Documentation

**Haiku** for:
- Quick lookups
- Simple edits
- Routine tasks

*Lower error rate = less steering = faster overall completion*

## Testing & Verification

### Before Marking Complete:
```bash
# Run relevant tests
pytest tests/ -v

# Check code style
ruff check src/

# For UI: take screenshot or use browser verification
```

### Verification by Domain:
- **Backend code**: Unit tests, integration tests
- **Frontend/UI**: Screenshots, Playwright, browser extension
- **CLI tools**: Run with test inputs, verify output
- **APIs**: Test endpoints, check response format
- **Mobile**: Use iOS/Android simulator MCPs

## Permissions Philosophy

### Allow (safe, read-only, reversible):
- `git status`, `git diff`, `git log`
- `pytest`, `ruff`, linters
- `ls`, `cat`, file reading

### Ask (needs confirmation):
- `git push`, `git commit`
- `pip install`, `npm install`
- File writes outside project

### Deny (dangerous, irreversible):
- `rm -rf`
- `git push --force`
- `git reset --hard`
- Commands affecting production

## Project-Specific CLAUDE.md

Each project subfolder can have its own CLAUDE.md with:
- Tech stack specifics
- Project structure
- Custom conventions
- Project-specific anti-patterns

This master file provides the universal workflow; project files provide context.

## Slash Commands & Subagents

Store reusable workflows in `.claude/commands/` for:
- Repetitive "inner loop" tasks (commit, test, deploy)
- Team-shared workflows (commit to git, share with team)

Use subagents for:
- Architecture validation
- Code refactoring verification
- Build validation

## Parallel Sessions Strategy

When running multiple Claude Code sessions:
- Number your terminal tabs (1, 2, 3...)
- Use background agents for long-running verification
- Web sessions for truly autonomous work (creates branch, pushes code)

## Quick Reference

| Situation | Action |
|-----------|--------|
| New feature | Plan mode → validate → implement |
| Bug fix | Reproduce → fix → verify fixed |
| Refactor | Tests pass before → refactor → tests pass after |
| UI change | Screenshot before → change → screenshot after |
| Uncertain | Ask, don't assume |

---

*This file is the ground truth for workflow practices. Project-specific details belong in each project's own CLAUDE.md.*
