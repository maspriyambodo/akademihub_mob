import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/repositories/tv_repository.dart';

class TvBootstrapPage extends StatefulWidget {
  const TvBootstrapPage({super.key});

  @override
  State<TvBootstrapPage> createState() => _TvBootstrapPageState();
}

class _TvBootstrapPageState extends State<TvBootstrapPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;
    if (!sl.isRegistered<TvRepository>()) {
      return;
    }
    final repo = sl<TvRepository>();
    final hasToken = await repo.hasDeviceToken();
    if (!mounted) return;
    if (hasToken) {
      context.go(AppRoutes.tvSignage);
    } else {
      context.go(AppRoutes.tvPairing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('tv_bootstrap_page'),
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'AkademiHub TV',
          style: TextStyle(
            color: Color(0xFF087F75),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


