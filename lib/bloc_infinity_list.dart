import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'infinite_list_bloc/infinite_list_bloc.dart';

part 'automatic_infinite_list_view.dart';

part 'manual_infinite_list_view.dart';

/// A typedef representing a callback function that returns a boolean value.
typedef BoolCallbackAction = bool Function();

/// An abstract base class that implements a stateful widget for infinite lists.
abstract class InfiniteListView<T> extends StatefulWidget {
  /// The [InfiniteListBloc] instance responsible for the list logic.
  final InfiniteListBloc<T> bloc;

  /// Whether the internal list should wrap its contents or expand.
  final bool shrinkWrap;

  /// Custom [ScrollPhysics] for the internal list view.
  final ScrollPhysics? physics;

  /// A builder function to create each item.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// An optional builder for a loading widget.
  final Widget Function(BuildContext context)? loadingWidget;

  /// An optional builder for an error widget.
  final Widget Function(BuildContext context, String error)? errorWidget;

  /// An optional builder for an empty widget.
  final Widget Function(BuildContext context)? emptyWidget;

  /// An optional builder for a widget indicating there are no more items.
  final Widget Function(BuildContext context)? noMoreItemWidget;

  /// An optional widget to display between list items.
  final Widget? dividerWidget;

  /// A callback determining whether to display the divider after the last item.
  final BoolCallbackAction? showLastDivider;

  /// Outer margin around the container.
  final EdgeInsetsGeometry? margin;

  /// Inner padding within the container.
  final EdgeInsetsGeometry? padding;

  /// Background color of the container.
  final Color? backgroundColor;

  /// Optional border radius.
  final BorderRadiusGeometry? borderRadius;

  /// Border color of the container.
  final Color borderColor;

  /// Border width for the container.
  final double borderWidth;

  /// A list of [BoxShadow] for the container.
  final List<BoxShadow>? boxShadow;

  /// The foreground color of the refresh indicator.
  final Color? refreshIndicatorColor;

  /// The background color of the refresh indicator.
  final Color? refreshIndicatorBackgroundColor;

  /// The displacement of the refresh indicator.
  final double refreshIndicatorDisplacement;

  /// The stroke width of the refresh indicator.
  final double refreshIndicatorStrokeWidth;

  /// Creates an [InfiniteListView].
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
    this.refreshIndicatorColor,
    this.refreshIndicatorBackgroundColor,
    this.refreshIndicatorDisplacement = 40.0,
    this.refreshIndicatorStrokeWidth = 2.0,
  });

  /// Creates an [AutomaticInfiniteListView].
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
    double? loadMoreThreshold = 200.0,
    double? bottomOffset = 50.0,
    Color? refreshIndicatorColor,
    Color? refreshIndicatorBackgroundColor,
    double refreshIndicatorDisplacement = 40.0,
    double refreshIndicatorStrokeWidth = 2.0,
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
      loadMoreThreshold: loadMoreThreshold,
      bottomOffset: bottomOffset,
      refreshIndicatorColor: refreshIndicatorColor,
      refreshIndicatorBackgroundColor: refreshIndicatorBackgroundColor,
      refreshIndicatorDisplacement: refreshIndicatorDisplacement,
      refreshIndicatorStrokeWidth: refreshIndicatorStrokeWidth,
    );
  }

  /// Creates a [ManualInfiniteListView].
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
    Color? refreshIndicatorColor,
    Color? refreshIndicatorBackgroundColor,
    double refreshIndicatorDisplacement = 40.0,
    double refreshIndicatorStrokeWidth = 2.0,
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
      refreshIndicatorColor: refreshIndicatorColor,
      refreshIndicatorBackgroundColor: refreshIndicatorBackgroundColor,
      refreshIndicatorDisplacement: refreshIndicatorDisplacement,
      refreshIndicatorStrokeWidth: refreshIndicatorStrokeWidth,
    );
  }
}
