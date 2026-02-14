---
name: apple-compliance-audit
cluster: mobile
description: "Apple App Store compliance audit for iOS apps covering Info.plist, entitlements, privacy manifests, App Store Review Guidelines, HIG, security, and submission readiness. Use when preparing an iOS app for App Store submission or verifying compliance after adding capabilities."
---

# Apple Compliance Audit

> **Version**: 1.1.0 | **Last updated**: 2026-02-14

## Purpose

Static-analysis compliance audit against Apple App Store Review Guidelines, Human Interface Guidelines, and iOS technical requirements. Produces a structured report with BLOCKER / WARNING / IMPROVEMENT findings. Designed to catch rejection reasons before submission.

---

## When to Run

| Trigger | Scope |
|---------|-------|
| Before every App Store submission | Full audit (all sections) |
| After adding a new capability or framework | Sections 1-2 |
| Weekly check during development | Quick audit (10 critical checks) |
| After a major iOS version update | Sections 3-4 |
| After adding a third-party SDK | Sections 2, 5 |

---

## Section 1 — Project Configuration & Build

### 1.1 Info.plist

Search ALL Info.plist files in the project. Verify:

- [ ] `CFBundleDisplayName` and `CFBundleName` are consistent
- [ ] `CFBundleShortVersionString` uses semantic versioning (X.Y.Z)
- [ ] `CFBundleVersion` is incremental and unique per submission
- [ ] `MinimumOSVersion` matches the deployment target
- [ ] `LSApplicationQueriesSchemes` declared if the app calls `canOpenURL()`
- [ ] `CFBundleURLTypes` declared if the app registers URL schemes
- [ ] `UIBackgroundModes` — every declared mode is actually used in code:
  - `audio` — app plays audio in background?
  - `fetch` — app uses background fetch?
  - `processing` — app uses `BGProcessingTask`?
  - `location` — app tracks location in background?
  - `remote-notification` — app receives push?
- [ ] `UILaunchStoryboardName` or `UILaunchScreen` configured
- [ ] `UISupportedInterfaceOrientations` appropriate for the app

**Rejection patterns**: unused background modes, duplicate `CFBundleVersion`, `MinimumOSVersion` too low for APIs used.

### 1.2 Entitlements

Search ALL `.entitlements` files. For each entitlement:

- [ ] Corresponding capability is actually needed and used in code
- [ ] Developer Portal activation verified (flag if not verifiable)
- [ ] Key entitlements to check:
  - `com.apple.developer.applesignin` — Sign in with Apple used?
  - `com.apple.developer.weatherkit` — WeatherKit used?
  - `com.apple.developer.usernotifications.critical-alerts` — justified?
  - `com.apple.security.app-sandbox` — correct for target?
  - `keychain-access-groups` — groups appropriate?
  - `aps-environment` — push configured?

**Risk**: entitlement present but capability unused = REJECTION. Capability used but entitlement missing = CRASH on device.

### 1.3 Build Settings

Check `.pbxproj` or build settings:

- [ ] `SWIFT_STRICT_CONCURRENCY` set (recommended: `complete`)
- [ ] `ENABLE_BITCODE = NO` (deprecated, must be NO)
- [ ] `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` match Info.plist
- [ ] `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym` for Release
- [ ] No debug settings leak into Release (`GCC_PREPROCESSOR_DEFINITIONS`, `SWIFT_ACTIVE_COMPILATION_CONDITIONS`)
- [ ] Code signing identity correct for Release vs Debug

---

## Section 2 — Privacy & User Data

### 2.1 Privacy Manifest (PrivacyInfo.xcprivacy)

**Mandatory since May 2024** — missing file = certain rejection.

