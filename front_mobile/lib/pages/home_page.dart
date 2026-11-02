import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/header_auventura.dart';
import '../theme/cores.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onIrParaServicos});

  final VoidCallback? onIrParaServicos;

  static const cream = Cores.cream;
  static const sand = Cores.sand;
  static const bark = Cores.bark;
  static const forest = Cores.forest;
  static const muted = Cores.muted;
  static const border = Cores.border;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: const HeaderAuventura(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 38),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(),
              const SizedBox(height: 24),
              _stats(),
              const SizedBox(height: 36),
              _services(),
              const SizedBox(height: 36),
              _whyChooseUs(),
              const SizedBox(height: 36),
              _cta(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: forest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 3,
                  backgroundColor: bark,
                ),
                SizedBox(width: 8),
                Text(
                  'SÃO PAULO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(
                fontSize: 37,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              children: const [
                TextSpan(text: 'O melhor '),
                TextSpan(
                  text: 'lar temporário',
                  style: TextStyle(
                    color: bark,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextSpan(text: ' do seu cão'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Na AUventura Park, seu pet é tratado como família. '
            'Segurança, socialização e carinho em cada momento do dia.',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.55,
              color: Colors.white.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Agendar agora'),
              style: FilledButton.styleFrom(
                backgroundColor: bark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('Ver depoimentos'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: '🐶',
            value: '200+',
            label: 'Cães\natendidos',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: '⭐',
            value: '4.9',
            label: 'Avaliação\nmédia',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: '🏡',
            value: '5/7',
            label: 'Dias na\nsemana',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: forest,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              height: 1.2,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _services() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTag('SERVIÇOS'),
        const SizedBox(height: 12),
        Text(
          'Tudo que seu pet precisa',
          style: GoogleFonts.fraunces(
            fontSize: 29,
            fontWeight: FontWeight.w900,
            color: forest,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha o serviço ideal e agende com poucos cliques.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: muted,
          ),
        ),
        const SizedBox(height: 20),
        _serviceCard(
          icon: Icons.home_outlined,
          title: 'Daycare',
          description:
              'Seu cão passa o dia se divertindo com outros pets em ambiente seguro e supervisionado.',
        ),
        _serviceCard(
          icon: Icons.content_cut,
          title: 'Banho & Tosa',
          description:
              'Banho, secagem e tosa profissional com cuidado e produtos de qualidade.',
        ),
        _serviceCard(
          icon: Icons.school_outlined,
          title: 'Adestramento',
          description:
              'Sessões focadas em obediência, comportamento e boas maneiras.',
        ),
        _serviceCard(
          icon: Icons.groups_outlined,
          title: 'Socialização',
          description:
              'Atividades em grupo para desenvolver habilidades sociais e gastar energia.',
        ),
      ],
    );
  }

  Widget _sectionTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF0E8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: const Color(0xFFE8622A),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: sand,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: forest,
              size: 27,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: forest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.5,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _whyChooseUs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: sand,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por que escolher a AUventura Park?',
            style: GoogleFonts.fraunces(
              fontSize: 29,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: forest,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Somos especialistas em bem-estar animal. Nossa equipe é treinada '
            'para cuidar do seu pet com segurança e afeto.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.6,
              color: muted,
            ),
          ),
          const SizedBox(height: 20),
          _checkItem('Espaço amplo e higienizado diariamente'),
          _checkItem('Monitoramento em tempo real'),
          _checkItem('Equipe certificada em primeiros socorros'),
          _checkItem('Relatório diário de atividades'),
          _checkItem('Ambiente separado por porte'),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/why-image.jpg',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: forest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        color: forest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Text(
            'Pronto para dar o primeiro passo?',
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 29,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Agende uma visita gratuita e conheça nosso espaço com o seu pet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onIrParaServicos,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text(
                'Fazer meu primeiro agendamento',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: bark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}