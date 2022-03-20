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

  final files = createDeclarationFiles(
    fields: languageInfo.fields,
    locales: languageInfo.locales,
    className: outputClass,
    emitFlutterGlue: true,
    emitSupportedLocales: true,
  );

  await formatAndWriteFiles(
    files,
    path: outputDirectory,
    recreateFolder: true,
  );
}
