import 'package:flutter/material.dart';

import '../models/notificacao.dart';
import '../services/api_client.dart';
import '../services/notificacoes_service.dart';
import '../theme/cores.dart';

enum _Acao { marcarComoLida, excluir }

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key, required this.token});

  final String token;

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  late Future<List<Notificacao>> _notificacoes;
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _notificacoes = apiGetNotificacoes(widget.token);
  }

  void _atualizar() {
    setState(() {
      _notificacoes = apiGetNotificacoes(widget.token);
    });
  }

  Future<void> _executar(_Acao acao, Notificacao notificacao) async {
    if (_processando) return;

    if (acao == _Acao.excluir) {
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir notificação?'),
          content: Text(notificacao.titulo),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );

      if (!mounted || confirmou != true || _processando) return;
    }

    setState(() => _processando = true);
    try {
      switch (acao) {
        case _Acao.marcarComoLida:
          await apiMarcarNotificacaoComoLida(widget.token, notificacao.id);
          break;
        case _Acao.excluir:
          await apiExcluirNotificacao(widget.token, notificacao.id);
          break;
      }

      if (mounted) _atualizar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.mensagem)),
      );
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.cream,
      appBar: AppBar(
        title: const Text('Notificações'),
        foregroundColor: Cores.forest,
        backgroundColor: Cores.cream,
        actions: [
          IconButton(
            tooltip: 'Atualizar notificações',
            onPressed: _processando ? null : _atualizar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Notificacao>>(
        future: _notificacoes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _atualizar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final notificacoes = snapshot.data!;
          if (notificacoes.isEmpty) {
            return const Center(child: Text('Você ainda não tem notificações.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notificacoes.length,
            itemBuilder: (context, index) {
              final notificacao = notificacoes[index];
              final data = notificacao.criadoEm;

              return Card(
                color: notificacao.lida ? Colors.white : Cores.sand,
                child: ListTile(
                  leading: Icon(
                    notificacao.lida
                        ? Icons.notifications_none
                        : Icons.notifications_active_outlined,
                    color: Cores.forest,
                    semanticLabel: notificacao.lida ? 'Lida' : 'Não lida',
                  ),
                  title: Text(
                    notificacao.titulo,
                    style: TextStyle(
                      fontWeight: notificacao.lida
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    data == null
                        ? notificacao.mensagem
                        : '${notificacao.mensagem}\n'
                            '${MaterialLocalizations.of(context).formatShortDate(data)}',
                  ),
                  trailing: PopupMenuButton<_Acao>(
                    tooltip: 'Opções da notificação',
                    enabled: !_processando,
                    onSelected: (acao) => _executar(acao, notificacao),
                    itemBuilder: (context) => [
                      if (!notificacao.lida)
                        const PopupMenuItem(
                          value: _Acao.marcarComoLida,
                          child: Text('Marcar como lida'),
                        ),
                      const PopupMenuItem(
                        value: _Acao.excluir,
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}