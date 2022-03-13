import 'package:intl/intl.dart';
import 'package:land/land.dart';

import 'format_expression.dart';

void main(List<String> arguments) {
  final parser = Parser();
  final expression = parser.parse('''You have {count,plural, 
  =0{no {any,plural, =1{deep} other{how}} items} 
  =1{one item} 
  other{{count} items}
}.''');
  // print(formatExpression(expression, parameters: {'count': 0}));
  print(generateEntryCode('batata', expression));
  // print(batata(7));
}

Set<String> _findParameters(Expression expression) {
  final parameters = <String>{};
  if (expression is ReferenceExpression) {
    parameters.add(expression.parameter);
  } else if (expression is MultipleExpression) {
    parameters.add(expression.parameter);
    for (final option in expression.options.values) {
      parameters.addAll(_findParameters(option));
    }
  } else if (expression is ExpressionList) {
    for (final expression in expression.expressions) {
      parameters.addAll(_findParameters(expression));
    }
  }
  return parameters;
}

String generateEntryCode(String name, Expression expression) {
  final varCreator = _VarCreator();
  if (expression is LiteralExpression) {
    return 'String get $name => \'${expression.value}\';\n';
  }
  if (expression is ReferenceExpression) {
    return 'String $name(Object ${expression.parameter}) {\n'
        '  return ${expression.parameter}.toString();\n'
        '}\n';
  }
  if (expression is ExpressionList) {
    // TODO: should have extracted parameters previously, or else
    //  we can not guarantee order when changing language
    final parameters = _findParameters(expression);
    final parameterList = parameters.map((p) => 'Object $p').join(', ');
    var code = 'String $name($parameterList) {\n';
    var pre = '';
    void prepend(String value) => pre += value;
    final values = <String>[];
    for (final expression in expression.expressions) {
      values.add(_value(expression, varCreator: varCreator, prepend: prepend));
    }
    code += pre + 'return ${values.join(' + ')};\n';
    code += '}\n';
    return code;
  } else {
    throw UnimplementedError();
  }
}

String _value(
  Expression expression, {
  required _VarCreator varCreator,
  required void Function(String) prepend,
}) {
  if (expression is LiteralExpression) {
    return '\'${expression.value}\'';
  } else if (expression is ReferenceExpression) {
    return '${expression.parameter}.toString()';
  } else if (expression is ExpressionList) {
    final values = <String>[];
    var code = '';
    for (final inner in expression.expressions) {
      values.add(_value(inner, varCreator: varCreator, prepend: prepend));
    }
    code += values.join(' + ');
    return code;
  } else if (expression is MultipleExpression) {
    final name = varCreator.create();
    prepend(_multiple(name, expression, varCreator));
    return name;
  } else {
    throw UnimplementedError();
  }
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
