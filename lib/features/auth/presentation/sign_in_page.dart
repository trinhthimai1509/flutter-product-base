import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/error/result.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/responsive.dart';
import '../application/auth_providers.dart';

/// Email/password + guest sign-in. Navigation after success is handled by
/// the router reacting to auth state, not by this page.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  static const minPasswordLength = 6;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  bool _guestSubmitting = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<Result<void>> Function() action,
    void Function(bool) setBusy,
  ) async {
    setState(() => setBusy(true));
    final result = await action();
    if (!mounted) return;
    setState(() => setBusy(false));
    if (result case Err(:final failure)) {
      context.showAppSnackBar(
        failure.localizedMessage(context.l10n),
        type: AppSnackType.error,
      );
    }
  }

  void _signIn() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _run(
      () => ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(_email.text, _password.text),
      (v) => _submitting = v,
    );
  }

  void _guest() => _run(
    () => ref.read(authControllerProvider.notifier).continueAsGuest(),
    (v) => _guestSubmitting = v,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final busy = _submitting || _guestSubmitting;
    final isFake = ref.watch(appConfigProvider).useFakeBackend;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ResponsiveCenter(
              maxWidth: 420,
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.authSignInTitle,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.authSignInSubtitle,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppTextField(
                        controller: _email,
                        label: l10n.authEmailLabel,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        enabled: !busy,
                        validator: (v) =>
                            _emailPattern.hasMatch(v?.trim() ?? '')
                            ? null
                            : l10n.authEmailInvalid,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _password,
                        label: l10n.authPasswordLabel,
                        prefixIcon: Icons.key_outlined,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        enabled: !busy,
                        onSubmitted: (_) => _signIn(),
                        validator: (v) =>
                            (v?.length ?? 0) >= SignInPage.minPasswordLength
                            ? null
                            : l10n.authPasswordTooShort(
                                SignInPage.minPasswordLength,
                              ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: l10n.authSignInButton,
                        onPressed: busy ? null : _signIn,
                        isLoading: _submitting,
                        expand: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: l10n.authContinueAsGuest,
                        variant: AppButtonVariant.secondary,
                        onPressed: busy ? null : _guest,
                        isLoading: _guestSubmitting,
                        expand: true,
                      ),
                      if (isFake) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.authDemoHint,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
