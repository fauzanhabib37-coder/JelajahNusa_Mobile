import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class AuthScreen extends StatefulWidget {
  final AppState state;
  const AuthScreen({super.key, required this.state});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool register = false, busy = false, obscure = true;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (register) {
        await widget.state.register(name.text, email.text, password.text);
      } else {
        await widget.state.login(email.text, password.text);
      }
      // Pop back to AppShell after successful auth (AppState notifyListeners
      // will rebuild all screens automatically).
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is AppException
              ? e.message
              : 'Belum dapat masuk. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                const Art(
                  'assets/illustrations/hero_nusantara.webp',
                  height: 245,
                  width: double.infinity,
                  radius: 0,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Nusa.bg.withValues(alpha: 0.15),
                          Nusa.bg.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Brand(),
                      const SizedBox(height: 55),
                      Text(
                        'Cerita baru,\nlangkah pertamamu.',
                        style: Nusa.heading(27),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        register ? 'Buat akun' : 'Selamat datang',
                        style: Nusa.heading(29),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        register
                            ? 'Mulai perjalanan mengenal Nusantara.'
                            : 'Masuk dan lanjutkan perjalanan belajarmu.',
                        style: const TextStyle(color: Nusa.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 28),
                      if (register) ...[
                        _label('Nama penjelajah'),
                        TextFormField(
                          key: const Key('auth_name'),
                          controller: name,
                          enabled: !busy,
                          maxLength: 40,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          validator: (v) => AppState.nameError(v ?? ''),
                          decoration: const InputDecoration(
                            hintText: 'Nama lengkap',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _label('Email'),
                      TextFormField(
                        key: const Key('auth_email'),
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.username],
                        validator: (v) => AppState.emailError(v ?? ''),
                        decoration: const InputDecoration(
                          hintText: 'nama@contoh.id',
                        ),
                      ),
                      const SizedBox(height: 20),
                      _label('Kata sandi'),
                      TextFormField(
                        key: const Key('auth_password'),
                        controller: password,
                        enabled: !busy,
                        obscureText: obscure,
                        maxLength: 128,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: [
                          register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        validator: (v) => (v?.length ?? 0) < (register ? 8 : 1)
                            ? (register
                                  ? 'Gunakan minimal 8 karakter.'
                                  : 'Masukkan kata sandi.')
                            : null,
                        onFieldSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          hintText: register
                              ? 'Minimal 8 karakter'
                              : 'Kata sandi akun lokal',
                          counterText: '',
                          suffixIcon: IconButton(
                            tooltip: obscure
                                ? 'Tampilkan kata sandi'
                                : 'Sembunyikan kata sandi',
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Nusa.red,
                              fontSize: 12,
                            ),
                            semanticsLabel: 'Kesalahan: $error',
                          ),
                        ),
                      const SizedBox(height: 28),
                      FilledButton(
                        key: const Key('auth_submit'),
                        onPressed: busy ? null : submit,
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                register ? 'Daftar & mulai jelajah' : 'Masuk',
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const Key('auth_toggle'),
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                register = !register;
                                error = null;
                                form.currentState?.reset();
                              }),
                        child: Text(
                          register
                              ? 'Sudah punya akun? Masuk'
                              : 'Belum punya akun? Daftar',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Akun dan progres tersimpan pada perangkat ini. Gunakan email sebagai pengenal akun lokal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Nusa.muted,
                          fontSize: 10,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _label(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
    ),
  );
}
