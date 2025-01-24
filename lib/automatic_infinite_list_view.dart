part of 'bloc_infinity_list.dart';

/// A widget that implements an automatic infinite scrolling list with pull-to-refresh functionality.
///
/// This widget is capable of:
/// - Dispatching a [LoadItemsEvent] to load the initial items when it's first built.
/// - Handling a pull-to-refresh gesture, which triggers a new [LoadItemsEvent].
/// - Detecting when the user is near the bottom of the list (via [_scrollController]) and
///   automatically dispatching a [LoadMoreItemsEvent].
/// - Displaying different states: loading, error, empty list, loaded list, and "no more items".
///
/// It supports either an expanding list (`shrinkWrap = false`) or a size-wrapping list (`shrinkWrap = true`).
/// When `shrinkWrap = true`, the [Container + ListView] is wrapped in a [SingleChildScrollView] using the
/// same [ScrollController], ensuring that both the pull-to-refresh and infinite scroll can still work.
///
/// The user can customize layout, padding, decoration, thresholds for "load more", and so on.
///
/// Example usage:
///
/// ```dart
/// AutomaticInfiniteListView<MyModel>(
///   bloc: myInfiniteListBloc,
///   itemBuilder: (context, item) => MyListItemWidget(item: item),
///   shrinkWrap: true,
///   physics: const NeverScrollableScrollPhysics(),
///   margin: const EdgeInsets.all(8),
///   padding: const EdgeInsets.all(16),
///   loadMoreThreshold: 250.0,
///   bottomOffset: 60.0,
/// );
/// ```
class AutomaticInfiniteListView<T> extends InfiniteListView<T> {
  /// Padding for individual list items.
  final EdgeInsetsGeometry? itemPadding;

  /// Padding for the loading indicator.
  final EdgeInsetsGeometry? loadingPadding;

  /// Padding for the 'no more items' indicator.
  final EdgeInsetsGeometry? noMoreItemPadding;

  /// The distance from the bottom at which the widget should trigger [LoadMoreItemsEvent].
  /// Defaults to `200.0`.
  final double loadMoreThreshold;

  /// Additional bottom offset to consider when computing the bottom scroll threshold.
  /// By default, it's added to [MediaQuery.of(context).viewPadding.bottom].
  /// Defaults to `50.0`.
  final double bottomOffset;

  const AutomaticInfiniteListView({
    super.key,

    /// Custom scroll physics can be passed here (e.g. [BouncingScrollPhysics] or [ClampingScrollPhysics]).
    super.physics,

    /// Whether the list should wrap its contents (`true`) or expand (`false`).
    super.shrinkWrap,

    /// The BLoC responsible for providing list states ([LoadedState], [LoadingState], etc.).
    required super.bloc,

    /// The builder function used to create individual list items.
    required super.itemBuilder,

    // Customizable decorations and visual parameters for the container
    super.margin,
    super.padding,
    super.backgroundColor,
    super.borderRadius,
    super.borderColor,
    super.borderWidth,
    super.boxShadow,

    /// Optional widgets to override default states
    super.loadingWidget,
    super.errorWidget,
    super.emptyWidget,
    super.noMoreItemWidget,
    super.dividerWidget,
    super.showLastDivider,

    /// Padding for individual items and special states
    this.itemPadding,
    this.loadingPadding,
    this.noMoreItemPadding,

    /// Custom threshold for infinite scroll detection
    this.loadMoreThreshold = 200.0,

    /// Additional offset from the bottom to consider
    this.bottomOffset = 50.0,
  });

  @override
  State<InfiniteListView<T>> createState() =>
      AutomaticInfiniteListViewState<T>();
}

