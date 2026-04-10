import 'package:bloc_infinity_list/bloc_infinity_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A simple data class representing an item in the list.
class ListItem {
  static int _staticId = 0;

  final int id;
  final String name;
  final String description;

  ListItem({required this.name, required this.description}) : id = ++_staticId;

  /// Resets the static ID counter. Useful for testing.
  static void resetIdCounter() {
    _staticId = 0;
  }
}

/// A custom BLoC that extends [InfiniteListBloc] to fetch [ListItem]s.
class MyCustomBloc extends InfiniteListBloc<ListItem> {
  MyCustomBloc({super.initialItems});

  @override
  Future<List<ListItem>> fetchItems({
    required int limit,
    required int offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (offset >= 20) {
      return [];
    }

    return List.generate(
      limit,
      (index) => ListItem(
        name: 'Item ${offset + index + 1}',
        description: 'Description for item ${offset + index + 1}',
      ),
    );
  }
}

/// A static bloc that emits exactly 10 items on the first fetch and then stops.
class MyStaticBloc extends InfiniteListBloc<ListItem> {
  bool hasLoadedOnce = false;

  @override
  Future<List<ListItem>> fetchItems(
      {required int limit, required int offset}) async {
    await Future.delayed(const Duration(milliseconds: 10));

    if (hasLoadedOnce) return [];

    hasLoadedOnce = true;

    return List.generate(10, (i) {
      return ListItem(
        name: 'Item ${i + 1}',
        description: 'Description ${i + 1}',
      );
    });
  }
}

/// Bloc that returns an empty list to simulate no data.
class MyCustomBlocEmpty extends MyCustomBloc {
  @override
  Future<List<ListItem>> fetchItems({
    required int limit,
    required int offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }
}

/// Bloc that throws an exception to simulate an error.
class MyCustomBlocError extends MyCustomBloc {
  @override
  Future<List<ListItem>> fetchItems({
    required int limit,
    required int offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    throw Exception('Network error');
  }
}

/// Bloc that returns different data on each fetch to simulate refresh.
class MyCustomBlocRefresh extends MyCustomBloc {
  bool isFirstLoad = true;

  @override
  Future<List<ListItem>> fetchItems({
    required int limit,
    required int offset,
  }) async {
    if (offset == 0 && !isFirstLoad) {
      ListItem.resetIdCounter();
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (isFirstLoad) {
      isFirstLoad = false;
      return List.generate(
        limit,
        (index) => ListItem(
          name: 'Item ${offset + index + 1}',
          description: 'Description',
        ),
      );
    } else {
      return List.generate(
        limit,
        (index) => ListItem(
          name: 'Refreshed Item ${offset + index + 1}',
          description: 'Description',
        ),
      );
    }
  }
}

/// Bloc with a limited number of items to simulate "No more items".
class MyCustomBlocLimited extends MyCustomBloc {
  final int maxItems;

  MyCustomBlocLimited({required this.maxItems});

