# use a custom paint for the entire grid
# Summary of Changes (2026-05-27)

## General Overview

This diff is primarily a **performance optimization pass** on the `DraggableGrid` component, with minor cleanup in generated plugin files. The core theme is replacing full cache invalidations with targeted mutations and introducing layout computation caching to reduce rebuild overhead.

---

## File-by-File Breakdown

### 1. `lib/ui/util_widgets/draggable_grid.dart` (181 insertions, 96 deletions)

**Why:** The grid was calling `_invalidateWidgetCacheAndNotifyListeners()` on every mutation (add/remove row/col, set cell, etc.), which rebuilt the entire widget list from scratch. These changes replace that with direct, index-aware mutations to the existing cache, avoiding redundant rebuilds.

#### Key Changes

| Change | What | Why |
|---|---|---|
| `setSelectMode()` | Added `_invalidateWidgetListCache()` before `notifyListeners()` | When select mode toggles, the cached widget list must be cleared (selection indicators change appearance), but notification is decoupled |
| `addRow()` | Instead of full cache invalidation, directly `_widgetListCache!.add(...)` for each new cell | Avoid rebuilding entire grid when appending a single row |
| `insertCol()` | Directly `_widgetListCache!.insert(...)` at the correct index for each row | Same optimization — O(n) insert instead of full rebuild |
| `insertRow()` | Builds new `GridCell` widgets and `insertAll` at the correct position in the cache | Avoids invalidating existing widgets when inserting a row mid-grid |
| `addCol()` | `_widgetListCache!.insert(...)` at the end of each row | Same optimization |
| `removeAt()` | In-place replacement of the cache entry at computed index | Instead of full rebuild, just swap one cell |
| `removeRow()` | `_widgetListCache!.removeRange(start, start + colCount)` | Removes exactly the row's cells from the flat list |
| `removeCol()` | Loops rows backwards and `removeAt` for the column index | Removes one column element per row from the flat cache |
| `setWidget()` | In-place replacement via `_widgetListCache![index] = ...` | Single-cell update without full rebuild |
| `_buildGridWidgetList()` | Added `key: ValueKey(cell)` to `GridCell` constructor | Stable keys let Flutter diff the widget tree correctly, avoiding unnecessary DOM mutations |
| `_SelectionIndicatorMixin._buildWidget()` | Moved early return of `widget` when `!selectMode` to the top | Avoids unnecessary ListenableBuilder/Stack when not in select mode |
| `_SelectionIndicatorMixin._buildWidget()` | Removed conditional LayoutBuilder — now always wraps in Stack/LayoutBuilder | Simplifies logic; the overhead of LayoutBuilder is negligible and the previous conditional structure was redundant |
| **New class: `_GridLayoutCache`** | Caches DPR, total/base/remainder physical dimensions per row/col | Prevents recomputing floor division and DPR lookup on every `paintChildren` and `getConstraintsForChild` call |
| **New class methods: `logicalWidth(col)` / `logicalHeight(row)`** | Derive logical size from cached physical base + remainder per cell | Cleaner, cached lookup vs inline recomputation |
| `GridFlowDelegate` | Added `_cache` and `_lastSize` fields; `_getCache()` method lazily builds `_GridLayoutCache` | Caches layout computations so `paintChildren` and `getConstraintsForChild` share the same cached values |
| `GridFlowDelegate.paintChildren()` | Removed inline DPR/total/base/rem math; uses `cache.logicalWidth/Height` | Cleaner, eliminates redundant computation on every paint |
| `GridFlowDelegate.getConstraintsForChild()` | Same refactor to use `_getCache()` | Consistent caching between layout and paint |
| **Cell class** | Added `==` override (compares row, col, identity of value) and `hashCode` | Needed for `ValueKey(cell)` to work correctly — stable equality ensures Flutter can identify moved/rebuilt cells across frames |

---

### 2. `lib/ui/widgets/parrot_button.dart` (1 insertion, 1 deletion)

**Change:** `key: UniqueKey()` → `key: ObjectKey(buttonData)`

**Why:** `UniqueKey()` creates a new key on every build, forcing Flutter to destroy and recreate the widget tree under this node every frame. `ObjectKey(buttonData)` uses the stable button data object identity, so the widget is only rebuilt when the underlying data actually changes. This fixes unnecessary remounting and state loss.

---

### 3. `macos/Flutter/GeneratedPluginRegistrant.swift` (2 deletions)

**Change:** Removed `import path_provider_foundation` and `PathProviderPlugin.register(...)`.

**Why:** The `path_provider` plugin has been removed from the macOS build dependencies — either it's no longer needed (replaced by another API) or was unused.

---

### 4. `windows/flutter/generated_plugins.cmake` (1 insertion)

**Change:** Added `jni` to the `FLUTTER_FFI_PLUGIN_LIST`.

**Why:** A new FFI dependency on the `jni` native bridge was added for Windows, likely needed to support a new native feature or plugin that requires JNI access.
