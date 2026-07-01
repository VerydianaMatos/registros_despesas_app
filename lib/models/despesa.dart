import 'package:cloud_firestore/cloud_firestore.dart';

class Despesa {
  Despesa({
    required this.id,
    required this.descricao,
    required this.categoria,
    required this.valor,
    required this.data,
  });

  final String id;
  final String descricao;
  final String categoria;
  final double valor;
  final DateTime data;

  factory Despesa.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['data'];

    return Despesa(
      id: id,
      descricao: map['descricao'] ?? '',
      categoria: map['categoria'] ?? '',
      valor: (map['valor'] ?? 0).toDouble(),
      data: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'categoria': categoria,
      'valor': valor,
      'data': Timestamp.fromDate(data),
    };
  }
}