- [ ] `PrivacyInfo.xcprivacy` exists in the project
- [ ] `NSPrivacyTracking` — consistent with actual tracking behavior
- [ ] `NSPrivacyTrackingDomains` — listed if tracking is true
- [ ] `NSPrivacyCollectedDataTypes` — all collected data types declared with:
  - `NSPrivacyCollectedDataType` (type)
  - `NSPrivacyCollectedDataTypeLinked` (linked to identity?)
  - `NSPrivacyCollectedDataTypeTracking` (used for tracking?)
  - `NSPrivacyCollectedDataTypePurposes` (purposes)
- [ ] `NSPrivacyAccessedAPITypes` — all Required Reason APIs declared

**Required Reason APIs** — search code for usage:

| API | Reason required |
|-----|-----------------|
| `UserDefaults` | CA92.1, 1C8F.1, etc. |
| `NSFileSystemFreeSize` / `statvfs` | Disk space |
| `NSProcessInfo.systemUptime` | System uptime |
| `Date` / `NSDate` (boot time) | Boot time |
| `activeKeyboards` | Keyboard |

**Rejection certainties**: missing `PrivacyInfo.xcprivacy`, Required Reason API used without declared reason, undeclared data collection.

### 2.2 Usage Descriptions (Permission Strings)

For EVERY permission used in code, verify the Info.plist usage description:

- [ ] Present (not missing)
- [ ] Specific (explains WHY the app needs the permission)
- [ ] Not generic (Apple rejects "This app needs access to X")
- [ ] Localized in all supported languages

| Code usage | Required Info.plist key |
|------------|------------------------|
| `CLLocationManager` | `NSLocationWhenInUseUsageDescription` |
| `CLLocationManager` (always) | `NSLocationAlwaysAndWhenInUseUsageDescription` |
| `AVCaptureDevice` (camera) | `NSCameraUsageDescription` |
| `PHPhotoLibrary` | `NSPhotoLibraryUsageDescription` |
| `EKEventStore` | `NSCalendarsUsageDescription` (or `NSCalendarsFullAccessUsageDescription` iOS 17+) |
| `CNContactStore` | `NSContactsUsageDescription` |
| `CMMotionManager` | `NSMotionUsageDescription` |
| HealthKit | `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` |
| MusicKit / `MPMediaLibrary` | `NSAppleMusicUsageDescription` |
| Speech recognition | `NSSpeechRecognitionUsageDescription` |
| LocalNetwork | `NSLocalNetworkUsageDescription` |
| Bluetooth | `NSBluetoothAlwaysUsageDescription` |
| FaceID | `NSFaceIDUsageDescription` |
| Microphone | `NSMicrophoneUsageDescription` |
| Siri | `NSSiriUsageDescription` |

**Risk**: missing usage description = runtime crash. Generic description = rejection risk. Not localized = rejection risk.

### 2.3 Sensitive Data Handling

- [ ] PII (name, email, date of birth) never stored in UserDefaults or plain text files
- [ ] PII stored in Keychain or encrypted storage
- [ ] No sensitive data in logs (`print()`, `NSLog()`, `os_log()` with user data interpolation)
- [ ] No sensitive data in URLs (query parameters with PII)
- [ ] No sensitive data in crash reports or analytics

**Violations**: PII in UserDefaults (guideline 5.1.1), PII in logs, hardcoded API keys.

### 2.4 App Tracking Transparency

If the app uses tracking (IDFA, fingerprinting, cross-app tracking):

- [ ] `ATTrackingManager.requestTrackingAuthorization()` called BEFORE tracking
- [ ] `NSUserTrackingUsageDescription` present in Info.plist
- [ ] Tracking does NOT occur if user denies consent

If the app does NOT use tracking:

- [ ] No usage of `ASIdentifierManager`, IDFA, fingerprinting, or cross-device tracking
- [ ] No third-party SDK performing silent tracking

---

## Section 3 — App Store Review Guidelines Compliance

### 3.1 Guideline 2.1 — App Completeness

- [ ] No placeholder or "coming soon" content visible
- [ ] All features reachable from UI are functional (no dead-end screens)
- [ ] No launch crashes — search for dangerous patterns:
  - `fatalError()` in non-debug code
  - `preconditionFailure()` in non-debug code
  - Force unwrap (`!`) on values that could be nil
  - `try!` on calls that could fail
  - `as!` on casts that could fail

