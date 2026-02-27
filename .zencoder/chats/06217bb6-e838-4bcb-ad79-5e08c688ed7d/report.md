# Implementation Report: VPN State Not Detected After App Restart

## What Was Implemented

Four targeted fixes across two files to resolve the bug where the UI shows "Disconnected" after the user kills and reopens the app while VPN is still running.

---

### Fix 1 — `v2ray_provider.dart`: Increased initial wait (800ms → 1500ms)

The flutter_v2ray plugin binds to the Android VPN service **asynchronously** on cold start. The previous 800ms was often not enough for the plugin to receive the VPN connected status event, especially on slower devices. Increasing to 1500ms gives the binding enough time to complete before state decisions are made.

### Fix 2 — `v2ray_provider.dart`: Removed `nativeState.isEmpty` from explicit disconnect condition ⭐ Critical fix

**Before:**
```dart
if (nativeState == 'disconnected' || nativeState == 'stopped' ||
    nativeState == 'stop' || nativeState.isEmpty) {
  initExplicitlyDisconnected = true;
}
```

**After:**
```dart
if (nativeState == 'disconnected' || nativeState == 'stopped' ||
    nativeState == 'stop') {
  initExplicitlyDisconnected = true;
}
```

Empty native state during cold start means "not yet received" — it is ambiguous, **not** the same as disconnected. Treating it as explicit disconnect caused `forceDisconnectedState()` to be called, which erased `active_config` from SharedPreferences — permanently destroying any chance of state recovery.

### Fix 3 — `v2ray_provider.dart`: Separated explicit-disconnect from no-active-config branch

`forceDisconnectedState()` (which clears SharedPreferences) is now **only** called when `initExplicitlyDisconnected = true` (i.e., native VPN service explicitly confirmed VPN is not running). The `_v2rayService.activeConfig == null` case (user was simply never connected) now only clears in-memory flags — no SharedPreferences erasure needed.

This preserves the saved `active_config` key until `_enhancedSyncWithVpnServiceState()` makes the final authoritative determination.

### Fix 4 — `v2ray_service.dart`: Increased timeout in `isActuallyConnected()` (3s → 5s)

The `getConnectedServerDelay()` call in `isActuallyConnected()` now has a 5-second timeout instead of 3 seconds. On cold start, the plugin may need extra time to bind to the VPN service before being able to respond. The longer timeout prevents false-negative detection.

---

## How the Fixed Flow Works (Cold Start with VPN Running)

1. Plugin initializes, optimistically restores `_activeConfig` from SharedPreferences
2. Wait 1500ms — plugin binds to VPN service, likely receives "connected" event
3. If native state = "connected" → `isVpnConnected = true` → done ✓
4. If still ambiguous, delay check runs (6s timeout)
5. If delay check returns `-1` AND native state is now explicitly "disconnected" → `initExplicitlyDisconnected = true`
6. If native state is **empty** (still binding) → NOT treated as explicit disconnect → keeps restored state
7. `_enhancedSyncWithVpnServiceState()` runs as the final check with 5s timeout
8. Confirms VPN is running → marks correct config as connected → UI shows connected ✓

---

## Files Modified

| File | Lines Changed |
|------|--------------|
| `lib/providers/v2ray_provider.dart` | ~432, ~452–461, ~500–524 |
| `lib/services/v2ray_service.dart` | ~949 |

---

## Testing Instructions

1. Connect to VPN via the app
2. Force-kill the app (Android task manager or `adb shell am force-stop com.tiksarvpn.app`)
3. Reopen the app
4. Verify: UI shows **Connected** with the correct server name within ~3 seconds of app open
5. Verify: Disconnect button works and actually disconnects
6. Repeat on a slow network to confirm the longer timeouts help
