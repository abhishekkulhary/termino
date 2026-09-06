import 'package:flutter_test/flutter_test.dart';
import 'package:termino/infrastructure/ssh/sockets/hostname_resolver_io.dart';

void main() {
  group('isMulticastName', () {
    test('recognises a .local name', () {
      expect(isMulticastName('my-server.local'), isTrue);
      expect(isMulticastName('My-Server.LOCAL'), isTrue);
      expect(isMulticastName('my-server.local.'), isTrue);
    });

    test('leaves ordinary names to ordinary DNS', () {
      expect(isMulticastName('example.com'), isFalse);
      expect(isMulticastName('localhost'), isFalse);
      expect(isMulticastName('server.localdomain'), isFalse);
    });

    test('leaves an address literal alone', () {
      // Nothing to look up, and a literal is never a .local name.
      expect(isMulticastName('192.168.0.206'), isFalse);
      expect(isMulticastName('::1'), isFalse);
      expect(isMulticastName('fe80::1'), isFalse);
    });
  });
}
