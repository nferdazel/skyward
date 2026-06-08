import 'dart:io';
import 'dart:math' as math;

void main() {
  final existing = _readCsv('data/curated/airports_seed.csv');
  final batch = _readCsv('data/curated/airports_replenishment_batch_01.csv');

  final statsByCountry = <String, _CountryStats>{};
  for (final row in existing.skip(1)) {
    if (row.length < 8) continue;
    final country = row[3];
    final demand = int.tryParse(row[6]) ?? 0;
    final tax = double.tryParse(row[7]) ?? 0;
    statsByCountry.putIfAbsent(country, _CountryStats.new).add(demand, tax);
  }

  const fallback = <String, (int demand, double tax)>{
    'Bangladesh': (68, 850.0),
    'Bhutan': (45, 650.0),
    'Cambodia': (55, 750.0),
    'Nepal': (52, 700.0),
    'Oman': (68, 850.0),
    'Pakistan': (62, 800.0),
    'Saudi Arabia': (76, 950.0),
    'United Arab Emirates': (88, 1200.0),
  };

  final reviewed = <List<String>>[
    [
      'iata',
      'name',
      'city',
      'country',
      'latitude',
      'longitude',
      'source_type',
      'scheduled_service',
      'reviewed_demand_index',
      'reviewed_airport_tax',
      'review_note',
    ],
  ];

  for (final row in batch.skip(1)) {
    final country = row[3];
    final stats = statsByCountry[country];
    int demand;
    double tax;
    String note;

    if (stats != null) {
      demand = _clampInt(((stats.maxDemand + stats.averageDemand) / 2).round(), 45, 96);
      tax = _roundTo50((stats.maxTax + stats.averageTax) / 2);
      note = 'REVIEWED_COUNTRY_BLEND';
    } else if (fallback.containsKey(country)) {
      final values = fallback[country]!;
      demand = values.$1;
      tax = values.$2;
      note = 'REVIEWED_COUNTRY_FALLBACK';
    } else {
      demand = 72;
      tax = 900.0;
      note = 'REVIEWED_GENERIC_FALLBACK';
    }

    reviewed.add([
      row[0],
      row[1],
      row[2],
      country,
      row[4],
      row[5],
      row[6],
      row[7],
      '$demand',
      tax.toStringAsFixed(2),
      note,
    ]);
  }

  final out = File('data/curated/airports_replenishment_batch_01_reviewed.csv');
  out.writeAsStringSync('${reviewed.map(_toCsvLine).join('\n')}\n');
  stdout.writeln('Wrote ${reviewed.length - 1} reviewed airport rows to ${out.path}.');
}

class _CountryStats {
  final List<int> _demands = [];
  final List<double> _taxes = [];

  void add(int demand, double tax) {
    _demands.add(demand);
    _taxes.add(tax);
  }

  int get maxDemand => _demands.reduce(math.max);
  int get averageDemand => (_demands.reduce((a, b) => a + b) / _demands.length).round();
  double get maxTax => _taxes.reduce(math.max);
  double get averageTax => _taxes.reduce((a, b) => a + b) / _taxes.length;
}

List<List<String>> _readCsv(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing file: $path');
    exitCode = 1;
    throw Exception('Missing file: $path');
  }

  return file
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .map(_parseCsvLine)
      .toList();
}

List<String> _parseCsvLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char == ',' && !inQuotes) {
      cells.add(buffer.toString());
      buffer.clear();
      continue;
    }

    buffer.write(char);
  }

  cells.add(buffer.toString());
  return cells;
}

String _toCsvLine(List<String> values) {
  return values.map((value) => '"${value.replaceAll('"', '""')}"').join(',');
}

int _clampInt(int value, int min, int max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

double _roundTo50(double value) {
  return (value / 50).round() * 50.0;
}
