import 'package:land/land.dart';

import 'format_expression.dart';

void main(List<String> arguments) {
  final parser = Parser();
  final expression = parser.parse('''
You have {count,plural, 
  =0{no items} 
  =1{one item} 
  other{{count} items}
}.
''');
  print(formatExpression(expression, parameters: {'count': 0}));
}
