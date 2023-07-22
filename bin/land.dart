// arb-dir: lib/i18n
// output-class: StockStrings
// output-localization-file: stock_strings.dart
// template-arb-file: stocks_en.arb

import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:land/land.dart';
import 'package:path/path.dart' as path;

void main() async {
  final configuration = await _Configuration.fromFilePath('land.yaml');

  final languageInfo = await loadARBFolder(
    configuration.arbDir,
    configurationFile: configuration.templateArbFile,
  );

  final pubspec = await _Pubspec.fromDirectory();

  final files = createDeclarationFiles(
    fields: languageInfo.fields,
    locales: languageInfo.locales,
    className: configuration.outputClass,
    emitFlutterGlue: pubspec.isFlutterProject,
    emitSupportedLocales: true,
  );

  await formatAndWriteFiles(
    files,
    path: configuration.outputDirectory,
    recreateFolder: true,
  );
}

class _Pubspec {
  final dynamic _yaml;

  bool get isFlutterProject => _yaml['dependencies']?['flutter'] != null;

  _Pubspec(this._yaml);

  static Future<_Pubspec> fromDirectory([String directory = '.']) async {
    final file = File(path.join(directory, 'pubspec.yaml'));
    final yaml = loadYaml(await file.readAsString());
    return _Pubspec(yaml);
  }
}

class _Configuration {
  final String arbDir;
  final String outputClass;
  final String outputDirectory;
  final String templateArbFile;

  _Configuration({
    required this.arbDir,
    required this.outputClass,
    required this.outputDirectory,
    required this.templateArbFile,
  });

  static Future<_Configuration> fromFilePath(String filePath) async {
    final yaml = loadYaml(await File(filePath).readAsString());
    return _Configuration(
      arbDir: yaml['arb-dir'],
      outputClass: yaml['output-class'],
      outputDirectory: yaml['output-directory'],
      templateArbFile: yaml['template-arb-file'],
    );
  }
}
