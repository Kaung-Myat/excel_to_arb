// excel2arb/bin/excel2arb.dart
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:args/args.dart'; // Import the args package

void main(List<String> args) {
  // Create an ArgParser to define your command-line arguments
  final parser =
      ArgParser()
        ..addOption('source', abbr: 's', help: 'The source directory containing Excel translation files (e.g., app_en.xlsx).', valueHelp: 'path/to/source/dir')
        ..addOption('target', abbr: 't', help: 'The target directory where the generated ARB files will be saved.', valueHelp: 'path/to/target/dir')
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.');

  ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } on FormatException catch (e) {
    print('❌ Error parsing arguments: ${e.message}');
    print('\n${parser.usage}'); // Print usage on error
    exit(1);
  }

  // Handle --help flag
  if (argResults['help'] == true) {
    print('Usage: excel_to_arb [options]');
    print(parser.usage);
    exit(0);
  }

  // Get source and target directories from parsed arguments
  final sourceDir = argResults['source'] as String?;
  final targetDir = argResults['target'] as String?;

  // Validate that source and target directories are provided
  if (sourceDir == null || targetDir == null) {
    print('❌ Error: Both --source (-s) and --target (-t) directories are required.');
    print('\n${parser.usage}');
    exit(1);
  }

  print('Starting Excel to ARB conversion');
  print('Source directory: $sourceDir');
  print('Target directory: $targetDir');

  // Validate source directory
  final sourceDirectory = Directory(sourceDir);
  if (!sourceDirectory.existsSync()) {
    print('❌ Source directory "$sourceDir" does not exist');
    exit(1);
  }

  // Create target directory if needed
  Directory(targetDir).createSync(recursive: true);

  // Process files
  final excelFiles = sourceDirectory.listSync().whereType<File>().where((file) => p.basename(file.path).startsWith('app_') && file.path.endsWith('.xlsx')).toList();

  print('💼 Found ${excelFiles.length} Excel translation files');

  if (excelFiles.isEmpty) {
    print('❌ No Excel files found (pattern: app_*.xlsx)');
    return;
  }

  for (final file in excelFiles) {
    try {
      _processFile(file, targetDir);
    } catch (e) {
      print('❌ Error processing ${file.path}: $e');
    }
  }
}

// _processFile function remains the same as your provided code
void _processFile(File file, String targetDir) {
  final fileName = p.basename(file.path);

  final locale = fileName.replaceAll('app_', '').replaceAll('.xlsx', '');

  print('\n📋 Processing: $fileName (Locale: $locale)');

  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  if (excel.tables.isEmpty) {
    print('⚠️ No worksheets found in ${file.path}');
    return;
  }

  final sheet = excel.tables.values.first;

  int count = 0;
  final arbContent = <String, dynamic>{'@@locale': locale};

  for (final row in sheet.rows.skip(1)) {
    if (row.length < 2) continue;

    final key = row[0]?.value?.toString().trim() ?? '';
    final value = row[1]?.value?.toString().trim() ?? '';

    if (key.isEmpty) continue;

    arbContent[key] = value;
    count++;

    String? description;
    if (row.length > 2 && row[2]?.value != null) {
      description = row[2]!.value!.toString().trim();
    }

    Map<String, dynamic>? placeholders;
    if (row.length > 3 && row[3]?.value != null) {
      final placeholdersString = row[3]!.value!.toString().trim();
      if (placeholdersString.isNotEmpty) {
        placeholders = {};
        final entries = placeholdersString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (var entry in entries) {
          final parts = entry.split(':').map((p) => p.trim()).toList();
          if (parts.length == 2) {
            placeholders[parts[0]] = {'type': parts[1]};
          } else {
            print('⚠️ Warning: Malformed placeholder entry "$entry" for key "$key". Expected "name:type".');
          }
        }
      }
    }

    if (description != null || placeholders != null) {
      final meta = <String, dynamic>{};
      if (description != null && description.isNotEmpty) {
        meta['description'] = description;
      }
      if (placeholders != null && placeholders.isNotEmpty) {
        meta['placeholders'] = placeholders;
      }
      if (meta.isNotEmpty) {
        arbContent['@$key'] = meta;
      }
    }
  }

  final arbFile = File(p.join(targetDir, 'app_$locale.arb'));
  arbFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(arbContent));
  print('✅ Generated ${arbFile.path} ($count entries)');
}
