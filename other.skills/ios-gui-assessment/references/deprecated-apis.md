# Deprecated iOS APIs Reference

## SwiftUI Deprecated APIs

```bash
# Run all checks at once:
grep -rn "NavigationView\b\|\.navigationBarTitle\b\|\.navigationBarItems\b\|\.navigationBarHidden\b\|\.accentColor\b\|\.foregroundColor\b\|\.background(Color\.\|UIHostingController.*ignoresSafeArea\|ActionSheet(\|Alert(isPresented.*message:" --include="*.swift"
```

| Deprecated API | Since | Replacement | grep pattern |
|---------------|-------|-------------|-------------|
| `NavigationView` | iOS 16 | `NavigationStack` or `NavigationSplitView` | `NavigationView\b` |
| `.navigationBarTitle` | iOS 16 | `.navigationTitle` | `\.navigationBarTitle\b` |
| `.navigationBarItems` | iOS 16 | `.toolbar { ToolbarItem {} }` | `\.navigationBarItems\b` |
| `.navigationBarHidden` | iOS 16 | `.toolbar(.hidden, for: .navigationBar)` | `\.navigationBarHidden\b` |
| `.accentColor` | iOS 15 | `.tint()` | `\.accentColor\b` |
| `.foregroundColor` | iOS 17 | `.foregroundStyle` | `\.foregroundColor\b` |
| `ActionSheet` | iOS 15 | `.confirmationDialog` | `ActionSheet(` |
| `Alert(isPresented:)` old form | iOS 15 | `.alert(title:isPresented:actions:message:)` | Requires manual review |
| `UIScreen.main` | iOS 16 | Window's screen via UIWindowScene | `UIScreen\.main` |
| `UIApplication.shared.keyWindow` | iOS 13 | Scene-based window access | `\.keyWindow` |

## UIKit Deprecated APIs

```bash
grep -rn "UIAlertView\b\|UIActionSheet\b\|UIWebView\b\|UISearchDisplayController\|beginAnimations\|commitAnimations\|UIScreen\.main\|\.keyWindow\b\|statusBarStyle\b\|UIPopoverController\b\|UIApplication.shared.open.*options:\[\:\]" --include="*.swift"
```

| Deprecated API | Since | Replacement |
|---------------|-------|-------------|
| `UIAlertView` | iOS 9 | `UIAlertController` |
| `UIActionSheet` | iOS 9 | `UIAlertController(.actionSheet)` |
| `UIWebView` | iOS 12 (removed) | `WKWebView` |
| `UISearchDisplayController` | iOS 8 | `UISearchController` |
| `beginAnimations/commitAnimations` | iOS 4 | `UIView.animate(withDuration:)` |
| `UIApplication.shared.keyWindow` | iOS 13 | Scene-based: `UIApplication.shared.connectedScenes` |
| `UIScreen.main` | iOS 16 | `view.window?.screen` or scene-based |
| `UIPopoverController` | iOS 9 | `UIPopoverPresentationController` |

## Common Anti-Patterns (Not Deprecated but Flagged)

```bash
grep -rn "GeometryReader\|\.onAppear.*fetch\|\.onAppear.*load\|DispatchQueue.main.async" --include="*.swift"
```

| Pattern | Issue | Better Alternative |
|---------|-------|--------------------|
| `GeometryReader` everywhere | Breaks layout, causes sizing issues | Use `.containerRelativeFrame` (iOS 17+) or relative sizing |
| `.onAppear { fetch() }` | Not cancellable, race conditions | `.task {}` (iOS 15+) |
| `DispatchQueue.main.async` in SwiftUI | Fragile timing hack | `@MainActor`, `.task {}`, or proper state management |
| `Timer.publish` for animations | Battery drain, imprecise | `TimelineView` (iOS 15+) or `.animation` |
| Force unwrap in views (`!`) | Crash risk | Optional binding or default values |
