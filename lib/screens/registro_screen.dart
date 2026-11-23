import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _repetirCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _emailCtrl.dispose();
    _contrasenaCtrl.dispose();
    _repetirCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AppScope.of(context).sesion.registrar(
            usuario: _usuarioCtrl.text,
            email: _emailCtrl.text,
            contrasena: _contrasenaCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. ¡Bienvenido!')),
      );
      // Se limpia la pila: no se puede volver al login con "atrás".
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
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
    const separador = SizedBox(height: AppEspacios.m);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
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
                    TextFormField(
                      controller: _usuarioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: AuthService.validarUsuario,
                    ),
                    separador,
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: AuthService.validarEmail,
                    ),
                    separador,
                    TextFormField(
                      controller: _contrasenaCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: AuthService.validarContrasena,
                    ),
                    separador,
                    TextFormField(
                      controller: _repetirCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Repite la contraseña',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      validator: (v) => v != _contrasenaCtrl.text
                          ? 'Las contraseñas no coinciden'
                          : null,
                      onFieldSubmitted: (_) => _registrar(),
                    ),
                    const SizedBox(height: AppEspacios.l),
                    FilledButton(
                      onPressed: _cargando ? null : _registrar,
                      child: _cargando
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Registrarme'),
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
