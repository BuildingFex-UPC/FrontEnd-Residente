import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui.dart';
import 'auth_controller.dart';

/// Login + invite-code activation for residents.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _invitePasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _inviteEmailController.dispose();
    _invitePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandHeader(),
                  const VerticalGap(24),
                  if (state.inviteMode)
                    _InviteSection(
                      state: state,
                      codeController: _codeController,
                      emailController: _inviteEmailController,
                      passwordController: _invitePasswordController,
                    )
                  else
                    _LoginForm(
                      state: state,
                      emailController: _emailController,
                      passwordController: _passwordController,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends ConsumerWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.apartment, size: 64, color: scheme.primary),
        const VerticalGap(12),
        Text(
          ref.tr('shell.appName'),
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const VerticalGap(8),
        Text(
          ref.tr('auth.tagline.main'),
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _LoginForm extends ConsumerWidget {
  const _LoginForm({
    required this.state,
    required this.emailController,
    required this.passwordController,
  });

  final AuthState state;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: ref.tr('auth.field.email')),
        ),
        const VerticalGap(16),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: ref.tr('auth.field.password')),
        ),
        if (state.error != null) ...[
          const VerticalGap(12),
          Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const VerticalGap(20),
        AppButton(
          text: ref.tr('auth.button.login'),
          loading: state.loading,
          onPressed: () => ref
              .read(authControllerProvider.notifier)
              .login(emailController.text, passwordController.text),
        ),
        const VerticalGap(12),
        TextButton(
          onPressed: () =>
              ref.read(authControllerProvider.notifier).openInviteMode(),
          child: Text(ref.tr('auth.link.have_invite')),
        ),
      ],
    );
  }
}

class _InviteSection extends ConsumerWidget {
  const _InviteSection({
    required this.state,
    required this.codeController,
    required this.emailController,
    required this.passwordController,
  });

  final AuthState state;
  final TextEditingController codeController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = state.inviteResident;
    final controller = ref.read(authControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ref.tr('auth.tagline.invite'),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const VerticalGap(16),
        if (resident == null) ...[
          ControlledTextField(
            label: ref.tr('auth.field.invite_code'),
            placeholder: ref.tr('auth.invite.placeholder'),
            supportingText: ref.tr('auth.invite.supporting'),
            errorText: state.inviteError,
            value: state.inviteCode,
            onChanged: controller.onInviteCodeChange,
          ),
          const VerticalGap(16),
          AppButton(
            text: ref.tr('auth.button.find_invite'),
            loading: state.inviteLoading,
            onPressed: controller.lookupInvite,
          ),
        ] else ...[
          Text(
            ref.tr('auth.invite.welcome'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const VerticalGap(8),
          Text(ref.tr('auth.invite.data_ok'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const VerticalGap(8),
          Text(ref.tr('auth.invite.name', {'name': resident.name})),
          Text(ref.tr('auth.invite.code', {'code': resident.code ?? state.inviteCode})),
          if (resident.floor?.isNotEmpty == true)
            Text(ref.tr('auth.invite.floor', {'floor': resident.floor!})),
          const VerticalGap(20),
          Text(
            ref.tr('auth.invite.create_credentials'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const VerticalGap(12),
          ControlledTextField(
            label: ref.tr('auth.field.email'),
            keyboardType: TextInputType.emailAddress,
            value: state.inviteEmail,
            onChanged: controller.onInviteEmailChange,
          ),
          const VerticalGap(12),
          ControlledTextField(
            label: ref.tr('auth.field.password'),
            obscure: true,
            value: state.invitePassword,
            onChanged: controller.onInvitePasswordChange,
          ),
          if (state.inviteError != null) ...[
            const VerticalGap(8),
            Text(state.inviteError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const VerticalGap(16),
          AppButton(
            text: ref.tr('auth.button.access'),
            loading: state.loading,
            onPressed: controller.acceptInvite,
          ),
        ],
        TextButton(onPressed: controller.closeInviteMode, child: Text(ref.tr('auth.link.back_to_login'))),
      ],
    );
  }
}
