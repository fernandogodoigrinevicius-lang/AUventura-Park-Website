import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/aviso.dart';
import '../components/modal_cadastrar_pet.dart';
import '../components/header_auventura.dart';
import '../models/pet.dart';
import '../services/api_client.dart';
import '../services/pets_service.dart';
import '../services/sessao.dart';
import '../theme/cores.dart';

class MyPetPage extends StatefulWidget {
  const MyPetPage({super.key});

  @override
  State<MyPetPage> createState() => _MyPetPageState();
}

class _MyPetPageState extends State<MyPetPage> {
  List<Pet> _pets = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarPets();
  }

  Future<void> _carregarPets() async {
    final token = sessao.token;
    if (token == null) {
      setState(() => _carregando = false);
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final pets = await apiGetPets(token);
      if (!mounted) return;
      setState(() => _pets = pets);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar seus pets.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _cadastrarPet() async {
    final novoPet = await ModalCadastrarPet.abrir(context);
    if (novoPet != null && mounted) {
      setState(() => _pets.add(novoPet));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${novoPet.nome} cadastrado com sucesso!'),
          backgroundColor: Cores.forest,
        ),
      );
    }
  }

  Future<void> _removerPet(Pet pet) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remover ${pet.nome}?',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w800,
            color: Cores.forest,
          ),
        ),
        content: Text(
          'Tem certeza de que deseja remover este pet da sua lista?',
          style: GoogleFonts.dmSans(color: Cores.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: Cores.muted,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;
    final token = sessao.token;
    if (token == null) return;

    try {
      await apiDeletePet(token, pet.id);
      if (!mounted) return;
      setState(() => _pets.removeWhere((p) => p.id == pet.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pet.nome} removido.'),
          backgroundColor: Cores.forest,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.cream,
      appBar: const HeaderAuventura(),
      body: SafeArea(
        child: RefreshIndicator(
          color: Cores.bark,
          onRefresh: _carregarPets,
          child: ListenableBuilder(
            listenable: sessao,
            builder: (context, _) {
              final usuario = sessao.usuario;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _boasVindas(usuario?.nome ?? 'Tutor'),
                    const SizedBox(height: 16),
                    _info(Icons.person_outline, 'Nome', usuario?.nome ?? '—'),
                    _info(Icons.mail_outline, 'E-mail', usuario?.email ?? '—'),
                    const SizedBox(height: 8),
                    _status(),
                    const SizedBox(height: 28),
                    _secaoPets(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _boasVindas(String nome) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Cores.forest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, color: Cores.bark, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $nome!',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seja bem-vindo(a) à sua Área do Tutor. Aqui você gerencia seus pets e acompanha seus serviços.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icone, String titulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Cores.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Cores.sand,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icone, color: Cores.forest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Cores.forest,
                  ),
                ),
                Text(
                  valor,
                  style: GoogleFonts.dmSans(fontSize: 13, color: Cores.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _status() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D4F),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AUventura Park cuidando com muito amor do seu companheiro!',
              style: GoogleFonts.dmSans(fontSize: 13, color: Cores.forest),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secaoPets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Meus Pets',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Cores.forest,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _cadastrarPet,
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Novo pet',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Cores.bark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_erro != null) Aviso.erro(_erro!),
        if (_carregando) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Cores.bark),
            ),
          ),
        ] else if (_pets.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Cores.border),
            ),
            child: Column(
              children: [
                const Text('🐶', style: TextStyle(fontSize: 34)),
                const SizedBox(height: 10),
                Text(
                  'Você ainda não cadastrou nenhum pet',
                  style: GoogleFonts.fraunces(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Cores.forest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cadastre seu pet para agendar serviços com apenas um toque!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: Cores.muted),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _cadastrarPet,
                  style: FilledButton.styleFrom(
                    backgroundColor: Cores.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Cadastrar Primeiro Pet'),
                ),
              ],
            ),
          ),
        ] else ...[
          ..._pets.map((pet) => _cardPet(pet)),
        ],
      ],
    );
  }

  Widget _cardPet(Pet pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Cores.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Cores.sand,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🐾', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.nome,
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Cores.forest,
                      ),
                    ),
                    Text(
                      pet.raca.isNotEmpty ? pet.raca : 'Sem raça definida',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: Cores.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () => _removerPet(pet),
                tooltip: 'Remover pet',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chipInfo('${pet.idade} ${pet.idade == 1 ? 'ano' : 'anos'}'),
              const SizedBox(width: 8),
              _chipInfo('${pet.peso.toStringAsFixed(1)} kg'),
            ],
          ),
          if (pet.vacinas.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pet.vacinas.map((v) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '✓ $v',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D4F),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipInfo(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Cores.sand.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Cores.forest,
        ),
      ),
    );
  }
}
