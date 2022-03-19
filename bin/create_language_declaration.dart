import 'package:intl/intl.dart';
import 'package:land/land.dart';

class LanguageField {
  final List<String> parameters;
  final String message;

  LanguageField(this.parameters, this.message);
}

// String createSuperDeclaration(Map<String, String> fields) {
//   var body = '';
//   for (final field in fields.entries) {
//     //
//   }
//   var code = '';
//   code += 'import \'package:intl/locale.dart\';\n';
//   return code;
// }

String createLanguageDeclaration(
  String localeName,
  Map<String, LanguageField> fields,
) {
  final parser = Parser();
  var body = '';
  for (final field in fields.entries) {
    final expression = parser.parse(field.value.message);
    body += _createGetterOrMethod(
      field.key,
      expression,
      field.value.parameters,
    );
    body += '\n';
  }
  final _class = _createClass(
    body,
    localeName: localeName,
    supername: 'L10N',
  );

  var code = '';
  code += 'import \'package:intl/intl.dart\';\n';
  code += 'import \'package:intl/locale.dart\';\n';
  code += 'import \'l10n.dart\';';
  code += _class.code;
  return code;
}

class _Class {
  final String name;
  final String code;

  _Class({
    required this.name,
    required this.code,
  });
}

_Class _createClass(
  String body, {
  required String localeName,
  required String supername,
}) {
  String capitalizeTag(String tag) {
    return tag
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }

  final _localeName = Intl.canonicalizedLocale(localeName);
  if (_localeName != localeName) {
    throw ArgumentError.value(
        localeName, 'localeName', 'Rename to $_localeName.');
  }
  final className = '$supername${capitalizeTag(_localeName)}';
  var code = '';
  code += 'class $className implements $supername {\n';
  code += 'static const localeName = \'$_localeName\';\n';
  code += '\n';
  code += '@override\n';
  code += 'final Locale locale;\n';
  code += '\n';
  code += '$className(): locale = Locale.parse(localeName);\n';
  code += '\n';
  code += body;
  code += '}\n';
  code += '\n';
  return _Class(name: className, code: code);
}

Set<String> _usingParameters(Expression expression) {
  final parameters = <String>{};
  if (expression is ReferenceExpression) {
    parameters.add(expression.parameter);
  } else if (expression is MultipleExpression) {
    parameters.add(expression.parameter);
    for (final option in expression.options.values) {
      parameters.addAll(_usingParameters(option));
    }
  } else if (expression is ExpressionList) {
    for (final expression in expression.expressions) {
      parameters.addAll(_usingParameters(expression));
    }
  }
  return parameters;
}

class _Scope {
  _Scope? parent;
  var declarations = '';

  _Scope([this.parent]);

  _Scope child() => _Scope(this);

  void declare(String code) {
    declarations += code;
  }
}

class _Visitor implements ExpressionVisitor<String> {
  final _var = _UniqueVar();
  _Scope scope;

  _Visitor(this.scope);

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
    final name = _var.create();
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
        throw Exception('Missing "other" for plurality in field named "$name".');
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

String _createGetterOrMethod(
  String name,
  Expression expression,
  List<String> parameters,
) {
  if (expression is LiteralExpression) {
    return 'String get $name => \'${expression.value}\';\n';
  }

  final usingParameters = _usingParameters(expression);
  for (final parameter in usingParameters) {
    if (!parameters.contains(parameter)) {
      throw Exception('Parameter named "$parameter" not declared in field named "$name".');
    }
  }

  final parameterList = parameters.map((p) => 'Object $p').join(', ');
  final scope = _Scope();
  final visitor = _Visitor(scope);
  final value = expression.visit(visitor);
  var code = 'String $name($parameterList) {\n';
  code += scope.declarations;
  code += 'return $value;\n';
  code += '}\n';
  return code;
}

class _UniqueVar {
  var count = 0;

  String create() => 'var${count++}';
}
