import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_init_service.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get usuarioAtual {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    return _auth.currentUser;
  }

  Future<void> login({
    required String email,
    required String senha,
  }) async {
    await FirebaseInitService.inicializar();
    await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    await FirebaseInitService.inicializar();
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
    await credencial.user?.updateDisplayName(nome);
  }

  Future<void> logout() async {
    await FirebaseInitService.inicializar();
    await _auth.signOut();
  }

  String mensagemErro(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'invalid-email':
          return 'E-mail inválido.';
        case 'user-not-found':
          return 'Usuário não encontrado.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';
        case 'email-already-in-use':
          return 'Este e-mail já está cadastrado.';
        case 'weak-password':
          return 'A senha deve ter pelo menos 6 caracteres.';
        case 'network-request-failed':
          return 'Sem conexão com a internet.';
        case 'operation-not-allowed':
          return 'Ative o login por e-mail/senha no Firebase Authentication.';
        case 'invalid-api-key':
        case 'api-key-not-valid':
        case 'configuration-not-found':
          return 'Ative o Authentication e o login por e-mail/senha no Firebase.';
        default:
          return 'Erro de autenticação: ${erro.message ?? erro.code}.';
      }
    }

    return 'Ocorreu um erro inesperado.';
  }
}
