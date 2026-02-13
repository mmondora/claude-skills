---
name: ios-app-audit
cluster: mobile
description: "Comprehensive production audit for iOS apps covering security, App Store compliance, privacy, reliability, performance, accessibility, and code quality. Use when auditing an iOS app before release or reviewing its production readiness."
---

# iOS App Audit

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Full production audit framework for any iOS application. Covers 10 areas in priority order (P0-P3) to systematically evaluate security, compliance, privacy, reliability, performance, and code quality before App Store submission or production release.

---

## Audit Scope

The audit covers 10 areas in priority order:

1. **Security & Malicious Code Detection** (P0)
2. **Apple App Store Compliance** (P0)
3. **Privacy & Data Protection** (P0)
4. **Core Feature Reliability** (P0)
5. **API Integration Robustness** (P1)
6. **Performance & Resource Usage** (P1)
7. **Audio/Media System Correctness** (P1) — if applicable
8. **UI/UX & Accessibility** (P2)
9. **Code Quality & Maintainability** (P2)
10. **Localization & Theme** (P3)

---

## 1. Security & Malicious Code Detection (P0)

### 1.1 Network Activity Audit

Scan entire codebase for ALL network operations:
```
URLSession, URLRequest, URLSessionDataTask, URLSessionUploadTask,
URLSessionDownloadTask, URLSessionWebSocketTask, WebSocket,
import Network, import CFNetwork, import WebKit,
CFSocket, CFStream, InputStream, OutputStream
```

For EACH network call found, document:
- **Location**: File:Line
- **Type**: URLSession / Socket / WebSocket / Other
- **URL/Endpoint**: exact URL or variable that resolves to URL
- **Method**: GET / POST / PUT / DELETE
- **Headers**: all headers set
- **Body/Payload**: what data is sent
- **Purpose**: stated purpose
- **Expected**: YES/NO — is this a documented, approved call?
- **Risk Level**: CRITICAL / HIGH / MEDIUM / LOW

Flag: analytics endpoints not disclosed to users, tracking pixels, unknown domains, shortened URLs, URLs constructed from variables or decoded from base64.

### 1.2 Obfuscation & Suspicious Patterns

Search for:
```swift
base64EncodedString, base64EncodedData, Data(base64Encoded:)
NSClassFromString, NSSelectorFromString, performSelector
dlopen, dlsym
ProcessInfo.processInfo // jailbreak detection without justification
ptrace, sysctl // anti-debugging without justification
UIPasteboard // clipboard access without user action
```

Flag: obfuscated strings, dynamic code execution, timer-based beacon behavior, anti-debugging, code that runs silently on launch.

### 1.3 Third-Party Dependencies

Inventory ALL dependencies (CocoaPods, SPM, Carthage, vendored frameworks):
- Name and version
- Source (official repo or fork?)
- Purpose in the app
- Known CVEs
- Network activity (does it phone home?)
- Data collection (what does it access?)
- License compatibility

### 1.4 Data Exfiltration Check

Verify NO unauthorized data leaves the device:
- [ ] API keys never sent anywhere except authorized API endpoints
- [ ] User personal data only sent to declared services
- [ ] Device identifiers (IDFA, IDFV, UUID) never collected or transmitted without consent
- [ ] No screenshots, photos, contacts, or health data accessed without permission
- [ ] No clipboard reading without explicit user action

---

## 2. Apple App Store Compliance (P0)

### 2.1 App Store Review Guidelines

| Guideline | Check |
|-----------|-------|
| 1.x Safety | No inappropriate content; AI-generated content cannot produce harmful output |
| 2.1 Completeness | Fully functional; no placeholder content, test data, or debug screens in release |
| 2.3 Metadata | App name, screenshots, and description match actual functionality |
| 2.5.1 APIs | Only public APIs; no deprecated APIs that cause rejection; correct minimum iOS |
| 3.1.1 IAP | External service costs disclosed; no hidden paywalls |
| 4.0 Design | Provides value beyond web wrapper; follows iOS HIG basics |
| 5.1 Privacy | Privacy Policy accessible; privacy labels match actual data practices |
| 5.1.1 Data | Data collected is necessary; user can delete data |
| 5.1.2 Sharing | Third-party data sharing disclosed; user consent obtained |

### 2.2 Info.plist & Entitlements

- [ ] Every permission requested has a usage description string explaining WHY
- [ ] No permissions requested that the app does not actually use
- [ ] Only necessary entitlements enabled
- [ ] Background modes: only those actually used
- [ ] No `NSAllowsArbitraryLoads` (must be absent or false)
- [ ] All network calls use HTTPS

