# DawnPulse — Comprehensive Production Audit

## Role

You are a senior security and quality auditor performing a full production audit of DawnPulse, an iOS alarm app with OpenAI integration. Analyze every relevant source file systematically. Be honest and critical — prioritize reliability and user safety over code elegance. This is an alarm app: reliability > features.

**Output:** Generate `audit-report.md` in the project root with the full report structured as specified at the end of this document.

---

## AUDIT SCOPE

The audit covers 10 areas in priority order:

1. **Security & Malicious Code Detection** (P0)
2. **Apple App Store Compliance** (P0)
3. **Privacy & Data Protection** (P0)
4. **Intent & Alarm Reliability** (P0)
5. **API Integration Robustness** (P1)
6. **Performance & Resource Usage** (P1)
7. **Audio System Correctness** (P1)
8. **UI/UX & Accessibility** (P2)
9. **Code Quality & Maintainability** (P2)
10. **Localization & Theme** (P3)

---

## 1. SECURITY & MALICIOUS CODE DETECTION

### 1.1 Network Activity Audit

**Scan entire codebase for ALL network operations. Search for:**
```
URLSession, URLRequest, URLSessionDataTask, URLSessionUploadTask,
URLSessionDownloadTask, URLSessionWebSocketTask, WebSocket,
import Network, import CFNetwork, import WebKit,
CFSocket, CFStream, InputStream, OutputStream,
Alamofire, AFNetworking
```

**For EACH network call found, document:**
```
Location: [File:Line]
Type: [URLSession / Socket / WebSocket / Other]
URL/Endpoint: [exact URL or variable that resolves to URL]
Method: [GET / POST / PUT / DELETE]
Headers: [all headers set]
Body/Payload: [what data is sent]
Purpose: [stated purpose]
Expected: [YES/NO — is this a documented, approved call?]
Risk Level: [CRITICAL / HIGH / MEDIUM / LOW]
```

**Approved network endpoints (whitelist):**
- `https://api.openai.com/v1/chat/completions` — GPT message generation
- `https://api.openai.com/v1/audio/speech` — TTS generation
- `*.apple.com` — system services only

**ANYTHING ELSE is a RED FLAG.** Specifically flag:
- Analytics endpoints not disclosed to users
- Tracking pixels or ad network calls
- Unknown domains or IP addresses
- Shortened URLs (bit.ly, t.co, etc.)
- Developer personal servers
- Any URL constructed from variables, config files, or downloaded data
- Any URL decoded from base64 or obfuscated strings

### 1.2 Obfuscation & Suspicious Patterns

**Search for:**
```swift
base64EncodedString, base64EncodedData, Data(base64Encoded:)
NSClassFromString, NSSelectorFromString, performSelector
dlopen, dlsym
ProcessInfo.processInfo (jailbreak detection without justification)
ptrace, sysctl (anti-debugging without justification)
UIPasteboard (clipboard access without user action)
UIScreen.main.snapshotView (screen capture)
```

**Flag any:**
- Obfuscated strings (base64-encoded URLs, XOR-encoded data)
- Dynamic code execution (eval-like patterns, runtime method resolution)
- Timer-based beacon behavior (periodic network calls without user trigger)
- Anti-debugging or jailbreak detection (unusual for an alarm app)
- Code that runs silently on app launch with no user interaction

### 1.3 Third-Party Dependencies

**Inventory ALL dependencies** (CocoaPods, SPM, Carthage, vendored frameworks):
```
For each dependency:
- Name and version
- Source (official repo or fork?)
- Purpose in the app
- Known CVEs (check advisories)
- Network activity (does it phone home?)
- Data collection (what does it access?)
- License compatibility
```

**Flag:** Any dependency not strictly necessary, any dependency with known vulnerabilities, any dependency that collects user data.

### 1.4 Data Exfiltration Check

**Verify NO unauthorized data leaves the device:**
- [ ] API keys never sent anywhere except OpenAI API Authorization header
- [ ] User personal data (name, birthday, zodiac, interests) only sent to OpenAI in the prompt
- [ ] Music library metadata only used locally (except batch categorization to OpenAI)
- [ ] Calendar event titles only used locally in prompt building
- [ ] Device identifiers (IDFA, IDFV, UUID) never collected or transmitted
- [ ] No screenshots, photos, contacts, or health data accessed
- [ ] No clipboard reading without explicit user action

---

## 2. APPLE APP STORE COMPLIANCE

### 2.1 App Store Review Guidelines Compliance

