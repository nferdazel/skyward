import 'dart:io';

const _airportsHeaders = <String>[
  'iata',
  'name',
  'city',
  'country',
  'latitude',
  'longitude',
  'demand_index',
  'airport_tax',
];

const _aircraftHeaders = <String>[
  'manufacturer',
  'model_name',
  'type',
  'range_km',
  'capacity',
  'speed_kmh',
  'fuel_burn_per_km',
  'maintenance_cost_per_hour',
  'purchase_price',
  'lease_price_per_month',
];

void main() {
  final errors = <String>[];

  errors.addAll(
    _validateCsv(
      path: 'data/curated/airports_seed.csv',
      expectedHeaders: _airportsHeaders,
      naturalKey: (row) => row['iata']?.trim().toUpperCase() ?? '',
      label: 'airports',
    ),
  );

  errors.addAll(
    _validateCsv(
      path: 'data/curated/aircraft_models_seed.csv',
      expectedHeaders: _aircraftHeaders,
      naturalKey: (row) =>
          '${row['manufacturer']?.trim().toUpperCase() ?? ''}::${row['model_name']?.trim().toUpperCase() ?? ''}',
      label: 'aircraft_models',
    ),
  );

  if (errors.isNotEmpty) {
    stderr.writeln('Catalog validation failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Catalog validation passed.');
}

List<String> _validateCsv({
  required String path,
  required List<String> expectedHeaders,
  required String Function(Map<String, String> row) naturalKey,
  required String label,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    return ['$label file not found: $path'];
  }

  final lines = file
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .toList();

  if (lines.isEmpty) {
    return ['$label file is empty: $path'];
  }

  final headers = _parseCsvLine(lines.first);
  if (headers.length != expectedHeaders.length) {
    return [
      '$label header length mismatch. Expected ${expectedHeaders.length}, got ${headers.length}.'
    ];
  }

  for (var i = 0; i < headers.length; i++) {
    if (headers[i] != expectedHeaders[i]) {
      return [
        '$label header mismatch at column ${i + 1}. Expected "${expectedHeaders[i]}", got "${headers[i]}".'
      ];
    }
  }

  final seenKeys = <String>{};
  final errors = <String>[];

  for (var i = 1; i < lines.length; i++) {
    final values = _parseCsvLine(lines[i]);
    if (values.length != headers.length) {
      errors.add(
        '$label row ${i + 1} column mismatch. Expected ${headers.length}, got ${values.length}.',
      );
      continue;
    }

    final row = <String, String>{};
    for (var c = 0; c < headers.length; c++) {
      row[headers[c]] = values[c];
    }

    final key = naturalKey(row);
    if (key.isEmpty) {
      errors.add('$label row ${i + 1} has empty natural key.');
      continue;
    }

    if (!seenKeys.add(key)) {
      errors.add('$label row ${i + 1} duplicates natural key "$key".');
    }

    if (label == 'airports') {
      final iata = row['iata']?.trim() ?? '';
      if (iata.length != 3) {
        errors.add('$label row ${i + 1} has invalid IATA "$iata".');
      }
    }
  }

  return errors;
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
