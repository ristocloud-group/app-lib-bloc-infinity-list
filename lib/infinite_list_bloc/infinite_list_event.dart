part of 'infinite_list_bloc.dart';

/// Abstract base class for events in the InfiniteListBloc.
abstract class InfiniteListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event triggered to load initial items in the list.
class LoadItemsEvent extends InfiniteListEvent {}

/// Event triggered to load more items in the list.
class LoadMoreItemsEvent extends InfiniteListEvent {
  final int? limit;
  final int? offset;

  LoadMoreItemsEvent({this.limit, this.offset});

  @override
  List<Object?> get props => [limit, offset];
}
