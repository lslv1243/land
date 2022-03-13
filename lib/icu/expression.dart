abstract class ExpressionVisitor {
  void visitList(ExpressionList expression);
  void visitLiteral(LiteralExpression expression);
  void visitSelect(MultipleExpression expression);
  void visitReference(ReferenceExpression expression);
}

abstract class Expression {
  void visit(ExpressionVisitor visitor);
}

class ExpressionList implements Expression {
  final List<Expression> expressions;

  ExpressionList(this.expressions);

  @override
  void visit(ExpressionVisitor visitor) {
    visitor.visitList(this);
  }
}

class LiteralExpression implements Expression {
  final String value;

  LiteralExpression(this.value);

  @override
  void visit(ExpressionVisitor visitor) {
    visitor.visitLiteral(this);
  }
}

class ReferenceExpression implements Expression {
  final String parameter;

  ReferenceExpression(this.parameter);

  @override
  void visit(ExpressionVisitor visitor) {
    visitor.visitReference(this);
  }
}

class MultipleExpression implements Expression {
  final String parameter;
  final String modifier;
  final Map<String, Expression> options;

  MultipleExpression(this.parameter, this.modifier, this.options);

  @override
  void visit(ExpressionVisitor visitor) {
    visitor.visitSelect(this);
  }
}
