import 'dart:io';

import 'package:intl/intl.dart';
import 'package:intl/locale.dart';
import 'package:land/land.dart';
import 'package:path/path.dart';
import 'package:dart_style/dart_style.dart';

import 'format_expression.dart';

void main(List<String> arguments) async {
  final parser = Parser();
  final topLevelMultiple = parser
      .parse('{count,plural, zero{No dogs} =1{One dog} other{{count} dogs}}');
  final topLevelList = parser.parse(
      'I have {count,plural, zero{no dogs} =1{one dog} other{{count} dogs}}.');
  final topLevelReference = parser.parse('{count}');
  final topLevelLiteral = parser.parse('Hello World!');

  var code = '';
  code += generateEntryCode('batata0', topLevelMultiple);
  code += generateEntryCode('batata1', topLevelList);
  code += generateEntryCode('batata2', topLevelReference);
  code += generateEntryCode('batata3', topLevelLiteral);
  code = _generateClass(code, languageTag: 'pt-BR');
  await writeFileAndFormat(code);

  // final l10n = L10NPtBr();
  // print(l10n.batata3);
  // print(l10n.batata1(10));
}

Future<void> writeFileAndFormat(String code) async {
  code = DartFormatter().format(code);
  final file = File('lib/generated/generated.dart');
  await file.writeAsString(code);
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
  code += 'static const localeName = \'$languageTag\';\n';
  code += 'final Locale locale;\n';
  code += '\n';
  code += '$className(): locale = Locale.parse(localeName);\n';
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

class Scope {
  Scope? parent;
  var declarations = '';

  Scope([this.parent]);

  Scope child() => Scope(this);

  void declare(String code) {
    declarations += code;
  }
}

class CodeBlockVisitor implements ExpressionVisitor<String> {
  final varCreator = VarCreator();
  Scope scope;

  CodeBlockVisitor(this.scope);

  @override
  String visitList(ExpressionList expression) {
    final values = <String>[];
    var code = '';
    for (final inner in expression.expressions) {
      values.add(inner.visit(this));
    }
    code += values.join(' + ');
    return code;
  }

  @override
  String visitLiteral(LiteralExpression expression) {
    return '\'${expression.value}\'';
  }

  @override
  String visitReference(ReferenceExpression expression) {
    return '${expression.parameter}.toString()';
  }

  @override
  String visitSelect(MultipleExpression expression) {
    final name = varCreator.create();
    scope.declare(_multiple(name, expression));
    return name;
  }

  String _multiple(String name, MultipleExpression expression) {
    String? value(String option) {
      final value = expression.options[option];
      if (value == null) return null;
      return value.visit(this);
    }

    String select() {
      var code = 'final String $name;\n';
      code += 'switch (${expression.parameter}){\n';

      for (final option in expression.options.entries) {
        code += 'case \'${option.key}\':\n';
        scope = scope.child();
        final variable = value(option.key);
        code += scope.declarations;
        scope = scope.parent!;
        code += '$name = $variable;\n';
        code += 'break;\n';
      }
      code += 'default:\n';
      code += 'throw UnimplementedError();\n';
      code += '}\n';
      return code;
    }

    String plural() {
      var code = 'final $name = Intl.pluralLogic(\n';
      code += '${expression.parameter} as num,\n';
      code += 'locale: localeName,\n';
      final zero = value('=0') ?? value('zero');
      if (zero != null) {
        code += 'zero: $zero,\n';
      }
      final one = value('=1') ?? value('one');
      if (one != null) {
        code += 'one: $one,\n';
      }
      final two = value('=2') ?? value('two');
      if (two != null) {
        code += 'two: $two,\n';
      }
      final few = value('few');
      if (few != null) {
        code += 'few: $few,\n';
      }
      final many = value('many');
      if (many != null) {
        code += 'many: $many,\n';
      }
      final other = value('other');
      if (other == null) {
        // TODO: improve this error reporting (provide position)
        throw Exception('"other" missing for plurality.');
      }
      code += 'other: $other,\n';
      code += ');\n';
      return code;
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
}

String generateEntryCode(String name, Expression expression) {
  if (expression is LiteralExpression) {
    return 'String get $name => \'${expression.value}\';\n';
  }

  // TODO: should have extracted parameters previously, or else
  //  we can not guarantee order when changing language
  final parameters = _parameterInUse(expression);
  // TODO: use parameters in use to verify that the declared parameters are correct
  //  instead of using it to declare the parameters
  final parameterList = parameters.map((p) => 'Object $p').join(', ');
  final scope = Scope();
  final visitor = CodeBlockVisitor(scope);
  final value = expression.visit(visitor);
  var code = 'String $name($parameterList) {\n';
  code += scope.declarations;
  code += 'return $value;\n';
  code += '}\n';
  return code;
}

class VarCreator {
  var count = 0;

  String create() => 'var${count++}';
}
