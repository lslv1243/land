import 'dart:io';

import 'package:dart_style/dart_style.dart';

import 'create_language_declaration.dart';
import 'package:land/generated/l10n.dart';

void main(List<String> arguments) async {
  // final fields = <String, List<String>>{
  //   'helloWorld': [],
  //   'count': ['count'],
  //   'nDogs': ['count'],
  //   'iHaveNDogs': ['count'],
  // };

  // final messagesEn = <String, String>{
  //   'helloWorld': 'Hello World!',
  //   'count': '{count}',
  //   'nDogs': '{count,plural, zero{No dogs} =1{One dog} other{{count} dogs}}',
  //   'iHaveNDogs':
  //       'I have {count,plural, zero{no dogs} =1{one dog} other{{count} dogs}}.',
  // };

  // final messagesPt = <String, String>{
  //   'helloWorld': 'Olá mundo!',
  //   'count': '{count}',
  //   'nDogs':
  //       '{count,plural, zero{Nenhum cachorro} =1{Um cachorro} other{{count} cachorros}}',
  //   'iHaveNDogs':
  //       'Eu tenho {count,plural, zero{nenhum cachorro} =1{um cachorro} other{{count} cachorros}}.',
  // };

  // final files = createDeclarationFiles(
  //   fields: fields,
  //   locales: {
  //     'en': messagesEn,
  //     'pt': messagesPt,
  //   },
  //   generateProxy: true,
  // );

  // await formatAndWriteFiles(files);

  final l10nPt = L10NPt();
  final l10nEn = L10NEn();
  final proxy = ProxyL10N(l10nPt);
  print(proxy.helloWorld);
  proxy.proxy = l10nEn;
  print(proxy.helloWorld);
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
