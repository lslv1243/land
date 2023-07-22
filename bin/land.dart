// arb-dir: lib/i18n
// output-class: StockStrings
// output-localization-file: stock_strings.dart
// template-arb-file: stocks_en.arb

import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:land/land.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  final parser = ArgParser();

  parser.addOption(
    'path',
    valueHelp: 'directory',
    defaultsTo: '.',
    help: 'Location of the project.',
  );

  parser.addFlag(
    'help',
    abbr: 'h',
    defaultsTo: false,
    negatable: false,
    help: 'Print this usage information.',
  );

  final args = parser.parse(arguments);
  if (args['help'] as bool) {
    print(parser.usage);
    return;
  }

  final directory = args['path'] as String;

  final _Configuration configuration;
  try {
    final file = File(path.join(directory, 'land.yaml'));
    configuration = await _Configuration.fromFile(file);
  } on Exception {
    print('Unable to find land.yaml file.');
    exit(1);
  }

  final _Pubspec pubspec;
  try {
    pubspec = await _Pubspec.fromDirectory(directory);
  } on Exception {
    print('Unable to find pubspec file.');
    exit(1);
  }

  final languageInfo = await loadARBFolder(
    path.join(directory, configuration.arbDir),
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
    path: path.join(directory, configuration.outputDirectory),
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
