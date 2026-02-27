# Technical Specification: VPN Connection State Not Detected After App Restart

## Complexity Assessment
**Medium** — Race condition in async initialization flow involving native plugin binding, SharedPreferences, and multiple overlapping state checks.

---

## Technical Context
- **Language**: Flutter/Dart
- **Platform**: Android
- **Key files**: `lib/providers/v2ray_provider.dart`, `lib/services/v2ray_service.dart`
- **Dependencies**: `flutter_v2ray_client`, `shared_preferences`

---

## Root Cause Analysis

### Bug: UI shows "Disconnected" after kill-and-restart even though VPN is running

**Scenario**: User connects to VPN → kills app → reopens app → UI shows disconnected.

### Execution flow on cold start (app was killed):

1. `V2RayProvider` constructor calls `_initialize()`
2. `_v2rayService.initialize()` → `_tryRestoreActiveConfig()`:
   - Reads `active_config` from SharedPreferences → sets `_activeConfig` optimistically
   - Spawns `_verifyConnectionInBackground()` asynchronously
3. **Wait 800ms** for native VPN status callback
4. Check `_currentStatus?.state` (the status from flutter_v2ray's `onStatusChanged` callback)
5. If native state is empty/unknown, call `getConnectedServerDelayDirect()` with 6s timeout
6. If delay check returns `-1` (explicit not-connected) AND native state is empty → **`initExplicitlyDisconnected = true`**
7. `_loadSavedStateAndShowUI()` — shows optimistic UI
8. Because `initExplicitlyDisconnected = true` → **calls `forceDisconnectedState()`**
   - This clears `_activeConfig` in memory
   - **This also removes `active_config` key from SharedPreferences**
9. `fetchServers()` replaces all configs; `_v2rayService.activeConfig` is now null → no config marked connected
10. `_enhancedSyncWithVpnServiceState()` → `isActuallyConnected()`:
    - Delay check with **3s timeout** — might fail/timeout on cold start
    - Tries to load saved config from SharedPreferences → **already cleared in step 8**
    - Returns false
11. All configs marked disconnected → UI shows disconnected ❌

### Bug #1 (Critical): Empty native state treated as explicit disconnect
In `_initialize()` ~line 453:
```dart
if (nativeState == 'disconnected' || nativeState == 'stopped' ||
    nativeState == 'stop' || nativeState.isEmpty) {  // ← WRONG
  initExplicitlyDisconnected = true;
}
```
After a cold start, the flutter_v2ray plugin needs time to **rebind to the Android VPN service**. During this binding period (typically 1-3s), `_currentStatus` is null/empty. This is ambiguous — NOT the same as "VPN is explicitly disconnected". Treating empty state as explicit disconnect is incorrect.

### Bug #2 (Contributing): Initial wait too short
800ms may not be enough for the plugin to bind to the VPN service and receive the connected status event, especially on slower devices.

### Bug #3 (Contributing): `forceDisconnectedState()` clears SharedPreferences prematurely
`forceDisconnectedState()` removes `active_config` from SharedPreferences. This prevents later recovery in `isActuallyConnected()` (PRIORITY 3 path and restore path both depend on the saved config). Calling it during initialization — before all async checks complete — is premature.

### Bug #4 (Contributing): Short timeout in `isActuallyConnected()`
3-second timeout for `getConnectedServerDelay()` in `isActuallyConnected()` is too short during cold start when the plugin is still binding to the VPN service.

---

## Implementation Approach

### Fix 1 (Critical): Remove `nativeState.isEmpty` from explicit disconnect condition

**File**: `lib/providers/v2ray_provider.dart`

Remove `nativeState.isEmpty` from the condition that sets `initExplicitlyDisconnected`. Only treat explicit states ('disconnected', 'stopped', 'stop') as confirmation that VPN is not running. Empty state means "not yet received" — ambiguous.

**Effect**: With `initExplicitlyDisconnected = false` (when native state is empty), the init flow goes to the ambiguous/timeout branch and keeps the restored state. `_enhancedSyncWithVpnServiceState()` then runs the authoritative check.

### Fix 2: Increase initial wait from 800ms to 1500ms

**File**: `lib/providers/v2ray_provider.dart`

Give the flutter_v2ray plugin more time to bind to the Android VPN service and receive the connected status event before we make decisions.

### Fix 3: Separate `initExplicitlyDisconnected` from `activeConfig == null` in clearing logic

**File**: `lib/providers/v2ray_provider.dart`

When `_v2rayService.activeConfig == null` (no previously saved config), calling `forceDisconnectedState()` is redundant (it's a no-op since activeConfig is already null). But it's semantically cleaner to not call it in that case. The important change is: only call `forceDisconnectedState()` when `initExplicitlyDisconnected = true`, so that SharedPreferences is only cleared when VPN is definitively confirmed as not running.

### Fix 4: Increase timeout in `isActuallyConnected()`

**File**: `lib/services/v2ray_service.dart`

Increase the `getConnectedServerDelay()` timeout from 3s to 5s to give the plugin more time to respond during cold start.

---

## Source Code Changes

| File | Change |
|------|--------|
| `lib/providers/v2ray_provider.dart` | Remove `nativeState.isEmpty` from disconnect condition; increase initial wait to 1500ms; separate explicit-disconnect and no-active-config branches |
| `lib/services/v2ray_service.dart` | Increase delay check timeout in `isActuallyConnected()` from 3s to 5s |

---

## Verification Approach
1. Connect to VPN
2. Force-kill the app (via Android task manager / `adb shell am force-stop`)
3. Reopen the app
4. Verify UI shows "Connected" with the correct server name
5. Verify the disconnect button works to actually disconnect
6. Test on both fast and slow networks/devices
