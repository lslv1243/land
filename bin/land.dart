import 'dart:io';

import 'package:dart_style/dart_style.dart';

import 'package:land/land.dart';

void main(List<String> arguments) async {
  final fields = <String, List<String>>{
    'helloWorld': [],
    'count': ['count'],
    'nDogs': ['count'],
    'iHaveNDogs': ['count'],
  };

  final messagesEn = <String, String>{
    'helloWorld': 'Hello World!',
    'count': '{count}',
    'nDogs': '{count,plural, zero{No dogs} =1{One dog} other{{count} dogs}}',
    'iHaveNDogs':
        'I have {count,plural, zero{no dogs} =1{one dog} other{{count} dogs}}.',
  };

  final messagesPt = <String, String>{
    'helloWorld': 'Olá mundo!',
    'count': '{count}',
    'nDogs':
        '{count,plural, zero{Nenhum cachorro} =1{Um cachorro} other{{count} cachorros}}',
    'iHaveNDogs':
        'Eu tenho {count,plural, zero{nenhum cachorro} =1{um cachorro} other{{count} cachorros}}.',
  };

  final files = createDeclarationFiles(
    fields: fields,
    locales: {
      'en': messagesEn,
      'pt': messagesPt,
    },
    generateProxy: true,
  );

  await formatAndWriteFiles(files);
}

Future<void> formatAndWriteFiles(List<DeclarationFile> files) async {
  final formatter = DartFormatter();
  final root = 'lib/generated';

  for (final languageFile in files) {
    final formatted = formatter.format(languageFile.code);
    final file = File('$root/${languageFile.name}');
    await file.create(recursive: true);
    await file.writeAsString(formatted);
  }
}