**Guideline 1.x — Safety:**
- [ ] No content inappropriate for the age rating
- [ ] TTS-generated content cannot produce harmful/offensive output (check prompt constraints)
- [ ] User-generated prompt content cannot be used to generate harmful content via the app

**Guideline 2.1 — App Completeness:**
- [ ] App is fully functional without requiring external accounts (graceful degradation without OpenAI key)
- [ ] No placeholder content, test data, or debug screens visible in release build
- [ ] All features described in App Store metadata actually work
- [ ] No broken links or dead-end flows

**Guideline 2.3 — Accurate Metadata:**
- [ ] App name matches across bundle, Info.plist, and App Store listing
- [ ] Screenshots accurately represent the app
- [ ] Description matches actual functionality
- [ ] Category selection appropriate (Utilities? Lifestyle?)

**Guideline 2.5.1 — Software Requirements:**
- [ ] Only uses public APIs (no private frameworks)
- [ ] No deprecated APIs that will cause rejection
- [ ] Minimum iOS version set correctly in Info.plist
- [ ] No UIKit usage that conflicts with SwiftUI lifecycle if declared as SwiftUI-only

**Guideline 3.1.1 — In-App Purchase:**
- [ ] If the app requires an OpenAI API key (user pays externally), this is clearly disclosed
- [ ] The app does not sell, resell, or broker access to OpenAI services
- [ ] No IAP required? Verify no hidden paywalls

**Guideline 4.0 — Design:**
- [ ] App provides value beyond a simple web wrapper
- [ ] UI follows iOS Human Interface Guidelines basics
- [ ] No mimicking system UI (fake alerts, fake settings)

**Guideline 5.1 — Privacy:**
- [ ] Privacy Policy URL provided and accessible
- [ ] Privacy Policy accurately describes all data collection
- [ ] App Privacy labels (App Store Connect) match actual data practices:
  - Data linked to user? (name, interests, birthday, zodiac — all local?)
  - Data used for tracking? (must be NO)
  - Data collected? (list all categories accurately)
- [ ] `NSPrivacyTracking` set to `false` in PrivacyInfo.xcprivacy
- [ ] `NSPrivacyTrackingDomains` is empty
- [ ] All `NSPrivacyAccessedAPITypes` declared with valid `NSPrivacyAccessedAPITypeReasons`
- [ ] `NSPrivacyCollectedDataTypes` complete and accurate

**Guideline 5.1.1 — Data Collection and Storage:**
- [ ] Data collected is necessary for app functionality
- [ ] User can delete their data
- [ ] Data is not shared with third parties (except OpenAI for core functionality, disclosed)

**Guideline 5.1.2 — Data Use and Sharing:**
- [ ] OpenAI data sharing disclosed in privacy policy
- [ ] User consents before API key is used
- [ ] No data shared with other third parties

### 2.2 Info.plist & Entitlements

