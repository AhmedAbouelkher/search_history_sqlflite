import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class HistoryQuery {
  final int? id;
  final String query;
  final DateTime createdAt;
  const HistoryQuery({
    this.id,
    required this.query,
    required this.createdAt,
  });
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll({'query': query});
    result.addAll({'created_at': createdAt.millisecondsSinceEpoch});
    return result;
  }

  factory HistoryQuery.fromMap(Map<String, dynamic> map) {
    return HistoryQuery(
      id: map['id'] ?? -1,
      query: map['query'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
  @override
  String toString() {
    return 'HistoryQuery(query: $query, createdAt: $createdAt)';
  }
}

class DayQueries {
  final DateTime date;
  final List<HistoryQuery> queries;
  const DayQueries({required this.date, required this.queries});
  @override
  String toString() => 'DayQueries(date: $date, queries: $queries)';
}

class HistoryDBProvider {
  Database? db;
  String? dbPath;

  Future<void> open() async {
    if (db != null) return;
    final path = await getDatabasesPath();
    dbPath = p.join(path, 'history_queries.db');
    db = await openDatabase(
      dbPath!,
      version: 1,
      onCreate: (Database db, int version) async {
        // set a unique index on query
        await db.execute('''CREATE TABLE history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          query TEXT NOT NULL UNIQUE,
          created_at INTEGER,
          UNIQUE(query)
        )''');
      },
    );
  }

  Future<void> close() async {
    await db?.close();
    db = null;
  }

  Future<void> insert(HistoryQuery historyQuery) async {
    assert(db != null, "DB is not opened, call open() first");
    await db!.insert(
      'history',
      historyQuery.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<HistoryQuery> queries) async {
    assert(db != null, "DB is not opened, call open() first");
    final batch = db!.batch();
    for (final query in queries) {
      batch.insert(
        'history',
        query.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    assert(db != null, "DB is not opened, call open() first");
    await db!.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // get all history queries grouped by date
  Future<List<DayQueries>> getAll() async {
    assert(db != null, "DB is not opened, call open() first");
    final List<Map<String, dynamic>> maps = await db!.query(
      'history',
      orderBy: 'created_at DESC',
    );
    final List<HistoryQuery> historyQueries =
        maps.map((map) => HistoryQuery.fromMap(map)).toList(growable: false);
    final List<DayQueries> result = [];
    for (final historyQuery in historyQueries) {
      final date = DateTime(
        historyQuery.createdAt.year,
        historyQuery.createdAt.month,
        historyQuery.createdAt.day,
      );
      final dayQueries = result.firstWhere(
        (element) => element.date == date,
        orElse: () {
          final dayQueries = DayQueries(date: date, queries: []);
          result.add(dayQueries);
          return dayQueries;
        },
      );
      dayQueries.queries.add(historyQuery);
    }
    return result;
  }

  Future<void> deleteAll() async {
    assert(db != null, "DB is not opened, call open() first");
    await db!.delete('history');
  }
}
