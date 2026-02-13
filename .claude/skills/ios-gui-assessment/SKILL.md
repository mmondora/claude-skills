---
name: ios-gui-assessment
cluster: mobile
description: "Audit iOS SwiftUI/UIKit projects for GUI consistency, native Apple control usage, HIG conformance, deprecated API detection, OS version compatibility, and accessibility. Use when reviewing, auditing, or checking an iOS app's UI/GUI."
---

# iOS GUI Assessment

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Systematic audit of iOS projects to verify that all UI components use native Apple controls, are consistent across supported OS versions, follow Human Interface Guidelines, and avoid deprecated or custom reimplementations of standard components. Produces a structured report with severity-ranked action items.

---

## When to Run This Assessment

Run when the user asks to audit, review, or check an iOS app's GUI for:
- Native Apple control usage (no custom replacements for standard components)
- OS version compatibility across the supported deployment target range
- HIG (Human Interface Guidelines) conformance
- Deprecated API usage
- Accessibility compliance
- Visual consistency

## Assessment Process

### Step 1 — Determine Project Scope

```bash
# Find deployment target
grep -rn "IPHONEOS_DEPLOYMENT_TARGET" *.xcodeproj/project.pbxproj | head -5

# Find all SwiftUI view files
find . -name "*.swift" -exec grep -l "import SwiftUI\|: View" {} \;

# Find all UIKit view controllers
find . -name "*.swift" -exec grep -l "UIViewController\|UITableViewController\|UICollectionViewController" {} \;

# Count UI files
echo "SwiftUI views:" $(grep -rl ": View {" --include="*.swift" | wc -l)
echo "UIKit VCs:" $(grep -rl "UIViewController" --include="*.swift" | wc -l)
```

Report: framework used (SwiftUI / UIKit / mixed), deployment target, number of view files.

### Step 2 — Scan for Non-Native Components

Search for custom implementations that replace standard Apple controls:

```bash
# Custom buttons replacing standard Button
grep -rn "UIButton(type:\|class.*Button.*:.*UIView\|struct.*Button.*:.*View" --include="*.swift" | grep -v "test\|Test\|spec\|Spec"

# Custom text fields replacing TextField
grep -rn "class.*TextField.*:.*UIView\|class.*Input.*:.*UIView" --include="*.swift"

# Custom navigation replacing NavigationStack/NavigationView
grep -rn "class.*Navigation.*:.*UIView\|class.*Router.*:.*UIView\|custom.*nav" --include="*.swift" -i

# Custom toggle/switch
grep -rn "class.*Toggle.*:.*UIView\|class.*Switch.*:.*UIView\|struct.*Toggle.*:.*View" --include="*.swift" | grep -v "FeatureToggle"

# Custom alerts replacing native .alert()
grep -rn "class.*Alert.*:.*UIView\|class.*Dialog.*:.*UIView\|struct.*Alert.*:.*View\|struct.*Dialog.*:.*View" --include="*.swift"

# Custom pickers replacing Picker/DatePicker
grep -rn "class.*Picker.*:.*UIView\|class.*Selector.*:.*UIView" --include="*.swift"

# Custom tab bar
grep -rn "class.*TabBar.*:.*UIView\|struct.*TabBar.*:.*View" --include="*.swift" | grep -v "test"

# Custom action sheet / bottom sheet
grep -rn "class.*Sheet.*:.*UIView\|class.*BottomSheet\|struct.*Sheet.*:.*View" --include="*.swift"

# Custom progress indicators
grep -rn "class.*Progress.*:.*UIView\|class.*Spinner.*:.*UIView\|class.*Loading.*:.*UIView" --include="*.swift"
```

For each match, classify as:
- **Replace with native** — a standard Apple control exists and should be used
- **Review needed** — might be justified (custom styling on native base), needs manual check
- **Acceptable** — no native equivalent exists, custom is appropriate

### Step 3 — Check OS Version Compatibility

Read deployment target from Step 1, then scan for APIs unavailable at that target.

#### iOS 17+ APIs

