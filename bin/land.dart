import 'dart:io';

import 'package:dart_style/dart_style.dart';

import 'create_language_declaration.dart';

void main(List<String> arguments) async {
  final declaration = createLanguageDeclaration('pt_BR', {
    'helloWorld': 'Hello World!',
    'count': '{count}',
    'nDogs': '{count,plural, zero{No dogs} =1{One dog} other{{count} dogs}}',
    'iHaveNDogs':
        'I have {count,plural, zero{no dogs} =1{one dog} other{{count} dogs}}.',
  });

  await writeFileAndFormat(declaration.code);
}

Future<void> writeFileAndFormat(String code) async {
  code = DartFormatter().format(code);
  final file = File('lib/generated/generated.dart');
  await file.writeAsString(code);
}
