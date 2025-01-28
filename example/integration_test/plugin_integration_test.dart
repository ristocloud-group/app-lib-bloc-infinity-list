import 'package:bloc_infinity_list/infinite_list_bloc/infinite_list_bloc.dart';
import 'package:bloc_infinity_list_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InfiniteListBloc loads and adds items',
      (WidgetTester tester) async {
    // Creazione del bloc
    final MyCustomBloc bloc = MyCustomBloc();

    // Costruzione dell'app di test
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<MyCustomBloc>(
          create: (_) => bloc,
          child: Scaffold(
            body: BlocBuilder<MyCustomBloc, BaseInfiniteListState<ListItem>>(
              builder: (context, state) {
                if (state is LoadingState<ListItem>) {
                  return const CircularProgressIndicator();
                }
                if (state is LoadedState<ListItem>) {
                  return ListView.builder(
                    itemCount: state.state.items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(state.state.items[index].name),
                      );
                    },
                  );
                }
                return const Text('No items');
              },
            ),
          ),
        ),
      ),
    );

    // Inizialmente, la lista dovrebbe essere vuota
    expect(find.text('No items'), findsOneWidget);

    // Emettere l'evento per caricare gli elementi iniziali
    bloc.add(LoadItemsEvent());

    // Attendere che il bloc emetta uno stato `LoadedState`
    await tester.runAsync(() async {
      await bloc.stream.firstWhere((state) => state is LoadedState<ListItem>);
    });

    // Forzare il rendering dell'interfaccia utente
    await tester.pumpAndSettle();

    // Verificare che la lista ora abbia elementi
    expect(find.byType(ListTile), findsWidgets);

    // Simulare il caricamento di altri elementi
    bloc.add(LoadMoreItemsEvent());

    // Aspettare nuovamente lo stato `LoadedState`
    await tester.runAsync(() async {
      await bloc.stream.firstWhere((state) => state is LoadedState<ListItem>);
    });

    // Forzare il rendering della UI
    await tester.pumpAndSettle();

    // Verificare che ci siano più elementi nella lista
    expect(find.byType(ListTile), findsWidgets);
  });
}
