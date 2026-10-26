import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_residente/core/i18n.dart';

void main() {
  group('AppTexts i18n catalog', () {
    test('resolves Spanish by default', () {
      AppTexts.setLang('es');
      expect(AppTexts.translate('shell.nav.finances'), 'Finanzas');
    });

    test('resolves English after switching language', () {
      AppTexts.setLang('en');
      expect(AppTexts.translate('shell.nav.finances'), 'Finances');
      AppTexts.setLang('es');
    });

    test('replaces placeholders with params', () {
      AppTexts.setLang('es');
      expect(
        AppTexts.format('auth.invite.name', {'name': 'Ana'}),
        'Nombre: Ana',
      );
    });

    test('unknown keys fall back to the key itself', () {
      expect(AppTexts.translate('does.not.exist'), 'does.not.exist');
      expect(AppTexts.translateOrNull('does.not.exist'), isNull);
    });

    test('admin login block message exists in both languages', () {
      AppTexts.setLang('es');
      expect(AppTexts.translateOrNull('err.ADMIN_LOGIN_BLOCKED'), isNotEmpty);
      AppTexts.setLang('en');
      expect(AppTexts.translateOrNull('err.ADMIN_LOGIN_BLOCKED'), isNotEmpty);
      AppTexts.setLang('es');
    });
  });
}
