import 'dart:io';

import 'package:intl/intl.dart';
import 'package:intl/locale.dart';
import 'package:land/land.dart';
import 'package:path/path.dart';

import 'format_expression.dart';

void main(List<String> arguments) async {
  final parser = Parser();
  final topLevelMultiple = parser
      .parse('{count,plural, zero{No dogs} =1{One dog} other{{count} dogs}}');
  final topLevelList = parser.parse(
      'I have {count,plural, zero{no dogs} =1{one dog} other{{count} dogs}}');
  final topLevelReference = parser.parse('{count}');
  final topLevelLiteral = parser.parse('Hello World!');

  var code = '';
  code += generateEntryCode('batata0', topLevelMultiple);
  code += generateEntryCode('batata1', topLevelList);
  code += generateEntryCode('batata2', topLevelReference);
  code += generateEntryCode('batata3', topLevelLiteral);
  code = _generateClass(code, languageTag: 'pt-BR');
  await writeFileAndFormat(code);

  // final l10n = L10N_pt_BR();
  // print(l10n.batata3);
  // print(l10n.batata1(10));
}

Future<void> writeFileAndFormat(String code) async {
  final file = File('lib/generated/generated.dart');
  await file.writeAsString(code);
  await Process.run('dart', ['format', file.path]);
}

String _generateClass(String fields, {required String languageTag}) {
  String capitalizeTag(String tag) {
    return tag
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }

  languageTag = Intl.canonicalizedLocale(languageTag);
  final className = 'L10N${capitalizeTag(languageTag)}';
  var code = '';
  code += 'import \'package:intl/intl.dart\';\n';
  code += 'import \'package:intl/locale.dart\';\n';
  code += 'class $className {\n';
  code += 'String get localeName => locale.toLanguageTag();\n';
  code += 'final Locale locale;\n';
  code += '\n';
  code += '$className(): locale = Locale.parse(\'$languageTag\');\n';
  code += '\n';
  code += fields;
  code += '}\n';
  code += '\n';
  return code;
}

Set<String> _parameterInUse(Expression expression) {
  final parameters = <String>{};
  if (expression is ReferenceExpression) {
    parameters.add(expression.parameter);
  } else if (expression is MultipleExpression) {
    parameters.add(expression.parameter);
    for (final option in expression.options.values) {
      parameters.addAll(_parameterInUse(option));
    }
  } else if (expression is ExpressionList) {
    for (final expression in expression.expressions) {
      parameters.addAll(_parameterInUse(expression));
    }
  }
  return parameters;
}

String generateEntryCode(String name, Expression expression) {
  final varCreator = _VarCreator();

  if (expression is LiteralExpression) {
    return 'String get $name => \'${expression.value}\';\n';
  }

  // TODO: should have extracted parameters previously, or else
  //  we can not guarantee order when changing language
  final parameters = _parameterInUse(expression);
  // TODO: use parameters in use to verify that the declared parameters are correct
  //  instead of using it to declare the parameters
  final parameterList = parameters.map((p) => 'Object $p').join(', ');
  var pre = '';
  void prepend(String value) => pre += value;
  final value = _value(expression, varCreator: varCreator, prepend: prepend);
  var code = 'String $name($parameterList) {\n';
  code += pre + 'return $value;\n';
  code += '}\n';
  return code;
}

String _value(
  Expression expression, {
  required _VarCreator varCreator,
  required void Function(String) prepend,
}) {
  if (expression is LiteralExpression) {
    return '\'${expression.value}\'';
  }

  if (expression is ReferenceExpression) {
    return '${expression.parameter}.toString()';
  }

  if (expression is ExpressionList) {
    final values = <String>[];
    var code = '';
    for (final inner in expression.expressions) {
      values.add(_value(inner, varCreator: varCreator, prepend: prepend));
    }
    code += values.join(' + ');
    return code;
  }

  if (expression is MultipleExpression) {
    final name = varCreator.create();
    prepend(_multiple(name, expression, varCreator));
    return name;
  }

  throw UnimplementedError();
}

String _multiple(
  String name,
  MultipleExpression expression,
  _VarCreator varCreator,
) {
  String? value(String option, {required void Function(String) prepend}) {
    final value = expression.options[option];
    if (value == null) return null;
    return _value(value, varCreator: varCreator, prepend: prepend);
  }

  String select() {
    var pre = '';
    void prepend(String value) => pre += value;

    var code = 'final String $name;\n';
    code += 'switch (${expression.parameter}){\n';

    for (final option in expression.options.entries) {
      code += 'case \'${option.key}\':\n';
      code += '$name = ${value(option.key, prepend: prepend)};\n';
      code += 'break;\n';
    }
    code += 'default:\n';
    code += 'throw UnimplementedError();\n';
    code += '}\n';
    return pre + code;
  }

  String plural() {
    var pre = '';
    void prepend(String value) => pre += value;
    String? _value(String option) => value(option, prepend: prepend);

    var code = 'final $name = Intl.pluralLogic(\n';
    code += '${expression.parameter} as num,\n';
    code += 'locale: localeName,\n';
    final zero = _value('=0') ?? _value('zero');
    if (zero != null) {
      code += 'zero: $zero,\n';
    }
    final one = _value('=1') ?? _value('one');
    if (one != null) {
      code += 'one: $one,\n';
    }
    final two = _value('=2') ?? _value('two');
    if (two != null) {
      code += 'two: $two,\n';
    }
    final few = _value('few');
    if (few != null) {
      code += 'few: $few,\n';
    }
    final many = _value('many');
    if (many != null) {
      code += 'many: $many,\n';
    }
    final other = _value('other');
    if (other == null) {
      // TODO: improve this error reporting (provide position)
      throw Exception('"other" missing for plurality.');
    }
    code += 'other: $other,\n';
    code += ');\n';

    return pre + code;
  }

  switch (expression.modifier) {
    case 'select':
      return select();
    case 'plural':
      return plural();
    default:
      throw UnimplementedError();
  }
}

class _VarCreator {
  var count = 0;

  String create() => 'var${count++}';
}
