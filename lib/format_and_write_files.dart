import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import 'create_declaration_files.dart';

Future<void> formatAndWriteFiles(
  List<DeclarationFile> files, {
  required String path,
  bool recreateFolder = false,
}) async {
  final formatter = DartFormatter();

  if (recreateFolder) {
    final directory = Directory(path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  for (final languageFile in files) {
    final formatted = formatter.format(languageFile.code);
    final file = File(p.join(path, languageFile.name));
    await file.create(recursive: true);
    await file.writeAsString(formatted);
  }
}
