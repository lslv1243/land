import 'dart:io';

import 'package:dart_style/dart_style.dart';

import 'create_language_declaration.dart';

void main(List<String> arguments) async {
  final fields = <String, List<String>>{
    'helloWorld': [],
    'count': ['count'],
    'nDogs': ['count'],
    'iHaveNDogs': ['count'],
  };

  final messagesPtBr = <String, String>{
    'helloWorld': 'Hello World!',
    'count': '{count}',
    'nDogs': '{count,plural, zero{No dogs} =1{One dog} other{{count} dogs}}',
    'iHaveNDogs':
        'I have {count,plural, zero{no dogs} =1{one dog} other{{count} dogs}}.',
  };

  final files = createDeclarationFiles(
    fields: fields,
    locales: {
      'pt_BR': messagesPtBr,
    },
    generateProxy: true,
  );

  await formatAndWriteFiles(files);
}

Future<void> formatAndWriteFiles(List<LanguageFile> files) async {
  final formatter = DartFormatter();
  final root = 'lib/generated';

  for (final languageFile in files) {
    final formatted = formatter.format(languageFile.code);
    final file = File('$root/${languageFile.name}');
    await file.create(recursive: true);
    await file.writeAsString(formatted);
  }
}
