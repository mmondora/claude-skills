# iOS API Version Reference

Quick reference for checking API availability against deployment targets.

## iOS 17+ APIs

```bash
grep -rn "\.scrollPosition\|\.contentMargins\|\.containerRelativeFrame\|\.scrollTargetBehavior\|\.sensoryFeedback\|TipView\|TipKit\|\.tipBackground\|\.popoverTip\|\.inspector\|\.onChange.*\\.old\|\.symbolEffect\|\.contentTransition(.numericText)\|\.fontDesign\|\.typesettingLanguage\|#Preview\b" --include="*.swift"
```

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

## iOS 16+ APIs

```bash
grep -rn "NavigationStack\|NavigationSplitView\|\.navigationDestination\|\.toolbarTitleMenu\|AnyLayout\|ViewThatFits\|\.contentTransition\|PhotosPicker\|\.gauge\|LabeledContent\|MultiDatePicker\|\.scrollDismissesKeyboard\|\.presentationDetents\|\.presentationDragIndicator\|\.toolbar(.hidden\|ShareLink\|\.gradient\b" --include="*.swift"
```

| API | iOS | Notes |
|-----|-----|-------|
| NavigationStack | 16.0 | Replaces NavigationView |
| NavigationSplitView | 16.0 | Multi-column navigation |
| `.navigationDestination` | 16.0 | Value-based navigation |
| `.presentationDetents` | 16.0 | Sheet sizing |
| `.presentationDragIndicator` | 16.0 | Sheet grab indicator |
| `.scrollDismissesKeyboard` | 16.0 | Keyboard dismiss on scroll |
| AnyLayout | 16.0 | Dynamic layout switching |
| ViewThatFits | 16.0 | Adaptive content |
| PhotosPicker | 16.0 | Photo library picker |
| Gauge | 16.0 | Gauge control |
| LabeledContent | 16.0 | Label+content pair |
| MultiDatePicker | 16.0 | Multiple date selection |
| ShareLink | 16.0 | Share sheet |
| `.toolbarTitleMenu` | 16.0 | Title menu in toolbar |

## iOS 15+ APIs

```bash
grep -rn "\.task {\|\.refreshable\|\.searchable\|\.swipeActions\|\.confirmationDialog\|AsyncImage\|FocusState\|\.interactiveDismissDisabled\|\.safeAreaInset\|TimelineView\|Canvas {\|\.badge(\|\.alert.*presenting\|ControlGroup\|\.tint(" --include="*.swift"
```

| API | iOS | Notes |
|-----|-----|-------|
| `.task {}` | 15.0 | Async task on appear |
| `.refreshable` | 15.0 | Pull to refresh |
| `.searchable` | 15.0 | Search integration |
| `.swipeActions` | 15.0 | List swipe actions |
| `.confirmationDialog` | 15.0 | Replaces ActionSheet |
| AsyncImage | 15.0 | Async image loading |
| @FocusState | 15.0 | Focus management |
| `.interactiveDismissDisabled` | 15.0 | Prevent sheet dismiss |
| `.safeAreaInset` | 15.0 | Safe area overlays |
| TimelineView | 15.0 | Time-based updates |
| Canvas | 15.0 | Immediate mode drawing |
| `.badge()` | 15.0 | Tab/list badges |
| `.tint()` | 15.0 | Replaces `.accentColor` |
| ControlGroup | 15.0 | Grouped controls |

## iOS 14+ APIs

```bash
grep -rn "\.onChange\|\.fullScreenCover\|ScrollViewReader\|LazyVGrid\|LazyHGrid\|LazyVStack\|LazyHStack\|@StateObject\|@AppStorage\|@SceneStorage\|Map {\|Label {\|Link {\|ProgressView\|TextEditor\|ColorPicker\|SignInWithAppleButton\|\.matchedGeometryEffect" --include="*.swift"
```

| API | iOS | Notes |
|-----|-----|-------|
| `.onChange(of:)` | 14.0 | Value change observer |
| `.fullScreenCover` | 14.0 | Full screen modal |
| ScrollViewReader | 14.0 | Scroll position control |
| LazyVGrid/LazyHGrid | 14.0 | Grid layouts |
| LazyVStack/LazyHStack | 14.0 | Lazy loading stacks |
| @StateObject | 14.0 | Owned observable |
| @AppStorage | 14.0 | UserDefaults binding |
| @SceneStorage | 14.0 | Scene state persistence |
| Label | 14.0 | Icon + text |
| Link | 14.0 | URL link |
| ProgressView | 14.0 | Progress indicator |
| TextEditor | 14.0 | Multi-line text input |
| ColorPicker | 14.0 | Color selection |
| `.matchedGeometryEffect` | 14.0 | Shared element transitions |
