---
name: ios-gui-assessment
description: Audit iOS SwiftUI/UIKit projects for GUI consistency, ensuring all UI components use native Apple controls (no custom replacements), support correct OS version ranges, follow Apple HIG patterns, and avoid deprecated APIs. Triggers when user asks to review, audit, assess, or check an iOS app's UI/GUI for consistency, native compliance, HIG conformance, accessibility, or OS compatibility. Also triggers on requests like "check my iOS UI", "verify SwiftUI components", "are my controls standard Apple", "GUI review", "UI audit", or "HIG compliance check".
---

# iOS GUI Assessment

Audit an iOS project to verify that all UI components use native Apple controls, are consistent across supported OS versions, follow Human Interface Guidelines, and avoid deprecated or custom reimplementations of standard components.

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
- ❌ **Replace with native** — a standard Apple control exists and should be used
- ⚠️ **Review needed** — might be justified (custom styling on native base), needs manual check
- ✅ **Acceptable** — no native equivalent exists, custom is appropriate

### Step 3 — Check OS Version Compatibility

Read deployment target from Step 1, then scan for APIs unavailable at that target. For complete API version reference, see `references/api-versions.md`.

```bash
# Find @available checks — these indicate version-dependent code
grep -rn "@available\|#available" --include="*.swift" | grep -v "test\|Test"
```

For each API found, cross-reference with the deployment target:
- ❌ **Breaking** — API used without `@available` check, will crash on older OS
- ⚠️ **Guarded** — API used with proper `if #available` check (verify the fallback works)
- ✅ **Safe** — API available at deployment target

### Step 4 — Check for Deprecated APIs

For complete deprecated API list, see `references/deprecated-apis.md`.

Classify each finding:
- ❌ **Deprecated** — replacement available, should migrate
- ⚠️ **Soft deprecated** — still works but newer API preferred, low priority
- ✅ **Current** — no deprecation issue

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
CRITICAL (❌), HIGH (⚠️), LOW — with file:line and description.

## Key Principles

- Native Apple controls adapt automatically to OS updates, Dark Mode, Dynamic Type, and accessibility. Custom reimplementations break all of these.
- If a standard Apple control exists for the purpose, use it. Customize via modifiers, not by rebuilding.
- Every `@available` check must have a working fallback for the deployment target.
- Prefer SwiftUI semantic colors (`.primary`, `.secondary`) over hardcoded colors.
- Prefer Dynamic Type text styles (`.body`, `.headline`) over fixed font sizes.
- Every interactive element must have an accessibility label or be hidden from VoiceOver.
