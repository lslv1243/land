import 'package:intl/locale.dart';
import 'package:land/generated/l10n/l10n.dart';

void main() {
  final proxy = ProxyL10N.loading(Locale.parse('pt'));
  print(proxy.helloWorld);
  proxy.load(Locale.parse('en'));
  print(proxy.helloWorld);
}