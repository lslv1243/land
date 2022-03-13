abstract class ExpressionVisitor<T> {
  T visitList(ExpressionList expression);
  T visitLiteral(LiteralExpression expression);
  T visitSelect(MultipleExpression expression);
  T visitReference(ReferenceExpression expression);
}

abstract class Expression {
  T visit<T>(ExpressionVisitor<T> visitor);
}

class ExpressionList implements Expression {
  final List<Expression> expressions;

  ExpressionList(this.expressions);

  @override
  T visit<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitList(this);
  }
}

class LiteralExpression implements Expression {
  final String value;

  LiteralExpression(this.value);

  @override
  T visit<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitLiteral(this);
  }
}

class ReferenceExpression implements Expression {
  final String parameter;

  ReferenceExpression(this.parameter);

  @override
  T visit<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitReference(this);
  }
}

class MultipleExpression implements Expression {
  final String parameter;
  final String modifier;
  final Map<String, Expression> options;

  MultipleExpression(this.parameter, this.modifier, this.options);

  @override
  T visit<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitSelect(this);
  }
}
