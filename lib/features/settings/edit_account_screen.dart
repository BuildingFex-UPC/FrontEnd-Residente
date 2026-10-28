import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/session_repository.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';

/// Edit the resident's account data.
///
/// The email (login) and the department code are read-only by design: the
/// email identifies the login and the code is assigned by the admin.
class EditAccountScreen extends ConsumerStatefulWidget {
  const EditAccountScreen({super.key});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  late final TextEditingController _name = TextEditingController(
    text: _profile?.name ?? '',
  );
  late final TextEditingController _dni = TextEditingController(
    text: _profile?.dni ?? '',
  );
  late final TextEditingController _address = TextEditingController(
    text: _profile?.address ?? '',
  );
  late final TextEditingController _floor = TextEditingController(
    text: _profile?.floor ?? '',
  );

  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _dni.dispose();
    _address.dispose();
    _floor.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(
      sessionRepositoryProvider.select((repo) => repo.current?.profile),
    );
    final loading = ref.watch(authControllerProvider.select((s) => s.loading));
    final scheme = Theme.of(context).colorScheme;
    final email = profile?.email ?? '—';

    return Scaffold(
      appBar: AppBar(title: Text(ref.tr('set.edit.title'))),
      body: SafeArea(
        child: ListView(
          // Reserve room for the on-screen keyboard so the fields and the
          // save buttons are never covered while typing.
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          children: [
            SectionCard(
              title: ref.tr('set.edit.personal'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ControlledTextField(
                    label: ref.tr('set.profile.name'),
                    value: _name.text,
                    onChanged: (v) => _name.text = v,
                  ),
                  const VerticalGap(12),
                  ControlledTextField(
                    label: ref.tr('set.profile.dni'),
                    value: _dni.text,
                    onChanged: (v) => _dni.text = v,
                    keyboardType: TextInputType.number,
                  ),
                  const VerticalGap(12),
                  ControlledTextField(
                    label: ref.tr('set.profile.address'),
                    value: _address.text,
                    onChanged: (v) => _address.text = v,
                  ),
                  const VerticalGap(12),
                  ControlledTextField(
                    label: ref.tr('set.profile.floor'),
                    value: _floor.text,
                    onChanged: (v) => _floor.text = v,
                  ),
                  const VerticalGap(12),
                  // Email and code are not editable (login identity + admin data).
                  KeyValue(label: ref.tr('set.profile.email'), value: email),
                  if (profile?.code?.isNotEmpty == true)
                    KeyValue(
                      label: ref.tr('set.profile.department'),
                      value: profile!.code!,
                    ),
                  const VerticalGap(16),
                  AppButton(
                    text: ref.tr('set.edit.save'),
                    loading: loading,
                    onPressed: () => _saveProfile(),
                  ),
                ],
              ),
            ),
            const VerticalGap(16),
            SectionCard(
              title: ref.tr('set.edit.password'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ControlledTextField(
                    label: ref.tr('set.edit.new_password'),
                    value: _password.text,
                    onChanged: (v) => _password.text = v,
                    obscure: _obscurePassword,
                    keyboardType: TextInputType.visiblePassword,
                    supportingText: ref.tr('set.edit.password_hint'),
                  ),
                  const VerticalGap(12),
                  ControlledTextField(
                    label: ref.tr('set.edit.confirm_password'),
                    value: _passwordConfirm.text,
                    onChanged: (v) => _passwordConfirm.text = v,
                    obscure: _obscurePassword,
                    keyboardType: TextInputType.visiblePassword,
                  ),
                  const VerticalGap(8),
                  Row(
                    children: [
                      Checkbox(
                        value: !_obscurePassword,
                        onChanged: (v) =>
                            setState(() => _obscurePassword = !(v ?? false)),
                      ),
                      Text(
                        ref.tr('set.edit.show_password'),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const VerticalGap(8),
                  AppOutlinedActionButton(
                    text: ref.tr('set.edit.change_password'),
                    onPressed: () => _savePassword(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  UserProfile? get _profile =>
      ref.read(sessionRepositoryProvider).current?.profile;

  Future<void> _saveProfile() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _name.text,
          dni: _dni.text,
          address: _address.text,
          floor: _floor.text,
        );
    if (!mounted) return;
    if (ok) {
      _showMessage(ref.tr('set.edit.saved'));
      Navigator.of(context).pop();
    } else {
      _showError();
    }
  }

  Future<void> _savePassword() async {
    if (_password.text != _passwordConfirm.text) {
      _showMessage(ref.tr('set.edit.password_mismatch'), error: true);
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .changePassword(_password.text);
    if (!mounted) return;
    if (ok) {
      _password.clear();
      _passwordConfirm.clear();
      _showMessage(ref.tr('set.edit.password_changed'));
    } else {
      _showError();
    }
  }

  void _showError() {
    final message = ref.read(authControllerProvider).error;
    _showMessage(message ?? ref.tr('err.UNEXPECTED_ERROR'), error: true);
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }
}
