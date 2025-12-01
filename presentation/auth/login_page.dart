// lib/presentation/auth/login_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _isLogin = true;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  // Anti-spam: cooldown entre envíos
  int _cooldown = 0;
  Timer? _cooldownTimer;

  // Password strength
  double _strength = 0.0;
  String _strengthLabel = 'Débil';

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  // -------------------- Cooldown --------------------
  void _startCooldown([int seconds = 2]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  // -------------------- Validadores --------------------
  InputDecoration _dec(String label, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: const OutlineInputBorder(),
      suffixIcon: suffix,
    );
  }

  String? _emailValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Ingresa tu correo';
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!re.hasMatch(t)) return 'Correo no válido';
    return null;
  }

  // Regla robusta para negocio:
  //  - >= 8 chars
  //  - al menos 1 minúscula, 1 mayúscula, 1 dígito
  //  - opcional: 1 símbolo
  String? _passwordValidator(String? v) {
    final t = (v ?? '');
    if (t.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[a-z]').hasMatch(t)) return 'Incluye al menos 1 minúscula';
    if (!RegExp(r'[A-Z]').hasMatch(t)) return 'Incluye al menos 1 mayúscula';
    if (!RegExp(r'\d').hasMatch(t)) return 'Incluye al menos 1 número';
    // opcional: símbolos
    // if (!RegExp(r'[!@#\$%\^&\*\-_+=\.,;:]').hasMatch(t)) return 'Incluye un símbolo';
    return null;
  }

  void _recalcStrength(String v) {
    // cálculo simple de fuerza
    double s = 0;
    if (v.length >= 8) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(v)) s += 0.25;
    if (RegExp(r'[a-z]').hasMatch(v)) s += 0.2;
    if (RegExp(r'\d').hasMatch(v)) s += 0.2;
    if (RegExp(r'[!@#\$%\^&\*\-_+=\.,;:]').hasMatch(v)) s += 0.1;

    String label;
    if (s < 0.35) {
      label = 'Débil';
    } else if (s < 0.65) {
      label = 'Media';
    } else if (s < 0.9) {
      label = 'Fuerte';
    } else {
      label = 'Muy fuerte';
    }

    setState(() {
      _strength = s.clamp(0.0, 1.0);
      _strengthLabel = label;
    });
  }

  // -------------------- Acciones --------------------
  Future<void> _submit() async {
    if (_loading || _cooldown > 0) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final auth = ref.read(authActionsProvider);
    try {
      if (_isLogin) {
        await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
        if (!mounted) return;

        // Si tu proyecto requiere confirmación por email, informa claramente:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registro realizado. Revisa tu correo para confirmar la cuenta antes de iniciar sesión.',
            ),
          ),
        );
      }
      // No navegamos manualmente. GoRouter redirige cuando hay sesión.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _startCooldown(2);
    }
  }

  Future<void> _forgotPassword() async {
    if (_loading || _cooldown > 0) return;

    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Enviar')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(authActionsProvider).resetPassword(emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo enviado (si existe una cuenta asociada).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
      _startCooldown(2);
    }
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 72, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(value: true, label: Text('Iniciar sesión'), icon: Icon(Icons.login)),
                        ButtonSegment<bool>(value: false, label: Text('Registrarme'), icon: Icon(Icons.person_add_alt)),
                      ],
                      selected: {_isLogin},
                      onSelectionChanged: (s) => setState(() => _isLogin = s.first),
                    ),
                    const SizedBox(height: 16),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: _dec('Nombre para mostrar', icon: Icons.badge_outlined),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Ingresa tu nombre (lo puedes cambiar luego).';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            decoration: _dec('Correo', icon: Icons.email_outlined),
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure1,
                            textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                            onEditingComplete: _isLogin ? _submit : null,
                            autofillHints: const [AutofillHints.password],
                            decoration: _dec(
                              'Contraseña',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                tooltip: _obscure1 ? 'Mostrar' : 'Ocultar',
                                onPressed: () => setState(() => _obscure1 = !_obscure1),
                                icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                              ),
                            ),
                            onChanged: _recalcStrength,
                            validator: _passwordValidator,
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 6),
                            // Indicador de fuerza
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: _strength,
                                      minHeight: 7,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_strengthLabel),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pass2Ctrl,
                              obscureText: _obscure2,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: _submit,
                              decoration: _dec(
                                'Repetir contraseña',
                                icon: Icons.lock_reset_outlined,
                                suffix: IconButton(
                                  tooltip: _obscure2 ? 'Mostrar' : 'Ocultar',
                                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                                  icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                                ),
                              ),
                              validator: (v) {
                                if (v != _passCtrl.text) return 'No coincide con la contraseña';
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: (_loading || _cooldown > 0) ? null : _forgotPassword,
                          icon: const Icon(Icons.mail_lock_outlined),
                          label: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Botón principal con cooldown
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: (_loading || _cooldown > 0) ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(
                          _cooldown > 0
                              ? (_isLogin ? 'Entrar ($_cooldown)' : 'Registrarme ($_cooldown)')
                              : (_isLogin ? 'Entrar' : 'Registrarme'),
                        ),
                      ),
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tras registrarte, revisa tu correo para confirmar tu cuenta (según ajustes de Supabase).',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    Opacity(
                      opacity: .7,
                      child: Text(
                        'Tus credenciales se validan con Supabase Auth. '
                            'Usa una contraseña segura y no la compartas.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
