import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/avatar.dart';
import '../../core/department_number.dart';
import '../../core/invite_codes.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';

/// Edit the resident's account data: personal fields, department (floor is
/// derived from the department number), login email and the profile icon
/// shown in the drawer (a gallery photo).
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
  late final TextEditingController _department = TextEditingController(
    text: _initialDepartment,
  );
  late final TextEditingController _email = TextEditingController(
    text: _profile?.email ?? '',
  );

  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _obscurePassword = true;

  /// Pending avatar (not persisted until "Save changes").
  String? _avatar;

  @override
  void initState() {
    super.initState();
    _avatar = _profile?.avatar;
  }

  @override
  void dispose() {
    _name.dispose();
    _dni.dispose();
    _address.dispose();
    _department.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider.select((s) => s.loading));
    final scheme = Theme.of(context).colorScheme;

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
              title: ref.tr('set.edit.avatar'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ref.tr('set.edit.avatar_hint'),
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const VerticalGap(12),
                  Center(child: AvatarView(avatar: _avatar, radius: 36)),
                  const VerticalGap(12),
                  AppOutlinedActionButton(
                    text: ref.tr('set.edit.avatar_photo'),
                    onPressed: () => _pickPhoto(),
                  ),
                  if (_avatar != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _avatar = null),
                      icon: const Icon(Icons.refresh),
                      label: Text(ref.tr('set.edit.avatar_default')),
                    ),
                ],
              ),
            ),
            const VerticalGap(16),
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
                  // The department is editable; the floor is derived from it
                  // (304 -> floor 3) and sent together with the code.
                  ControlledTextField(
                    label: ref.tr('set.profile.department'),
                    value: _department.text,
                    onChanged: (v) => _department.text = v,
                    keyboardType: TextInputType.number,
                    supportingText: ref.tr('set.edit.department_hint'),
                  ),
                  const VerticalGap(12),
                  // The email is editable (it is the login) but validated by
                  // format and uniqueness on the backend.
                  ControlledTextField(
                    label: ref.tr('set.profile.email'),
                    value: _email.text,
                    onChanged: (v) => _email.text = v,
                    keyboardType: TextInputType.emailAddress,
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
      ref.read(authControllerProvider).session?.profile;

  /// Initial department number shown in the field, derived from the code
  /// ("301-5jhe" → "301"); empty when the account has no code yet.
  String get _initialDepartment {
    final code = _profile?.code;
    if (code == null || code.trim().isEmpty) return '';
    return InviteCodes.departmentOf(code);
  }

  /// Picks a photo, shrinks it (512px max, JPEG) and stores it as a small
  /// data URL so the backend keeps the profile icon self-contained.
  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final dataUrl = _encodeAvatar(bytes);
      if (dataUrl == null) {
        _showMessage(ref.tr('set.edit.avatar_photo_failed'), error: true);
        return;
      }
      setState(() => _avatar = dataUrl);
    } catch (_) {
      // Camera/gallery denied or unavailable: surface a friendly error.
      _showMessage(ref.tr('set.edit.avatar_photo_failed'), error: true);
    }
  }

  /// Re-encodes [bytes] as a compressed JPEG data URL. Returns null when the
  /// image cannot be decoded or stays too large for the backend cap.
  static String? _encodeAvatar(Uint8List bytes, {int quality = 75}) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final resized = decoded.width > 512 || decoded.height > 512
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 512 : null,
            height: decoded.height > decoded.width ? 512 : null,
          )
        : decoded;
    for (var q = quality; q >= 30; q -= 15) {
      final encoded = img.encodeJpg(resized, quality: q);
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(encoded)}';
      // Backend cap is 600k chars; keep a safety margin.
      if (dataUrl.length <= 500_000) return dataUrl;
    }
    return null;
  }

  Future<void> _saveProfile() async {
    // The department encodes floor+unit (304 -> floor 3); parse it so the
    // floor sent to the backend always matches the department number.
    final parsed = DepartmentNumber.parse(_department.text);
    if (parsed == null) {
      _showMessage(ref.tr('err.INVALID_DEPARTMENT_NUMBER'), error: true);
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _name.text,
          dni: _dni.text,
          address: _address.text,
          floor: parsed.floor,
          email: _email.text,
          avatar: _avatar,
          code: _codeForDepartment(parsed.department),
        );
    if (!mounted) return;
    if (ok) {
      _showMessage(ref.tr('set.edit.saved'));
      Navigator.of(context).pop();
    } else {
      _showError();
    }
  }

  /// Rebuilds the resident's code for a new department number, keeping the
  /// random invite suffix so the code stays unique ("301-5jhe" -> "402-5jhe";
  /// a legacy plain "301" -> "402").
  String _codeForDepartment(String department) {
    final current = _profile?.code?.trim() ?? '';
    final dash = current.indexOf('-');
    if (dash >= 0) return '$department${current.substring(dash)}';
    return department;
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