### 3.2 Guideline 2.3 — Accurate Metadata

- [ ] App name is appropriate (no keyword stuffing)
- [ ] Bundle ID consistent with brand/developer
- [ ] No references to competitor platforms in UI-facing code (Android, Google, Samsung)

### 3.3 Guideline 3.1.1 — In-App Purchase

If the app has in-app purchases:

- [ ] StoreKit 2 (or StoreKit 1) used correctly
- [ ] Product IDs defined and correct
- [ ] Restore purchases implemented and accessible — **missing = certain rejection**
- [ ] App functions reasonably without purchases (not an empty shell forcing purchase)
- [ ] No external links to bypass IAP (guideline 3.1.1)
- [ ] Subscription pricing and terms clear in UI
- [ ] Terms of Use and Privacy Policy linked — **mandatory for subscriptions**

### 3.4 Guideline 4.0 — Design

- [ ] No private API usage (search: `_`-prefixed selectors, `performSelector` with suspicious strings, `dlopen`, `dlsym`)
- [ ] No deprecated APIs without alternatives (search: `@available`, `#available`, deprecated warnings)
- [ ] `UIWebView` NOT used (must be `WKWebView`) — **certain rejection if UIWebView present**
- [ ] All screen sizes handled (no broken layout on SE, mini, Pro Max)

### 3.5 Guideline 4.7 — AI-Generated Content

If the app uses AI-generated content:

- [ ] AI content identified as such (best practice)
- [ ] AI content cannot generate offensive or dangerous material
- [ ] Moderation or filtering on AI content

### 3.6 Guideline 5.1 — Data Collection and Storage

- [ ] Privacy policy accessible from the app (working link)
- [ ] Privacy policy accessible from App Store Connect
- [ ] Collected data consistent with privacy manifest and App Store Connect declarations

### 3.7 Guideline 5.1.2 — Data Use and Sharing

- [ ] No user data sent to third parties without consent
- [ ] External API calls (OpenAI, weather, etc.) send minimum necessary data
- [ ] No PII sent over plaintext HTTP — search for `http://` (not `https://`) in URL strings

---

## Section 4 — Human Interface Guidelines

### 4.1 Accessibility

- [ ] All interactive controls have `accessibilityLabel` (check: views with `.onTapGesture`, `Button`, `NavigationLink`, `Toggle`, `Slider` without `.accessibilityLabel`)
- [ ] Decorative images have `.accessibilityHidden(true)`
- [ ] Informative images have `.accessibilityLabel`
- [ ] Dynamic Type supported (no hardcoded font sizes without `.dynamicTypeSize` range)
- [ ] Color contrast sufficient (WCAG AA: 4.5:1 for normal text)
- [ ] VoiceOver: no controls invisible to navigation

### 4.2 Launch Screen

- [ ] Launch screen configured (storyboard or Info.plist `UILaunchScreen`)
- [ ] Launch screen contains no: prices, changing text, interactive elements
- [ ] Launch screen visually consistent with first app screen

### 4.3 Icons and Assets

- [ ] AppIcon present in asset catalog with ALL required sizes (1024x1024 for App Store + device sizes)
- [ ] AppIcon has no transparency (Apple requires opaque background — iOS applies corner radius)
- [ ] AppIcon has no badges or overlays that mimic system badges
- [ ] No missing assets in asset catalog (Xcode warnings)

**Fix needed**: icon with alpha/transparency — iOS adds automatic BLACK or WHITE background.

### 4.4 Orientation and Layout

- [ ] Rotation handled correctly (if supported)
- [ ] Safe area respected (no content under notch or Dynamic Island)
- [ ] Keyboard does not cover input fields (KeyboardAvoidance)

---

## Section 5 — Security & Networking

### 5.1 App Transport Security

