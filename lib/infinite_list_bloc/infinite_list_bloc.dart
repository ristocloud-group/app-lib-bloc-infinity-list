import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'infinite_list_event.dart';
part 'infinite_list_state.dart';

/// Abstract class representing a BLoC for handling infinite lists.
abstract class InfiniteListBloc<T>
    extends Bloc<InfiniteListEvent, BaseInfiniteListState<T>> {
  /// Default limit for fetching items in a single request.
  late int defaultLimit = 10;

  /// A list of initial items to preload, if any.
  final List<T>? initialItems;

  /// Initializes the InfiniteListBloc with an initial state.
  InfiniteListBloc({
    this.initialItems,
    int? limitFetch,
  }) : super(
          initialItems != null && initialItems.isNotEmpty
              ? LoadedState<T>(
                  InfiniteListState<T>(
                    items: initialItems,
                  ),
                )
              : InitialState<T>(),
        ) {
    defaultLimit = limitFetch ?? 10;

    on<LoadItemsEvent>(
      _onLoadItems,
      transformer: restartable(),
    );

    on<LoadMoreItemsEvent>(
      _onLoadMoreItems,
      transformer: droppable(),
    );
  }

  /// Handler for [LoadItemsEvent].
  Future<void> _onLoadItems(
      LoadItemsEvent event, Emitter<BaseInfiniteListState<T>> emit) async {
    try {
      if (initialItems != null && initialItems!.isNotEmpty) {
        emit(LoadedState<T>(InfiniteListState<T>(items: initialItems!)));
      } else {
        emit(InitialState<T>());
        final List<T> items = await fetchItems(limit: defaultLimit, offset: 0);
        if (isClosed) return;
        emit(LoadedState<T>(InfiniteListState<T>(items: items)));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ErrorState<T>(
        state.state,
        error: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler for [LoadMoreItemsEvent].
  Future<void> _onLoadMoreItems(
      LoadMoreItemsEvent event, Emitter<BaseInfiniteListState<T>> emit) async {
    if (state is! LoadedState<T>) return;

    try {
      emit(LoadingState<T>(state.state));
      final int currentOffset = state.state.items.length;

      final List<T> items = await fetchItems(
        limit: event.limit ?? defaultLimit,
        offset: currentOffset,
      );

      if (isClosed) return;

      if (state is! LoadingState<T>) return;

      if (items.isEmpty) {
        emit(NoMoreItemsState<T>(state.state));
      } else {
        emit(LoadedState<T>(state.state.moreItems(newItems: items)));
      }
    } catch (e) {
      if (isClosed) return;
      if (state is! LoadingState<T>) return;

      emit(ErrorState<T>(
        state.state,
        error: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Abstract method to fetch items from an external source.
  Future<List<T>> fetchItems({required int limit, required int offset});
}
