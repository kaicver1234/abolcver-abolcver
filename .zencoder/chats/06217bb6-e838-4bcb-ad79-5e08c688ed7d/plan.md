# Spec and build

## Agent Instructions

Ask the user questions when anything is unclear or needs their input. This includes:

- Ambiguous or incomplete requirements
- Technical decisions that affect architecture or user experience
- Trade-offs that require business context

Do not make assumptions on important decisions — get clarification first.

---

## Workflow Steps

### [x] Step: Technical Specification

Assess the task's difficulty, as underestimating it leads to poor outcomes.

- easy: Straightforward implementation, trivial bug fix or feature
- medium: Moderate complexity, some edge cases or caveats to consider
- hard: Complex logic, many caveats, architectural considerations, or high-risk changes

Create a technical specification for the task that is appropriate for the complexity level:

- Review the existing codebase architecture and identify reusable components.
- Define the implementation approach based on established patterns in the project.
- Identify all source code files that will be created or modified.
- Define any necessary data model, API, or interface changes.
- Describe verification steps using the project's test and lint commands.

Save the output to `e:\project\tiksar vpn\tiksa-vpn - MAIN\.zencoder\chats\06217bb6-e838-4bcb-ad79-5e08c688ed7d/spec.md` with:

- Technical context (language, dependencies)
- Implementation approach
- Source code structure changes
- Data model / API / interface changes
- Verification approach

If the task is complex enough, create a detailed implementation plan based on `e:\project\tiksar vpn\tiksa-vpn - MAIN\.zencoder\chats\06217bb6-e838-4bcb-ad79-5e08c688ed7d/spec.md`:

- Break down the work into concrete tasks (incrementable, testable milestones)
- Each task should reference relevant contracts and include verification steps
- Replace the Implementation step below with the planned tasks

Rule of thumb for step size: each step should represent a coherent unit of work (e.g., implement a component, add an API endpoint, write tests for a module). Avoid steps that are too granular (single function).

Save to `e:\project\tiksar vpn\tiksa-vpn - MAIN\.zencoder\chats\06217bb6-e838-4bcb-ad79-5e08c688ed7d/plan.md`. If the feature is trivial and doesn't warrant this breakdown, keep the Implementation step below as is.

---

### [x] Step: Implementation — Fix VPN state not detected after app restart

#### [x] Task 1: Fix `v2ray_provider.dart` — cold-start connection detection

- Increased initial wait from `800ms` to `1500ms`
- Removed `nativeState.isEmpty` from `initExplicitlyDisconnected` condition
- Separated `initExplicitlyDisconnected` from `_v2rayService.activeConfig == null` branch

#### [x] Task 2: Fix `v2ray_service.dart` — increase delay check timeout

- Increased `getConnectedServerDelay()` timeout in `isActuallyConnected()` from `3s` to `5s`

#### [x] Task 3: Write implementation report

Saved to `e:\project\tiksar vpn\tiksa-vpn - MAIN\.zencoder\chats\06217bb6-e838-4bcb-ad79-5e08c688ed7d/report.md`

### [x] Step: Additional fixes (second review)

#### [x] Task 4: Fix `v2ray_service.dart` — `_verifyConnectionInBackground()` too aggressive on cold start

Root cause discovered: background verification fired 3 rapid attempts at t=0 (before plugin bound to VPN service), all returned -1, clearing SharedPreferences before `_initialize()` could use the saved config.

- Added **3-second initial delay** before first check
- Added **2-second delay between failed attempts** (not just exceptions)
- Changed clear threshold from `explicitFailures >= 2` to `explicitFailures >= 3` (all 3 must fail explicitly)

#### [x] Task 5: Fix `modern_home_screen.dart` — timer and stats font

- Changed `GoogleFonts.orbitron` → `GoogleFonts.poppins` for connection timer
- Changed `GoogleFonts.orbitron` → `GoogleFonts.poppins` for download/upload stat values

### [x] Step: Definitive fix — reactive VPN state detection

#### [x] Task 6: Add `waitForNativeStatus()` to `v2ray_service.dart`

Reactive Completer-based method that resolves as soon as `onStatusChanged` delivers
a meaningful state, instead of sleeping a fixed duration.
- Added `_statusWaiters` list of Completers
- Added `_resolveStatusWaiters()` called inside `_handleStatusChange()`
- Added public `waitForNativeStatus({timeout})` that returns immediately if status is already known, otherwise waits up to timeout

#### [x] Task 7: Remove `_verifyConnectionInBackground()` call from `_tryRestoreActiveConfig()`

This was the root cause of ALL race conditions. The background verifier ran at t=0 (before plugin bound to VPN service), all 3 delay checks returned -1, `forceDisconnectedState()` wiped SharedPreferences before `_initialize()` could use the saved config.

The authoritative check is now exclusively done by `_enhancedSyncWithVpnServiceState()`.

#### [x] Task 8: Rewrite `_initialize()` and `_syncVpnStatusOnResume()` in `v2ray_provider.dart`

- Replaced fixed `1500ms delay + polling` with `waitForNativeStatus(timeout: 5s)`
- Native status 'connected'/'running' → confirmed connected immediately
- Native status 'disconnected'/'stopped'/'stop' → confirmed disconnected immediately
- Empty/timeout → one-shot fallback delay check, then ambiguous → keep restored state
- Same pattern applied to `_syncVpnStatusOnResume()` for app foreground case
