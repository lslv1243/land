import 'package:land/land.dart';

void main(List<String> arguments) {
  final parser = Parser();
  final printer = PrintVisitor();
  final expression = parser.parse('''
You have {count,plural, 
  =0{no items} 
  =1{1 item} 
  other{{count} items}
}.
''');
  expression.visit(printer);

  final applier = ApplyVisitor(
    {'count': 5},
    modifiers: {
      'plural': ApplyVisitorModifierPlural(),
    },
  );
  print(expression.visit(applier));
}

abstract class ApplyVisitorModifier {
  String resolve(MultipleExpression expression, ApplyVisitor visitor);
}

class ApplyVisitorModifierPlural implements ApplyVisitorModifier {
  @override
  String resolve(MultipleExpression expression, ApplyVisitor visitor) {
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
    if (count == 1 && options.contains('one')) return 'one';
    if (count == 2 && options.contains('two')) return 'two';
    return 'other';
  }
}

class ApplyVisitor implements ExpressionVisitor<String> {
  final Map<String, Object> parameters;
  final Map<String, ApplyVisitorModifier> modifiers;

  ApplyVisitor(this.parameters, {this.modifiers = const {}});

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

class PrintVisitor implements ExpressionVisitor<void> {
  var tab = 0;
  var list = 0;

  @override
  void visitLiteral(LiteralExpression expression) {
    print(_tab('[LIT] ${expression.value}'));
  }

  @override
  void visitReference(ReferenceExpression expression) {
    print(_tab('[REF] ${expression.parameter}'));
  }

  @override
  void visitSelect(MultipleExpression expression) {
    print(_tab('[SEL] ${expression.parameter}, ${expression.modifier}'));
    list -= 1;
    tab += 1;
    for (final entry in expression.options.entries) {
      print(_tab('[OPT] ${entry.key}'));
      entry.value.visit(this);
    }
    list += 1;
    tab -= 1;
  }

  @override
  void visitList(ExpressionList expression) {
    print(_tab('[LIST]'));
    tab += 1;
    list += 1;
    for (final expression in expression.expressions) {
      expression.visit(this);
    }
    tab -= 1;
    list -= 1;
  }

  String _tab(String value) {
    var message = '';
    for (var i = 0; i < tab; i += 1) {
      message += ' ';
    }
    if (list > 0) {
      message += '- ';
    }
    message += value;
    return message;
  }
}
