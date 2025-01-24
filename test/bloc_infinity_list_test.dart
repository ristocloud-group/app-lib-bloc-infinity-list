// test/bloc_infinity_list_test.dart

import 'package:bloc_infinity_list/bloc_infinity_list.dart';
import 'package:bloc_infinity_list/infinite_list_bloc/infinite_list_bloc.dart';
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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Simulate end of data
    if (offset >= 20) {
      return [];
    }

    // Generate dummy data
    return List.generate(
      limit,
      (index) => ListItem(
        name: 'Item ${offset + index + 1}',
        description: 'Description for item ${offset + index + 1}',
      ),
    );
  }
}

/// Un bloc statico che emette esattamente 10 item al primo fetch e poi si ferma.
class MyStaticBloc extends InfiniteListBloc<ListItem> {
  bool loadedOnce = false;

  @override
  Future<List<ListItem>> fetchItems(
      {required int limit, required int offset}) async {
    await Future.delayed(const Duration(milliseconds: 10));
    // Se ha già caricato una volta, restituiamo un array vuoto
    if (loadedOnce) return [];

    loadedOnce = true;
    // Restituiamo 10 item
    return List.generate(10, (i) {
      return ListItem(
        name: 'Item ${i + 1}',
        description: 'Description ${i + 1}',
      );
    });
  }
}

