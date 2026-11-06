import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pet.dart';
import '../theme/cores.dart';
import 'chip_opcao.dart';
import 'modal_cadastrar_pet.dart';

// "Qual pet vai ser atendido?": um chip por pet e o "+ Cadastrar pet", que
// abre o cadastro sem sair do agendamento. Usado no agendamento comum e no
// Daycare.
class SeletorPet extends StatelessWidget {
  const SeletorPet({
    super.key,
    required this.pets,
    required this.selecionadoId,
    required this.onSelecionar,
    required this.onCadastrado,
    this.carregando = false,
    this.erro,
  });

  final List<Pet> pets;
  final int? selecionadoId;
  final ValueChanged<Pet> onSelecionar;
  final ValueChanged<Pet> onCadastrado;
  final bool carregando;
  final String? erro;

  Future<void> _cadastrar(BuildContext context) async {
    final novoPet = await ModalCadastrarPet.abrir(context);
    if (novoPet == null || !context.mounted) return;
    onCadastrado(novoPet);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${novoPet.nome} cadastrado com sucesso!'),
        backgroundColor: Cores.forest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mensagem = erro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pet in pets)
              ChipOpcao(
                texto: '🐶 ${pet.nome}',
                selecionado: pet.id == selecionadoId,
                onTap: () => onSelecionar(pet),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16, color: Cores.bark),
              label: Text(
                'Cadastrar pet',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Cores.bark,
                ),
              ),
              backgroundColor: Cores.cream,
              side: const BorderSide(color: Cores.bark),
              onPressed: () => _cadastrar(context),
            ),
          ],
        ),
        if (carregando)
          _dica('Carregando seus pets...')
        else if (mensagem != null)
          _dica(mensagem, cor: const Color(0xFFB3261E))
        else if (pets.isEmpty)
          _dica(
            'Você ainda não tem pets cadastrados. Toque em "Cadastrar pet".',
          ),
      ],
    );
  }

  Widget _dica(String texto, {Color cor = Cores.muted}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        texto,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: cor,
        ),
      ),
    );
  }
}