| API | iOS | Notes |
|-----|-----|-------|
| `.scrollPosition` | 17.0 | ScrollView position binding |
| `.contentMargins` | 17.0 | Replaces padding in scroll views |
| `.containerRelativeFrame` | 17.0 | Size relative to container |
| `.scrollTargetBehavior` | 17.0 | Paging/aligned scroll |
| `.sensoryFeedback` | 17.0 | Haptic feedback modifier |
| TipKit / TipView | 17.0 | In-app tips |
| `.inspector` | 17.0 | Inspector panel |
| `.onChange(of:initial:)` | 17.0 | New onChange with old/new values |
| `.symbolEffect` | 17.0 | SF Symbol animations |
| `#Preview` macro | 17.0 | Replaces PreviewProvider |
| `.foregroundStyle` | 17.0 | Replaces `.foregroundColor` |
| `Observable` macro | 17.0 | Replaces ObservableObject |

```bash
grep -rn "\.scrollPosition\|\.contentMargins\|\.containerRelativeFrame\|\.scrollTargetBehavior\|\.sensoryFeedback\|TipView\|TipKit\|\.inspector\|\.onChange.*\.old\|\.symbolEffect\|#Preview\b\|Observable\b" --include="*.swift"
```

#### iOS 16+ APIs

| API | iOS | Notes |
|-----|-----|-------|
| NavigationStack | 16.0 | Replaces NavigationView |
| NavigationSplitView | 16.0 | Multi-column navigation |
| `.navigationDestination` | 16.0 | Value-based navigation |
| `.presentationDetents` | 16.0 | Sheet sizing |
| `.scrollDismissesKeyboard` | 16.0 | Keyboard dismiss on scroll |
| AnyLayout | 16.0 | Dynamic layout switching |
| ViewThatFits | 16.0 | Adaptive content |
| PhotosPicker | 16.0 | Photo library picker |
| ShareLink | 16.0 | Share sheet |

```bash
grep -rn "NavigationStack\|NavigationSplitView\|\.navigationDestination\|\.presentationDetents\|AnyLayout\|ViewThatFits\|PhotosPicker\|ShareLink" --include="*.swift"
```

#### iOS 15+ APIs

| API | iOS | Notes |
|-----|-----|-------|
| `.task {}` | 15.0 | Async task on appear |
| `.refreshable` | 15.0 | Pull to refresh |
| `.searchable` | 15.0 | Search integration |
| `.swipeActions` | 15.0 | List swipe actions |
| `.confirmationDialog` | 15.0 | Replaces ActionSheet |
| AsyncImage | 15.0 | Async image loading |
| @FocusState | 15.0 | Focus management |
| `.tint()` | 15.0 | Replaces `.accentColor` |

#### iOS 14+ APIs

| API | iOS | Notes |
|-----|-----|-------|
| `.onChange(of:)` | 14.0 | Value change observer |
| `.fullScreenCover` | 14.0 | Full screen modal |
| LazyVGrid/LazyHGrid | 14.0 | Grid layouts |
| @StateObject | 14.0 | Owned observable |
| @AppStorage | 14.0 | UserDefaults binding |
| ProgressView | 14.0 | Progress indicator |

```bash
# Find @available checks — these indicate version-dependent code
grep -rn "@available\|#available" --include="*.swift" | grep -v "test\|Test"
```

For each API found, cross-reference with the deployment target:
- **Breaking** — API used without `@available` check, will crash on older OS
- **Guarded** — API used with proper `if #available` check (verify the fallback works)
- **Safe** — API available at deployment target

### Step 4 — Check for Deprecated APIs

#### SwiftUI Deprecated

| Deprecated API | Since | Replacement |
|---------------|-------|-------------|
| `NavigationView` | iOS 16 | `NavigationStack` or `NavigationSplitView` |
| `.navigationBarTitle` | iOS 16 | `.navigationTitle` |
| `.navigationBarItems` | iOS 16 | `.toolbar { ToolbarItem {} }` |
| `.navigationBarHidden` | iOS 16 | `.toolbar(.hidden, for: .navigationBar)` |
| `.accentColor` | iOS 15 | `.tint()` |
| `.foregroundColor` | iOS 17 | `.foregroundStyle` |
| `ActionSheet` | iOS 15 | `.confirmationDialog` |
| `UIScreen.main` | iOS 16 | Window's screen via UIWindowScene |
| `UIApplication.shared.keyWindow` | iOS 13 | Scene-based window access |

```bash
grep -rn "NavigationView\b\|\.navigationBarTitle\b\|\.navigationBarItems\b\|\.navigationBarHidden\b\|\.accentColor\b\|\.foregroundColor\b\|ActionSheet(\|UIScreen\.main\|\.keyWindow\b" --include="*.swift"
```

