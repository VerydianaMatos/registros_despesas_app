import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/despesa.dart';
import 'firebase_init_service.dart';

class DespesaService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _colecao() {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw Exception('Usuário não autenticado.');
    }

    return _firestore
        .collection('usuarios')
        .doc(usuario.uid)
        .collection('despesas');
  }

  Future<List<Despesa>> listar() async {
    await FirebaseInitService.inicializar();
    final snapshot = await _colecao().orderBy('data', descending: true).get();

    return snapshot.docs
        .map((doc) => Despesa.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> criar(Despesa despesa) async {
    await FirebaseInitService.inicializar();
    await _colecao().add(despesa.toMap());
  }

  Future<void> editar(Despesa despesa) async {
    await FirebaseInitService.inicializar();
    await _colecao().doc(despesa.id).update(despesa.toMap());
  }

  Future<void> remover(String id) async {
    await FirebaseInitService.inicializar();
    await _colecao().doc(id).delete();
  }
}
