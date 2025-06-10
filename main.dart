import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  const sourceDir = 'resources/l10n'; // Directory containing Excel files
  const targetDir = 'config/l10n'; // Output directory for ARB files

  print('Starting Excel to ARB conversion');
  final sourcePath = Directory(sourceDir).absolute.path;
  print('Searching for Excel files in: $sourcePath');

  // Create directories if needed
  Directory(sourceDir).createSync(recursive: true);
  Directory(targetDir).createSync(recursive: true);

  // Get all files in directory
  final files = Directory(sourceDir).listSync();
  print('📄 Found ${files.length} files in directory');

  // Filter Excel files
  final excelFiles =
      files.whereType<File>().where((file) {
        final name = file.path.split(Platform.pathSeparator).last;
        return name.endsWith('.xlsx') && name.startsWith('app_');
      }).toList();

  print('💼 Found ${excelFiles.length} Excel translation files');

  if (excelFiles.isEmpty) {
    print('❌ No matching Excel files found (pattern: app_*.xlsx)');
    print('   Please ensure files exist in: $sourcePath');
    return;
  }

  // Process files
  for (final file in excelFiles) {
    try {
      _processFile(file, targetDir);
    } catch (e) {
      print('\n❌ Error processing ${file.path}: $e');
    }
  }
}

void _processFile(File file, String targetDir) {
  final fileName = file.path.split(Platform.pathSeparator).last;
  final locale = fileName.replaceAll('app_', '').replaceAll('.xlsx', '');

  print('\n📋 Processing: $fileName');
  print('   Locale: $locale');

  try {
    // Read and decode Excel
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      print('⚠️ No worksheets found in Excel file');
      return;
    }

    final sheet = excel.tables.values.first;

    // Prepare ARB content
    final arbContent = <String, dynamic>{'@@locale': locale};
    int count = 0;

    // Process each row
    for (final row in sheet.rows) {
      if (row.length < 2) continue;

      final keyCell = row[0];
      final valueCell = row[1];

      if (keyCell == null || valueCell == null) continue;

      final key = keyCell.value?.toString() ?? '';
      final value = valueCell.value?.toString() ?? '';

      if (key.isEmpty) continue;

      arbContent[key] = value;
      // arbContent['@$key'] = <String, dynamic>{};
      count++;
    }

    // Write ARB file
    final arbFile = File('$targetDir/app_$locale.arb');
    arbFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(arbContent));

    print('✅ Generated: ${arbFile.path}');
    print('   Entries: $count');
  } catch (e) {
    print('❌ Error: ${e.toString()}');
  }
}
