import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'create_declaration_files.dart';

Future<ARBLanguageInfo> loadARBFolder(String path,
    {required String configurationFile}) async {
  final configPath = p.join(path, configurationFile);
  final configuration = await File(configPath).readAsString();
  final configJSON = jsonDecode(configuration);

  final languagesJSON = <String, Map<String, dynamic>>{};

  await for (final file in Directory(path).list()) {
    if (p.extension(file.path) != '.arb') continue;
    final fileName = p.basenameWithoutExtension(file.path);
    final localeSeparatorIndex = fileName.indexOf('_');
    // we gonna ignore any arb files which does not have a locale suffix
    if (localeSeparatorIndex == -1) continue;

    final locale = await File(file.path).readAsString();
    final localeJSON = jsonDecode(locale);
    final localeName = fileName.substring(localeSeparatorIndex + 1);
    languagesJSON[localeName] = localeJSON;
  }

  return _getInfoFromContent(configJSON, languagesJSON);
}

class ARBLanguageInfo {
  final List<DeclarationField> fields;
  final Map<String, Map<String, String>> locales;

  ARBLanguageInfo(this.fields, this.locales);
}

ARBLanguageInfo _getInfoFromContent(
  Map<String, dynamic> configurationJSON,
  Map<String, Map<String, dynamic>> languagesJson,
) {
  final fields = <DeclarationField>[];
  for (final entry in configurationJSON.entries) {
    if (entry.key[0] != '@') continue;
    // we gonna skip this to avoid reading localeName from ARB
    if (entry.key[1] == '@') continue;
    final name = entry.key.substring(1);
    final placeholders = entry.value['placeholders'] as Map<String, dynamic>?;
    final parameters = <DeclarationFieldParameter>[];
    if (placeholders != null) {
      for (final placeholderEntry in placeholders.entries) {
        parameters.add(DeclarationFieldParameter(
          placeholderEntry.key,
          placeholderEntry.value['type'],
        ));
      }
    }
    fields.add(DeclarationField(
      name,
      parameters,
    ));
  }

  final locales = <String, Map<String, String>>{};

  for (final language in languagesJson.entries) {
    final messages = <String, String>{};
    for (final entry in language.value.entries) {
      // it may be a language and a configuration file at the same time
      if (entry.key.startsWith('@')) continue;
      messages[entry.key] = entry.value;
    }
    locales[language.key] = messages;
  }

  return ARBLanguageInfo(fields, locales);
}
