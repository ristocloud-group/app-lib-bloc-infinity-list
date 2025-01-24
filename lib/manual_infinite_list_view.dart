part of 'bloc_infinity_list.dart';

/// A specialized widget for manually controlled infinite lists,
/// featuring a "Load More" button at the bottom of the list.
///
/// Unlike the automatic version, this widget does not automatically
/// load more items as the user scrolls. Instead, it displays a
/// "Load More" button (or a custom widget, if provided) to fetch the
/// next set of items manually.
///
/// **Key features:**
/// - Dispatches an initial [LoadItemsEvent] in [initState].
/// - Supports pull-to-refresh via a [RefreshIndicator].
/// - Displays a "Load More" button or a custom widget when more items
///   are available to load.
/// - Shows an optional "no more items" widget when the list is exhausted.
class ManualInfiniteListView<T> extends InfiniteListView<T> {
  /// A builder function that returns a "Load More" button widget.
  ///
  /// If provided, this builder is called at the bottom of the list
  /// when more items can be loaded. If not provided, a default
  /// [ElevatedButton] is shown instead.
  final Widget Function(BuildContext context)? loadMoreButtonBuilder;

  /// Creates a new instance of [ManualInfiniteListView].
  ///
  /// * [bloc]: The [InfiniteListBloc] responsible for managing list states
  ///   such as loading, error, empty, etc.
  /// * [shrinkWrap]: Whether the list should wrap its content or expand
  ///   to fill its parent. By default, you can pass `true` or `false`.
  /// * [itemBuilder]: A function that builds the UI for each item in the list.
  /// * [loadMoreButtonBuilder]: An optional builder to customize the
  ///   "Load More" button widget. If null, a default button is provided.
  /// * [loadingWidget], [errorWidget], [emptyWidget], [noMoreItemWidget]:
  ///   Optional callbacks to provide custom widgets for their respective states.
  /// * [dividerWidget]: A widget displayed between list items.
  /// * [showLastDivider]: A callback to conditionally show the divider
  ///   after the last item.
  /// * [margin], [padding], [backgroundColor], [borderRadius], [borderColor],
  ///   [borderWidth], [boxShadow]: Visual customization parameters for
  ///   the container wrapping the list.
  /// * [physics]: Custom scroll physics for the internal [ListView].
  const ManualInfiniteListView({
    super.key,
    required super.bloc,
    required super.shrinkWrap,
    required super.itemBuilder,
    this.loadMoreButtonBuilder,
    // Optional parameters
    super.loadingWidget,
    super.errorWidget,
    super.emptyWidget,
    super.noMoreItemWidget,
    super.dividerWidget,
    super.showLastDivider,
    super.margin,
    super.padding,
    super.backgroundColor,
    super.borderRadius,
    super.borderColor,
    super.borderWidth,
    super.boxShadow,
    super.physics,
  });

  @override
  State<InfiniteListView<T>> createState() => ManualInfiniteListViewState<T>();
}

/// The state class for [ManualInfiniteListView].
///
/// It listens to the [InfiniteListBloc] to rebuild when the list state changes.
/// Upon initialization, it dispatches a [LoadItemsEvent] to fetch the first
/// batch of items.
class ManualInfiniteListViewState<T> extends State<ManualInfiniteListView<T>> {
  @override
  void initState() {
    super.initState();
    // Dispatch an event to load the initial items.
    widget.bloc.add(LoadItemsEvent());
  }