### 2.3 Build & Submission Readiness

- [ ] Bundle identifier correct and unique
- [ ] Version number semantic (X.Y.Z)
- [ ] All required app icons present
- [ ] Launch screen configured
- [ ] No debug code, test API keys, or development flags in release configuration
- [ ] No `print()` or `NSLog()` statements that leak sensitive data in release builds

### 2.4 Required API Reason Declarations (iOS 17+)

PrivacyInfo.xcprivacy must declare reasons for these APIs if used:
- [ ] UserDefaults — reason declared
- [ ] File timestamp APIs — reason declared
- [ ] System boot time APIs — reason declared
- [ ] Disk space APIs — reason declared
- [ ] Active keyboard APIs — reason declared

---

## 3. Privacy & Data Protection (P0)

### 3.1 Sensitive Data Storage

For each data type the app stores, verify:
- Secrets (API keys, tokens) are in Keychain only — never in UserDefaults, Core Data, or files
- Personal data storage location is appropriate
- Temporary data (cache, temp files) has cleanup logic
- No sensitive data appears in logs, crash reports, or error messages

### 3.2 Data Retention & User Control

- [ ] User can delete all their stored data
- [ ] Old data has retention limits
- [ ] App does not retain data after deletion request

### 3.3 GDPR / CCPA Compliance

- [ ] User can access their stored data
- [ ] User can delete their stored data
- [ ] Data collection disclosed in privacy policy
- [ ] Third-party data processing disclosed
- [ ] Consent obtained before data collection

---

## 4. Core Feature Reliability (P0)

### 4.1 Entry Points

For each way the app can be launched or activated (app icon, URL scheme, Shortcuts, notifications, widgets), verify:
- [ ] Entry point routes to the correct handler
- [ ] No double-trigger if called twice rapidly
- [ ] Failure path provides user feedback (never silent failure)

### 4.2 Failure Mode Testing

For each critical feature, document expected behavior under:
- No network connectivity
- Invalid credentials / expired tokens
- API timeout
- Invalid response data (malformed JSON, unexpected schema)
- Permission denied (camera, location, etc.)
- App killed during operation
- Phone call / interruption during operation
- Low memory warning
- Rapid repeated invocation

### 4.3 Thread Safety

- [ ] `@MainActor` applied correctly on UI-bound types
- [ ] No data races (verify with Thread Sanitizer)
- [ ] `Published` properties only updated on main thread
- [ ] Core Data contexts used on correct threads
- [ ] No retain cycles in closures (`[weak self]` where needed)

### 4.4 State Machine Integrity

- [ ] Critical flows have clear states with valid transitions
- [ ] Every state transition is valid (no illegal jumps)
- [ ] State reset on dismissal is complete (no leaked state)
- [ ] No double-completion on async operations

---

## 5. API Integration Robustness (P1)

For each external API integration:
- [ ] Timeout configured (reasonable values, not infinite)
- [ ] Retry with exponential backoff (where appropriate)
- [ ] Rate limit (429) handling: backoff, do not retry immediately
- [ ] Invalid credentials: fail immediately, clear user feedback
- [ ] Response validation: parsed and validated before use
- [ ] Prompt injection risk assessed (if sending user data to AI services)
- [ ] Fallback behavior when API is unavailable

---

## 6. Performance & Resource Usage (P1)

### 6.1 Memory

Targets:
- Idle: < 30 MB (adjust per app complexity)
- Active feature: < 100 MB
- Leaks: 0

Check:
- [ ] All tasks cancelled in deinit
- [ ] Media players stopped and deallocated after use
- [ ] Notification observers removed
- [ ] Timer objects invalidated
- [ ] Temp files deleted after use
- [ ] No memory growth over repeated feature usage

### 6.2 CPU

- [ ] Idle CPU < 1%
- [ ] Active feature CPU < 50% sustained
- [ ] No unnecessary background work

### 6.3 Battery

- [ ] No background refresh when not needed
- [ ] No location services unless required
- [ ] No network polling (use push notifications or event-driven)

### 6.4 Launch Performance

- [ ] Cold launch < 2s to first meaningful content
- [ ] No blocking work on main thread during launch

---

## 7. Audio/Media System Correctness (P1)

*Skip this section if the app does not use audio or media playback.*

- [ ] Audio session category correct for use case
- [ ] Session activated before playback, deactivated after
- [ ] Interruption handling (phone call): pause/resume or stop cleanly
- [ ] Volume control works as expected
- [ ] No audio artifacts or orphaned playback after dismissal
- [ ] No interference with other apps' audio after feature dismissed

