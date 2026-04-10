## 0.1.0

- **Concurrency Control**: Integrated `bloc_concurrency` to eliminate race conditions between
  pull-to-refresh and infinite scrolling. `LoadItemsEvent` now uses a `restartable()` transformer,
  and `LoadMoreItemsEvent` uses a `droppable()` transformer.
- **Single Import Architecture**: Exported BLoC components directly from the main library file.
  Users now only need a single `import 'package:bloc_infinity_list/bloc_infinity_list.dart';` to
  access widgets, states, and events.
- **RefreshIndicator Customization**: Added deep customization for pull-to-refresh styling,
  including `refreshIndicatorColor`, `refreshIndicatorBackgroundColor`,
  `refreshIndicatorDisplacement`, and `refreshIndicatorStrokeWidth`.
- **Codebase Clean-up**: Removed redundant standard comments in favor of clean DartDoc (`///`)
  documentation. Fully translated test files to English.
- **Documentation**: Major Wiki and documentation overhaul, adding dedicated guides for Automatic
  and Manual modes, concurrency workflows, and complete usage examples.

## 0.0.8

- Web support
- Refactoring

## 0.0.7

- Added a new **AutomaticInfiniteListPage** with `shrinkWrap = false` for classic scrolling
- Reintroduced **ScrollController** logic for infinite scroll detection in both shrinkWrap modes
- Enhanced **DartDoc comments** across `AutomaticInfiniteListView`, `ManualInfiniteListView`, and
  the base `InfiniteListView` class
- Showcased **pull-to-refresh** integration and “no more items” handling
- Provided **example pages** illustrating manual and automatic loading scenarios

## 0.0.6

- Custom no more item widget
- Documentation refactoring

## 0.0.5

- Documentation refactoring
- Custom divider

## 0.0.4

- Added customization options
- Refactoring

## 0.0.3

- Change readme

## 0.0.2

- Update documentation.

## 0.0.1

- Added infinite scrolling ListView with BLoC integration and debounce feature.