import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pet.dart';
import '../models/servico_info.dart';
import '../services/api_client.dart';
import '../services/pets_service.dart';
import '../services/sessao.dart';
import '../theme/cores.dart';
import 'aviso.dart';
import 'campo_form.dart';

class ModalCadastrarPet extends StatefulWidget {
  const ModalCadastrarPet({super.key});

  static Future<Pet?> show(BuildContext context) {
    return showModalBottomSheet<Pet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModalCadastrarPet(),
    );
  }

  @override
  State<ModalCadastrarPet> createState() => _ModalCadastrarPetState();
}

class _ModalCadastrarPetState extends State<ModalCadastrarPet> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _idade = TextEditingController();
  final _peso = TextEditingController();
  final _raca = TextEditingController();

  final Set<String> _vacinasSelecionadas = {};
  List<String> _sugestoesRaca = [];
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _idade.dispose();
    _peso.dispose();
    _raca.dispose();
    super.dispose();
  }

  void _aoDigitarRaca(String val) {
    if (val.trim().isEmpty) {
      setState(() => _sugestoesRaca = []);
      return;
    }
    final filtro = val.toLowerCase();
    setState(() {
      _sugestoesRaca = racasPopulares
          .where((r) => r.toLowerCase().contains(filtro))
          .take(4)
          .toList();
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final token = sessao.token;
    if (token == null) {
      setState(() => _erro = 'Você precisa estar logado para cadastrar um pet.');
      return;
    }

    final idadeNum = int.tryParse(_idade.text.trim());
    final pesoNum = double.tryParse(_peso.text.trim().replaceAll(',', '.'));

    if (idadeNum == null || idadeNum <= 0) {
      setState(() => _erro = 'Idade inválida.');
      return;
    }
    if (pesoNum == null || pesoNum <= 0) {
      setState(() => _erro = 'Peso inválido.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final novoPet = await apiCreatePet(
        token,
        nome: _nome.text.trim(),
        idade: idadeNum,
        peso: pesoNum,
        raca: _raca.text.trim(),
        vacinas: _vacinasSelecionadas.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(novoPet);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Cores.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Cores.sand,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('🐾', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cadastrar Novo Pet',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Cores.forest,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Cores.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_erro != null) Aviso.erro(_erro!),
              CampoForm(
                controller: _nome,
                rotulo: 'Nome do pet',
                dica: 'Ex: Thor',
                limite: 100,
              ),
              Row(
                children: [
                  Expanded(
                    child: CampoForm(
                      controller: _idade,
                      rotulo: 'Idade (anos)',
                      dica: 'Ex: 3',
                      teclado: TextInputType.number,
                      limite: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampoForm(
                      controller: _peso,
                      rotulo: 'Peso (kg)',
                      dica: 'Ex: 12.5',
                      teclado: const TextInputType.numberWithOptions(decimal: true),
                      limite: 6,
                    ),
                  ),
                ],
              ),
              CampoForm(
                controller: _raca,
                rotulo: 'Raça',
                dica: 'Ex: Golden Retriever ou SRD',
                limite: 100,
                validar: (val) {
                  _aoDigitarRaca(val);
                  return null;
                },
              ),
              if (_sugestoesRaca.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _sugestoesRaca.map((raca) {
                    return ActionChip(
                      label: Text(
                        raca,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Cores.forest,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Cores.border),
                      onPressed: () {
                        _raca.text = raca;
                        setState(() => _sugestoesRaca = []);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Vacinação',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Cores.forest,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vacinasDisponiveis.map((v) {
                  final marcada = _vacinasSelecionadas.contains(v.id);
                  return FilterChip(
                    label: Text(v.label),
                    selected: marcada,
                    selectedColor: Cores.sand,
                    checkmarkColor: Cores.forest,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: marcada ? Cores.forest : Cores.border,
                    ),
                    labelStyle: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: marcada ? FontWeight.w700 : FontWeight.w500,
                      color: Cores.forest,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _vacinasSelecionadas.add(v.id);
                        } else {
                          _vacinasSelecionadas.remove(v.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _salvando ? null : _salvar,
                style: FilledButton.styleFrom(
                  backgroundColor: Cores.forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _salvando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Cadastrar Pet',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
