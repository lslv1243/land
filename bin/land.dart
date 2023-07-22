// arb-dir: lib/i18n
// output-class: StockStrings
// output-localization-file: stock_strings.dart
// template-arb-file: stocks_en.arb

import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:land/land.dart';

void main() async {
  final configuration = await _Configuration.fromFile(File('land.yaml'));

  final languageInfo = await loadARBFolder(
    configuration.arbDir,
    configurationFile: configuration.templateArbFile,
  );

  final isFlutter = await _isFlutterProject();

  final files = createDeclarationFiles(
    fields: languageInfo.fields,
    locales: languageInfo.locales,
    className: configuration.outputClass,
    emitFlutterGlue: isFlutter,
    emitSupportedLocales: true,
  );

  await formatAndWriteFiles(
    files,
    path: configuration.outputDirectory,
    recreateFolder: true,
  );
}

Future<bool> _isFlutterProject() async {
  final String pubspec;
  try {
    pubspec = await File('pubspec.yaml').readAsString();
  } catch (_) {
    // if we don't find a pubspec.yaml we just assume
    // it is not flutter and go on with our lives
    return false;
  }
  final pubspecYaml = loadYaml(pubspec);
  return pubspecYaml['dependencies']?['flutter'] != null;
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