---

## 8. UI/UX & Accessibility (P2)

### 8.1 Accessibility

- [ ] VoiceOver: all interactive elements labeled
- [ ] Dynamic Type: text scales correctly
- [ ] Contrast: WCAG AA compliance (4.5:1 for text)
- [ ] Reduce Motion: animations respect system setting
- [ ] Color: information not conveyed by color alone

### 8.2 UI Correctness

- [ ] All screens tested on smallest (SE) and largest (Pro Max) iPhone
- [ ] Safe Area respected everywhere
- [ ] No text truncation with longest localized strings
- [ ] Loading states visible during async operations
- [ ] Error states shown to user (not silent failures)

### 8.3 Dark/Light Mode

- [ ] All screens adapt correctly to both modes
- [ ] No hardcoded colors (use semantic colors)
- [ ] Icons/symbols visible in both modes

---

## 9. Code Quality & Maintainability (P2)

### 9.1 Architecture

- [ ] Consistent architectural pattern (MVVM, MV, etc.)
- [ ] Separation of concerns: Views, ViewModels, Services
- [ ] Dependency injection used (protocols, not concrete types)
- [ ] No business logic in Views
- [ ] No UI logic in Services

### 9.2 Error Handling

- [ ] Zero force unwraps (`!`) in production code — flag every instance
- [ ] All `try` have proper `catch` with logging
- [ ] All `try?` have comment explaining why error is ignored
- [ ] Fallback chains complete — no dead-end error paths

### 9.3 Code Hygiene

- [ ] No `print()` in production code (use structured logging)
- [ ] No TODO/FIXME without tracking reference
- [ ] No dead code or commented-out blocks
- [ ] No magic numbers (use named constants)
- [ ] Naming conventions consistent (Swift style)

### 9.4 Testing

- [ ] Unit test coverage for business logic: target > 60%
- [ ] Critical paths covered
- [ ] Mock services exist for offline testing

---

## 10. Localization & Theme (P3)

- [ ] All user-facing strings in Localizable.strings (or String Catalogs)
- [ ] All supported language files complete (no missing keys)
- [ ] No hardcoded strings in code
- [ ] Date/number formatting uses locale
- [ ] System/Light/Dark modes all functional
- [ ] Theme change immediate (no restart required)

---

## Report Format

Generate an audit report with this structure:

```markdown
# [App Name] Audit Report — [DATE]
## Version: [VERSION]

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

## SECURITY FINDINGS

### Network Endpoints Found
| URL | Purpose | Expected? | Risk | Action |

### Data Storage Audit
| Data | Storage Location | Encrypted? | Expected? | Risk |

### Dependency Audit
| Name | Version | Purpose | CVEs | Risk |

### Permissions Audit
| Permission | Declared? | Used? | Justified? | Risk |

## APP STORE COMPLIANCE
| Guideline | Status | Notes |

## ISSUES BY PRIORITY

### P0 — CRITICAL (Block Release)
For each: ID, Category, Location (File:Line), Description,
Impact, Risk Score (0-100), Fix, Effort (S/M/L)

### P1 — HIGH (Fix Before Release)
### P2 — MEDIUM (Fix Soon)
### P3 — LOW (Nice to Have)

## PERFORMANCE METRICS
| Metric | Target | Actual | Status |

## POSITIVE FINDINGS
[Things done well, patterns to keep]

## RECOMMENDATIONS
### Immediate (before release)
### Short-term (patch release)
### Long-term (next version)
```

---

## Execution Instructions

1. **Read ALL source files** before starting the report. Do not produce partial findings.
2. **Be specific** — always include file path and line number for every finding.
3. **Test where possible** — if you can determine behavior from code analysis, document it. If runtime testing is needed, say so explicitly.
4. **Prioritize ruthlessly** — P0 means "do not ship without fixing this." Use it sparingly but firmly.
5. **No diplomatic language** — if something is broken, say it's broken. If something is a security risk, say it clearly.
6. **Document positives** — good patterns should be called out for replication.

---

## For Claude Code

When asked to audit an iOS app:

1. Read ALL source files before producing findings — partial audits are worse than no audit
2. Follow the 10 areas in priority order (P0 first)
3. Skip section 7 (Audio/Media) if the app doesn't use audio/media
4. Every finding must include file path and line number
5. Use the Report Format above for the final output
6. Classify every issue with a priority (P0-P3) and effort estimate (S/M/L)
7. Be honest and critical — prioritize reliability and user safety over code elegance

---

*Internal references*: `testing-implementation/SKILL.md`, `ios-gui-assessment/SKILL.md`
