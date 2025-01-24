// infinite_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'infinite_list_bloc/infinite_list_bloc.dart';

part 'automatic_infinite_list_view.dart';
part 'manual_infinite_list_view.dart';

/// A typedef representing a callback function that returns a boolean value.
///
/// This callback is typically used to determine conditional behaviors within the
/// [InfiniteListView], such as whether to display the last divider in the list.
///
/// ## Usage Example
///
/// ```dart
/// bool shouldShowLastDivider() {
///   // Your logic here
///   return true;
/// }
///
/// InfiniteListView<MyItem>.manual(
///   bloc: myInfiniteListBloc,
///   itemBuilder: (context, item) => ListTile(title: Text(item.title)),
///   showLastDivider: shouldShowLastDivider,
/// );
/// ```
typedef BoolCallbackAction = bool Function();

/// An abstract base class that implements a stateful widget for infinite lists,
/// with optional pull-to-refresh and various customization parameters.
///
/// This class is intended to be extended by specialized classes:
/// - [AutomaticInfiniteListView], created via [InfiniteListView.automatic()],
///   which automatically loads more items when the user scrolls near the bottom.
/// - [ManualInfiniteListView], created via [InfiniteListView.manual()],
///   which provides a "Load More" button for manually fetching additional items.
///
/// ### Key Features
/// - It uses a [BlocBuilder] tied to an [InfiniteListBloc] that emits states such
///   as [InitialState], [LoadingState], [LoadedState], [NoMoreItemsState], and
///   [ErrorState].
/// - It can display a variety of widgets for loading, errors, empty states,
///   and "no more items" states.
/// - It supports shrink-wrapping and custom [ScrollPhysics].
///
/// ### Usage
///
/// ```dart
/// // Example of creating an automatic infinite list
/// InfiniteListView<MyModel>.automatic(
///   bloc: myInfiniteListBloc,
///   itemBuilder: (context, item) => MyItemWidget(item: item),
///   // optional customizations...
/// );
///
/// // Example of creating a manual infinite list
/// InfiniteListView<MyModel>.manual(
///   bloc: myInfiniteListBloc,
///   itemBuilder: (context, item) => MyItemWidget(item: item),
///   // optional customizations, including a custom "Load More" button...
/// );
/// ```
abstract class InfiniteListView<T> extends StatefulWidget {
  /// The [InfiniteListBloc] instance responsible for the list's loading,
  /// refreshing, and error-handling logic.
  final InfiniteListBloc<T> bloc;

  /// Whether the internal list should wrap its contents (`true`) or expand
  /// to fill its parent (`false`).
  ///
  /// - If `true`, typically the widget may be placed inside another scrollable
  ///   parent, and it might use [NeverScrollableScrollPhysics] internally.
  /// - If `false`, the list uses normal scroll physics and can expand to fill
  ///   the available space.
  final bool shrinkWrap;

  /// Custom [ScrollPhysics] for the internal list view.
  ///
  /// Defaults to:
  /// - [NeverScrollableScrollPhysics] if [shrinkWrap] is `true`,
  /// - [AlwaysScrollableScrollPhysics] if [shrinkWrap] is `false`,
  /// unless specified otherwise.
  final ScrollPhysics? physics;

  /// A builder function to create each item of type [T] within the list.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// An optional builder for a loading widget, shown when the list is in
  /// a [LoadingState] or when it first initializes ([InitialState]).
  final Widget Function(BuildContext context)? loadingWidget;

  /// An optional builder for an error widget, shown when the list is in an
  /// [ErrorState]. Receives the error message as a parameter.
  final Widget Function(BuildContext context, String error)? errorWidget;

  /// An optional builder for an empty widget, shown when there are no items
  /// in the list ([LoadedState.state.items] is empty).
  final Widget Function(BuildContext context)? emptyWidget;

  /// An optional builder for a widget indicating there are no more items,
  /// shown when the bloc reaches [NoMoreItemsState].
  final Widget Function(BuildContext context)? noMoreItemWidget;

  /// An optional widget to display between list items (e.g., a divider).
  final Widget? dividerWidget;

  /// A callback determining whether to display the divider after the last item.
  /// If not provided, the divider is shown by default.
  final BoolCallbackAction? showLastDivider;

  /// Outer margin around the container that wraps the list.
  final EdgeInsetsGeometry? margin;

  /// Inner padding within the container that wraps the list.
  final EdgeInsetsGeometry? padding;

  /// Background color of the container that wraps the list.
  final Color? backgroundColor;

  /// Optional border radius for rounding the corners of the container.
  final BorderRadiusGeometry? borderRadius;

  /// Border color of the container. Defaults to [Colors.transparent].
  final Color borderColor;

  /// Border width for the container. Defaults to `1`.
  final double borderWidth;

  /// A list of [BoxShadow] for the container, allowing shadow effects.
  final List<BoxShadow>? boxShadow;

