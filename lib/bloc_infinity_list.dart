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

/// An abstract class representing an infinite scrolling list view.
///
/// This class provides factory constructors to create instances of infinite
/// list views with different loading behaviors.
///
/// - [InfiniteListView.automatic]: Automatically loads more items when the
///   user scrolls to the bottom.
/// - [InfiniteListView.manual]: Provides a "Load More" button at the end of
///   the list for manual loading.
///
/// The [InfiniteListView] uses an [InfiniteListBloc] to manage the state and
/// loading of items.
///
/// ## Parameters
/// - [shrinkWrap]: Determines whether the extent of the scroll view in the
///   scrollDirection should be determined by the contents being viewed.
///   - **`true`**: The scroll view will size itself to the height of its
///     children. Useful when embedding the list within another scrollable widget.
///   - **`false`**: The scroll view will occupy all available space in the
///     scrollDirection. Suitable for standalone scrollable lists.
/// - [physics]: Determines the physics for the scroll view. Controls how the
///   scroll view behaves when user input is received.
///   - **`NeverScrollableScrollPhysics`**: Disables scrolling for the list.
///     Useful when the list is embedded within another scrollable widget.
///   - **`AlwaysScrollableScrollPhysics`** or other scroll physics: Enables
///     scrolling as per the specified behavior.
///
/// ## Usage Examples
///
/// ### Standalone Scrollable List
/// ```dart
/// InfiniteListView<MyItem>.automatic(
///   bloc: myInfiniteListBloc,
///   shrinkWrap: false, // Occupies all available space
///   physics: AlwaysScrollableScrollPhysics(), // Enables scrolling
///   itemBuilder: (context, item) => ListTile(title: Text(item.title)),
/// );
/// ```
///
/// ### Embedded within a SingleChildScrollView
/// ```dart
/// SingleChildScrollView(
///   child: Column(
///     children: [
///       // Other widgets
///       InfiniteListView<MyItem>.manual(
///         bloc: myInfiniteListBloc,
///         shrinkWrap: true, // Sizes to content
///         physics: NeverScrollableScrollPhysics(), // Delegates scrolling
///         itemBuilder: (context, item) => ListTile(title: Text(item.title)),
///         loadMoreButtonBuilder: (context) => ElevatedButton(
///           onPressed: () => myInfiniteListBloc.add(LoadMoreItemsEvent()),
///           child: Text('Load More'),
///         ),
///       ),
///       // Other widgets
///     ],
///   ),
/// );
/// ```
abstract class InfiniteListView<T> extends StatefulWidget {
  /// The BLoC responsible for fetching and managing the list items.
  final InfiniteListBloc<T> bloc;

  /// Determines whether the scroll view should shrink to fit its content.
  final bool shrinkWrap;

  /// A function that builds the widget for each item in the list.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// A widget to display while the list is loading.
  final Widget Function(BuildContext context)? loadingWidget;

  /// A widget to display when an error occurs.
  final Widget Function(BuildContext context, String error)? errorWidget;

  /// A widget to display when there are no items in the list.
  final Widget Function(BuildContext context)? emptyWidget;

  /// A widget to display when there are no more items in the list.
  final Widget Function(BuildContext context)? noMoreItemWidget;

  /// A widget to display between the items in the list.
  final Widget? dividerWidget;

  /// A callback to determine whether to show the last divider in the list.
  ///
  /// When building the list items, [InfiniteListView] uses this callback to decide
  /// if the divider should be displayed after the final item in the list. This is
  /// useful for scenarios where the last item should not have a trailing divider,
  /// or when additional conditions need to be met.
  ///
  /// ## Example
  ///
  /// ```dart
  /// InfiniteListView<MyItem>.manual(
  ///   bloc: myInfiniteListBloc,
  ///   itemBuilder: (context, item) => ListTile(title: Text(item.title)),
  ///   showLastDivider: () => false, // Hides the last divider
  /// );
  /// ```
  final BoolCallbackAction? showLastDivider;

  /// The margin for the list view.
  final EdgeInsetsGeometry? margin;

  /// The padding for the list view.
  final EdgeInsetsGeometry? padding;

  /// The background color of the list view.
  final Color? backgroundColor;

  /// The border radius of the list view.
  final BorderRadiusGeometry? borderRadius;

  /// The border color of the list view.
  final Color borderColor;

  /// The border width of the list view.
  final double borderWidth;

  /// The box shadow for the list view.
  final List<BoxShadow>? boxShadow;

  /// The physics for the scroll view.
  final ScrollPhysics? physics;

  /// Creates an [InfiniteListView] widget.
  const InfiniteListView({
    super.key,
    required this.bloc,
    required this.shrinkWrap,
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
    this.physics,
  });

  /// Factory constructor for automatic loading mode.
  ///
  /// Automatically loads more items when the user scrolls to the bottom of
  /// the list.
  factory InfiniteListView.automatic({
    Key? key,
    required InfiniteListBloc<T> bloc,
    required Widget Function(BuildContext context, T item) itemBuilder,
    // Optional parameters
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
    return AutomaticInfiniteListView<T>(
      key: key,
      bloc: bloc,
      itemBuilder: itemBuilder,
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

  /// Factory constructor for manual loading mode.
  ///
  /// Provides a "Load More" button at the end of the list for manual loading
  /// of more items.
  factory InfiniteListView.manual({
    Key? key,
    required InfiniteListBloc<T> bloc,
    bool shrinkWrap = false,
    required Widget Function(BuildContext context, T item) itemBuilder,
    Widget Function(BuildContext context)? loadMoreButtonBuilder,
    // Optional parameters
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
