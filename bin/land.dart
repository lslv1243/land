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

  await writeFormattedFiles(
    createSuperDeclaration(fields),
    {
      'pt_BR': createLanguageDeclaration('pt_BR', messagesPtBr, fields),
    },
  );
}

Future<void> writeFormattedFiles(
  String superDeclaration,
  Map<String, String> languagesDeclarations,
) async {
  final formatter = DartFormatter();
  final root = 'lib/generated';

  final declarationsFiles = <String>[];

  for (final language in languagesDeclarations.entries) {
    final declaration = formatter.format(language.value);
    final suffix = language.key.toLowerCase();
    final declarationFile = 'l10n_$suffix.dart';
    declarationsFiles.add(declarationFile);    
    await File('$root/$declarationFile').writeAsString(declaration);
  }

  // export the languages declarations to facilitate importing
  var exports = '';
  for (final file in declarationsFiles) {
    exports += 'export \'$file\';\n';
  }
  exports += '\n';
  superDeclaration = exports + superDeclaration;

  superDeclaration = formatter.format(superDeclaration);
  await File('$root/l10n.dart').writeAsString(superDeclaration);
}
