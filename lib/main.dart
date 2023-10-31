import 'package:faker/faker.dart';
import 'package:flutter/material.dart';

import 'db.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Main(),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  final faker = Faker();
  final historyDBProvider = HistoryDBProvider();
  Future<List<DayQueries>>? _historyQueries;

  @override
  void initState() {
    historyDBProvider.open().then((_) => refresh());
    super.initState();
  }

  @override
  void dispose() {
    historyDBProvider.close();
    super.dispose();
  }

  Future<void> refresh() async {
    _historyQueries = historyDBProvider.getAll();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              historyDBProvider.deleteAll();
              refresh();
            },
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // historyDBProvider.insert(HistoryQuery(
          //   query: faker.lorem.words(3).join(' '),
          //   // query: "qqqqqqqqqq",
          //   // createdAt: DateTime.now(),
          //   createdAt: faker.date.dateTimeBetween(
          //     DateTime.now().subtract(const Duration(days: 7)),
          //     DateTime.now(),
          //   ),
          // ));
          final queries = <HistoryQuery>[];
          for (var i = 0; i < 100; i++) {
            queries.add(HistoryQuery(
              query: faker.lorem.words(3).join(' '),
              createdAt: faker.date.dateTimeBetween(
                DateTime.now().subtract(const Duration(days: 7)),
                DateTime.now(),
              ),
            ));
          }
          historyDBProvider.insertMany(queries);
          refresh();
        },
      ),
      body: SafeArea(
        child: FutureBuilder<List<DayQueries>>(
          future: _historyQueries,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final dayQueries = snapshot.data ?? [];
            if (dayQueries.isEmpty) {
              return const Center(
                child: Text('No data'),
              );
            }

            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                itemCount: dayQueries.length,
                itemBuilder: (context, index) {
                  final day = dayQueries[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          day.date.toString(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: day.queries.length,
                        itemBuilder: (context, index) {
                          final query = day.queries[index];
                          return ListTile(
                            title: Text(query.query),
                            subtitle: Text(query.createdAt.toString()),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                historyDBProvider.delete(query.id!);
                                refresh();
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
