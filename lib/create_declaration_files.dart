import 'package:intl/intl.dart';
import 'package:land/land.dart';

class DeclarationFile {
  final String name;
  final String code;

  DeclarationFile({required this.name, required this.code});
}

List<DeclarationFile> createDeclarationFiles({
  required Map<String, List<String>> fields,
  required Map<String, Map<String, String>> locales,
  String className = 'L10N',
  bool generateProxy = false,
  bool emitSupportedLocales = false,
}) {
  final declarations = <DeclarationFile>[];

  final parent = _LanguageSuper(
    fileName: '${className.toLowerCase()}.dart',
    className: className,
  );

  final languagesDeclarationsFiles = <String>[];
  String? proxyDeclarationFile;
  final localesClasses = <String, String>{};

  if (generateProxy) {
    final proxyDeclaration = _createProxyDeclaration(
      fields,
      parent: parent,
    );
    final file = 'proxy_${className.toLowerCase()}.dart';
    proxyDeclarationFile = file;
    declarations.add(DeclarationFile(
      name: file,
      code: proxyDeclaration,
    ));
  }

  for (final locale in locales.entries) {
    final declaration = _createLanguageDeclaration(
      locale.key,
      locale.value,
      fields,
      parent: parent,
    );

    final file = '${className.toLowerCase()}_${locale.key.toLowerCase()}.dart';
    languagesDeclarationsFiles.add(file);
    localesClasses[locale.key] = declaration.className;
    declarations.add(DeclarationFile(
      name: file,
      code: declaration.code,
    ));
  }

  final superDeclaration = _createSuperDeclaration(
    fields,
    className: parent.className,
    languagesDeclarationsFiles: languagesDeclarationsFiles,
    proxyDeclarationFile: proxyDeclarationFile,
    supportedLocales: emitSupportedLocales ? localesClasses : null,
  );
  declarations.add(DeclarationFile(
    name: parent.fileName,
    code: superDeclaration,
  ));

  return declarations;
}

String _createProxyDeclaration(
  Map<String, List<String>> fields, {
  required _LanguageSuper parent,
  String proxyField = 'proxy',
}) {
  var body = '';
  for (final field in fields.entries) {
    body += '@override\n';
    body += _createGetterOrMethodProxy(
      field.key,
      field.value,
      proxyField: proxyField,
    );
    body += '\n';
  }

  final classCode = _createProxyClass(
    body,
    supername: parent.className,
    proxyField: proxyField,
  );

  var code = '';
  code += 'import \'package:intl/locale.dart\';\n';
  code += '\n';
  code += 'import \'${parent.fileName}\';\n';
  code += '\n';
  code += classCode;
  return code;
}

String _createSuperDeclaration(
  Map<String, List<String>> fields, {
  required String className,
  Map<String, String>? supportedLocales,
  List<String>? languagesDeclarationsFiles,
  String? proxyDeclarationFile,
}) {
  var body = '';
  for (final field in fields.entries) {
    body += _createGetterOrMethodDeclaration(field.key, field.value);
    body += '\n';
  }
  final classCode = _createSuperClass(
    body,
    name: className,
    supportedLocales: supportedLocales,
  );

  var code = '';
  final allDeclarationFiles = [
    if (proxyDeclarationFile != null) proxyDeclarationFile,
    if (languagesDeclarationsFiles != null) ...languagesDeclarationsFiles,
  ];
  if (allDeclarationFiles.isNotEmpty) {
    for (final file in allDeclarationFiles) {
      code += 'export \'$file\';\n';
    }
    code += '\n';
  }
  code += 'import \'package:intl/locale.dart\';\n';
  code += '\n';
  // if we wanna generate the supported locales, make sure to import the files
  // we assume the declarations files will contain all of the supported locales
  if (supportedLocales != null) {
    for (final file in languagesDeclarationsFiles!) {
      code += 'import \'$file\';\n';
    }
    code += '\n';
  }
  code += classCode;
  return code;
}

class _LanguageSuper {
  final String fileName;
  final String className;

  _LanguageSuper({
    required this.fileName,
    required this.className,
  });
}

class _LanguageDeclaration {
  final String className;
  final String code;

  _LanguageDeclaration({
    required this.className,
    required this.code,
  });
}

_LanguageDeclaration _createLanguageDeclaration(
  String localeName,
  Map<String, String> messages,
  Map<String, List<String>> fields, {
  _LanguageSuper? parent,
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
    if (parent != null) {
      body += '@override\n';
    }
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
    supername: parent?.className,
  );

  var code = '';
  code += 'import \'package:intl/intl.dart\';\n';
  code += 'import \'package:intl/locale.dart\';\n';
  code += '\n';
  if (parent != null) {
    code += 'import \'${parent.fileName}\';\n';
    code += '\n';
  }
  code += _class.code;

  return _LanguageDeclaration(
    className: _class.name,
    code: code,
  );
}

String _createProxyClass(
  String body, {
  required String supername,
  required String proxyField,
}) {
  final className = 'Proxy$supername';
  var code = '';
  code += 'class $className implements $supername {\n';
  code += '@override\n';
  code += 'Locale get locale => $proxyField.locale;\n';
  code += '\n';
  code += '$supername $proxyField;\n';
  code += '\n';
  code += '$className(this.$proxyField);\n';
  code += '\n';
  code += body;
  code += '}\n';
  return code;
}

String _createSuperClass(
  String body, {
  required String name,
  Map<String, String>? supportedLocales,
}) {
  var code = '';
  code += 'abstract class $name {\n';
  code += 'Locale get locale;\n';
  code += '\n';
  if (supportedLocales != null) {
    code += 'static final locales = <String, Type>{\n';
    for (final locale in supportedLocales.entries) {
      code += '\'${locale.key}\': ${locale.value},\n';
    }
    code += '};\n';
    code += '\n';
  }
  code += body;
  code += '}\n';
  return code;
}

class _LanguageClass {
  final String name;
  final String code;

  _LanguageClass({
    required this.name,
    required this.code,
  });
}

_LanguageClass _createClass(
  String body, {
  required String localeName,
  String? supername,
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
  final className = '${supername ?? 'Language'}${capitalizeTag(_localeName)}';
  var code = '';
  code += 'class $className ';
  if (supername != null) {
    code += 'implements $supername ';
  }
  code += '{\n';
  code += 'static const localeName = \'$_localeName\';\n';
  code += '\n';
  if (supername != null) {
    code += '@override\n';
  }
  code += 'final Locale locale;\n';
  code += '\n';
  code += '$className(): locale = Locale.parse(localeName);\n';
  code += '\n';
  code += body;
  code += '}\n';

  return _LanguageClass(
    name: className,
    code: code,
  );
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

String _createGetterOrMethodProxy(
  String name,
  List<String> parameters, {
  required String proxyField,
}) {
  if (parameters.isEmpty) return 'String get $name => $proxyField.$name;\n';
  final parameterList = parameters.map((p) => 'Object $p').join(', ');
  final argumentsList = parameters.join(', ');
  return 'String $name($parameterList) => $proxyField.$name($argumentsList);\n';
}

String _createGetterOrMethodDeclaration(String name, List<String> parameters) {
  if (parameters.isEmpty) return 'String get $name;\n';
  final parameterList = parameters.map((p) => 'Object $p').join(', ');
  return 'String $name($parameterList);\n';
}

String _createGetterOrMethod(
    String name, Expression expression, List<String> parameters) {
  if (parameters.isEmpty) {
    final literal = (expression as LiteralExpression).value;
    return 'String get $name => \'$literal\';\n';
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
