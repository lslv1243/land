import 'package:land/land.dart';

void main(List<String> arguments) async {
  final fields = <DeclarationField>[
    DeclarationField('helloWorld', []),
    DeclarationField('count', [DeclarationFieldParameter('count')]),
    DeclarationField('nDogs', [DeclarationFieldParameter('count')]),
    DeclarationField('iHaveNDogs', [DeclarationFieldParameter('count')]),
  ];

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
    emitSupportedLocales: true,
    emitProxyLoader: true,
  );

  await formatAndWriteFiles(
    files,
    path: 'lib/generated/l10n',
    recreateFolder: true,
  );
}
