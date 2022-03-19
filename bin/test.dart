import 'package:land/generated/l10n/l10n.dart';

void main() {
  final proxy = ProxyL10N.loading('pt');
  print(proxy.helloWorld);
  proxy.load('en');
  print(proxy.helloWorld);
}