  @override
  Widget build(BuildContext context) {
    // Use a BlocBuilder to listen to changes in the InfiniteListBloc.
    return BlocBuilder<InfiniteListBloc<T>, BaseInfiniteListState<T>>(
      bloc: widget.bloc,
      builder: (context, state) {
        // Show a loading widget when the state is "initial".
        if (state is InitialState<T>) {
          return _loadingWidget(context);
        }
        // Display an error widget if an error occurred.
        else if (state is ErrorState<T>) {
          return _errorWidget(context, state.error.toString());
        }
        // Handle states where the list could be loaded, loading more, or has no more items.
        else if (state is LoadedState<T> ||
            state is NoMoreItemsState<T> ||
            state is LoadingState<T>) {
          final items = state.state.items;

          // If the list is empty, show an empty widget.
          if (items.isEmpty) {
            return _emptyWidget(context);
          }

          // Otherwise, wrap everything in a RefreshIndicator for pull-to-refresh.
          return RefreshIndicator(
            onRefresh: () async {
              widget.bloc.add(LoadItemsEvent());
              // Wait for the bloc to emit a LoadedState or ErrorState after reload.
              await widget.bloc.stream.firstWhere(
                (s) => s is LoadedState<T> || s is ErrorState<T>,
              );
            },
            child: Container(
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
              child: ListView.separated(
                padding: EdgeInsets.zero,
                // Use the shrinkWrap parameter from the parent widget.
                shrinkWrap: widget.shrinkWrap,
                // If shrinkWrap == true, disable internal scrolling by default
                // (NeverScrollableScrollPhysics). Otherwise, allow scrolling.
                physics: widget.physics ??
                    (widget.shrinkWrap
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics()),
                // The list itemCount is the number of items + 1 (for the load-more button slot).
                itemCount: items.length + 1,
                separatorBuilder: (context, index) {
                  // Show the divider unless it's the last item and showLastDivider() is false
                  if (index != items.length - 1 ||
                      (widget.showLastDivider?.call() ?? true)) {
                    return widget.dividerWidget ?? const SizedBox.shrink();
                  }
                  return const SizedBox.shrink();
                },
                itemBuilder: (context, index) {
                  // If we're within the item range, build the item.
                  if (index < items.length) {
                    return widget.itemBuilder(context, items[index]);
                  }
                  // Otherwise, it's the slot for the "Load More" button or "no more" widget.
                  else {
                    return _buildLoadMoreButton(state);
                  }
                },
              ),
            ),
          );
        }

        // If the state doesn't match any known case, return an empty widget.
        return const SizedBox.shrink();
      },
    );
  }

  /// Builds the "Load More" button or "no more" widget, depending on the current state.
  Widget _buildLoadMoreButton(BaseInfiniteListState<T> state) {
    final isLoading = state is LoadingState<T>;
    final noMoreItems = state is NoMoreItemsState<T>;

    // If no more items are available, show the "no more items" widget.
    if (noMoreItems) {
      return _noMoreItemWidget(context);
    }

    // Otherwise, display either the user-provided loadMoreButtonBuilder or a default button.
    return Center(
      child: widget.loadMoreButtonBuilder?.call(context) ??
          ElevatedButton(
            key: const Key('loadMoreButton'),
            onPressed:
                isLoading ? null : () => widget.bloc.add(LoadMoreItemsEvent()),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.deepPurple,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ),
                  )
                : const Text(
                    'Load More',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
    );
  }

  /// Returns a loading widget, defaulting to a [CircularProgressIndicator]
  /// if no custom widget is provided.
  Widget _loadingWidget(BuildContext context) {
    return widget.loadingWidget?.call(context) ??
        const Center(child: CircularProgressIndicator());
  }

  /// Returns a widget that displays the given [error] message.
  /// Defaults to a [Text] widget if none is provided.
  Widget _errorWidget(BuildContext context, String error) {
    return widget.errorWidget?.call(context, error) ??
        Center(child: Text('Error: $error'));
  }

  /// Returns a widget to display when no items are found in the list.
  /// Defaults to a simple [Text] widget if none is provided.
  Widget _emptyWidget(BuildContext context) {
    return widget.emptyWidget?.call(context) ??
        const Center(child: Text('No items'));
  }

  /// Returns a widget to display when there are no more items to load.
  /// Defaults to a simple [Text] widget if none is provided.
  Widget _noMoreItemWidget(BuildContext context) {
    return widget.noMoreItemWidget?.call(context) ??
        const Center(child: Text('No more items'));
  }
}