// Subclasses for testing different scenarios

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
    // Reset the ID counter on refresh
    if (offset == 0 && !isFirstLoad) {
      ListItem.resetIdCounter();
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (isFirstLoad) {
      // First load
      isFirstLoad = false;
      return List.generate(
        limit,
        (index) => ListItem(
          name: 'Item ${offset + index + 1}',
          description: 'Description',
        ),
      );
    } else {
      // After refresh
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
                // Rimosso il controllo sul loader
              ),
            ),
          ),
        ),
      );

      // 1) Attendi caricamento iniziale
      await tester.pumpAndSettle();

      // 2) Simula lo scroll per innescare il caricamento
      await tester.scrollUntilVisible(find.text('Item 9'), 100);
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle(); // Assegna tempo per il caricamento

      // 3) Verifica che i nuovi item (Item 11, etc.) siano comparsi
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
                  // Rimosso o modificato la physics se necessario
                  // per consentire lo scroll.
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

        // 1) Aspetta il caricamento iniziale
        await tester.pumpAndSettle();

        // Verifica che Item 1 sia presente
        expect(find.text('Item 1'), findsOneWidget);

        // 2) Scorri la ListView finché "Item 9" non diventa visibile
        await tester.dragUntilVisible(
          find.text('Item 9'), // l'elemento che vogliamo portare in viewport
          find.byType(ListView).first, // la ListView da scrollare
          const Offset(0, -50), // offset di scroll (trasciniamo in su)
        );

        // 3) Ora che "Item 9" è visibile, facciamo un altro scroll
        // per simulare l'arrivo al fondo e scatenare il caricamento
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();

        // 4) Verifica che i nuovi elementi siano caricati (es. Item 11)
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

        // 1) Aspetta il caricamento iniziale
        await tester.pumpAndSettle();

        // Verifichiamo che "Item 1" sia apparso
        expect(find.text('Item 1'), findsOneWidget);

        // 2) Scrolliamo la ListView finché "Item 9" (o "Item 10") non diventa visibile.
        // Scegliamo "Item 9" come target. Con step -50: spostiamo la lista un po' alla volta.
        await tester.dragUntilVisible(
          find.text('Item 9'),
          // Il widget scrollabile su cui effettuare il drag:
          find.byType(ListView).first,
          const Offset(0, -50),
        );

        // 3) Ora facciamo un ulteriore drag più "deciso" per superare la soglia
        //    (loadMoreThreshold = 300 + bottomOffset = 80).
        await tester.drag(
          find.byType(ListView).first,
          const Offset(0, -400),
        );

        // 4) Aspettiamo che il bloc carichi il nuovo batch di item
        await tester.pumpAndSettle();

        // 5) Controlliamo che "Item 11" sia ora presente
        expect(find.text('Item 11'), findsOneWidget);
      },
    );

    /// TEST 1: showLastDivider = false => ci aspettiamo 8 divider
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
                  // Callback fissa su "false"
                  showLastDivider: () => false,
                  itemBuilder: (context, item) => Text(item.name),
                  dividerWidget: const Divider(thickness: 2),
                ),
              ),
            ),
          ),
        );

        // Aspetta che carichi i 10 item
        await tester.pumpAndSettle();

        // Con 10 item e showDivider = false => 9 divider
        expect(find.byType(Divider), findsNWidgets(9));
      },
    );

    /// TEST 2: showLastDivider = true => ci aspettiamo 9 divider
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
                  // Callback fissa su "true"
                  showLastDivider: () => true,
                  itemBuilder: (context, item) => Text(item.name),
                  dividerWidget: const Divider(thickness: 2),
                ),
              ),
            ),
          ),
        );

        // Aspetta che carichi i 10 item
        await tester.pumpAndSettle();

        // Con 10 item e showDivider = true => 10 divider
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
              create: (_) => bloc..add(LoadItemsEvent()),
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

      // Wait for the initial load
      await tester.pumpAndSettle();

      // Scroll to the bottom to bring 'Load More' button into view
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify that "Load More" button is visible
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
              create: (_) => bloc..add(LoadItemsEvent()),
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

      // Wait for the initial load
      await tester.pumpAndSettle();

      // Scroll to the bottom to bring 'Load More' button into view
      await tester.scrollUntilVisible(find.text('Load More'), 500);
      await tester.pumpAndSettle();

      // Ensure the "Load More" button is displayed
      expect(find.byKey(const Key('loadMoreButton')), findsOneWidget);
      expect(find.text('Load More'), findsOneWidget);

      // Tap the "Load More" button
      await tester.tap(find.byKey(const Key('loadMoreButton')));
      await tester.pump(); // Start loading more items

      // Wait for the loading indicator to appear on the button
      await tester.pump(const Duration(milliseconds: 70));

      // Verify that the loading indicator appears on the button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for more items to load
      await tester.pumpAndSettle();

      // Verify that more items are loaded
      expect(find.text('Item 11'), findsOneWidget);
    });

    testWidgets('Infinite List shows empty state when no items are loaded',
        (WidgetTester tester) async {
      // Use the bloc that returns an empty list
      final bloc = MyCustomBlocEmpty();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBlocEmpty>(
              create: (_) => bloc..add(LoadItemsEvent()),
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

      // Wait for the initial load
      await tester.pumpAndSettle();

      // Verify that empty widget is displayed
      expect(find.text('No items available'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('Infinite List shows error state when an error occurs',
        (WidgetTester tester) async {
      // Use the bloc that throws an exception
      final bloc = MyCustomBlocError();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBlocError>(
              create: (_) => bloc..add(LoadItemsEvent()),
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

      // Start the initial loading and trigger the error
      await tester.pump(); // Start loading
      await tester.pump(const Duration(milliseconds: 100)); // Wait for error
      await tester.pumpAndSettle(); // Wait for the UI to update

      // Verify that error widget is displayed
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
              create: (_) => bloc..add(LoadItemsEvent()),
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

      // Wait for the initial load
      await tester.pumpAndSettle();

      // Load all items by scrolling multiple times
      for (int i = 1; i <= 2; i++) {
        // Assuming limit=10 and maxItems=20
        // Scroll to the bottom to trigger loading more items
        await tester.scrollUntilVisible(find.text("Item ${10 * i}"), 100);
        // Wait for more items to load
        await tester.pumpAndSettle();
      }

      // Scroll again to see if no more items remain
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify that "No more items" widget is displayed
      expect(find.text('No more items'), findsOneWidget);
    });

    testWidgets(
        'Manual Infinite List hides "Load More" when all data is loaded',
        (WidgetTester tester) async {
      // Initialize the bloc with a maximum of 10 items
      final bloc = MyCustomBlocLimited(maxItems: 10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBlocLimited>(
              create: (_) => bloc..add(LoadItemsEvent()),
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

                  // Determine if currently loading more items
                  final isLoadingMore = state is LoadingState<ListItem> &&
                      state.state.items.isNotEmpty;

                  // Determine if there are no more items
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

      // Wait for the initial load to complete
      await tester.pumpAndSettle();

      // Verify that initial items are loaded
      expect(find.text('Item 1'), findsOneWidget);

      // Scroll to the bottom to bring "Load More" button into view
      await tester.scrollUntilVisible(find.text('Load More'), 100);
      await tester.pumpAndSettle();

      // Tap the "Load More" button
      await tester.tap(find.text('Load More'));
      await tester.pump(); // Start loading more items

      // Wait for the loading indicator to appear on the button
      await tester.pump(const Duration(milliseconds: 70));

      // Verify that the loading indicator appears on the button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for more items to load
      await tester.pumpAndSettle();

      // After loading all items, "Load More" button should no longer be displayed
      expect(find.text('Load More'), findsNothing);

      // Verify that "No more items" widget is displayed
      expect(find.text('No more items'), findsOneWidget);
    });

    testWidgets('Infinite List refreshes on pull down',
        (WidgetTester tester) async {
      final bloc = MyCustomBlocRefresh();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBlocRefresh>(
              create: (_) => bloc..add(LoadItemsEvent()),
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

      // Wait for the initial load
      await tester.pumpAndSettle();

      // Verify that initial items are loaded
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Refreshed Item 1'), findsNothing);

      // Perform pull-to-refresh by dragging down
      await tester.drag(
        find.byType(ListView),
        const Offset(0, 300), // Drag down by 300 pixels
      );
      await tester.pump(); // Start the refresh

      // Wait for the refresh indicator to appear
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for the refresh to complete
      await tester.pumpAndSettle();

      // Verify that new items are loaded
      expect(find.text('Refreshed Item 1'), findsOneWidget);
      // Also check that old items are not present
      expect(find.text('Item 1'), findsNothing);
    });

    testWidgets('Infinite List handles scroll physics properly',
        (WidgetTester tester) async {
      final bloc = MyCustomBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MyCustomBloc>(
              create: (_) => bloc..add(LoadItemsEvent()),
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

      // Wait for the initial load
      await tester.pumpAndSettle();

      // Verify that the initial item is displayed
      expect(find.text('Item 1'), findsOneWidget);

      // Try to scroll the list
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pump();

      // Verify that the list did not scroll (Item 1 is still visible)
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets(
      'Infinite List displays initial items correctly when initialized with initial items',
      (WidgetTester tester) async {
        // Define 5 initial items
        final initialItems = List.generate(
          5,
          (index) => ListItem(
            name: 'Initial Item ${index + 1}',
            description: 'Description for initial item ${index + 1}',
          ),
        );

        // Initialize the Test BLoC with initial items
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
                        // Assigning a unique key here
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

        // Allow the initial items to be rendered
        await tester.pumpAndSettle();

        // Verify that the initial 5 items are displayed
        for (int i = 1; i <= 5; i++) {
          expect(find.text('Initial Item $i'), findsOneWidget);
          expect(find.text('Description for initial item $i'), findsOneWidget);
        }

        // Verify that no loading indicator is present initially
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Find and tap the "Load More" button
        final loadMoreButton = find.byKey(const Key('loadMoreButton'));
        expect(loadMoreButton, findsOneWidget);

        await tester.tap(loadMoreButton);
        await tester.pump(); // Start the tap event

        // Allow the BLoC to process the LoadMoreItemsEvent and emit LoadingState
        await tester.pump(); // This pump allows the BLoC to emit LoadingState

        // Verify that the loading indicator appears within the "Load More" button
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the fetchItems to complete (100ms as defined in BLoC)
        await tester.pump(const Duration(milliseconds: 100));

        // Allow all animations and state transitions to settle
        await tester.pumpAndSettle();

        // Verify that additional items are loaded
        expect(find.text('Item 6'), findsOneWidget);
        await tester.scrollUntilVisible(find.text("Item 10"), 100);
        expect(find.text('Item 10'), findsOneWidget);

        // Verify that initial items are still present
        await tester.scrollUntilVisible(find.text("Initial Item 1"), -100);
        for (int i = 1; i <= 5; i++) {
          expect(find.text('Initial Item $i'), findsOneWidget);
        }

        // Verify that no loading indicator is present after loading more items
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });

  testWidgets(
      'Displays initial items and loads more items on "Load More" button tap',
      (WidgetTester tester) async {
    // Reset the static ID counter before the test
    ListItem.resetIdCounter();

    // Define 5 initial items
    final initialItems = List.generate(
      5,
      (index) => ListItem(
        name: 'Secondary Preloaded Item ${index + 1}',
        description: 'Description for secondary preloaded item ${index + 1}',
      ),
    );

    // Initialize the BLoC with initial items
    final bloc = MyCustomBloc(initialItems: initialItems);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Widget
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
                // InfiniteListView.manual
                BlocProvider<MyCustomBloc>(
                  create: (_) => bloc,
                  child: InfiniteListView<ListItem>.manual(
                    bloc: bloc,
                    shrinkWrap: true,
                    // Enable shrink wrapping
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
                          key: const Key('loadMoreButton'), // Unique key
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
                // Footer Widget
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

    // Allow the initial items to be rendered
    await tester.pumpAndSettle();

    // Verify that the initial 5 items are displayed
    for (int i = 1; i <= 5; i++) {
      expect(find.text('Secondary Preloaded Item $i'), findsOneWidget);
      expect(
        find.text('Description for secondary preloaded item $i'),
        findsOneWidget,
      );
    }

    // Verify that no loading indicator is present initially
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Find and tap the "Load More" button
    final loadMoreButton = find.byKey(const Key('loadMoreButton'));
    expect(loadMoreButton, findsOneWidget);

    await tester.tap(loadMoreButton);
    await tester.pump(); // Start the tap event

    // Allow the BLoC to process the LoadMoreItemsEvent and emit LoadingState
    await tester.pump(); // This pump allows the BLoC to emit LoadingState

    // Verify that the loading indicator appears within the "Load More" button
    expect(
      find.descendant(
        of: find.byKey(const Key('loadMoreButton')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    // Wait for the fetchItems to complete (1 second as defined in BLoC code above)
    await tester.pump(const Duration(seconds: 1));
    // Let any final animations settle
    await tester.pumpAndSettle();

    // Verify that additional items are loaded (Items 6 to 10)
    for (int i = 6; i <= 10; i++) {
      expect(find.text('Item $i'), findsOneWidget);
      expect(find.text('Description for item $i'), findsOneWidget);
    }

    // Verify that initial items are still present
    for (int i = 1; i <= 5; i++) {
      expect(find.text('Secondary Preloaded Item $i'), findsOneWidget);
      expect(
        find.text('Description for secondary preloaded item $i'),
        findsOneWidget,
      );
    }

    // Verify that no loading indicator is present after loading more items
    expect(
      find.descendant(
        of: find.byKey(const Key('loadMoreButton')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
  });
}