#### UIKit Deprecated

| Deprecated API | Since | Replacement |
|---------------|-------|-------------|
| `UIAlertView` | iOS 9 | `UIAlertController` |
| `UIActionSheet` | iOS 9 | `UIAlertController(.actionSheet)` |
| `UIWebView` | iOS 12 | `WKWebView` |
| `UISearchDisplayController` | iOS 8 | `UISearchController` |
| `beginAnimations/commitAnimations` | iOS 4 | `UIView.animate(withDuration:)` |

#### Common Anti-Patterns

| Pattern | Issue | Better Alternative |
|---------|-------|--------------------|
| `GeometryReader` everywhere | Breaks layout, causes sizing issues | `.containerRelativeFrame` (iOS 17+) or relative sizing |
| `.onAppear { fetch() }` | Not cancellable, race conditions | `.task {}` (iOS 15+) |
| `DispatchQueue.main.async` in SwiftUI | Fragile timing hack | `@MainActor`, `.task {}`, or proper state management |
| `Timer.publish` for animations | Battery drain, imprecise | `TimelineView` (iOS 15+) or `.animation` |
| Force unwrap in views (`!`) | Crash risk | Optional binding or default values |

Classify each finding:
- **Deprecated** — replacement available, should migrate
- **Soft deprecated** — still works but newer API preferred, low priority
- **Current** — no deprecation issue

### Step 5 — Accessibility Audit

```bash
# Interactive elements without accessibility labels
grep -rn "Button(\|Image(\|Image(systemName:" --include="*.swift" | head -30

# Hardcoded font sizes (should use Dynamic Type)
grep -rn "\.font(.system(size:" --include="*.swift"

# Hardcoded colors that might break in Dark Mode
grep -rn 'Color(red:\|UIColor(red:\|#colorLiteral' --include="*.swift"

# Fixed frame sizes on text containers
grep -rn "\.frame(width:.*height:" --include="*.swift" | head -20
```

### Step 6 — HIG Pattern Compliance

```bash
# Navigation consistency
grep -rn "NavigationStack\|NavigationView\|NavigationSplitView" --include="*.swift"

# Modality usage (flag if >10 sheets)
grep -rn "\.sheet(\|\.fullScreenCover(" --include="*.swift" | wc -l

# Lists: ScrollView+ForEach where List should be used
grep -rn "ScrollView.*ForEach\|ScrollView.*VStack.*ForEach" --include="*.swift"

# Tab count (<6 per HIG)
grep -rn "\.tabItem\|TabView" --include="*.swift"
```

## Output Format

Generate a report with these sections:

### 1. Project Summary
Framework, deployment target, view file count.

### 2. Non-Native Components
Table: File | Line | Component | Issue | Severity | Recommendation

### 3. OS Compatibility Issues
Table: File | Line | API | Min iOS | Target | Guarded? | Severity

### 4. Deprecated APIs
Table: File | Line | Deprecated API | Replacement | Priority

### 5. Accessibility
Table: File | Line | Issue | Fix

### 6. HIG Conformance
Table: Pattern | Status | Notes

### 7. Action Items (sorted by severity)
CRITICAL, HIGH, LOW — with file:line and description.

## Key Principles

- Native Apple controls adapt automatically to OS updates, Dark Mode, Dynamic Type, and accessibility. Custom reimplementations break all of these.
- If a standard Apple control exists for the purpose, use it. Customize via modifiers, not by rebuilding.
- Every `@available` check must have a working fallback for the deployment target.
- Prefer SwiftUI semantic colors (`.primary`, `.secondary`) over hardcoded colors.
- Prefer Dynamic Type text styles (`.body`, `.headline`) over fixed font sizes.
- Every interactive element must have an accessibility label or be hidden from VoiceOver.

---

## For Claude Code

When asked to audit an iOS app's GUI:

1. Run the 6-step assessment process in order — do not skip steps
2. Read every Swift file containing UI code before producing findings
3. Always include file path and line number for every finding
4. Cross-reference the deployment target from Step 1 against all API usage
5. Classify every finding with a severity level — do not leave ambiguous items unclassified
6. Generate the full report in the Output Format specified above
7. If runtime testing is needed (e.g., visual checks, Dynamic Type scaling), state it explicitly as a manual verification item

---

*Internal references*: `testing-implementation/SKILL.md`
