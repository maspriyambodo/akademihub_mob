import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const _motionCurve = Curves.easeOutCubic;

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    final entrance = CurvedAnimation(
      parent: _entranceController,
      curve: _motionCurve,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(entrance);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(entrance);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = Responsive.pagePadding(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Stack(
          children: [
            const Positioned.fill(
              child: ExcludeSemantics(child: _EducationalBackground()),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSplit = constraints.maxWidth >= 840;
                  final form = _LoginForm(
                    formKey: _formKey,
                    usernameController: _usernameCtrl,
                    passwordController: _passwordCtrl,
                    obscurePassword: _obscurePassword,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: _submit,
                  );

                  final content = isSplit
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(flex: 5, child: _BrandPanel()),
                            const SizedBox(width: 48),
                            Expanded(flex: 4, child: form),
                          ],
                        )
                      : form;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      pagePadding.left + AppSpacing.xs,
                      pagePadding.top + AppSpacing.md,
                      pagePadding.right + AppSpacing.xs,
                      pagePadding.bottom + keyboardInset + AppSpacing.md,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight -
                            pagePadding.vertical -
                            AppSpacing.lg,
                      ),
                      child: Center(
                        child: BatasLebarKonten(
                          maxWidth: isSplit ? 1080 : 460,
                          child: reduceMotion
                              ? content
                              : FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: SlideTransition(
                                    position: _slideAnimation,
                                    child: content,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppElevation.level2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BrandHeader(inverse: true),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Ruang Belajar Digital\nTerpadu & Modern',
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Kelola aktivitas akademik, presensi, tugas, dan nilai dalam satu sistem terintegrasi.',
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _BenefitPoint(
            icon: Icons.menu_book_rounded,
            title: 'Akademik',
            subtitle: 'Jadwal, materi pembelajaran, dan rekap nilai terpusat',
          ),
          const SizedBox(height: AppSpacing.md),
          const _BenefitPoint(
            icon: Icons.how_to_reg_rounded,
            title: 'Kehadiran & Presensi',
            subtitle: 'Pencatatan absensi siswa dan guru secara real-time',
          ),
          const SizedBox(height: AppSpacing.md),
          const _BenefitPoint(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Administrasi & Keuangan',
            subtitle: 'Tagihan SPP dan riwayat transaksi transparan',
          ),
        ],
      ),
    );
  }
}

class _BenefitPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitPoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryLight),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool inverse;
  const _BrandHeader({this.inverse = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: inverse ? AppColors.primaryLight : AppColors.primaryDark,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            color: inverse ? AppColors.primaryDark : AppColors.paperBright,
            size: 26,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RUANG BELAJAR DIGITAL',
                style: TextStyle(
                  color: inverse ? AppColors.primaryLight : AppColors.inkMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'AkademiHub',
                style: TextStyle(
                  color: inverse ? Colors.white : AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BrandHeader(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Selamat datang kembali',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Masuk untuk mengakses layanan ruang belajar digital Anda.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.paperBright,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.55)),
            boxShadow: AppElevation.level2,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: usernameController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (value) {
                    final username = value?.trim() ?? '';
                    if (username.isEmpty) {
                      return 'Username wajib diisi';
                    }
                    if (username.length > 100) {
                      return 'Username maksimal 100 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      tooltip: obscurePassword
                          ? 'Tampilkan password'
                          : 'Sembunyikan password',
                      onPressed: onTogglePassword,
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : onSubmit,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Masuk'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.center,
          child: Text(
            'AkademiHub · Ruang Belajar Nusantara',
            style: textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }
}

class _EducationalBackground extends StatelessWidget {
  const _EducationalBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _EducationalBookLinePainter());
  }
}

class _EducationalBookLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    final lineY1 = size.height * 0.25;
    final lineY2 = size.height * 0.50;
    final lineY3 = size.height * 0.75;

    canvas.drawLine(Offset(0, lineY1), Offset(size.width, lineY1), linePaint);
    canvas.drawLine(Offset(0, lineY2), Offset(size.width, lineY2), linePaint);
    canvas.drawLine(Offset(0, lineY3), Offset(size.width, lineY3), linePaint);

    final curvePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32.0;

    final path = Path();
    path.moveTo(size.width * 0.6, 0);
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.1,
      size.width,
      size.height * 0.25,
    );
    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
