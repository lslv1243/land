import 'package:land/land.dart';

void main() async {
  final languageInfo = await loadARBFolder(
    'l10n',
    configurationFile: 'app_en.arb',
  );

  final files = createDeclarationFiles(
    fields: languageInfo.fields,
    locales: languageInfo.locales,
    emitSupportedLocales: true,
    emitFlutterGlue: true,
  );

  await formatAndWriteFiles(
    files,
    path: 'lib/generated/l10n',
    recreateFolder: true,
  );
}
