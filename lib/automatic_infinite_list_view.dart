part of 'bloc_infinity_list.dart';

/// A class for the automatic infinite list view implementation.
///
/// Automatically loads more items when the user scrolls to the bottom, with a customizable and dynamic container.
class AutomaticInfiniteListView<T> extends InfiniteListView<T> {
  final EdgeInsetsGeometry? itemPadding;
  final EdgeInsetsGeometry? loadingPadding;
  final EdgeInsetsGeometry? noMoreItemPadding;

  const AutomaticInfiniteListView({
    this.itemPadding,
    this.loadingPadding,
    this.noMoreItemPadding,
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
    widget.bloc.add(LoadItemsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Called whenever the scroll position changes to ensure the container moves in sync with the list.
  void _onScroll() {
    if (_isBottom) {
      final currentState = widget.bloc.state;
      if (currentState is LoadedState<T>) {
        widget.bloc.add(LoadMoreItemsEvent());
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) {
      return false;
    }

    const double threshold = 200.0;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    final double padding = MediaQuery.of(context).viewPadding.bottom + 50.0;

    if ((maxScroll - currentScroll) <= (threshold + padding)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final previousState = widget.bloc.state;
              widget.bloc.add(LoadItemsEvent());
              await widget.bloc.stream.firstWhere(
                  (state) => state is LoadedState<T> || state is ErrorState<T>);
              if (previousState is LoadedState<T>) {
                setState(() {});
              }
              if (previousState is LoadedState<T>) {
                setState(() {});
              }
            },
            child: BlocBuilder<InfiniteListBloc<T>, BaseInfiniteListState<T>>(
              buildWhen: (previous, current) {
                if (previous is LoadingState<T> && current is LoadedState<T>) {
                  return true;
                }
                if (previous is LoadedState<T> && current is LoadedState<T>) {
                  return previous.state.items.length !=
                      current.state.items.length;
                }
                if (previous is LoadingState<T> &&
                    current is NoMoreItemsState<T>) {
                  return true;
                }
                return previous.runtimeType != current.runtimeType;
              },
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

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
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
                        controller: _scrollController,
                        physics: widget.physics ??
                            const AlwaysScrollableScrollPhysics(),
                        shrinkWrap: widget.shrinkWrap,
                        itemCount: state is LoadingState<T>
                            ? items.length + 1
                            : state is NoMoreItemsState<T>
                                ? items.length + 1
                                : items.length,
                        separatorBuilder: (context, index) =>
                            widget.dividerWidget ?? const SizedBox.shrink(),
                        itemBuilder: (context, index) {
                          if (index < items.length) {
                            return Padding(
                              padding: widget.itemPadding ??
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: widget.itemBuilder(context, items[index]),
                            );
                          } else if (index == items.length &&
                              state is NoMoreItemsState<T>) {
                            return Center(
                              child: Padding(
                                padding: widget.noMoreItemPadding ??
                                    const EdgeInsets.all(12.0),
                                child: _noMoreItemWidget(context),
                              ),
                            );
                          } else {
                            return Center(
                              child: Padding(
                                padding: widget.loadingPadding ??
                                    const EdgeInsets.all(12.0),
                                child: _loadingWidget(context),
                              ),
                            );
                          }
                        }),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
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
