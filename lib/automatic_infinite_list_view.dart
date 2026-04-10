part of 'bloc_infinity_list.dart';

/// A widget that implements an automatic infinite scrolling list with pull-to-refresh functionality.
class AutomaticInfiniteListView<T> extends InfiniteListView<T> {
  /// Padding for individual list items.
  final EdgeInsetsGeometry? itemPadding;

  /// Padding for the loading indicator.
  final EdgeInsetsGeometry? loadingPadding;

  /// Padding for the 'no more items' indicator.
  final EdgeInsetsGeometry? noMoreItemPadding;

  /// The distance from the bottom at which the widget should trigger a load.
  final double? loadMoreThreshold;

  /// Additional bottom offset to consider when computing the bottom scroll.
  final double? bottomOffset;

  /// Creates an [AutomaticInfiniteListView].
  const AutomaticInfiniteListView({
    super.key,
    super.physics,
    super.shrinkWrap,
    required super.bloc,
    required super.itemBuilder,
    super.margin,
    super.padding,
    super.backgroundColor,
    super.borderRadius,
    super.borderColor,
    super.borderWidth,
    super.boxShadow,
    super.loadingWidget,
    super.errorWidget,
    super.emptyWidget,
    super.noMoreItemWidget,
    super.dividerWidget,
    super.showLastDivider,
    super.refreshIndicatorColor,
    super.refreshIndicatorBackgroundColor,
    super.refreshIndicatorDisplacement,
    super.refreshIndicatorStrokeWidth,
    this.itemPadding,
    this.loadingPadding,
    this.noMoreItemPadding,
    this.loadMoreThreshold,
    this.bottomOffset,
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
    widget.bloc.add(LoadItemsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final currentState = widget.bloc.state;
      if (currentState is LoadedState<T>) {
        widget.bloc.add(LoadMoreItemsEvent());
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    final double threshold = widget.loadMoreThreshold ?? 200.0;
    final double offset = widget.bottomOffset ?? 50.0;
    final double bottomSafeArea =
        MediaQuery.of(context).viewPadding.bottom + offset;

    return (maxScroll - currentScroll) <= (threshold + bottomSafeArea);
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
                (st) => st is LoadedState<T> || st is ErrorState<T>,
              );
            },
            child: _buildContainerAndList(items, state),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContainerAndList(List<T> items, BaseInfiniteListState<T> state) {
    final listView = ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: widget.shrinkWrap == true,
      physics: widget.physics ??
          (widget.shrinkWrap == true
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics()),
      controller: widget.shrinkWrap == true ? null : _scrollController,
      itemCount: _calculateItemCount(items, state),
      separatorBuilder: (context, index) {
        if (index != items.length - 1 ||
            (widget.showLastDivider?.call() ?? true)) {
          return widget.dividerWidget ?? const SizedBox.shrink();
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        return _buildListItem(index, items, state);
      },
    );

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

    if (widget.shrinkWrap == true) {
      return SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: containerWithList,
      );
    } else {
      return containerWithList;
    }
  }

  int _calculateItemCount(List<T> items, BaseInfiniteListState<T> state) {
    if (state is LoadingState<T> || state is NoMoreItemsState<T>) {
      return items.length + 1;
    }
    return items.length;
  }

  Widget _buildListItem(
      int index, List<T> items, BaseInfiniteListState<T> state) {
    if (index < items.length) {
      return Padding(
        padding:
            widget.itemPadding ?? const EdgeInsets.symmetric(vertical: 4.0),
        child: widget.itemBuilder(context, items[index]),
      );
    } else if (index == items.length && state is NoMoreItemsState<T>) {
      return Center(
        child: Padding(
          padding: widget.noMoreItemPadding ?? const EdgeInsets.all(12.0),
          child: _noMoreItemWidget(context),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: widget.loadingPadding ?? const EdgeInsets.all(12.0),
          child: _loadingWidget(context),
        ),
      );
    }
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