- [ ] No `NSAppTransportSecurity` exceptions in Info.plist (no `NSAllowsArbitraryLoads = true`)
- [ ] If exceptions exist, they target specific domains with justification
- [ ] All connections use HTTPS — search for `http://` in URL strings

### 5.2 Secret Management

- [ ] No API keys hardcoded in Swift source files — search: `apiKey`, `api_key`, `secret`, `token`, `password`, `Bearer`, `sk-`, `pk_`, `OPENAI`, `FIREBASE`
- [ ] Secrets stored in: Keychain, xcconfig (gitignored), Firebase remote config, or environment variables
- [ ] `.gitignore` excludes files with secrets (`.xcconfig`, `GoogleService-Info.plist` if containing keys)
- [ ] No secrets in committed git history

### 5.3 Certificate Pinning (optional but recommended)

- [ ] If communicating with a proprietary backend, check for certificate pinning
- [ ] If pinning implemented, backup certificates configured (prevent app brick on cert renewal)

---

## Section 6 — Quality & Stability

### 6.1 Memory and Performance

- [ ] No retain cycles — search for closures capturing `self` without `[weak self]` in async contexts: `.sink { self. }`, `Timer { self. }`, `NotificationCenter { self. }`, `DispatchQueue { self. }`
- [ ] No timers or observers left unremoved — search: `Timer.scheduledTimer`, `NotificationCenter.addObserver` without matching `removeObserver`/`invalidate`
- [ ] Images loaded at appropriate resolution (no 4K image in a 44x44 thumbnail)

### 6.2 Concurrency Safety

- [ ] `@MainActor` used where UI updates from background threads
- [ ] No concurrent access to shared mutable properties without protection (actor, lock, serial queue)
- [ ] `DispatchQueue.global().async` followed by class/struct property access dispatched back to main
- [ ] `Sendable` compliance for types passed between concurrency domains

### 6.3 Error Handling

- [ ] No empty catch blocks (`catch { }` without logging or handling)
- [ ] Network errors show user feedback (never silent failure)
- [ ] Timeouts configured for all network calls
- [ ] Fallback for unavailable external services

### 6.4 Localization

- [ ] All UI-facing strings use `NSLocalizedString` / `String(localized:)` / `.xcstrings`
- [ ] No hardcoded user-visible strings — search: `Text("fixed string")`, `.navigationTitle("fixed")`, `Label("fixed")`, `Button("fixed")`
- [ ] Dates and numbers formatted with current locale (`DateFormatter`, `NumberFormatter` with `.locale`)
- [ ] Plurals handled correctly (no "1 items")

---

## Section 7 — StoreKit & Subscriptions

*Skip this section if the app has no in-app purchases or subscriptions.*

### 7.1 StoreKit Implementation

- [ ] StoreKit 2 (preferred) or StoreKit 1 used correctly
- [ ] `Transaction.updates` listener active for background transactions
- [ ] Entitlement check at app launch
- [ ] Purchase error handling covers: cancelled, failed, pending, deferred
- [ ] Restore purchases accessible — **mandatory, Apple verifies this**

### 7.2 Subscription Requirements

- [ ] Duration and price clear BEFORE purchase
- [ ] Auto-renewal information visible
- [ ] Link to Terms of Use
- [ ] Link to Privacy Policy
- [ ] Information on how to cancel the subscription
- [ ] No dark patterns (giant buy button, tiny skip)

### 7.3 Sandbox Testing

- [ ] App works in sandbox environment (StoreKit testing)
- [ ] Correct handling of sandbox vs production receipt

---

## Section 8 — Assets & Intellectual Property

### 8.1 Usage Rights

- [ ] No assets (images, fonts, sounds, music) without clear license
- [ ] Custom fonts: license verified for app distribution
- [ ] Images: no unlicensed stock images, no screenshots of other apps
- [ ] Sounds/music: royalty-free license verified
- [ ] No third-party trademarks used improperly

### 8.2 Placeholder Content

