import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/login_page.dart';
import '../pages/notificacoes_page.dart';
import '../services/sessao.dart';
import '../theme/cores.dart';

class HeaderAuventura extends StatelessWidget implements PreferredSizeWidget {
  const HeaderAuventura({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0.5,
      toolbarHeight: 74,
      titleSpacing: 16,
      title: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Cores.forest,
                    ),
                    children: const [
                      TextSpan(
                        text: 'AU',
                        style: TextStyle(color: Cores.bark),
                      ),
                      TextSpan(text: 'ventura Park'),
                    ],
                  ),
                ),
                Text(
                  'Cuidado para seu pet, tranquilidade para você.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: Cores.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
            actions: [
        ListenableBuilder(
          listenable: sessao,
          builder: (context, _) {
            final token = sessao.token;
            if (token == null) return const SizedBox.shrink();

            return IconButton(
              tooltip: 'Notificações',
              color: Cores.forest,
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NotificacoesPage(token: token),
                  ),
                );
              },
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.only(right: 10),
          child: _MenuUsuario(),
        ),
      ],
    );
  }
}

// O bonequinho: deslogado oferece "Login"; logado mostra o nome e "Sair".
class _MenuUsuario extends StatelessWidget {
  const _MenuUsuario();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sessao,
      builder: (context, _) {
        final usuario = sessao.usuario;
        return PopupMenuButton<String>(
          tooltip: 'Menu do usuário',
          position: PopupMenuPosition.under,
          onSelected: (opcao) {
            if (opcao == 'login') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            } else {
              sessao.sair();
            }
          },
          itemBuilder: (_) => usuario == null
              ? const [
                  PopupMenuItem(
                    value: 'login',
                    child: ListTile(
                      leading: Icon(Icons.login),
                      title: Text('Login'),
                    ),
                  ),
                ]
              : [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'Olá, ${usuario.nome}',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: Cores.forest,
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'sair',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Sair'),
                    ),
                  ),
                ],
          child: CircleAvatar(
            backgroundColor: usuario == null ? Cores.sand : Cores.forest,
            child: usuario == null
                ? const Icon(Icons.person_outline, color: Cores.forest)
                : Text(
                    usuario.nome.isEmpty ? '?' : usuario.nome[0].toUpperCase(),
                    style: GoogleFonts.fraunces(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
