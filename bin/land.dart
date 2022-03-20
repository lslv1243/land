// arb-dir: lib/i18n
// output-class: StockStrings
// output-localization-file: stock_strings.dart
// template-arb-file: stocks_en.arb

import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:land/land.dart';

void main() async {
  final configuration = await File('land.yaml').readAsString();
  final configYaml = loadYaml(configuration);

  final String arbDir = configYaml['arb-dir'];
  final String outputClass = configYaml['output-class'];
  final String outputDirectory = configYaml['output-directory'];
  final String templateArbFile = configYaml['template-arb-file'];

  final languageInfo = await loadARBFolder(
    arbDir,
    configurationFile: templateArbFile,
  );

  final isFlutter = await _isFlutterProject();

  final files = createDeclarationFiles(
    fields: languageInfo.fields,
    locales: languageInfo.locales,
    className: outputClass,
    emitFlutterGlue: isFlutter,
    emitSupportedLocales: true,
  );

  await formatAndWriteFiles(
    files,
    path: outputDirectory,
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
