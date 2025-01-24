import 'dart:async';

import 'package:bloc_infinity_list/bloc_infinity_list.dart';
import 'package:bloc_infinity_list/infinite_list_bloc/infinite_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  /// Constructor accepts an optional list of initial items.
  MyCustomBloc({super.initialItems, super.limitFetch});

  @override
  Future<List<ListItem>> fetchItems({
    required int limit,
    required int offset,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate end of data
    if (offset >= 50) {
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

void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite ListView Example',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16.0),
          titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
      ),
      home: const HomePage(),
    );
  }
}

/// The home page that contains navigation to the four examples.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State class for [HomePage].
class _HomePageState extends State<HomePage> {
  // Set Automatic (shrinkWrap = true) as default index = 0
  int _selectedIndex = 0;

  // We now have 4 pages:
  final List<Widget> _pages = [
    // Automatic with shrinkWrap = true
    const AutomaticInfiniteListPage(),
    // Automatic with shrinkWrap = false (NEW PAGE)
    const AutomaticInfiniteListPageNoShrinkWrap(),
    // Manual infinite list
    const ManualInfiniteListPage(),
    // Manual infinite list with initial items
    const ManualInfiniteListPageWithInitialItems(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite ListView Example'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.autorenew),
            label: 'Auto ShrinkWrap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vertical_align_bottom),
            label: 'Auto Full',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app),
            label: 'Manual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Default Manual',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

/// A page demonstrating the automatic infinite list with shrinkWrap enabled.
class AutomaticInfiniteListPage extends StatefulWidget {
  const AutomaticInfiniteListPage({super.key});

  @override
  State<AutomaticInfiniteListPage> createState() =>
      _AutomaticInfiniteListPageState();
}

class _AutomaticInfiniteListPageState extends State<AutomaticInfiniteListPage> {
  late final MyCustomBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = MyCustomBloc();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MyCustomBloc>(
      create: (_) => _bloc,
      child: InfiniteListView<ListItem>.automatic(
        bloc: _bloc,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
        itemBuilder: _buildListItem,
        dividerWidget: const SizedBox(height: 0),
        loadingWidget: _buildLoadingWidget,
        errorWidget: _buildErrorWidget,
        emptyWidget: _buildEmptyWidget,
        noMoreItemWidget: _buildNoMoreItemWidget,
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ListItem item) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            item.id.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(
          item.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on ${item.name}')),
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );

  Widget _buildErrorWidget(BuildContext context, String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
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
                _bloc.add(LoadItemsEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyWidget(BuildContext context) => Center(
        child: Text(
          'No items available',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 18,
          ),
        ),
      );

  Widget _buildNoMoreItemWidget(BuildContext context) => Center(
        child: Text(
          'You have reached the end!',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
}

class AutomaticInfiniteListPageNoShrinkWrap extends StatefulWidget {
  const AutomaticInfiniteListPageNoShrinkWrap({super.key});

  @override
  State<AutomaticInfiniteListPageNoShrinkWrap> createState() =>
      _AutomaticInfiniteListPageNoShrinkWrapState();
}

class _AutomaticInfiniteListPageNoShrinkWrapState
    extends State<AutomaticInfiniteListPageNoShrinkWrap> {
  late final MyCustomBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = MyCustomBloc();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MyCustomBloc>(
      create: (_) => _bloc,
      child: InfiniteListView<ListItem>.automatic(
        bloc: _bloc,
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(),
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
        itemBuilder: _buildListItem,
        dividerWidget: const Divider(thickness: 2),
        showLastDivider: () => true,
        loadingWidget: _buildLoadingWidget,
        errorWidget: _buildErrorWidget,
        emptyWidget: _buildEmptyWidget,
        noMoreItemWidget: _buildNoMoreItemWidget,
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ListItem item) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            item.id.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(
          item.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on ${item.name}')),
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );

  Widget _buildErrorWidget(BuildContext context, String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
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
                _bloc.add(LoadItemsEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyWidget(BuildContext context) => Center(
        child: Text(
          'No items available',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 18,
          ),
        ),
      );

  Widget _buildNoMoreItemWidget(BuildContext context) => Center(
        child: Text(
          'You have reached the end!',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
}

/// A page demonstrating the manual infinite list with a "Load More" button.
class ManualInfiniteListPage extends StatefulWidget {
  const ManualInfiniteListPage({super.key});

  @override
  State<ManualInfiniteListPage> createState() => _ManualInfiniteListPageState();
}

class _ManualInfiniteListPageState extends State<ManualInfiniteListPage> {
  late final MyCustomBloc _bloc;

  @override
  void initState() {
    super.initState();
    // Initialize the bloc without initial items
    _bloc = MyCustomBloc();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MyCustomBloc>(
      create: (_) => _bloc,
      child: InfiniteListView<ListItem>.manual(
        bloc: _bloc,
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
        physics: const BouncingScrollPhysics(),
        itemBuilder: _buildListItem,
        loadMoreButtonBuilder: _buildLoadMoreButton,
        dividerWidget: const Divider(
          height: 2,
          thickness: 1,
          indent: 20,
        ),
        showLastDivider: () => _bloc.state is! NoMoreItemsState,
        loadingWidget: _buildLoadingWidget,
        errorWidget: _buildErrorWidget,
        emptyWidget: _buildEmptyWidget,
        noMoreItemWidget: _buildNoMoreItemWidget,
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ListItem item) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            item.id.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(
          item.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Handle item tap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on ${item.name}')),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton(BuildContext context) {
    final state = _bloc.state;
    final isLoading = state is LoadingState<ListItem>;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        key: const Key('loadMoreButton'), // Assigning a unique key here
        onPressed: isLoading
            ? null
            : () {
                _bloc.add(LoadMoreItemsEvent());
              },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Theme.of(context).primaryColor,
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

  Widget _buildLoadingWidget(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );

  Widget _buildErrorWidget(BuildContext context, String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
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
                _bloc.add(LoadItemsEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyWidget(BuildContext context) => Center(
        child: Text(
          'No items available',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 18,
          ),
        ),
      );

  Widget _buildNoMoreItemWidget(BuildContext context) => Center(
        child: Text(
          'You have reached the end!',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
}

/// A second manual infinite list page demonstrating another manual list with initial items.
/// **This page is updated to dynamically grow in height and can be embedded within another scrollable widget.**
class ManualInfiniteListPageWithInitialItems extends StatefulWidget {
  const ManualInfiniteListPageWithInitialItems({super.key});

  @override
  State<ManualInfiniteListPageWithInitialItems> createState() =>
      _ManualInfiniteListPageWithInitialItemsState();
}

class _ManualInfiniteListPageWithInitialItemsState
    extends State<ManualInfiniteListPageWithInitialItems> {
  late final MyCustomBloc _bloc;

  @override
  void initState() {
    super.initState();
    // Define 5 initial items
    final initialItems = List.generate(
      5,
      (index) => ListItem(
        name: 'Secondary Preloaded Item ${index + 1}',
        description: 'Description for secondary preloaded item ${index + 1}',
      ),
    );
    // Initialize the bloc with initial items
    _bloc = MyCustomBloc(initialItems: initialItems, limitFetch: 5);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // **Embedding within SingleChildScrollView and Column for dynamic height**
    return SingleChildScrollView(
      child: Column(
        children: [
          // Other widgets above the InfiniteListView
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Manual Infinite List with Initial Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // The updated InfiniteListView.manual with shrinkWrap enabled
          BlocProvider<MyCustomBloc>(
            create: (_) => _bloc,
            child: InfiniteListView<ListItem>.manual(
              bloc: _bloc,
              shrinkWrap: true,
              // Enable shrink wrapping
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
              itemBuilder: _buildListItem,
              loadMoreButtonBuilder: _buildLoadMoreButton,
              dividerWidget: const SizedBox(height: 0),
              loadingWidget: _buildLoadingWidget,
              errorWidget: _buildErrorWidget,
              emptyWidget: _buildEmptyWidget,
              noMoreItemWidget: _buildNoMoreItemWidget,
            ),
          ),
          // Other widgets below the InfiniteListView
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Footer Widget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ListItem item) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(
            item.id.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(
          item.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Handle item tap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on ${item.name}')),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton(BuildContext context) {
    final state = _bloc.state;
    final isLoading = state is LoadingState<ListItem>;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        key: const Key('loadMoreButton'), // Assigning a unique key here
        onPressed: isLoading
            ? null
            : () {
                _bloc.add(LoadMoreItemsEvent());
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

  Widget _buildLoadingWidget(BuildContext context) => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );

  Widget _buildErrorWidget(BuildContext context, String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
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
                _bloc.add(LoadItemsEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyWidget(BuildContext context) => Center(
        child: Text(
          'No items available',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 18,
          ),
        ),
      );

  Widget _buildNoMoreItemWidget(BuildContext context) => Center(
        child: Text(
          'No more items',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
}
