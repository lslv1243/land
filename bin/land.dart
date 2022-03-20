// arb-dir: lib/i18n
// output-class: StockStrings
// output-localization-file: stock_strings.dart
// template-arb-file: stocks_en.arb

import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:land/land.dart';
import 'package:path/path.dart' as p;

void main() async {
  final configuration = await File('l10n.yaml').readAsString();
  final configYaml = loadYaml(configuration);

  final String arbDir = configYaml['arb-dir'];
  final String outputClass = configYaml['output-class'];
  final String outputLocalizationFile = configYaml['output-localization-file'];
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

  // we are currently just using the directory where the expected output
  // localization file should live, we are creating a custom filename for now
  final outputPath = p.dirname(outputLocalizationFile);
  await formatAndWriteFiles(
    files,
    path: outputPath,
    recreateFolder: true,
  );
}
