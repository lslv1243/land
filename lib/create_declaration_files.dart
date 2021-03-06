import 'package:intl/intl.dart';
import 'package:intl/locale.dart';
import 'package:land/land.dart';

class DeclarationFile {
  final String name;
  final String code;

  DeclarationFile({required this.name, required this.code});
}

class DeclarationField {
  final String name;
  final List<DeclarationFieldParameter> parameters;

  DeclarationField(this.name, this.parameters);
}

class DeclarationFieldParameter {
  final String name;
  final String? type;

  DeclarationFieldParameter(this.name, [this.type]);
}

List<DeclarationFile> createDeclarationFiles({
  required List<DeclarationField> fields,
  required Map<String, Map<String, String>> locales,
  String className = 'L10N',
  bool emitProxy = false,
  bool emitSupportedLocales = false,
  bool emitProxyLoader = false,
  bool emitFlutterGlue = false,
}) {
  if (emitProxyLoader) {
    if (!emitProxy) {
      throw Exception(
          'It is necessary to emit proxy to emit the proxy loader.');
    }
    if (!emitSupportedLocales) {
      throw Exception(
          'It is necessary to emit supported locales to emit the proxy loader.');
    }
  }
  if (emitFlutterGlue) {
    if (!emitSupportedLocales) {
      throw Exception(
          'It is necessary to emit supported locales to emit the flutter glue.');
    }
  }

  final declarations = <DeclarationFile>[];

  final parent = _LanguageSuper(
    fileName: '${className.toLowerCase()}.dart',
    className: className,
  );

  final languagesDeclarationsFiles = <String>[];
  String? proxyDeclarationFile;
  final localesClasses = <Locale, String>{};

  if (emitProxy) {
    final proxyDeclaration = _createProxyDeclaration(
      fields,
      parent: parent,
      emitLoader: emitProxyLoader,
      useFlutterIntl: emitFlutterGlue,
    );
    final file = 'proxy_${className.toLowerCase()}.dart';
    proxyDeclarationFile = file;
    declarations.add(DeclarationFile(
      name: file,
      code: proxyDeclaration,
    ));
  }

  // for faster lookup
  final fieldsMap = {for (var field in fields) field.name: field};
  for (final locale in locales.entries) {
    final localeObj = Locale.parse(locale.key);
    final declaration = _createLanguageDeclaration(
      localeObj,
      locale.value,
      fieldsMap,
      parent: parent,
      useFlutterIntl: emitFlutterGlue,
    );

    final file = '${className.toLowerCase()}_${locale.key.toLowerCase()}.dart';
    languagesDeclarationsFiles.add(file);
    localesClasses[localeObj] = declaration.className;
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
    emitFlutterGlue: emitFlutterGlue,
  );
  declarations.add(DeclarationFile(
    name: parent.fileName,
    code: superDeclaration,
  ));

  return declarations;
}

String _createProxyDeclaration(
  List<DeclarationField> fields, {
  required _LanguageSuper parent,
  String proxyField = 'proxy',
  bool emitLoader = false,
  bool useFlutterIntl = false,
}) {
  var body = '';
  for (final field in fields) {
    body += '@override\n';
    body += _createGetterOrMethodProxy(
      field.name,
      field.parameters,
      proxyField: proxyField,
    );
    body += '\n';
  }

  final classCode = _createProxyClass(
    body,
    supername: parent.className,
    proxyField: proxyField,
    emitLoader: emitLoader,
  );

  var code = '';
  if (useFlutterIntl) {
    code += 'import \'dart:ui\';\n';
  } else {
    code += 'import \'package:intl/locale.dart\';\n';
  }
  code += '\n';
  code += 'import \'${parent.fileName}\';\n';
  code += '\n';
  code += classCode;
  return code;
}

