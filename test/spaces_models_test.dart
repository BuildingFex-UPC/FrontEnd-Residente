import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_residente/features/spaces/socialspaces_models.dart';

void main() {
  group('Space.fromJson cost', () {
    test('parses the decimal cost exposed by the compat API', () {
      final space = Space.fromJson(const {
        'id': 'salon-1',
        'name': 'Salón social',
        'capacity': 20,
        'cost': 25.5,
      });
      expect(space.cost, 25.5);
    });

    test('accepts integer costs coming from numeric(10,2)', () {
      final space = Space.fromJson(const {
        'id': 'terraza-1',
        'name': 'Terraza',
        'cost': 30,
      });
      expect(space.cost, 30);
    });

    test('defaults to 0 (free) when the API omits the field', () {
      final space = Space.fromJson(const {'id': 'parrilla', 'name': 'Parrilla'});
      expect(space.cost, 0);
    });
  });
}
