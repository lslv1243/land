import 'package:land/land.dart';

void main(List<String> arguments) {
  final parser = Parser();
  final printer = PrintVisitor();
  final expression = parser.parse('''
'You have {count,plural, 
  =0{no items} 
  =1{1 item} 
  other{{count} items}
}.'
''');
  expression.visit(printer);

  final applier = ApplyVisitor({'count': '=1'});
  print(expression.visit(applier));
}

class ApplyVisitor implements ExpressionVisitor<String> {
  final Map<String, Object> parameters;

  ApplyVisitor(this.parameters);

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
    final option = parameters[expression.parameter]!.toString();
    return expression.options[option]!.visit(this);
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
