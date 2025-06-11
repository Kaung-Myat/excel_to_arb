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
  final locale = fileName.replaceAll('app_', '').replaceAll('.xlsx', '');

  print('\n📋 Processing: $fileName (Locale: $locale)');

  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  if (excel.tables.isEmpty) {
    print('⚠️ No worksheets found');
    return;
  }

  final sheet = excel.tables.values.first;
  final arbContent = <String, dynamic>{'@@locale': locale};
  int count = 0;

  for (final row in sheet.rows) {
    if (row.length < 2) continue;
    final key = row[0]?.value?.toString().trim() ?? '';
    final value = row[1]?.value?.toString().trim() ?? '';
    if (key.isEmpty) continue;

    arbContent[key] = value;
    count++;
  }

  final arbFile = File('$targetDir/app_$locale.arb');
  arbFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(arbContent));
  print('✅ Generated ${arbFile.path} ($count entries)');
}