class AutomaticInfiniteListViewState<T>
    extends State<AutomaticInfiniteListView<T>> {
  /// The internal [ScrollController] that manages scroll events and detects "bottom" for infinite scroll.
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    // Create and attach a ScrollController to detect end-of-scroll events.
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Dispatch the initial event to load items.
    widget.bloc.add(LoadItemsEvent());
  }

  @override
  void dispose() {
    // Detach listener and dispose controller to avoid memory leaks.
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Called whenever the scroll position changes to check if we've reached the bottom
  /// and, if so, dispatch a [LoadMoreItemsEvent].
  void _onScroll() {
    if (_isBottom) {
      final currentState = widget.bloc.state;
      if (currentState is LoadedState<T>) {
        widget.bloc.add(LoadMoreItemsEvent());
      }
    }
  }

  /// Checks whether the user has scrolled within [widget.loadMoreThreshold]
  /// of the bottom of the scrollable area, considering [widget.bottomOffset]
  /// plus any OS-level bottom padding (e.g. on iOS with a notch).
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    final double bottomSafeArea =
        MediaQuery.of(context).viewPadding.bottom + widget.bottomOffset;

    // If the user is within [loadMoreThreshold + bottomSafeArea] of the bottom,
    // we consider it "near the bottom".
    return (maxScroll - currentScroll) <=
        (widget.loadMoreThreshold + bottomSafeArea);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfiniteListBloc<T>, BaseInfiniteListState<T>>(
      bloc: widget.bloc,
      builder: (context, state) {
        // Handle different BLoC states

        if (state is InitialState<T>) {
          // When the list is being initialized, show a loading widget
          return _loadingWidget(context);
        } else if (state is ErrorState<T>) {
          // If an error occurred, show an error widget
          return _errorWidget(context, state.error.toString());
        } else if (state is LoadedState<T> ||
            state is NoMoreItemsState<T> ||
            state is LoadingState<T>) {
          // Extract the loaded items
          final items = state.state.items;

          // If the list is empty, show an empty widget
          if (items.isEmpty) {
            return _emptyWidget(context);
          }

          // Otherwise, we have some data to show; wrap it in a RefreshIndicator
          return RefreshIndicator(
            onRefresh: () async {
              // Trigger a full reload of the list
              widget.bloc.add(LoadItemsEvent());
              // Wait until we see a LoadedState or ErrorState from the BLoC
              await widget.bloc.stream.firstWhere(
                (st) => st is LoadedState<T> || st is ErrorState<T>,
              );
            },
            child: _buildContainerAndList(items, state),
          );
        }

        // For any other case, show an empty widget (or you can handle it differently)
        return const SizedBox.shrink();
      },
    );
  }

  /// Builds the parent [Container] and the appropriate scrollable widget:
  /// - If [widget.shrinkWrap] is `true`, we wrap the [Container + ListView]
  ///   in a [SingleChildScrollView] so that [RefreshIndicator] and infinite scroll
  ///   both work properly.
  /// - If [widget.shrinkWrap] is `false`, we simply return the [Container] with the [ListView].
  Widget _buildContainerAndList(List<T> items, BaseInfiniteListState<T> state) {
    // Create the ListView that displays items (plus loader / no-more-items)
    final listView = ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: widget.shrinkWrap == true,
      physics: widget.physics ??
          (widget.shrinkWrap == true
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics()),
      // If shrinkWrap is false, use our ScrollController for infinite scroll detection
      controller: widget.shrinkWrap == true ? null : _scrollController,
      itemCount: _calculateItemCount(items, state),
      separatorBuilder: (context, index) =>
          widget.dividerWidget ?? const SizedBox.shrink(),
      itemBuilder: (context, index) {
        return _buildListItem(index, items, state);
      },
    );

    // Our Container (the parent of the ListView)
    final containerWithList = Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
        boxShadow: widget.boxShadow,
      ),
      child: listView,
    );

    // If shrinkWrap is true, wrap the container in a SingleChildScrollView
    // that uses the same ScrollController. This allows:
    // 1) The pull-to-refresh gesture to work via overscroll.
    // 2) The infinite scroll detection to continue working.
    if (widget.shrinkWrap == true) {
      return SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: containerWithList,
      );
    } else {
      // If shrinkWrap is false, just return the container with the ListView
      return containerWithList;
    }
  }

  /// Returns the total number of items the ListView should display,
  /// accounting for an extra slot if we're loading or if there's "no more items."
  int _calculateItemCount(List<T> items, BaseInfiniteListState<T> state) {
    if (state is LoadingState<T> || state is NoMoreItemsState<T>) {
      // If loading or no-more-items, we add one extra item for the loader / no-more widget
      return items.length + 1;
    }
    return items.length;
  }

  /// Builds an individual item for the ListView at [index].
  /// This could be a normal item, a loader item, or a "no more items" widget.
  Widget _buildListItem(
      int index, List<T> items, BaseInfiniteListState<T> state) {
    // If index is within the range of the current items, build a normal item
    if (index < items.length) {
      return Padding(
        padding:
            widget.itemPadding ?? const EdgeInsets.symmetric(vertical: 4.0),
        child: widget.itemBuilder(context, items[index]),
      );
    }
    // If we're at the extra item slot and the state is "No more items", show the "no more" widget
    else if (index == items.length && state is NoMoreItemsState<T>) {
      return Center(
        child: Padding(
          padding: widget.noMoreItemPadding ?? const EdgeInsets.all(12.0),
          child: _noMoreItemWidget(context),
        ),
      );
    }
    // Otherwise, it must be the loader widget (at the extra item slot)
    else {
      return Center(
        child: Padding(
          padding: widget.loadingPadding ?? const EdgeInsets.all(12.0),
          child: _loadingWidget(context),
        ),
      );
    }
  }

  /// Default loading widget if [loadingWidget] is not provided.
  Widget _loadingWidget(BuildContext context) {
    return widget.loadingWidget?.call(context) ??
        const Center(child: CircularProgressIndicator());
  }

  /// Default error widget if [errorWidget] is not provided.
  Widget _errorWidget(BuildContext context, String error) {
    return widget.errorWidget?.call(context, error) ??
        Center(child: Text('Error: $error'));
  }

  /// Default empty widget if [emptyWidget] is not provided.
  Widget _emptyWidget(BuildContext context) {
    return widget.emptyWidget?.call(context) ??
        const Center(child: Text('No items'));
  }

  /// Default "no more items" widget if [noMoreItemWidget] is not provided.
  Widget _noMoreItemWidget(BuildContext context) {
    return widget.noMoreItemWidget?.call(context) ??
        const Center(child: Text('No more items'));
  }
}
