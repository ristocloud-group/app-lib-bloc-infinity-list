part of 'bloc_infinity_list.dart';

/// A class for the manual infinite list view implementation.
///
/// Provides a "Load More" button at the end of the list for manual loading.
class ManualInfiniteListView<T> extends InfiniteListView<T> {
  /// A builder for the "Load More" button when in manual mode.
  final Widget Function(BuildContext context)? loadMoreButtonBuilder;

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

class ManualInfiniteListViewState<T> extends State<ManualInfiniteListView<T>> {
  @override
  void initState() {
    super.initState();

    // Load initial items
    widget.bloc.add(LoadItemsEvent());
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
                padding: EdgeInsets.zero,
                // Respect the shrinkWrap parameter
                shrinkWrap: widget.shrinkWrap,
                physics: widget.physics ??
                    (widget.shrinkWrap
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics()),
                // - If shrinkWrap is true, disable internal scrolling
                // - If shrinkWrap is false, enable scrolling based on the provided physics
                itemCount: items.length + 1,
                separatorBuilder: (context, index) {
                  if (index != items.length - 1 ||
                      (widget.showLastDivider?.call() ?? true)) {
                    return widget.dividerWidget ?? const SizedBox.shrink();
                  }
                  return const SizedBox.shrink();
                },
                itemBuilder: (context, index) {
                  if (index < items.length) {
                    return widget.itemBuilder(context, items[index]);
                  } else {
                    // "Load More" button or indicator
                    return _buildLoadMoreButton(state);
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

  /// Builds the "Load More" button or indicator based on the current state.
  Widget _buildLoadMoreButton(BaseInfiniteListState<T> state) {
    final isLoading = state is LoadingState<T>;
    final noMoreItems = state is NoMoreItemsState<T>;

    if (noMoreItems) {
      return _noMoreItemWidget(context);
    }

    return Center(
      child: widget.loadMoreButtonBuilder?.call(context) ??
          ElevatedButton(
            key: const Key('loadMoreButton'), // Assigning a unique key here
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
