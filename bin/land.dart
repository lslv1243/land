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

  try {
    await _runForDirectory(directory);
  } on Exception catch (exception) {
    // If we failed to run in the current folder
    // we try to run in every folder inside the provided folder
    // if any run, we consider a success.
    // This implementation is to support folder of dart projects.
    var anyRan = false;
    await for (final entity in Directory(directory).list()) {
      try {
        if (entity is Directory) {
          await _runForDirectory(entity.path);
          anyRan = true;
        }
      } on Exception {
        // ignore
      }
    }

    if (!anyRan) {
      print(exception);
      exit(1);
    }
  }
}

Future<void> _runForDirectory(String directory) async {
  final _Configuration configuration;
  try {
    final file = File(path.join(directory, 'land.yaml'));
    configuration = await _Configuration.fromFile(file);
  } on Exception {
    throw Exception('Unable to find land.yaml file.');
  }

  final _Pubspec pubspec;
  try {
    pubspec = await _Pubspec.fromDirectory(directory);
  } on Exception {
    throw Exception('Unable to find pubspec file.');
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
    emitProxy: configuration.proxy != null,
    emitProxyLoader: configuration.proxy?.loader == true,
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

class _ProxyConfiguration {
  final bool loader;

  _ProxyConfiguration({
    required this.loader,
  });

  static _ProxyConfiguration fromYaml(dynamic yaml) {
    return _ProxyConfiguration(
      loader: yaml['loader'] ?? false,
    );
  }
}

class _Configuration {
  final String arbDir;
  final String outputClass;
  final String outputDirectory;
  final String templateArbFile;
  final _ProxyConfiguration? proxy;

  _Configuration({
    required this.arbDir,
    required this.outputClass,
    required this.outputDirectory,
    required this.templateArbFile,
    required this.proxy,
  });

  static _Configuration fromYaml(dynamic yaml) {
    final proxy = yaml['proxy'];
    return _Configuration(
      arbDir: yaml['arb-dir'],
      outputClass: yaml['output-class'],
      outputDirectory: yaml['output-directory'],
      templateArbFile: yaml['template-arb-file'],
      proxy: proxy == null ? null : _ProxyConfiguration.fromYaml(proxy),
    );
  }

  static Future<_Configuration> fromFile(File file) async {
    final yaml = loadYaml(await file.readAsString());
    return _Configuration.fromYaml(yaml);
  }
}
