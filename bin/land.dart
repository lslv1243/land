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

  final messages = <String, String>{
    'helloWorld': 'Hello World!',
    'count': '{count}',
    'nDogs': '{count,plural, zero{No dogs} =1{One dog} other{{count} dogs}}',
    'iHaveNDogs':
        'I have {count,plural, zero{no dogs} =1{one dog} other{{count} dogs}}.',
  };

  final portuguese = createLanguageDeclaration('pt_BR', messages, fields);

  await writeFileAndFormat(portuguese);
}

Future<void> writeFileAndFormat(String code) async {
  code = DartFormatter().format(code);
  final file = File('lib/generated/generated.dart');
  await file.writeAsString(code);
}
