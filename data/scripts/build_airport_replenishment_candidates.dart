import 'dart:io';

void main() {
  final currentAirports = _readCsv('data/curated/airports_seed.csv');
  final referenceAirports = _readCsv('data/reference/ourairports_airports.csv');
  final countries = _readCsv('data/reference/ourairports_countries.csv');

  final currentIatas = currentAirports.skip(1).map((row) => row[0]).toSet();
  final countryNameByCode = <String, String>{
    for (final row in countries.skip(1))
      if (row.length >= 3) row[1]: row[2],
  };

  final candidates = <List<String>>[
    [
      'iata',
      'name',
      'city',
      'country',
      'latitude',
      'longitude',
      'source_type',
      'scheduled_service',
      'proposed_demand_index',
      'proposed_airport_tax',
      'review_note',
    ],
  ];
  final batch01 = <List<String>>[
    candidates.first,
  ];

  const batch01Countries = <String>{
    'AE',
    'AU',
    'BD',
    'BH',
    'BN',
    'BT',
    'CN',
    'HK',
    'ID',
    'IN',
    'JP',
    'KH',
    'KR',
    'LA',
    'LK',
    'MM',
    'MO',
    'MY',
    'NP',
    'NZ',
    'OM',
    'PH',
    'PK',
    'QA',
    'SA',
    'SG',
    'TH',
    'TW',
    'VN',
  };

  for (final row in referenceAirports.skip(1)) {
    if (row.length < 14) continue;

    final type = row[2];
    final name = row[3];
    final latitude = row[4];
    final longitude = row[5];
    final isoCountry = row[8];
    final municipality = row[10];
    final scheduledService = row[11];
    final iata = row[13];

    if (scheduledService != 'yes') continue;
    if (type != 'large_airport') continue;
    if (iata.isEmpty || iata == r'\N' || iata.length != 3) continue;
    if (currentIatas.contains(iata)) continue;
    if (latitude.isEmpty || longitude.isEmpty) continue;

    final candidate = [
      iata,
      name,
      municipality,
      countryNameByCode[isoCountry] ?? isoCountry,
      latitude,
      longitude,
      type,
      scheduledService,
      '82',
      '1050.00',
      'AUTO_PROPOSED_FROM_OURAIRPORTS_LARGE_SCHEDULED',
    ];

    candidates.add(candidate);

    if (batch01Countries.contains(isoCountry)) {
      batch01.add(candidate);
    }
  }

  candidates.sort((a, b) {
    if (a[0] == 'iata') return -1;
    if (b[0] == 'iata') return 1;
    final countryCompare = a[3].compareTo(b[3]);
    if (countryCompare != 0) return countryCompare;
    return a[2].compareTo(b[2]);
  });

  final output = File('data/curated/airports_replenishment_candidates.csv');
  output.writeAsStringSync(
    '${candidates.map(_toCsvLine).join('\n')}\n',
  );

  final batchOutput = File('data/curated/airports_replenishment_batch_01.csv');
  batchOutput.writeAsStringSync(
    '${batch01.map(_toCsvLine).join('\n')}\n',
  );

  stdout.writeln(
    'Wrote ${candidates.length - 1} airport replenishment candidates to ${output.path}.',
  );
  stdout.writeln(
    'Wrote ${batch01.length - 1} airport batch-01 candidates to ${batchOutput.path}.',
  );
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
  return values
      .map((value) => '"${value.replaceAll('"', '""')}"')
      .join(',');
}