- [ ] No visible placeholder content (Lorem ipsum, TODO, FIXME in UI-facing strings)
- [ ] Search: `TODO`, `FIXME`, `HACK`, `XXX`, `Lorem`, `placeholder` in localized strings and UI text

---

## Quick Audit (10 Critical Checks)

For a rapid pre-submission check, verify only these 10 items:

1. `PrivacyInfo.xcprivacy` exists and declares Required Reason APIs?
2. ALL usage descriptions present for permissions used?
3. `UIWebView` absent? (search entire project)
4. Restore purchases implemented (if IAP present)?
5. No API keys hardcoded in source code?
6. Info.plist `UIBackgroundModes`: every mode actually used?
7. AppIcon: all sizes present, no transparency?
8. Force unwrap (`!`) in critical code (launch, init)?
9. Privacy policy linked (if IAP/subscription/data collection)?
10. `NSAllowsArbitraryLoads` is not true?

For each check: PASS / FAIL (with file path and fix).

---

## Report Format

```markdown
# Apple Compliance Audit Report
**App:** [app name]
**Version:** [version]
**Audit date:** [date]
**Auditor:** Claude Code

## Executive Summary
- Total issues found: X
- BLOCKER (certain rejection): X
- WARNING (probable rejection): X
- IMPROVEMENT (recommendation): X
- PASS: X areas verified without issues

## Detailed Issues

### [BLOCKER/WARNING/IMPROVEMENT] — Short title
**Section:** X.X
**Guideline:** [Apple guideline number if applicable]
**File:** [file path]
**Line:** [line number if applicable]
**Problem:** Precise description of the issue found
**Evidence:** Code or configuration demonstrating the issue
**Suggested fix:** What to do to resolve
**Apple reference:** [link to documentation/guideline]

## Summary Checklist
Table with all checks and their status (PASS/BLOCKER/WARNING/IMPROVEMENT/SKIPPED)

## Pre-Submission Recommendations
Priority-ordered list of actions to take before submission.
```

---

## Limitations

This audit is based on STATIC code analysis. It cannot verify:

- Runtime behavior (actual crashes, real performance)
- Apple Developer Portal configuration (activated entitlements)
- App Store Connect configuration (privacy labels, screenshots)
- Subjective design review (guideline 4.0)
- Dynamically generated content (AI, user-generated content)

Complement this audit with: device testing on all target models, Developer Portal verification, App Store Connect verification, Xcode Accessibility Inspector, Thread Sanitizer, and Address Sanitizer.

---

## Anti-Patterns

- **Last-minute compliance check** — running the audit days before submission; compliance issues in Info.plist, entitlements, or privacy manifests require code changes that need testing
- **Ignoring privacy manifest requirements** — missing NSPrivacyAccessedAPITypes for required reason APIs; Apple rejects apps that use covered APIs without declared reasons
- **Hardcoded entitlements** — copying entitlements from Stack Overflow without understanding scope; each entitlement must match actual app capabilities
- **Missing App Transport Security exceptions** — using NSAllowsArbitraryLoads instead of per-domain exceptions; Apple requires justification for each ATS exception
- **Skipping accessibility audit** — assuming VoiceOver works without testing; missing accessibility labels and traits cause rejection and exclude users

---

## For Claude Code

When asked to perform an Apple compliance audit:

1. Read ALL source files, Info.plist, entitlements, and PrivacyInfo.xcprivacy before producing findings
2. Follow the sections in order (1-8), skip section 7 if no IAP/subscriptions
3. Every finding must include file path and line number
4. Classify every issue as BLOCKER, WARNING, or IMPROVEMENT
5. Be strict: a false positive is better than a rejection in App Review
6. Use the Report Format above for the final output
7. Always run the Quick Audit checks even if a full audit is not requested
8. Flag any entitlement or background mode present but not used in code — this is the most common rejection reason

---

*Internal references*: `ios-app-audit/SKILL.md`, `ios-gui-assessment/SKILL.md`
