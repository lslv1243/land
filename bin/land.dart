import 'dart:io';

import 'package:dart_style/dart_style.dart';

import 'create_language_declaration.dart';

void main(List<String> arguments) async {
  final portuguese = createLanguageDeclaration('pt_BR', {
    'helloWorld': LanguageField(
      [],
      'Hello World!',
    ),
    'count': LanguageField(
      ['count'],
      '{count}',
    ),
    'nDogs': LanguageField(
      ['count'],
      '{count,plural, zero{No dogs} =1{One dog} other{{count} dogs}}',
    ),
    'iHaveNDogs': LanguageField(
      ['count'],
      'I have {count,plural, zero{no dogs} =1{one dog} other{{count} dogs}}.',
    ),
  });

  await writeFileAndFormat(portuguese);
}

Future<void> writeFileAndFormat(String code) async {
  code = DartFormatter().format(code);
  final file = File('lib/generated/generated.dart');
  await file.writeAsString(code);
}
