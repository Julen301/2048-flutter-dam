import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/titulo_juego.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identificadorCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  bool _cargando = false;
  bool _ocultar = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se precarga el último jugador guardado en preferencias (B.3).
    if (_identificadorCtrl.text.isEmpty) {
      AppScope.of(context).preferencias.leerUltimoJugador().then((nombre) {
        if (mounted && nombre != null && _identificadorCtrl.text.isEmpty) {
          _identificadorCtrl.text = nombre;
        }
      });
    }
  }

  @override
  void dispose() {
    _identificadorCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AppScope.of(context)
          .sesion
          .iniciarSesion(_identificadorCtrl.text, _contrasenaCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppEspacios.l),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppTamanos.anchoMaxFormulario),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TituloJuego(),
                    const SizedBox(height: AppEspacios.l),
                    Text('Inicia sesión para jugar',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppEspacios.xl),
                    TextFormField(
                      controller: _identificadorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuario o email',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: AppEspacios.m),
                    TextFormField(
                      controller: _contrasenaCtrl,
                      obscureText: _ocultar,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                          icon: Icon(_ocultar
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                      onFieldSubmitted: (_) => _entrar(),
                    ),
                    const SizedBox(height: AppEspacios.l),
                    FilledButton(
                      onPressed: _cargando ? null : _entrar,
                      child: _cargando
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: AppEspacios.s),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.pushNamed(context, AppRoutes.registro),
                      child: const Text('¿No tienes cuenta? Regístrate'),
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
