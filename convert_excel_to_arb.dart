import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';

void main(List<String> args) {
  // Validate command-line arguments
  if (args.length != 2) {
    print('❌ Usage: dart convert_excel_to_arb.dart <sourceDir> <targetDir>');
    exit(1);
  }

  final sourceDir = args[0];
  final targetDir = args[1];

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
  final excelFiles = sourceDirectory.listSync().whereType<File>().where((file) => file.path.split(Platform.pathSeparator).last.startsWith('app_') && file.path.endsWith('.xlsx')).toList();

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

void _processFile(File file, String targetDir) {
  final fileName = file.path.split(Platform.pathSeparator).last;

  // Extracts locale from 'app_en.xlsx' -> 'en'
  final locale = fileName.replaceAll('app_', '').replaceAll('.xlsx', '');

  print('\n📋 Processing: $fileName (Locale: $locale)');

  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  if (excel.tables.isEmpty) {
    print('⚠️ No worksheets found in ${file.path}');
    return;
  }

  // Get the first sheet (you might want to make this configurable)
  final sheet = excel.tables.values.first;

  int count = 0;
  final arbContent = <String, dynamic>{'@@locale': locale};

  // Assuming the following column structure (0-indexed):
  // Column 0: Key
  // Column 1: Value
  // Column 2: Description (optional)
  // Column 3: Placeholders (optional, format: "placeholderName:type, anotherName:type")

  // If your Excel file does NOT have a header, remove `.skip(1)`
  for (final row in sheet.rows.skip(1)) {
    if (row.length < 2) continue; // Needs at least Key and Value

    final key = row[0]?.value?.toString().trim() ?? '';
    final value = row[1]?.value?.toString().trim() ?? '';

    if (key.isEmpty) continue; // Skip if key is empty

    arbContent[key] = value;
    count++;

    // Handle description (Column 2)
    String? description;
    if (row.length > 2 && row[2]?.value != null) {
      description = row[2]!.value!.toString().trim();
    }

    // Handle placeholders (Column 3)
    Map<String, dynamic>? placeholders;
    if (row.length > 3 && row[3]?.value != null) {
      final placeholdersString = row[3]!.value!.toString().trim();
      if (placeholdersString.isNotEmpty) {
        placeholders = {};
        // Expected format: "fieldName:String, anotherName:int"
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

    // Add description and placeholders to the ARB entry if they exist
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

  final arbFile = File('$targetDir/app_$locale.arb');
  arbFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(arbContent)); // 2 spaces indent
  print('✅ Generated ${arbFile.path} ($count entries)');
}
