part of 'bloc_infinity_list.dart';

/// A specialized widget for manually controlled infinite lists.
class ManualInfiniteListView<T> extends InfiniteListView<T> {
  /// A builder function that returns a "Load More" button widget.
  final Widget Function(BuildContext context)? loadMoreButtonBuilder;

  /// Creates a new instance of [ManualInfiniteListView].
  const ManualInfiniteListView({
    super.key,
    required super.bloc,
    required super.shrinkWrap,
    required super.itemBuilder,
    this.loadMoreButtonBuilder,
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
    super.refreshIndicatorColor,
    super.refreshIndicatorBackgroundColor,
    super.refreshIndicatorDisplacement,
    super.refreshIndicatorStrokeWidth,
  });

  @override
  State<InfiniteListView<T>> createState() => ManualInfiniteListViewState<T>();
}

class ManualInfiniteListViewState<T> extends State<ManualInfiniteListView<T>> {
  @override
  void initState() {
    super.initState();
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
            color: widget.refreshIndicatorColor,
            backgroundColor: widget.refreshIndicatorBackgroundColor,
            displacement: widget.refreshIndicatorDisplacement,
            strokeWidth: widget.refreshIndicatorStrokeWidth,
            onRefresh: () async {
              widget.bloc.add(LoadItemsEvent());
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
                shrinkWrap: widget.shrinkWrap,
                physics: widget.physics ??
                    (widget.shrinkWrap
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics()),
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

  Widget _buildLoadMoreButton(BaseInfiniteListState<T> state) {
    final isLoading = state is LoadingState<T>;
    final noMoreItems = state is NoMoreItemsState<T>;

    if (noMoreItems) {
      return _noMoreItemWidget(context);
    }

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

  Widget _loadingWidget(BuildContext context) {
    return widget.loadingWidget?.call(context) ??
        const Center(child: CircularProgressIndicator());
  }

  Widget _errorWidget(BuildContext context, String error) {
    return widget.errorWidget?.call(context, error) ??
        Center(child: Text('Error: $error'));
  }

  Widget _emptyWidget(BuildContext context) {
    return widget.emptyWidget?.call(context) ??
        const Center(child: Text('No items'));
  }

  Widget _noMoreItemWidget(BuildContext context) {
    return widget.noMoreItemWidget?.call(context) ??
        const Center(child: Text('No more items'));
  }
}