String _createSuperDeclaration(
  List<DeclarationField> fields, {
  required String className,
  Map<Locale, String>? supportedLocales,
  List<String>? languagesDeclarationsFiles,
  String? proxyDeclarationFile,
  bool emitFlutterGlue = false,
}) {
  var body = '';
  for (final field in fields) {
    body += _createGetterOrMethodDeclaration(
      field.name,
      field.parameters,
    );
    body += '\n';
  }
  _DelegateClass? delegateClass;
  if (emitFlutterGlue) {
    delegateClass = _createFlutterDelegateClass(supername: className);
  }
  final classCode = _createSuperClass(
    body,
    name: className,
    supportedLocales: supportedLocales,
    flutterDelegateClass: delegateClass?.name,
    useFlutterIntl: emitFlutterGlue,
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
  if (emitFlutterGlue) {
    code += 'import \'package:flutter/foundation.dart\';\n';
    code += 'import \'package:flutter/widgets.dart\';\n';
    code +=
        'import \'package:flutter_localizations/flutter_localizations.dart\';\n';
  } else {
    code += 'import \'package:intl/locale.dart\';\n';
  }
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
  if (delegateClass != null) {
    code += '\n';
    code += delegateClass.code;
  }
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
  Locale locale,
  Map<String, String> messages,
  Map<String, DeclarationField> fieldsMap, {
  _LanguageSuper? parent,
  bool useFlutterIntl = false,
}) {
  final parser = Parser();
  var body = '';

  // make sure we have all fields declared in this locale
  for (final field in fieldsMap.values) {
    if (!messages.containsKey(field.name)) {
      throw Exception(
          'Missing message for field named "${field.name}" in locale "$locale".');
    }
  }

  for (final message in messages.entries) {
    final field = fieldsMap[message.key];
    if (field == null) {
      throw Exception(
          'Unexpected field named "${message.key}" in locale "$locale".');
    }
    final expression = parser.parse(message.value);
    if (parent != null) {
      body += '@override\n';
    }
    body += _createGetterOrMethod(
      message.key,
      expression,
      field.parameters,
    );
    body += '\n';
  }

  final _class = _createClass(
    body,
    locale: locale,
    supername: parent?.className,
    useFlutterIntl: useFlutterIntl,
  );

  var code = '';
  code += 'import \'package:intl/intl.dart\';\n';
  if (useFlutterIntl) {
    code += 'import \'dart:ui\';\n';
  } else {
    code += 'import \'package:intl/locale.dart\';\n';
  }
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
  required bool emitLoader,
}) {
  final className = 'Proxy$supername';
  var code = '';
  code += 'class $className implements $supername {\n';
  code += '@override\n';
  code += 'Locale get locale => $proxyField.locale;\n';
  code += '\n';
  code += '$supername $proxyField;\n';
  code += '\n';
  if (emitLoader) {
    code += 'void load(Locale locale) {\n';
    code += '$proxyField = $supername.locales[locale]!;\n';
    code += '}\n';
    code += '\n';
    code += 'factory $className.loading(Locale locale) {\n';
    code += 'final proxy = $supername.locales[locale]!;\n';
    code += 'return $className(proxy);\n';
    code += '}\n';
    code += '\n';
  }
  code += '$className(this.$proxyField);\n';
  code += '\n';
  code += body;
  code += '}\n';
  return code;
}

class _DelegateClass {
  final String name;
  final String code;

  _DelegateClass({
    required this.name,
    required this.code,
  });
}

_DelegateClass _createFlutterDelegateClass({required String supername}) {
  final classname = '_${supername}Delegate';
  var code = 'class $classname extends LocalizationsDelegate<$supername> {\n';
  code += 'const $classname();\n';
  code += '\n';
  code += '@override\n';
  code += 'Future<$supername> load(Locale locale) {\n';
  code += 'return SynchronousFuture<$supername>($supername.locales[locale]!);\n';
  code += '}\n';
  code += '@override\n';
  code +=
      'bool isSupported(Locale locale) => $supername.supportedLocales.contains(locale);\n';
  code += '\n';
  code += '@override\n';
  code += 'bool shouldReload($classname old) => false;\n';
  code += '}\n';
  return _DelegateClass(name: classname, code: code);
}

