part of 'bloc_infinity_list.dart';

/// A class for the automatic infinite list view implementation.
///
/// Automatically loads more items when the user scrolls to the bottom.
class AutomaticInfiniteListView<T> extends InfiniteListView<T> {
  const AutomaticInfiniteListView({
    super.key,
    required super.bloc,
    required super.itemBuilder,
    super.shrinkWrap = false, // Typically false for standalone lists
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
  State<InfiniteListView<T>> createState() =>
      AutomaticInfiniteListViewState<T>();
}

class AutomaticInfiniteListViewState<T>
    extends State<AutomaticInfiniteListView<T>> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Load initial items
    widget.bloc.add(LoadItemsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Called whenever the scroll position changes.
  void _onScroll() {
    if (_isBottom) {
      // Trigger loading more items when scrolled to the bottom
      final currentState = widget.bloc.state;
      if (currentState is LoadedState<T>) {
        widget.bloc.add(LoadMoreItemsEvent());
      }
    }
  }

  /// Checks if the scroll position is near the bottom.
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    const threshold = 200.0; // Distance from bottom to trigger load
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return (maxScroll - currentScroll) <= threshold;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfiniteListBloc<T>, BaseInfiniteListState<T>>(
      bloc: widget.bloc,
      builder: (context, state) {
        if (state is InitialState<T>) {
          return _loadingWidget(context);
        } else if (state is ErrorState<T>) {
          return _errorWidget(context, state.error.toString());
        } else if (state is LoadedState<T> ||
            state is NoMoreItemsState<T> ||
            state is LoadingState<T>) {
          final items = state.state.items;
          if (items.isEmpty) {
            return _emptyWidget(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              widget.bloc.add(LoadItemsEvent());
              // Wait for the bloc to emit a LoadedState or ErrorState
              await widget.bloc.stream.firstWhere(
                  (state) => state is LoadedState<T> || state is ErrorState<T>);
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
                controller: _scrollController,
                physics:
                    widget.physics ?? const AlwaysScrollableScrollPhysics(),
                // Default scroll physics
                shrinkWrap: widget.shrinkWrap,
                // Typically false for standalone lists
                itemCount: items.length + 1,
                // Add one for the bottom indicator
                separatorBuilder: (context, index) =>
                    widget.dividerWidget ?? const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  if (index < items.length) {
                    return widget.itemBuilder(context, items[index]);
                  } else {
                    // Bottom indicator based on state
                    return _buildBottomIndicator(state);
                  }
                },
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Builds the bottom indicator widget based on the current state.
  Widget _buildBottomIndicator(BaseInfiniteListState<T> state) {
    if (state is LoadingState<T>) {
      return _loadingWidget(context);
    } else if (state is NoMoreItemsState<T>) {
      return _noMoreItemWidget(context);
    } else {
      return const SizedBox.shrink();
    }
  }

  /// Builds the widget for the loading indicator.
  Widget _loadingWidget(BuildContext context) {
    return widget.loadingWidget?.call(context) ??
        const Center(child: CircularProgressIndicator());
  }

  /// Builds the widget for displaying an error.
  Widget _errorWidget(BuildContext context, String error) {
    return widget.errorWidget?.call(context, error) ??
        Center(child: Text('Error: $error'));
  }

  /// Builds the widget for an empty list.
  Widget _emptyWidget(BuildContext context) {
    return widget.emptyWidget?.call(context) ??
        const Center(child: Text('No items'));
  }

  /// Builds the widget for when there are no more items in the list.
  Widget _noMoreItemWidget(BuildContext context) {
    return widget.noMoreItemWidget?.call(context) ??
        const Center(child: Text('No more items'));
  }
}