**Usage Descriptions (must exist for every permission requested):**
- [ ] `NSAppleMusicUsageDescription` — present, clear, accurate
- [ ] `NSCalendarsUsageDescription` — present if calendar used
- [ ] `NSSpeechRecognitionUsageDescription` — NOT present (we don't use speech recognition)
- [ ] `NSMicrophoneUsageDescription` — NOT present (we don't record audio)
- [ ] `NSLocationWhenInUseUsageDescription` — NOT present (we don't use location)
- [ ] `NSCameraUsageDescription` — NOT present
- [ ] `NSContactsUsageDescription` — NOT present
- [ ] `NSPhotoLibraryUsageDescription` — NOT present

**Every usage description string must clearly explain WHY the permission is needed in user-friendly language.**

**Flag any permission requested that the app does not actually use.**

**Entitlements:**
- [ ] Only necessary entitlements enabled
- [ ] Background modes: only those actually used (audio, background fetch if applicable)
- [ ] No App Groups unless justified
- [ ] No Keychain sharing unless justified
- [ ] Push notifications: only if implemented

### 2.3 App Transport Security

- [ ] No `NSAllowsArbitraryLoads` in Info.plist (must be absent or false)
- [ ] No ATS exceptions unless justified and documented
- [ ] All network calls use HTTPS

### 2.4 Build & Submission Readiness

- [ ] Bundle identifier correct and unique
- [ ] Version number semantic (X.Y.Z)
- [ ] Build number incremented
- [ ] All required app icons present (all sizes)
- [ ] Launch screen configured (no black screen on launch)
- [ ] Deployment target matches declared minimum iOS version
- [ ] No debug code, test API keys, or development flags in release configuration
- [ ] No `print()` or `NSLog()` statements that could leak sensitive data in release builds
- [ ] Bitcode setting correct for current Xcode requirements
- [ ] Archive builds successfully with no warnings that would cause rejection

### 2.5 Required API Reason Declarations (iOS 17+)

**PrivacyInfo.xcprivacy must declare reasons for these APIs if used:**
- [ ] UserDefaults — reason declared if used
- [ ] File timestamp APIs — reason declared if used
- [ ] System boot time APIs — reason declared if used
- [ ] Disk space APIs — reason declared if used
- [ ] Active keyboard APIs — reason declared if used

**Scan codebase for usage of these APIs and verify each has a corresponding reason in PrivacyInfo.xcprivacy.**

---

## 3. PRIVACY & DATA PROTECTION

### 3.1 Sensitive Data Storage

**Audit ALL storage locations:**

| Data | Required Storage | Verify |
|------|-----------------|--------|
| OpenAI API key | Keychain only | Never in UserDefaults, Core Data, files, or logs |
| User name | UserDefaults or Core Data | Acceptable, not highly sensitive |
| Birthday | UserDefaults or Core Data | Acceptable |
| Religion | MUST NOT EXIST | Remove from everywhere (tracked bug) |
| Interests | UserDefaults or Core Data | Acceptable |
| Calendar events | In-memory only | Never persisted by the app |
| Music library data | Core Data (categorization) | Only metadata, no audio content |
| TTS audio files | Temp directory | Deleted after playback |
| Messages generated | Cache (with TTL) | Not persisted long-term |

**Search for API key leaks:**
```
Search patterns: print.*apiKey, print.*key, log.*apiKey, 
NSLog.*key, os_log.*key, Logger.*key, debugPrint.*key
```

- [ ] API key never appears in error messages shown to user
- [ ] API key never in crash logs
- [ ] API key never in Intent parameters
- [ ] API key cleared from memory after use where feasible

### 3.2 Data Retention & User Control

- [ ] User can delete all categorization data (reset function exists)
- [ ] User can delete their profile data
- [ ] User can remove their API key
- [ ] Old data has retention limits (activation history, message cache, debug logs)
- [ ] App does not retain data after deletion request

### 3.3 GDPR / CCPA Compliance

- [ ] User can access their stored data
- [ ] User can delete their stored data
- [ ] Data collection is disclosed in privacy policy
- [ ] OpenAI data processing is disclosed
- [ ] No data shared with undisclosed third parties
- [ ] Consent obtained before first API call

---

## 4. INTENT & ALARM RELIABILITY

### 4.1 Entry Points

**All three entry paths must be tested and verified:**

| Entry | Handler | Expected Behavior |
|-------|---------|-------------------|
| iOS Shortcuts | `ActivateDawnPulseIntent.perform()` | Fire-and-forget, no 30s timeout |
| Native alarm | `AppDelegate` notification handler | Direct orchestrator trigger |
| URL scheme | `dawnpulse://activate` | Parse parameters, trigger |

**For each entry point verify:**
- [ ] Routes to the same `SmartAlarmOrchestrator.trigger()`
- [ ] No double-trigger if called twice rapidly
- [ ] Source tag recorded in activation history
- [ ] Failure path provides audio feedback (never silent)

### 4.2 Failure Mode Testing

**Test each scenario and document actual behavior:**

| Scenario | Expected | Verify |
|----------|----------|--------|
| No network | Template message + Apple TTS + random song | Never silent |
| Invalid API key | Offline mode + setup nudge | Clear user feedback |
| GPT timeout (>15s) | Fallback message + default mood | No hang |
| GPT invalid JSON | Raw text + fallback mood .uplifting | No crash |
| TTS timeout (>20s) | Apple TTS fallback | No hang |
| Empty music library | Bundled fallback audio | Verify alarm.mp3 exists |
| All clusters empty | Random from library, then bundled fallback | Fallback chain works |
| Permission denied (music) | Bundled fallback, graceful UI message | No crash |
| App killed during alarm | Music should stop, no orphaned state | Clean state on relaunch |
| Phone call during alarm | Audio pauses, resumes or stops cleanly | No crash |
| Low memory warning | Non-critical resources released | No crash |
| Multiple Intent triggers rapidly | Only one alarm executes | Deduplication works |

### 4.3 Thread Safety

- [ ] `SmartAlarmOrchestrator`: `@MainActor` applied correctly
- [ ] `SpeechService`: `NSLock` protects concurrent access
- [ ] `tryActivate()` and `tryFinish()` are atomic
- [ ] No data races (run Thread Sanitizer)
- [ ] `Published` properties only updated on main thread
- [ ] Core Data contexts used on correct threads (main vs background)
- [ ] No retain cycles in closures (`[weak self]` everywhere needed)

### 4.4 State Machine Integrity

- [ ] Alarm state machine has clear states (idle, loading, playing, finishing, dismissed)
- [ ] Every state transition is valid (no illegal jumps)
- [ ] State reset on dismiss is complete (no leaked state)
- [ ] `hasFinished` flag prevents double-completion
- [ ] Grace period (2s) allows UI to show completion before dismiss

---

## 5. API INTEGRATION ROBUSTNESS

### 5.1 OpenAI GPT

- [ ] Model string correct and not deprecated
- [ ] `response_format: {"type": "json_object"}` used for JSON mode
- [ ] System prompt explicitly says "respond with JSON" (required by OpenAI for JSON mode)
- [ ] max_tokens set appropriately (not too high, not too low)
- [ ] Temperature reasonable (0.7-0.8 for creative text)
- [ ] Timeout: 15s per request, 30s overall — appropriate?
- [ ] Retry: 3 attempts with exponential backoff (1s, 2s, 4s)
- [ ] 429 rate limit handling: does NOT retry (correct for rate limits)
- [ ] Invalid API key: fails immediately, no retry (correct)
- [ ] Response validation: JSON parsed, mood enum validated, message non-empty
- [ ] Prompt injection risk: calendar event titles injected into prompt without sanitization — **flag this**

### 5.2 OpenAI TTS

- [ ] Model: tts-1-hd (quality appropriate for wake-up)
- [ ] Voice: configurable, default reasonable
- [ ] Speed: 1.0 (fixed — should this be configurable?)
- [ ] Format: mp3 (appropriate for iOS playback)
- [ ] Timeout: 20s — appropriate?
- [ ] Retry: 2 attempts with 2s delay
- [ ] Fallback: Apple `AVSpeechSynthesizer` — verified working?
- [ ] Cache: `TTSCacheManager` stores by (message + voice) — cache invalidation?
- [ ] Temp file cleanup: MP3 files deleted after playback?
- [ ] Playback safety timeout: 300s (5 min) — what happens when it fires?

### 5.3 Calendar & Weather Services

- [ ] Calendar permission requested at appropriate time
- [ ] Calendar denied: graceful fallback (no events in prompt)
- [ ] Weather fetch: best-effort, non-blocking
- [ ] Weather unavailable: omitted from prompt, no error to user
- [ ] No calendar data persisted by the app
- [ ] No weather data persisted beyond current session

---

## 6. PERFORMANCE & RESOURCE USAGE

### 6.1 Memory

**Run Instruments Leaks for 5 minutes of continuous alarm triggers.**

**Targets:**
- Idle: < 30 MB
- Alarm active: < 50 MB
- Categorization peak: < 100 MB
- Leaks: 0

**Check specifically:**
- [ ] `SmartAlarmOrchestrator` — all tasks cancelled in deinit
- [ ] `AVAudioPlayer` — stopped and deallocated after use
- [ ] `MPMusicPlayerController` — notification observers removed
- [ ] Timer objects — all invalidated
- [ ] Monitoring tasks — all cancelled on dismiss
- [ ] Core Data — fetch requests use batch size, no full-library loads
- [ ] Temp audio files — deleted after playback
- [ ] No memory growth over 10 consecutive alarms

### 6.2 CPU

**Run Time Profiler during alarm trigger and categorization.**

**Targets:**
- Idle: < 1%
- Alarm trigger: < 30% sustained
- Categorization: < 50% sustained

**Hot paths to check:**
- JSON parsing of GPT responses
- Core Data queries during song selection
- Fuzzy string matching (Levenshtein)
- UI rendering during playback view

### 6.3 Battery

- [ ] No background refresh when not needed
- [ ] No location services
- [ ] Audio session deactivated when not in use
- [ ] No network polling
- [ ] Target: < 5% battery per alarm

### 6.4 Launch Performance

**Timing breakdown for Intent → audio:**
- Intent invoke → app foreground: target < 2s
- Foreground → UI visible: target < 1s
- UI visible → first audio: target < 10s
- Total: target < 13s

---

## 7. AUDIO SYSTEM CORRECTNESS

### 7.1 Audio Session

- [ ] Category: `.playback` (plays with silent switch off)
- [ ] Options: `.duckOthers`, `.mixWithOthers`
- [ ] Session activated before playback, deactivated after
- [ ] Interruption handling (phone call): documented behavior
- [ ] No interference with other apps' audio after alarm dismissed

### 7.2 Volume Control

- [ ] Volume ramp logic: verify smooth progression (5% → target)
- [ ] `userMusicVolume` setting actually respected during playback
- [ ] Ducking ratio (0.3) applied to correct base value
- [ ] `MPMusicPlayerController` volume limitations documented
- [ ] `AVAudioPlayer` volume works as expected
- [ ] Volume restored correctly after TTS ends
- [ ] Debug log entry for every volume change (value + reason)

### 7.3 Playback State

- [ ] Song end detection reliable (monitor polling 0.2s)
- [ ] Stop command interrupts immediately
- [ ] No audio artifacts (clicks, pops, silence gaps)
- [ ] Fade-out actually works when "Dissolvenza e stop" selected
- [ ] No orphaned audio after dismiss

---

## 8. UI/UX & ACCESSIBILITY

### 8.1 Accessibility

- [ ] VoiceOver: all interactive elements labeled
- [ ] VoiceOver: playback controls accessible
- [ ] Dynamic Type: text scales correctly
- [ ] Contrast: WCAG AA compliance (4.5:1 for text)
- [ ] Reduce Motion: animations respect system setting
- [ ] Color: information not conveyed by color alone

### 8.2 UI Correctness

- [ ] All screens tested on smallest iPhone (SE) and largest (Pro Max)
- [ ] Safe Area respected everywhere
- [ ] No text truncation with longest localized strings
- [ ] Loading states visible during async operations
- [ ] Error states shown to user (not silent failures)
- [ ] No hardcoded strings (all in Localizable.strings)

### 8.3 Dark/Light Mode

- [ ] All screens adapt correctly
- [ ] No hardcoded colors (use semantic colors)
- [ ] Gradients readable in both modes
- [ ] Icons/symbols visible in both modes
- [ ] Switch during playback doesn't break UI

---

## 9. CODE QUALITY & MAINTAINABILITY

### 9.1 Architecture

- [ ] MVVM pattern consistently applied
- [ ] Separation of concerns: Views, ViewModels, Services
- [ ] Dependency injection used (protocols, not concrete types)
- [ ] No business logic in Views
- [ ] No UI logic in Services

### 9.2 Error Handling

- [ ] Zero force unwraps (`!`) in v2.x code — flag every instance
- [ ] All `try` have proper `catch` with logging
- [ ] All `try?` have comment explaining why error is ignored
- [ ] User-facing errors are localized
- [ ] Fallback chains complete — no dead-end error paths

### 9.3 Code Hygiene

- [ ] No `print()` in production code (use structured logging)
- [ ] No TODO/FIXME without tracking reference
- [ ] No dead code or commented-out blocks
- [ ] No magic numbers (use named constants)
- [ ] No code duplication > 10 lines (DRY)
- [ ] Naming conventions consistent (Swift style)

### 9.4 Testing

- [ ] Unit test coverage for business logic: target > 60%
- [ ] Critical paths covered: alarm trigger, GPT call, song selection, fallback chain
- [ ] Mock services exist for offline testing
- [ ] No flaky tests

---

## 10. LOCALIZATION & THEME

### 10.1 Localization (5 languages: en, it, es, fr, de)

- [ ] All user-facing strings in Localizable.strings
- [ ] All 5 language files complete (no missing keys)
- [ ] No hardcoded strings in new code
- [ ] Error messages localized
- [ ] Date/number formatting uses locale
- [ ] Text fits in UI for all languages (German tends to be longest)
- [ ] TTS voice matches selected language

### 10.2 Theme

- [ ] System/Light/Dark modes all functional
- [ ] Theme change immediate (no restart required)
- [ ] Theme persisted across sessions
- [ ] System mode follows iOS appearance setting

---

## REPORT FORMAT

Generate `audit-report.md` with this exact structure:

```markdown
# DawnPulse Audit Report — [DATE]
## Version: [VERSION FROM CODE]

---

## EXECUTIVE SUMMARY

**Release Readiness:** GO / NO-GO
**Overall Health Score:** X/10
**Critical Issues (P0):** X
**High Priority (P1):** X
**Medium Priority (P2):** X
**Low Priority (P3):** X

**Release Blockers:**
- [List all P0 issues]

**Top 3 Recommendations:**
1. [Highest impact fix]
2. [Second highest]
3. [Third highest]

---

## SECURITY FINDINGS

### Network Endpoints Found

| URL | Purpose | Expected? | Risk | Action |
|-----|---------|-----------|------|--------|
| [each endpoint] | | | | |

### Data Storage Audit

| Data | Storage Location | Encrypted? | Expected? | Risk |
|------|-----------------|------------|-----------|------|
| [each data type] | | | | |

### Dependency Audit

| Name | Version | Purpose | CVEs | Risk |
|------|---------|---------|------|------|
| [each dependency] | | | | |

### Permissions Audit

| Permission | Declared? | Used? | Justified? | Risk |
|------------|-----------|-------|------------|------|
| [each permission] | | | | |

---

## APP STORE COMPLIANCE

### Review Guidelines Check

| Guideline | Status | Notes |
|-----------|--------|-------|
| 1.x Safety | ✅/⚠️/❌ | |
| 2.1 Completeness | ✅/⚠️/❌ | |
| 2.3 Metadata | ✅/⚠️/❌ | |
| 2.5.1 APIs | ✅/⚠️/❌ | |
| 3.1.1 IAP | ✅/⚠️/❌ | |
| 4.0 Design | ✅/⚠️/❌ | |
| 5.1 Privacy | ✅/⚠️/❌ | |
| 5.1.1 Data | ✅/⚠️/❌ | |
| 5.1.2 Sharing | ✅/⚠️/❌ | |

### PrivacyInfo.xcprivacy

| API Category | Used? | Reason Declared? | Correct? |
|-------------|-------|-----------------|----------|
| [each API type] | | | |

### Info.plist & Entitlements

| Key | Present? | Correct? | Notes |
|-----|----------|----------|-------|
| [each relevant key] | | | |

---

## ISSUES BY PRIORITY

### P0 — CRITICAL (Block Release)

For each issue:
- **ID:** AUDIT-XXX
- **Category:** Security / Compliance / Reliability / Performance
- **Location:** File:Line
- **Description:** What is wrong
- **Impact:** What happens if not fixed
- **Risk Score:** 0-100 (likelihood × severity)
- **Reproduction:** Steps to reproduce
- **Fix:** Recommended solution
- **Effort:** S (<2h) / M (2-8h) / L (>8h)

### P1 — HIGH (Fix Before Release)
[same format]

### P2 — MEDIUM (Fix Soon)
[same format]

### P3 — LOW (Nice to Have)
[same format]

---

## PERFORMANCE METRICS

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Memory (idle) | <30 MB | | |
| Memory (alarm) | <50 MB | | |
| Memory (categorization) | <100 MB | | |
| CPU (idle) | <1% | | |
| CPU (alarm) | <30% | | |
| CPU (categorization) | <50% | | |
| Intent → audio | <13s | | |
| Battery per alarm | <5% | | |
| Leaks | 0 | | |
| Force unwraps (new code) | 0 | | |

---

## v2.0.0 REGRESSION

| Feature | Status | Notes |
|---------|--------|-------|
| Native alarms | ✅/❌ | |
| Settings preserved | ✅/❌ | |
| Performance baseline | ✅/❌ | |
| No new crashes | ✅/❌ | |

---

## POSITIVE FINDINGS
[Things done well, patterns to keep and replicate]

---

## RECOMMENDATIONS

### Immediate (before release)
1. [Fix]
2. [Fix]

### Short-term (patch release)
1. [Improvement]

### Long-term (next version)
1. [Architecture improvement]

---

## CLEAN CODE CERTIFICATE

**Can issue clean certificate:** YES / NO

**Blockers:**
- [List all remaining blockers]

**Re-audit required after fixes:** YES / NO
```

---

## EXECUTION INSTRUCTIONS

1. **Read ALL source files** before starting the report. Do not produce partial findings.
2. **Be specific** — always include file path and line number for every finding.
3. **Test where possible** — if you can determine behavior from code analysis, document it. If runtime testing is needed, say so explicitly.
4. **Prioritize ruthlessly** — P0 means "do not ship without fixing this." Use it sparingly but firmly.
5. **No diplomatic language** — if something is broken, say it's broken. If something is a security risk, say it clearly.
6. **Document positives** — good patterns should be called out for replication.
7. **Save the report** as `audit-report.md` in the project root.
