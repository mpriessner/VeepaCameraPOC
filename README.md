# VeepaCameraPOC

> Proof-of-concept for integrating Veepa IP cameras with iOS applications via Flutter Add-to-App.

## Purpose

This POC validates the Flutter Add-to-App integration approach for connecting Veepa cameras to native iOS apps. It de-risks the SciSymbioLens Phase 4 implementation.

## Status

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | Pure Flutter POC | 📋 Planned |
| Phase 2 | Flutter Add-to-App | ⏳ Future |

## Quick Start

### Prerequisites
- Flutter SDK (>=3.0.0)
- Xcode 15+
- Physical Veepa camera on local network
- iOS device for testing (simulator has limitations)

### Phase 1: Flutter POC
```bash
cd flutter_veepa_module
flutter pub get
flutter run
```

### Phase 2: SwiftUI Host
```bash
cd ios_host_app
xcodegen generate
open VeepaPOC.xcodeproj
```

## Project Structure

```
VeepaCameraPOC/
├── flutter_veepa_module/   # Flutter camera module
├── ios_host_app/           # SwiftUI host (Phase 2)
├── docs/
│   ├── brief.md            # Project brief
│   ├── prd.md              # Product requirements
│   ├── stories/            # User stories
│   └── LEARNINGS.md        # Integration learnings
├── .bmad-core/             # BMAD methodology
├── .ralph/                 # RALPH automation
└── CLAUDE.md               # Claude Code instructions
```

## Documentation

- [Project Brief](docs/brief.md) - Vision and goals
- [PRD](docs/prd.md) - Detailed requirements and stories
- [Learnings](docs/LEARNINGS.md) - Integration discoveries

## Related Projects

- **SciSymbioLens**: Parent iOS app that will receive this integration
- **Veepaisdk**: Source SDK at `/Users/mpriessner/windsurf_repos/Veepaisdk`

## Methodology

This project uses:
- **BMAD**: Breakthrough Method of Agile AI-driven Development
- **RALPH**: Automated story execution
- **TDD**: Test-driven development where applicable

## License

Private - For SciSymbioLens development only.
