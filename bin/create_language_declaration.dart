import 'package:intl/intl.dart';
import 'package:land/land.dart';

class LanguageFile {
  final String name;
  final String code;

  LanguageFile({required this.name, required this.code});
}

List<LanguageFile> createDeclarationFiles({
  required Map<String, List<String>> fields,
  required Map<String, Map<String, String>> locales,
  String className = 'L10N',
}) {
  final declarations = <LanguageFile>[];

  String filename([String? locale]) {
    var name = className.toLowerCase();
    if (locale != null) {
      name += '_${locale.toLowerCase()}';
    }
    name += '.dart';
    return name;
  }

  final declarationsFiles = <String>[];

  for (final locale in locales.entries) {
    final declaration = _createLanguageDeclaration(
        locale.key, locale.value, fields,
        superclassName: className);

    final file = filename(locale.key);
    declarationsFiles.add(file);
    declarations.add(LanguageFile(
      name: file,
      code: declaration,
    ));
  }

  final superDeclaration = _createSuperDeclaration(
    fields,
    className: className,
    declarationsFiles: declarationsFiles,
  );
  declarations.add(LanguageFile(
    name: filename(),
    code: superDeclaration,
  ));

  return declarations;
}

String _createSuperDeclaration(
  Map<String, List<String>> fields, {
  required String className,
  List<String>? declarationsFiles,
}) {
  var body = '';
  for (final field in fields.entries) {
    body += _createGetterOrMethodDeclaration(field.key, field.value);
    body += '\n';
  }
  final _classCode = _createSuperClass(
    body,
    name: className,
  );

  var code = '';
  if (declarationsFiles != null) {
    for (final file in declarationsFiles) {
      code += 'export \'$file\';\n';
    }
    code += '\n';
  }
  code += 'import \'package:intl/locale.dart\';\n';
  code += _classCode;
  return code;
}

String _createLanguageDeclaration(
  String localeName,
  Map<String, String> messages,
  Map<String, List<String>> fields, {
  required String superclassName,
}) {
  final parser = Parser();
  var body = '';

  // make sure we have all fields declared in this locale
  for (final fieldName in fields.keys) {
    if (!messages.containsKey(fieldName)) {
      throw Exception(
          'Missing message for field named "$fieldName" in locale "$localeName".');
    }
  }

  for (final message in messages.entries) {
    final field = fields[message.key];
    if (field == null) {
      throw Exception(
          'Unexpected field named "${message.key}" in locale "$localeName".');
    }
    final expression = parser.parse(message.value);
    body += _createGetterOrMethod(
      message.key,
      expression,
      field,
    );
    body += '\n';
  }

  final _class = _createClass(
    body,
    localeName: localeName,
    supername: superclassName,
  );

  var code = '';
  code += 'import \'package:intl/intl.dart\';\n';
  code += 'import \'package:intl/locale.dart\';\n';
  code += '\n';
  // TODO: this filename is hardcoded
  code += 'import \'l10n.dart\';\n';
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

String _createSuperClass(
  String body, {
  required String name,
}) {
  var code = '';
  code += 'abstract class $name {\n';
  code += 'Locale get locale;\n';
  code += '\n';
  code += body;
  code += '}\n';
  return code;
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
        throw Exception(
            'Missing "other" for plurality in field named "$name".');
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

String _createGetterOrMethodDeclaration(String name, List<String> parameters) {
  if (parameters.isEmpty) return 'String get $name;\n';
  final parameterList = parameters.map((p) => 'Object $p').join(', ');
  return 'String $name($parameterList);\n';
}

String _createGetterOrMethod(
  String name,
  Expression expression,
  List<String> parameters,
) {
  if (parameters.isEmpty) {
    final literal = (expression as LiteralExpression).value;
    return '@override String get $name => \'$literal\';\n';
  }

  final usingParameters = _usingParameters(expression);
  for (final parameter in usingParameters) {
    if (!parameters.contains(parameter)) {
      throw Exception(
          'Parameter named "$parameter" not declared in field named "$name".');
    }
  }

  final parameterList = parameters.map((p) => 'Object $p').join(', ');
  final scope = _Scope();
  final visitor = _Visitor(scope);
  final value = expression.visit(visitor);
  var code = '@override String $name($parameterList) {\n';
  code += scope.declarations;
  code += 'return $value;\n';
  code += '}\n';
  return code;
}

class _UniqueVar {
  var count = 0;

  String create() => 'var${count++}';
}