  @override
  Future<List<ListItem>> fetchItems({
    required int limit,
    required int offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (offset >= maxItems) return [];
    final remaining = maxItems - offset;
    final fetchLimit = remaining < limit ? remaining : limit;
    return List.generate(
      fetchLimit,
      (index) => ListItem(
        name: 'Item ${offset + index + 1}',
        description: 'Description for item ${offset + index + 1}',
      ),
    );
  }
}

/// Bloc that accepts initial items to simulate preloaded data.
class MyCustomBlocWithInitialItems extends MyCustomBloc {
  MyCustomBlocWithInitialItems({super.initialItems});
}

void main() {
  group('InfiniteListView Tests', () {
    testWidgets('Automatic Infinite List loads more items on scroll',
        (WidgetTester tester) async {
      final bloc = MyCustomBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBloc>(
              create: (_) => bloc,
              child: InfiniteListView<ListItem>.automatic(
                bloc: bloc,
                itemBuilder: (context, item) => ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.description),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Item 9'), 100);
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 11'), findsOneWidget);
    });

    testWidgets(
      'Automatic Infinite List with shrinkWrap = true works correctly',
      (WidgetTester tester) async {
        final bloc = MyCustomBloc();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<MyCustomBloc>(
                create: (_) => bloc,
                child: InfiniteListView<ListItem>.automatic(
                  bloc: bloc,
                  shrinkWrap: true,
                  itemBuilder: (context, item) {
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(item.description),
                    );
                  },
                  loadingWidget: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Item 1'), findsOneWidget);

        await tester.dragUntilVisible(
          find.text('Item 9'),
          find.byType(ListView).first,
          const Offset(0, -50),
        );

        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Item 11'), findsOneWidget);
      },
    );

    testWidgets(
      'Automatic Infinite List triggers LoadMore with custom loadMoreThreshold and bottomOffset',
      (WidgetTester tester) async {
        final bloc = MyCustomBloc();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<MyCustomBloc>(
                create: (_) => bloc,
                child: InfiniteListView<ListItem>.automatic(
                  bloc: bloc,
                  loadMoreThreshold: 300,
                  bottomOffset: 80,
                  itemBuilder: (context, item) {
                    return ListTile(
                      key: ValueKey(item.id),
                      title: Text(item.name),
                      subtitle: Text(item.description),
                    );
                  },
                  loadingWidget: (context) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Item 1'), findsOneWidget);

        await tester.dragUntilVisible(
          find.text('Item 9'),
          find.byType(ListView).first,
          const Offset(0, -50),
        );

        await tester.drag(
          find.byType(ListView).first,
          const Offset(0, -400),
        );

        await tester.pumpAndSettle();

        expect(find.text('Item 11'), findsOneWidget);
      },
    );

    testWidgets(
      'Automatic Infinite List with showLastDivider = false -> 9 divider',
      (WidgetTester tester) async {
        final bloc = MyStaticBloc();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<MyStaticBloc>(
                create: (_) => bloc,
                child: InfiniteListView<ListItem>.automatic(
                  bloc: bloc,
                  showLastDivider: () => false,
                  itemBuilder: (context, item) => Text(item.name),
                  dividerWidget: const Divider(thickness: 2),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Divider), findsNWidgets(9));
      },
    );

    testWidgets(
      'Automatic Infinite List with showLastDivider = true -> 10 divider',
      (WidgetTester tester) async {
        final bloc = MyStaticBloc();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<MyStaticBloc>(
                create: (_) => bloc,
                child: InfiniteListView<ListItem>.automatic(
                  bloc: bloc,
                  showLastDivider: () => true,
                  itemBuilder: (context, item) => Text(item.name),
                  dividerWidget: const Divider(thickness: 2),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Divider), findsNWidgets(9));
      },
    );

    testWidgets('Manual Infinite List shows "Load More" button',
        (WidgetTester tester) async {
      final bloc = MyCustomBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBloc>(
              create: (_) => bloc,
              child: InfiniteListView<ListItem>.manual(
                bloc: bloc,
                itemBuilder: (context, item) {
                  return ListTile(
                    key: ValueKey(item.id),
                    title: Text(item.name),
                    subtitle: Text(item.description),
                  );
                },
                loadMoreButtonBuilder: (context) {
                  final state = bloc.state;

                  final isLoadingMore = state is LoadingState<ListItem> &&
                      state.state.items.isNotEmpty;

                  final noMoreItems = state is NoMoreItemsState<ListItem>;

                  if (noMoreItems) {
                    return const SizedBox.shrink();
                  }

                  if (state.state.items.isNotEmpty) {
                    return ElevatedButton(
                      key: const Key('loadMoreButton'),
                      onPressed: isLoadingMore
                          ? null
                          : () {
                              bloc.add(LoadMoreItemsEvent());
                            },
                      child: isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Load More'),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
                loadingWidget: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loadMoreButton')), findsOneWidget);
      expect(find.text('Load More'), findsOneWidget);
    });

    testWidgets('Manual Infinite List "Load More" button loads more items',
        (WidgetTester tester) async {
      final bloc = MyCustomBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBloc>(
              create: (_) => bloc,
              child: InfiniteListView<ListItem>.manual(
                bloc: bloc,
                itemBuilder: (context, item) {
                  return ListTile(
                    key: ValueKey(item.id),
                    title: Text(item.name),
                    subtitle: Text(item.description),
                  );
                },
                loadMoreButtonBuilder: (context) {
                  final state = bloc.state;

                  final isLoadingMore = state is LoadingState<ListItem> &&
                      state.state.items.isNotEmpty;

                  final noMoreItems = state is NoMoreItemsState<ListItem>;

                  if (noMoreItems) {
                    return const SizedBox.shrink();
                  }

                  if (state.state.items.isNotEmpty) {
                    return ElevatedButton(
                      key: const Key('loadMoreButton'),
                      onPressed: isLoadingMore
                          ? null
                          : () {
                              bloc.add(LoadMoreItemsEvent());
                            },
                      child: isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Load More'),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
                loadingWidget: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Load More'), 500);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loadMoreButton')), findsOneWidget);
      expect(find.text('Load More'), findsOneWidget);

      await tester.tap(find.byKey(const Key('loadMoreButton')));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 70));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Item 11'), findsOneWidget);
    });

    testWidgets('Infinite List shows empty state when no items are loaded',
        (WidgetTester tester) async {
      final bloc = MyCustomBlocEmpty();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBlocEmpty>(
              create: (_) => bloc,
              child: InfiniteListView<ListItem>.automatic(
                bloc: bloc,
                itemBuilder: (context, item) {
                  return ListTile(
                    key: ValueKey(item.id),
                    title: Text(item.name),
                    subtitle: Text(item.description),
                  );
                },
                emptyWidget: (context) => const Center(
                  child: Text('No items available'),
                ),
                loadingWidget: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No items available'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('Infinite List shows error state when an error occurs',
        (WidgetTester tester) async {
      final bloc = MyCustomBlocError();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBlocError>(
              create: (_) => bloc,
              child: InfiniteListView<ListItem>.automatic(
                bloc: bloc,
                itemBuilder: (context, item) {
                  return ListTile(
                    key: ValueKey(item.id),
                    title: Text(item.name),
                    subtitle: Text(item.description),
                  );
                },
                errorWidget: (context, error) => Center(
                  child: Text('Error occurred: $error'),
                ),
                loadingWidget: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error occurred:'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('Infinite List shows "No more items" when all data is loaded',
        (WidgetTester tester) async {
      final bloc = MyCustomBlocLimited(maxItems: 20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBloc>(
              create: (_) => bloc,
              child: InfiniteListView<ListItem>.automatic(
                bloc: bloc,
                itemBuilder: (context, item) {
                  return ListTile(
                    key: ValueKey(item.id),
                    title: Text(item.name),
                    subtitle: Text(item.description),
                  );
                },
                noMoreItemWidget: (context) =>
                    const Center(child: Text('No more items')),
                loadingWidget: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (int i = 1; i <= 2; i++) {
        await tester.scrollUntilVisible(find.text("Item ${10 * i}"), 100);
        await tester.pumpAndSettle();
      }

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('No more items'), findsOneWidget);
    });

    testWidgets(
        'Manual Infinite List hides "Load More" when all data is loaded',
        (WidgetTester tester) async {
      final bloc = MyCustomBlocLimited(maxItems: 10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBlocLimited>(
              create: (_) => bloc,
              child: InfiniteListView<ListItem>.manual(
                bloc: bloc,
                itemBuilder: (context, item) {
                  return ListTile(
                    key: ValueKey(item.id),
                    title: Text(item.name),
                    subtitle: Text(item.description),
                  );
                },
                loadMoreButtonBuilder: (context) {
                  final state = bloc.state;

                  final isLoadingMore = state is LoadingState<ListItem> &&
                      state.state.items.isNotEmpty;

                  final noMoreItems = state is NoMoreItemsState<ListItem>;

                  if (noMoreItems) {
                    return const SizedBox.shrink();
                  }

                  if (state.state.items.isNotEmpty) {
                    return ElevatedButton(
                      onPressed: isLoadingMore
                          ? null
                          : () {
                              bloc.add(LoadMoreItemsEvent());
                            },
                      child: isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Load More'),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
                noMoreItemWidget: (context) =>
                    const Center(child: Text('No more items')),
                loadingWidget: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Load More'), 100);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Load More'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 70));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Load More'), findsNothing);

      expect(find.text('No more items'), findsOneWidget);
    });

    testWidgets('Infinite List refreshes on pull down',
        (WidgetTester tester) async {
      final bloc = MyCustomBlocRefresh();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBlocRefresh>(
              create: (_) => bloc,
              child: InfiniteListView<ListItem>.automatic(
                bloc: bloc,
                itemBuilder: (context, item) {
                  return ListTile(
                    key: ValueKey(item.id),
                    title: Text(item.name),
                    subtitle: Text(item.description),
                  );
                },
                loadingWidget: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Refreshed Item 1'), findsNothing);

      await tester.drag(
        find.byType(ListView),
        const Offset(0, 300),
      );
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpAndSettle();

      expect(find.text('Refreshed Item 1'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
    });

    testWidgets('Infinite List handles scroll physics properly',
        (WidgetTester tester) async {
      final bloc = MyCustomBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBloc>(
              create: (_) => bloc,
              child: InfiniteListView<ListItem>.automatic(
                bloc: bloc,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, item) {
                  return ListTile(
                    key: ValueKey(item.id),
                    title: Text(item.name),
                    subtitle: Text(item.description),
                  );
                },
                loadingWidget: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);

      await tester.drag(
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pump();

      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets(
      'Infinite List displays initial items correctly when initialized with initial items',
      (WidgetTester tester) async {
        final initialItems = List.generate(
          5,
          (index) => ListItem(
            name: 'Initial Item ${index + 1}',
            description: 'Description for initial item ${index + 1}',
          ),
        );

        final bloc = MyCustomBlocWithInitialItems(initialItems: initialItems);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<MyCustomBlocWithInitialItems>(
                create: (_) => bloc,
                child: InfiniteListView<ListItem>.manual(
                  bloc: bloc,
                  itemBuilder: (context, item) {
                    return ListTile(
                      key: ValueKey(item.id),
                      title: Text(item.name),
                      subtitle: Text(item.description),
                    );
                  },
                  loadMoreButtonBuilder: (context) {
                    final state = bloc.state;
                    final isLoading = state is LoadingState<ListItem>;

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        key: const Key('loadMoreButton'),
                        onPressed: isLoading
                            ? null
                            : () {
                                bloc.add(LoadMoreItemsEvent());
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text(
                                'Load More',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                      ),
                    );
                  },
                  loadingWidget: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, error) => Center(
                    child: Text('Error: $error'),
                  ),
                  emptyWidget: (context) => const Center(
                    child: Text('No items available'),
                  ),
                  noMoreItemWidget: (context) => const Center(
                    child: Text('No more items'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        for (int i = 1; i <= 5; i++) {
          expect(find.text('Initial Item $i'), findsOneWidget);
          expect(find.text('Description for initial item $i'), findsOneWidget);
        }

        expect(find.byType(CircularProgressIndicator), findsNothing);

        final loadMoreButton = find.byKey(const Key('loadMoreButton'));
        expect(loadMoreButton, findsOneWidget);

        await tester.tap(loadMoreButton);
        await tester.pump();

        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 100));

        await tester.pumpAndSettle();

        expect(find.text('Item 6'), findsOneWidget);
        await tester.scrollUntilVisible(find.text("Item 10"), 100);
        expect(find.text('Item 10'), findsOneWidget);

        await tester.scrollUntilVisible(find.text("Initial Item 1"), -100);
        for (int i = 1; i <= 5; i++) {
          expect(find.text('Initial Item $i'), findsOneWidget);
        }

        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });

  testWidgets(
      'Displays initial items and loads more items on "Load More" button tap',
      (WidgetTester tester) async {
    ListItem.resetIdCounter();

    final initialItems = List.generate(
      5,
      (index) => ListItem(
        name: 'Secondary Preloaded Item ${index + 1}',
        description: 'Description for secondary preloaded item ${index + 1}',
      ),
    );

    final bloc = MyCustomBloc(initialItems: initialItems);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Builder(
                    builder: (context) {
                      return Text(
                        'Manual Infinite List with Initial Items',
                        style: Theme.of(context).textTheme.titleLarge,
                      );
                    },
                  ),
                ),
                BlocProvider<MyCustomBloc>(
                  create: (_) => bloc,
                  child: InfiniteListView<ListItem>.manual(
                    bloc: bloc,
                    shrinkWrap: true,
                    itemBuilder: (context, item) {
                      return ListTile(
                        key: ValueKey(item.id),
                        title: Text(item.name),
                        subtitle: Text(item.description),
                      );
                    },
                    loadMoreButtonBuilder: (context) {
                      final state = bloc.state;
                      final isLoading = state is LoadingState<ListItem>;

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          key: const Key('loadMoreButton'),
                          onPressed: isLoading
                              ? null
                              : () {
                                  bloc.add(LoadMoreItemsEvent());
                                },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Text(
                                  'Load More',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                        ),
                      );
                    },
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    borderRadius: BorderRadius.circular(12.0),
                    borderColor: Colors.grey.shade300,
                    borderWidth: 1.0,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 6.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    physics: const NeverScrollableScrollPhysics(),
                    dividerWidget: const SizedBox(height: 0),
                    loadingWidget: (context) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade300, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Something went wrong!',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              bloc.add(LoadItemsEvent());
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    emptyWidget: (context) => Center(
                      child: Text(
                        'No items available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 18,
                        ),
                      ),
                    ),
                    noMoreItemWidget: (context) => Center(
                      child: Text(
                        'No more items',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Builder(
                    builder: (context) {
                      return Text(
                        'Footer Widget',
                        style: Theme.of(context).textTheme.titleLarge,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    for (int i = 1; i <= 5; i++) {
      expect(find.text('Secondary Preloaded Item $i'), findsOneWidget);
      expect(
        find.text('Description for secondary preloaded item $i'),
        findsOneWidget,
      );
    }

    expect(find.byType(CircularProgressIndicator), findsNothing);

    final loadMoreButton = find.byKey(const Key('loadMoreButton'));
    expect(loadMoreButton, findsOneWidget);

    await tester.tap(loadMoreButton);
    await tester.pump();

    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('loadMoreButton')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    for (int i = 6; i <= 10; i++) {
      expect(find.text('Item $i'), findsOneWidget);
      expect(find.text('Description for item $i'), findsOneWidget);
    }

    for (int i = 1; i <= 5; i++) {
      expect(find.text('Secondary Preloaded Item $i'), findsOneWidget);
      expect(
        find.text('Description for secondary preloaded item $i'),
        findsOneWidget,
      );
    }

    expect(
      find.descendant(
        of: find.byKey(const Key('loadMoreButton')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
  });
}