  /// Creates an [InfiniteListView].
  ///
  /// This constructor is generally not called directly, but rather through
  /// one of the factory constructors: [InfiniteListView.automatic] or
  /// [InfiniteListView.manual]. Subclasses like [AutomaticInfiniteListView]
  /// and [ManualInfiniteListView] extend this class to provide specific
  /// loading behaviors.
  const InfiniteListView({
    super.key,
    required this.bloc,
    this.shrinkWrap = false,
    this.physics,
    required this.itemBuilder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.noMoreItemWidget,
    this.dividerWidget,
    this.showLastDivider,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.borderColor = Colors.transparent,
    this.borderWidth = 1,
    this.boxShadow,
  });

  /// Creates an [AutomaticInfiniteListView], which automatically loads more
  /// items when the user scrolls near the bottom of the list.
  ///
  /// - [bloc]: An [InfiniteListBloc] that manages the list’s states (loading,
  ///   error, loaded, etc.).
  /// - [itemBuilder]: A function to build each list item widget.
  /// - [shrinkWrap]: Whether the list should wrap its content.
  ///   Defaults to `false`.
  /// - [physics]: Optional custom scroll physics.
  /// - [loadingWidget], [errorWidget], [emptyWidget], [noMoreItemWidget]:
  ///   Callbacks to provide custom widgets for various states.
  /// - [dividerWidget]: A widget shown between items.
  /// - [showLastDivider]: A callback to conditionally show the divider
  ///   after the last item.
  /// - [margin], [padding], [backgroundColor], [borderRadius], [borderColor],
  ///   [borderWidth], [boxShadow]: Visual customization for the container
  ///   wrapping the list.
  factory InfiniteListView.automatic({
    Key? key,
    required InfiniteListBloc<T> bloc,
    required Widget Function(BuildContext context, T item) itemBuilder,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    Widget Function(BuildContext context)? loadingWidget,
    Widget Function(BuildContext context, String error)? errorWidget,
    Widget Function(BuildContext context)? emptyWidget,
    Widget Function(BuildContext context)? noMoreItemWidget,
    Widget? dividerWidget,
    BoolCallbackAction? showLastDivider,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    BorderRadiusGeometry? borderRadius,
    Color borderColor = Colors.transparent,
    double borderWidth = 1,
    List<BoxShadow>? boxShadow,
  }) {
    return AutomaticInfiniteListView<T>(
      key: key,
      bloc: bloc,
      itemBuilder: itemBuilder,
      shrinkWrap: shrinkWrap,
      physics: physics,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      emptyWidget: emptyWidget,
      noMoreItemWidget: noMoreItemWidget,
      dividerWidget: dividerWidget,
      showLastDivider: showLastDivider,
      margin: margin,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      borderColor: borderColor,
      borderWidth: borderWidth,
      boxShadow: boxShadow,
    );
  }

  /// Creates a [ManualInfiniteListView], which displays a "Load More" button
  /// (or a custom widget) at the bottom of the list to fetch additional items
  /// when tapped.
  ///
  /// - [bloc]: An [InfiniteListBloc] that manages the list’s states.
  /// - [itemBuilder]: A function to build each list item widget.
  /// - [loadMoreButtonBuilder]: A callback to build a custom "Load More" button.
  ///   If omitted, a default button is shown.
  /// - [shrinkWrap]: Whether the list should wrap its content. Defaults to `false`.
  /// - [physics]: Optional custom scroll physics.
  /// - [loadingWidget], [errorWidget], [emptyWidget], [noMoreItemWidget]:
  ///   Callbacks to provide custom widgets for various states.
  /// - [dividerWidget]: A widget shown between items.
  /// - [showLastDivider]: A callback to conditionally show the divider
  ///   after the last item.
  /// - [margin], [padding], [backgroundColor], [borderRadius], [borderColor],
  ///   [borderWidth], [boxShadow]: Visual customization for the container
  ///   wrapping the list.
  factory InfiniteListView.manual({
    Key? key,
    required InfiniteListBloc<T> bloc,
    bool shrinkWrap = false,
    required Widget Function(BuildContext context, T item) itemBuilder,
    Widget Function(BuildContext context)? loadMoreButtonBuilder,
    Widget Function(BuildContext context)? loadingWidget,
    Widget Function(BuildContext context, String error)? errorWidget,
    Widget Function(BuildContext context)? emptyWidget,
    Widget Function(BuildContext context)? noMoreItemWidget,
    Widget? dividerWidget,
    BoolCallbackAction? showLastDivider,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    BorderRadiusGeometry? borderRadius,
    Color borderColor = Colors.transparent,
    double borderWidth = 1,
    List<BoxShadow>? boxShadow,
    ScrollPhysics? physics,
  }) {
    return ManualInfiniteListView<T>(
      key: key,
      bloc: bloc,
      shrinkWrap: shrinkWrap,
      itemBuilder: itemBuilder,
      loadMoreButtonBuilder: loadMoreButtonBuilder,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      emptyWidget: emptyWidget,
      noMoreItemWidget: noMoreItemWidget,
      dividerWidget: dividerWidget,
      showLastDivider: showLastDivider,
      margin: margin,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      borderColor: borderColor,
      borderWidth: borderWidth,
      boxShadow: boxShadow,
      physics: physics,
    );
  }
}
