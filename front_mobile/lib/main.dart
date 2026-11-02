import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/services_page.dart';
import 'pages/testimonials_page.dart';
import 'pages/contact_page.dart';
import 'pages/my_pet_page.dart';
import 'services/sessao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Abre já logado com o que está salvo; a validação no back vem depois,
  // sem travar a abertura do app se o servidor estiver fora do ar.
  await sessao.carregar();
  runApp(const AuventuraApp());
  sessao.validar();
}

class AuventuraApp extends StatelessWidget {
  const AuventuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AUventura Park',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDF8F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D4A3E),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // A aba My Pet só existe logado, sempre na última posição.
  static const _indiceMyPet = 4;

  int currentIndex = 0;
  late bool _logado = sessao.logado;

  @override
  void initState() {
    super.initState();
    sessao.addListener(_aoMudarSessao);
  }

  @override
  void dispose() {
    sessao.removeListener(_aoMudarSessao);
    super.dispose();
  }

  void _aoMudarSessao() {
    setState(() {
      if (sessao.logado && !_logado) currentIndex = _indiceMyPet;
      if (!sessao.logado && currentIndex == _indiceMyPet) currentIndex = 0;
      _logado = sessao.logado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomePage(onIrParaServicos: () => setState(() => currentIndex = 1)),
          const ServicesPage(),
          const TestimonialsPage(),
          const ContactPage(),
          if (_logado) const MyPetPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Serviços',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Depoimentos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: 'Contato',
          ),
          if (_logado)
            const NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'My Pet',
            ),
        ],
      ),
    );
  }
}