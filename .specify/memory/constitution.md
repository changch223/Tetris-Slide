<!--
SYNC IMPACT REPORT
==================
Version change: (uninitialized template) → 1.0.0
Bump rationale: Initial ratification — first concrete population of all five
principles plus governance from the placeholder template.

Principles defined (all new from placeholders):
- I.   SwiftUI-Native Simplicity
- II.  Player-First UX
- III. Localization Parity
- IV.  Ads & Privacy Compliance
- V.   Pragmatic Testing

Sections added:
- Platform & Compliance Constraints (Section 2)
- Development Workflow & Quality Gates (Section 3)

Sections removed: none

Templates reviewed for alignment:
- ✅ .specify/templates/plan-template.md — Constitution Check gate is
     principle-agnostic; no edits required. Reviewers must enforce the five
     principles below at the gate.
- ✅ .specify/templates/spec-template.md — generic structure remains valid;
     no edits required.
- ✅ .specify/templates/tasks-template.md — generic structure remains valid;
     no edits required.
- ✅ CLAUDE.md — pointer-only file; no edits required.

Deferred / TODO: none.
-->

# tetris-2048 Constitution

## Core Principles

### I. SwiftUI-Native Simplicity

The app MUST be built with SwiftUI as the primary UI framework, using
Apple-platform idioms (state, bindings, navigation, Combine where appropriate)
in preference to third-party UI abstractions. New screens MUST start as the
simplest SwiftUI view that satisfies the requirement; introduce ViewModels,
custom modifiers, or wrappers only when duplicated logic or testability
demands it. UIKit interop is permitted only when SwiftUI lacks the needed
capability and MUST be isolated behind a clearly named adapter.

**Rationale**: A solo iOS game ships fastest and stays maintainable when it
follows the platform's default tooling rather than parallel abstractions.

### II. Player-First UX

Every change MUST preserve a smooth, low-friction play experience: target 60
fps on supported devices, sub-100ms response to tile input, and no required
network round-trip on the gameplay path. Modal interruptions (ads, dialogs,
permission prompts) MUST NOT appear during an active move; they are allowed
only between rounds or on explicit user action. New features MUST justify any
added taps on the primary play loop.

**Rationale**: Casual puzzle players abandon games that stutter or interrupt
flow; gameplay smoothness is the product.

### III. Localization Parity

All user-visible strings MUST be added simultaneously to every supported
locale: `en`, `ja`, `zh-Hans`, `zh-Hant`, and `zh-HK`. No string may be
hard-coded in Swift source — all UI text MUST go through `Localizable.strings`
(or `String(localized:)`). A change that adds or modifies a string in one
locale without updating the others MUST NOT be merged. Untranslated copy is
acceptable only as an explicit, time-boxed TODO with the English fallback
clearly marked.

**Rationale**: The app already ships in five locales; partial translations
degrade store ratings and look unprofessional in the affected markets.

### IV. Ads & Privacy Compliance

Ad integration (Google Mobile Ads / AdMob) MUST follow Apple's App Tracking
Transparency rules: the ATT prompt MUST appear before any tracking-enabled
request, and the app MUST function fully when the user denies tracking.
Privacy-impacting SDKs and APIs MUST be reflected in the App Privacy
declarations and (where applicable) the privacy manifest. EU users MUST be
served a UMP/GDPR consent form before personalized ads. Ad placements MUST
NOT obstruct gameplay controls or be triggered without a clear user-initiated
boundary (round end, menu navigation).

**Rationale**: Non-compliance risks App Store rejection, account suspension,
and regulatory penalties — all of which are existential for a solo
publisher.

### V. Pragmatic Testing

Automated tests are encouraged but not mandatory for every change. Pure
gameplay logic (board state, scoring, merge/spawn rules, save/load) MUST have
unit tests covering the happy path and known edge cases. UI flows that have
broken in the past MUST gain a UI test or regression check at the time of
fix. Every release candidate MUST pass a documented manual smoke pass on at
least one physical device covering: launch, each game mode, an ad
impression, locale switch, and resume-from-background.

**Rationale**: A solo iOS project cannot sustain full TDD overhead, but
silent regressions in core game math or release-blocking flows are
unacceptable. This principle targets test effort where bugs actually hurt.

## Platform & Compliance Constraints

- **Target platform**: iOS, deployment target as configured in the Xcode
  project. Raising the deployment target is a MINOR governance event and
  MUST be noted in the changelog.
- **Primary language**: Swift, with SwiftUI as the UI layer.
- **Dependencies**: Managed via CocoaPods (`Podfile`). Adding a new
  third-party SDK requires a written justification (in the PR or commit
  body) covering: purpose, size impact, privacy disclosures triggered, and
  one rejected alternative.
- **Privacy artifacts**: `Info.plist` usage strings, App Privacy answers in
  App Store Connect, and the privacy manifest MUST stay in sync with the
  SDKs and APIs actually in use.
- **Assets & localization**: Strings live in `*.lproj/Localizable.strings`;
  images, sounds, and icons live in `Assets.xcassets`, `Sound/`, and
  `ICON/`. New assets MUST be added through these locations, not loose
  references.

## Development Workflow & Quality Gates

- **Branching**: Feature work happens on a feature branch created via
  `/speckit-git-feature`; direct commits to `main` are reserved for trivial
  fixes.
- **Spec Kit flow**: Non-trivial features SHOULD go through
  `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` →
  `/speckit-implement`. The plan's Constitution Check gate MUST verify the
  five principles above; violations require an entry in the plan's
  Complexity Tracking table with justification.
- **Pre-merge gates** (every change):
  1. Project builds in Xcode with no new warnings on the configured
     deployment target.
  2. Existing unit and UI tests pass.
  3. Any added user-visible string exists in all five locales.
  4. Any new SDK or privacy-impacting API has its declarations updated.
- **Pre-release gates** (every TestFlight / App Store submission):
  1. Manual smoke pass per Principle V on a physical device.
  2. Ad consent (ATT + UMP) flows verified.
  3. Version and build number incremented.
- **Code review**: For solo work, the author MUST self-review the diff
  against this constitution before merging; the checklist above doubles as
  the self-review prompt.

## Governance

- This constitution supersedes ad-hoc preferences and prior conventions.
  When a tool, template, or habit conflicts with a principle here, the
  constitution wins until amended.
- **Amendment procedure**: Edit `.specify/memory/constitution.md` via the
  `/speckit-constitution` flow, which updates the Sync Impact Report,
  bumps the version, and propagates changes to dependent templates.
- **Versioning policy** (semantic):
  - **MAJOR**: A principle is removed or its meaning is materially
    redefined in a backward-incompatible way.
  - **MINOR**: A new principle or governance section is added, or an
    existing one is materially expanded.
  - **PATCH**: Wording, clarification, or typo fixes that do not change
    intent.
- **Compliance review**: Every Spec Kit `plan.md` MUST run the Constitution
  Check gate. Releases MUST confirm the pre-release gates above. Drift
  discovered in review MUST be filed as an amendment, not silently
  tolerated.
- **Runtime guidance**: `CLAUDE.md` and `/specs/<feature>/plan.md` provide
  per-feature technical context. They MUST defer to this constitution on
  any conflict.

**Version**: 1.0.0 | **Ratified**: 2026-05-08 | **Last Amended**: 2026-05-08
