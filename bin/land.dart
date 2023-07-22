// arb-dir: lib/i18n
// output-class: StockStrings
// output-localization-file: stock_strings.dart
// template-arb-file: stocks_en.arb

import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:land/land.dart';
import 'package:path/path.dart' as path;

void main() async {
  final configurationFile = File('land.yaml');
  final _Configuration configuration;
  try {
    configuration = await _Configuration.fromFile(configurationFile);
  } on Exception {
    print('Unable to find ${path.basename(configurationFile.path)} file.');
    exit(1);
  }

  final _Pubspec pubspec;
  try {
    pubspec = await _Pubspec.fromDirectory('.');
  } on Exception {
    print('Unable to find ${_Pubspec.fileName} file.');
    exit(1);
  }

  final languageInfo = await loadARBFolder(
    configuration.arbDir,
    configurationFile: configuration.templateArbFile,
  );

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
  static final fileName = 'pubspec.yaml';

  final dynamic _yaml;

  bool get isFlutterProject => _yaml['dependencies']?['flutter'] != null;

  _Pubspec(this._yaml);

  static Future<_Pubspec> fromDirectory(String directory) async {
    final file = File(path.join(directory, fileName));
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

  static Future<_Configuration> fromFile(File file) async {
    final yaml = loadYaml(await file.readAsString());
    return _Configuration(
      arbDir: yaml['arb-dir'],
      outputClass: yaml['output-class'],
      outputDirectory: yaml['output-directory'],
      templateArbFile: yaml['template-arb-file'],
    );
  }
}
