import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i18n.dart';
import 'language_controller.dart';

/// Reactive translation helper for widgets.
///
/// Watches the language provider so the widget rebuilds on a language change,
/// then resolves [key] (with optional `{placeholder}` [params]) in the active
/// language.
extension I18nX on WidgetRef {
  String tr(String key, [Map<String, String> params = const {}]) {
    watch(languageControllerProvider);
    return AppTexts.format(key, params);
  }
}

/// Brand colors shared with the web/admin apps.
const Color bfPrimary = Color(0xFF3D5AFE);
const Color bfSuccess = Color(0xFF2E7D32);
const Color bfWarning = Color(0xFFED6C02);
const Color bfSurface = Color(0xFFF7F8FC);

/// Dark-mode counterparts of the brand surfaces.
const Color bfSurfaceDark = Color(0xFF121318);
const Color bfCardDark = Color(0xFF1D1F27);

/// Text-safe warning tone (Android `Visual_Contrast`, 4.5:1).
///
/// [bfWarning] only reaches ≈3.1:1 on light backgrounds, so it is fine for
/// large values (20 sp bold) but not for 12-18 sp text: light mode uses a
/// darker orange (≈5.5:1) and dark mode a lighter one (≈7:1), both of which
/// also clear 4.5:1 over the chip's own 12% tint.
Color bfWarningText(Brightness brightness) => brightness == Brightness.dark
    ? const Color(0xFFFF9142)
    : const Color(0xFFAB4E00);

/// Text-safe success tone: [bfSuccess] is 5.1:1 on white but only ≈4.4:1 over
/// its own 12% chip tint in light mode and ≈3.2:1 on dark cards.
Color bfSuccessText(Brightness brightness) => brightness == Brightness.dark
    ? const Color(0xFF66BB6A)
    : const Color(0xFF256B29);

/// Card/sheet background: white in light mode, an elevated dark surface at
/// night (Android Core App Quality: adapt to the system theme).
Color bfCardColor(Brightness brightness) =>
    brightness == Brightness.dark ? bfCardDark : Colors.white;

/// Builds the app theme for the given [brightness] so the same widget tree
/// works in both light and dark mode.
ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(seedColor: bfPrimary, brightness: brightness),
    scaffoldBackgroundColor: isDark ? bfSurfaceDark : bfSurface,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: bfCardColor(brightness),
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}

class VerticalGap extends StatelessWidget {
  const VerticalGap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

/// A titled white card used to group form fields and lists.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.destructive = false,
    this.expand = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool destructive;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(text);
    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: destructive
          ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
          : null,
      child: child,
    );
    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class AppOutlinedActionButton extends StatelessWidget {
  const AppOutlinedActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
        // Android Core App Quality (Accessibility): announce the button role
        // and its disabled state (e.g. a space under maintenance) explicitly.
        button: true,
        enabled: enabled,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: enabled ? onPressed : null,
            child: Text(text),
          ),
        ),
      );
}

/// A controlled text field that keeps its editing controller in sync with the
/// parent state (rebuilds update the field only when the value actually
/// diverges, so the cursor doesn't jump while typing).
class ControlledTextField extends StatefulWidget {
  const ControlledTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.obscure = false,
    this.keyboardType,
    this.supportingText,
    this.errorText,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? supportingText;
  final String? errorText;
  final int maxLines;

  @override
  State<ControlledTextField> createState() => _ControlledTextFieldState();
}

class _ControlledTextFieldState extends State<ControlledTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  /// Visibility of the masked content; only meaningful when [ControlledTextField.obscure] is set.
  bool _visible = false;

  @override
  void didUpdateWidget(covariant ControlledTextField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        obscureText: widget.obscure && !_visible,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.placeholder,
          errorText: widget.errorText,
          helperText: widget.errorText == null ? widget.supportingText : null,
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(
                    _visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: AppTexts.translate(
                    _visible ? 'auth.hide_password' : 'auth.show_password',
                  ),
                  onPressed: () => setState(() => _visible = !_visible),
                )
              : null,
        ),
      );
}

class KeyValue extends StatelessWidget {
  const KeyValue({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}

class FullScreenLoading extends StatelessWidget {
  const FullScreenLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState(this.message, {super.key, this.onRetry, this.retryLabel});

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onRetry, child: Text(retryLabel ?? '↻')),
              ],
            ],
          ),
        ),
      );
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    required this.onDismiss,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  final bool destructive;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: onDismiss, child: const Text('—')),
          TextButton(
            onPressed: onConfirm,
            style: destructive
                ? TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)
                : null,
            child: Text(confirmText),
          ),
        ],
      );
}

/// A small colored chip used for statuses and counters.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Chip text is 12 sp: the warning/success oranges must meet 4.5:1 over
    // the chip's own tint, so swap in the readable tone for the theme.
    final brightness = Theme.of(context).brightness;
    final tone = color == bfWarning
        ? bfWarningText(brightness)
        : color == bfSuccess
            ? bfSuccessText(brightness)
            : color;
    return Semantics(
      // Group the chip so screen readers announce it as a single status
      // (e.g. "En mantenimiento") instead of loose characters.
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(color: tone, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
