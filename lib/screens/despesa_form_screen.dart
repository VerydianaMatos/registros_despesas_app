import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/despesa.dart';
import '../services/auth_service.dart';
import '../services/despesa_service.dart';

class DespesaFormScreen extends StatefulWidget {
  const DespesaFormScreen({super.key});

  @override
  State<DespesaFormScreen> createState() => _DespesaFormScreenState();
}

class _DespesaFormScreenState extends State<DespesaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _despesaService = DespesaService();
  final _authService = AuthService();

  final List<String> _categorias = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Outros',
  ];

  Despesa? _despesa;
  String _categoriaSelecionada = 'Alimentação';
  DateTime _dataSelecionada = DateTime.now();
  bool _carregando = false;
  bool _iniciou = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_iniciou) return;
    _iniciou = true;

    if (_authService.usuarioAtual == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return;
    }

    final argumento = ModalRoute.of(context)?.settings.arguments;
    if (argumento is Despesa) {
      _despesa = argumento;
      _descricaoController.text = argumento.descricao;
      _valorController.text = _formatarValorCampo(argumento.valor);
      _categoriaSelecionada = _categorias.contains(argumento.categoria)
          ? argumento.categoria
          : _categorias.first;
      _dataSelecionada = argumento.data;
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  String _formatarValorCampo(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  double? _converterValor(String valor) {
    final limpo = valor.trim().replaceAll(RegExp(r'[^0-9,.]'), '');

    if (limpo.isEmpty || limpo == ',' || limpo == '.') return null;

    final normalizado = limpo.contains(',')
        ? limpo.replaceAll('.', '').replaceAll(',', '.')
        : limpo;

    return double.tryParse(normalizado);
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _carregando = true);

    final valor = _converterValor(_valorController.text)!;
    final despesa = Despesa(
      id: _despesa?.id ?? '',
      descricao: _descricaoController.text.trim(),
      categoria: _categoriaSelecionada,
      valor: valor,
      data: _dataSelecionada,
    );

    try {
      if (_despesa == null) {
        await _despesaService.criar(despesa).timeout(
              const Duration(seconds: 8),
            );
      } else {
        await _despesaService.editar(despesa).timeout(
              const Duration(seconds: 8),
            );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao salvar. Verifique o Firestore, as regras ou a conexão. Detalhe: $erro',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = _despesa != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar despesa' : 'Nova despesa'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _descricaoController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe a descrição.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _categoriaSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categorias
                      .map(
                        (categoria) => DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() {
                        _categoriaSelecionada = valor;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [_ValorReaisInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (valor) {
                    final numero = _converterValor(valor ?? '');

                    if (numero == null || numero <= 0) {
                      return 'Informe um valor em reais. Ex.: 25,90';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _selecionarData,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Data: ${_formatarData(_dataSelecionada)}'),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _carregando ? null : _salvar,
                  icon: _carregando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(editando ? 'Salvar alterações' : 'Cadastrar'),
                ),
                TextButton(
                  onPressed: _carregando ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValorReaisInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = newValue.text.replaceAll('.', ',');
    final buffer = StringBuffer();
    var encontrouVirgula = false;
    var casasDecimais = 0;

    for (var i = 0; i < texto.length; i++) {
      final caractere = texto[i];

      if (RegExp(r'[0-9]').hasMatch(caractere)) {
        if (encontrouVirgula) {
          if (casasDecimais >= 2) continue;
          casasDecimais++;
        }
        buffer.write(caractere);
      } else if (caractere == ',' && !encontrouVirgula) {
        encontrouVirgula = true;
        buffer.write(',');
      }
    }

    final novoTexto = buffer.toString();

    return TextEditingValue(
      text: novoTexto,
      selection: TextSelection.collapsed(offset: novoTexto.length),
    );
  }
}
