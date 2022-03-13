import 'expression.dart';

class Parser {
  Expression parse(String message) {
    late Expression Function(int start, int end) parseLiteral;
    late Expression Function(int start, int end) parseExpression;

    int getClosing(int start, int end) {
      var closing = start;
      var skip = 0;
      while (closing < end) {
        if (message[closing] == '{') {
          skip += 1;
          closing += 1;
          continue;
        }
        if (message[closing] == '}') {
          if (skip > 0) {
            skip -= 1;
            closing += 1;
            continue;
          }
          break;
        }
        closing += 1;
      }
      if (closing >= end || message[closing] != '}' || skip > 0) {
        throw ParserException(
            'Expected "}" character for closing expression at $start.');
      }
      return closing;
    }

    parseLiteral = (int start, int end) {
      var i = start;
      var lastStart = i;
      final expressions = <Expression>[];
      loop:
      while (i < end) {
        switch (message[i]) {
          case '{':
            if (lastStart != i) {
              final literal = message.substring(lastStart, i);
              expressions.add(LiteralExpression(literal));
            }

            final closing = getClosing(i + 1, end);
            expressions.add(parseExpression(i + 1, closing));
            i = closing + 1;
            lastStart = i;
            continue loop;
          case '}':
            throw ParserException('Unexpected "}" character at $i.');
        }
        i += 1;
      }
      // handle overshooting when closing braces
      if (i == end + 1) i -= 1;
      if (i != lastStart) {
        final literal = message.substring(lastStart, i);
        expressions.add(LiteralExpression(literal));
      }
      if (expressions.isEmpty) throw ParserException('Empty expression.');
      return expressions.length == 1
          ? expressions.first
          : ExpressionList(expressions);
    };

    parseExpression = (int start, int end) {
      var i = start;
      var lastStart = i;
      String? parameter;
      String? modifier;
      final options = <String, Expression>{};
      loop:
      while (i < end) {
        switch (message[i]) {
          case ',':
            if (parameter == null) {
              parameter = message.substring(lastStart, i).trim();
              if (parameter.isEmpty) {
                throw ParserException(
                    'Expected parameter before modifier at $i.');
              }
              i += 1;
              lastStart = i;
              continue loop;
            }
            if (modifier == null) {
              modifier = message.substring(lastStart, i).trim();
              if (modifier.isEmpty) {
                throw ParserException(
                    'Expected modifier before options at $i.');
              }
              i += 1;
              lastStart = i;
              continue loop;
            }
            throw ParserException('Unexpected "," character at $i.');
          case '{':
            if (parameter != null && modifier == null) {
              throw ParserException('Unexpected "{" character at $i.');
            }
            final name = message.substring(lastStart, i).trim();
            if (name.isEmpty) {
              throw ParserException(
                  'Expected option name before option at $i.');
            }
            final closing = getClosing(i + 1, end);
            options[name] = parseLiteral(i + 1, closing);
            i = closing + 1;
            lastStart = i;
            continue loop;
        }
        i += 1;
      }
      // if we did not find any parameter, we consider that the expression is just a reference
      if (parameter == null) {
        final name = message.substring(start, end).trim();
        if (name.isEmpty) {
          throw ParserException('Expected reference name at $start.');
        }
        return ReferenceExpression(name);
      }
      if (modifier == null) {
        throw ParserException('Expected modifier for expression at $start.');
      }
      return MultipleExpression(parameter, modifier, options);
    };

    return parseLiteral(0, message.length);
  }
}

class ParserException implements Exception {
  final String message;

  ParserException(this.message);

  @override
  String toString() {
    return '[ParserException] $message';
  }
}
