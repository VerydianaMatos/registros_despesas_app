import 'package:flutter/material.dart';

import '../models/despesa.dart';
import '../services/auth_service.dart';
import '../services/despesa_service.dart';

class DespesaScreen extends StatefulWidget {
  const DespesaScreen({super.key});

  @override
  State<DespesaScreen> createState() => _DespesaScreenState();
}

class _DespesaScreenState extends State<DespesaScreen> {
  final _despesaService = DespesaService();
  final _authService = AuthService();
  final Set<String> _despesasOcultas = {};
  late Future<List<Despesa>> _futureDespesas;

  final List<String> _categorias = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Outros',
  ];

  String _filtroCategoria = 'Todas';

  @override
  void initState() {
    super.initState();
    if (_authService.usuarioAtual == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      _futureDespesas = Future.value([]);
      return;
    }
    _carregarDespesas();
  }

  void _carregarDespesas() {
    _futureDespesas = _despesaService.listar();
  }

  Future<void> _atualizarLista() async {
    setState(_carregarDespesas);
    await _futureDespesas;
  }

  Future<void> _sair() async {
    await _authService.logout();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _abrirFormulario({Despesa? despesa}) async {
    final salvou = await Navigator.pushNamed(
      context,
      '/despesa-form',
      arguments: despesa,
    );

    if (salvou == true && mounted) {
      setState(_carregarDespesas);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            despesa == null
                ? 'Despesa cadastrada com sucesso.'
                : 'Despesa atualizada com sucesso.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmarRemocao(Despesa despesa) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover despesa'),
          content: Text('Deseja remover "${despesa.descricao}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmou == true) {
      await _removerDespesa(despesa);
    }
  }

  Future<void> _removerDespesa(Despesa despesa) async {
    setState(() {
      _despesasOcultas.add(despesa.id);
    });

    try {
      await _despesaService.remover(despesa.id);

      if (!mounted) return;
      setState(_carregarDespesas);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Despesa removida com sucesso.')),
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _despesasOcultas.remove(despesa.id);
        _carregarDespesas();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover despesa: $erro')),
      );
    }
  }

  List<Despesa> _filtrar(List<Despesa> despesas) {
    final despesasVisiveis = despesas
        .where((despesa) => !_despesasOcultas.contains(despesa.id))
        .toList();

    if (_filtroCategoria == 'Todas') {
      return despesasVisiveis;
    }

    return despesasVisiveis
        .where((despesa) => despesa.categoria == _filtroCategoria)
        .toList();
  }

  double _total(List<Despesa> despesas) {
    return despesas.fold(0, (total, despesa) => total + despesa.valor);
  }

  double _media(List<Despesa> despesas) {
    if (despesas.isEmpty) return 0;
    return _total(despesas) / despesas.length;
  }

  String _maiorCategoria(List<Despesa> despesas) {
    if (despesas.isEmpty) return '-';

    final totais = <String, double>{};
    for (final despesa in despesas) {
      totais[despesa.categoria] =
          (totais[despesa.categoria] ?? 0) + despesa.valor;
    }

    return totais.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Map<String, double> _totaisPorMes(List<Despesa> despesas) {
    final totais = <String, double>{};

    for (final despesa in despesas) {
      final chave = _formatarMes(despesa.data);
      totais[chave] = (totais[chave] ?? 0) + despesa.valor;
    }

    return totais;
  }

  double _mediaMensal(List<Despesa> despesas) {
    final totais = _totaisPorMes(despesas);

    if (totais.isEmpty) return 0;

    final total = totais.values.fold(0.0, (soma, valor) => soma + valor);
    return total / totais.length;
  }

  String _formatarMoeda(double valor) {
    final partes = valor.abs().toStringAsFixed(2).split('.');
    final reais = partes[0];
    final centavos = partes[1];
    final buffer = StringBuffer();

    for (var i = 0; i < reais.length; i++) {
      final restantes = reais.length - i - 1;
      buffer.write(reais[i]);

      if (restantes > 0 && restantes % 3 == 0) {
        buffer.write('.');
      }
    }

    final sinal = valor < 0 ? '- ' : '';
    return '${sinal}R\$ ${buffer.toString()},$centavos';
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  String _formatarMes(DateTime data) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return '${meses[data.month - 1]}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Despesas'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _atualizarLista,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _sair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<Despesa>>(
        future: _futureDespesas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar despesas:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final todasDespesas = snapshot.data ?? [];
          final despesas = _filtrar(todasDespesas);
          final totaisMensais = _totaisPorMes(todasDespesas);

          return RefreshIndicator(
            onRefresh: _atualizarLista,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ResumoDespesas(
                  total: _formatarMoeda(_total(despesas)),
                  quantidade: despesas.length,
                  media: _formatarMoeda(_media(despesas)),
                  maiorCategoria: _maiorCategoria(despesas),
                ),
                const SizedBox(height: 12),
                _HistoricoMensal(
                  totaisMensais: totaisMensais,
                  mediaMensal: _formatarMoeda(_mediaMensal(todasDespesas)),
                  formatarMoeda: _formatarMoeda,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _filtroCategoria,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por categoria',
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: ['Todas', ..._categorias]
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
                        _filtroCategoria = valor;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (todasDespesas.isEmpty)
                  const _EstadoVazio(
                    texto: 'Nenhuma despesa cadastrada.',
                    detalhe: 'Toque no botão + para registrar a primeira.',
                  )
                else if (despesas.isEmpty)
                  const _EstadoVazio(
                    texto: 'Nenhuma despesa nesta categoria.',
                    detalhe: 'Troque o filtro ou cadastre uma nova despesa.',
                  )
                else
                  ...despesas.map(
                    (despesa) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DespesaCard(
                        despesa: despesa,
                        valorFormatado: _formatarMoeda(despesa.valor),
                        dataFormatada: _formatarData(despesa.data),
                        onEditar: () => _abrirFormulario(despesa: despesa),
                        onRemover: () => _confirmarRemocao(despesa),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Despesa'),
      ),
    );
  }
}

class _DespesaCard extends StatelessWidget {
  const _DespesaCard({
    required this.despesa,
    required this.valorFormatado,
    required this.dataFormatada,
    required this.onEditar,
    required this.onRemover,
  });

  final Despesa despesa;
  final String valorFormatado;
  final String dataFormatada;
  final VoidCallback onEditar;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  child: Text(
                    despesa.categoria.isEmpty
                        ? '?'
                        : despesa.categoria[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        despesa.descricao,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        despesa.categoria,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6E6E6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'Valor',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        valorFormatado,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Data: $dataFormatada',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRemover,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoricoMensal extends StatelessWidget {
  const _HistoricoMensal({
    required this.totaisMensais,
    required this.mediaMensal,
    required this.formatarMoeda,
  });

  final Map<String, double> totaisMensais;
  final String mediaMensal;
  final String Function(double valor) formatarMoeda;

  @override
  Widget build(BuildContext context) {
    final entradas = totaisMensais.entries.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 20),
              const SizedBox(width: 8),
              Text(
                'Gastos por mês',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Média mensal: $mediaMensal',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          if (entradas.isEmpty)
            const Text(
              'Ainda não há meses anteriores para comparar.',
              style: TextStyle(color: Colors.black54),
            )
          else
            ...entradas.take(6).map(
                  (entrada) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entrada.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          formatarMoeda(entrada.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ResumoDespesas extends StatelessWidget {
  const _ResumoDespesas({
    required this.total,
    required this.quantidade,
    required this.media,
    required this.maiorCategoria,
  });

  final String total;
  final int quantidade;
  final String media;
  final String maiorCategoria;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total registrado',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                total,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ResumoItem(
                titulo: 'Itens',
                valor: quantidade.toString(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ResumoItem(
                titulo: 'Média',
                valor: media,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ResumoItem(
                titulo: 'Maior gasto',
                valor: maiorCategoria,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResumoItem extends StatelessWidget {
  const _ResumoItem({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({
    required this.texto,
    required this.detalhe,
  });

  final String texto;
  final String detalhe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            detalhe,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
