import 'package:land/land.dart';

void printExpression(Expression expression) {
  expression.visit(_PrintVisitor());
}

class _PrintVisitor implements ExpressionVisitor<void> {
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
