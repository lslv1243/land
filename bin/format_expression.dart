import 'package:land/land.dart';

String formatExpression(
  Expression expression, {
  required Map<String, Object> parameters,
}) {
  return expression.visit(_FormatVisitor(
    parameters,
    modifiers: {
      'plural': _FormatVisitorModifierPlural(),
    },
  ));
}

abstract class _FormatVisitorModifier {
  String resolve(MultipleExpression expression, _FormatVisitor visitor);
}

class _FormatVisitorModifierPlural implements _FormatVisitorModifier {
  @override
  String resolve(MultipleExpression expression, _FormatVisitor visitor) {
    final count = visitor.parameters[expression.parameter] as num;
    final countString = count.toString();
    for (final option in expression.options.entries) {
      if (option.key[0] != '=') continue;
      if (option.key.substring(1) == countString) {
        return option.value.visit(visitor);
      }
    }
    final plural = choosePlural(count, expression.options.keys.toSet());
    return expression.options[plural]!.visit(visitor);
  }

  String choosePlural(num count, Set<String> options) {
    // TODO: this is language specific
    return 'other';
  }
}

class _FormatVisitor implements ExpressionVisitor<String> {
  final Map<String, Object> parameters;
  final Map<String, _FormatVisitorModifier> modifiers;

  _FormatVisitor(this.parameters, {this.modifiers = const {}});

  @override
  String visitList(ExpressionList expression) {
    return expression.expressions
        .map((expression) => expression.visit(this))
        .join();
  }

  @override
  String visitLiteral(LiteralExpression expression) {
    return expression.value;
  }

  @override
  String visitReference(ReferenceExpression expression) {
    return parameters[expression.parameter]!.toString();
  }

  @override
  String visitSelect(MultipleExpression expression) {
    final modifier = modifiers[expression.modifier];
    if (modifier != null) {
      return modifier.resolve(expression, this);
    }
    final parameter = parameters[expression.parameter]!.toString();
    return expression.options[parameter]!.visit(this);
  }
}