String _createSuperClass(
  String body, {
  required String name,
  Map<Locale, String>? supportedLocales,
  required String? flutterDelegateClass,
  required bool useFlutterIntl,
}) {
  var code = '';
  code += 'abstract class $name {\n';
  code += 'Locale get locale;\n';
  code += '\n';
  if (supportedLocales != null) {
    code += 'static final locales = <Locale, $name>{\n';
    for (final locale in supportedLocales.entries) {
      final localeCode = locale.key.forCode(useFlutterIntl);
      code += '$localeCode: ${locale.value}(),\n';
    }
    code += '};\n';
    code += '\n';
    code += 'static final supportedLocales = <Locale>[\n';
    for (final locale in supportedLocales.entries) {
      final localeCode = locale.key.forCode(useFlutterIntl);
      code += '$localeCode,\n';
    }
    code += '];\n';
    code += '\n';
  }
  if (flutterDelegateClass != null) {
    code += 'static $name of(BuildContext context) {\n';
    code += 'return Localizations.of<$name>(context, $name)!;\n';
    code += '}\n';
    code += '\n';
    code +=
        'static const LocalizationsDelegate<$name> delegate = $flutterDelegateClass();\n';
    code += '\n';
    code +=
        'static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[\n';
    code += 'delegate,\n';
    code += 'GlobalMaterialLocalizations.delegate,\n';
    code += 'GlobalCupertinoLocalizations.delegate,\n';
    code += 'GlobalWidgetsLocalizations.delegate,\n';
    code += '];\n';
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
  required Locale locale,
  String? supername,
  required bool useFlutterIntl,
}) {
  String capitalizeTag(String tag) {
    return tag
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }

  final localeName = Intl.canonicalizedLocale(locale.toLanguageTag());
  final className = '${supername ?? 'Language'}${capitalizeTag(localeName)}';
  var code = '';
  code += 'class $className ';
  if (supername != null) {
    code += 'implements $supername ';
  }
  code += '{\n';
  code += 'static const localeName = \'$localeName\';\n';
  code += '\n';
  if (supername != null) {
    code += '@override\n';
  }
  code += 'final Locale locale;\n';
  code += '\n';
  final localeCode = locale.forCode(useFlutterIntl);
  code += '$className(): locale = $localeCode;\n';
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
    if (expression.expressions.isEmpty) {
      return '\'\'';
    }
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
    return '\'${_cleanLiteral(expression.value)}\'';
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
      code += 'switch (${expression.parameter}.toString()){\n';

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
  List<DeclarationFieldParameter> parameters, {
  required String proxyField,
}) {
  if (parameters.isEmpty) return 'String get $name => $proxyField.$name;\n';
  final parameterList = parameters.forCode();
  final argumentsList = parameters.map((p) => p.name).join(', ');
  return 'String $name($parameterList) => $proxyField.$name($argumentsList);\n';
}

String _createGetterOrMethodDeclaration(
    String name, List<DeclarationFieldParameter> parameters) {
  if (parameters.isEmpty) return 'String get $name;\n';
  final parameterList = parameters.forCode();
  return 'String $name($parameterList);\n';
}

String _createGetterOrMethod(String name, Expression expression,
    List<DeclarationFieldParameter> parameters) {
  if (parameters.isEmpty) {
    final literal = (expression as LiteralExpression).value;
    return 'String get $name => \'${_cleanLiteral(literal)}\';\n';
  }

  final usingParameters = _usingParameters(expression);
  for (final parameter in usingParameters) {
    final index = parameters.indexWhere((p) => p.name == parameter);
    if (index == -1) {
      throw Exception(
          'Parameter named "$parameter" not declared in field named "$name".');
    }
  }

  final parameterList = parameters.forCode();
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

extension on List<DeclarationFieldParameter> {
  String forCode() {
    return map((parameter) {
      final type = parameter.type ?? 'Object';
      return '$type ${parameter.name}';
    }).join(', ');
  }
}

extension on Locale {
  String forCode(bool flutterIntl) {
    var code = 'Locale.fromSubtags(languageCode: \'$languageCode\'';
    if (countryCode != null) {
      code += ', countryCode: \'$countryCode\'';
    }
    if (scriptCode != null) {
      code += ', scriptCode: \'$scriptCode\'';
    }
    code += ')';
    return code;
  }
}

String _cleanLiteral(String literal) {
  return literal.replaceAll('\n', '\\n').replaceAll('\'', '\\\'');
}
