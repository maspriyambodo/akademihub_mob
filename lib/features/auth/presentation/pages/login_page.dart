import 'package:flutter/cupertino.dart';
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
  static const _motionCurve = Cubic(0.32, 0.72, 0, 1);

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
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
      duration: const Duration(milliseconds: 700),
    );
    final entrance = CurvedAnimation(
      parent: _entranceController,
      curve: _motionCurve,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(entrance);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(entrance);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortScreen = MediaQuery.sizeOf(context).height < 680;
    final pagePadding = Responsive.pagePadding(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSplit = constraints.maxWidth >= 840;
              final form = _LoginContent(
                formKey: _formKey,
                emailController: _emailCtrl,
                passwordController: _passwordCtrl,
                obscurePassword: _obscurePassword,
                shortScreen: shortScreen,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _submit,
              );
              final content = isSplit
                  ? Row(
                      children: [
                        const Expanded(flex: 5, child: _BrandPanel()),
                        const SizedBox(width: 56),
                        Expanded(flex: 4, child: form),
                      ],
                    )
                  : form;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  pagePadding.left + 8,
                  pagePadding.top,
                  pagePadding.right + 8,
                  pagePadding.bottom + keyboardInset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - pagePadding.vertical,
                  ),
                  child: BatasLebarKonten(
                    maxWidth: isSplit ? 1080 : 520,
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 560),
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 56),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(inverse: true),
          const Spacer(),
          Text(
            'Satu ruang untuk\nsetiap langkah belajar.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontSize: 38,
              height: 1.08,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Jadwal hari ini, tugas berikutnya, dan perkembangan akademik tetap dekat.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withAlpha(180),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 34),
          const Row(
            children: [
              Icon(
                CupertinoIcons.check_mark_circled,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Data sekolah tersinkron aman',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool shortScreen;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _LoginContent({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.shortScreen,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BrandMark(),
        SizedBox(height: shortScreen ? 22 : 36),
        Text(
          'Kembali ke ruang belajar Anda.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Masuk untuk melihat jadwal, tugas, nilai, dan kabar sekolah terbaru.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: shortScreen ? 24 : 36),
        _DoubleBezel(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(CupertinoIcons.envelope, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(CupertinoIcons.lock, size: 20),
                    suffixIcon: IconButton(
                      tooltip: obscurePassword
                          ? 'Tampilkan password'
                          : 'Sembunyikan password',
                      onPressed: onTogglePassword,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: const Cubic(0.32, 0.72, 0, 1),
                        switchOutCurve: const Cubic(0.4, 0, 1, 1),
                        child: Icon(
                          obscurePassword
                              ? CupertinoIcons.eye_slash
                              : CupertinoIcons.eye,
                          key: ValueKey(obscurePassword),
                          size: 20,
                        ),
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
                SizedBox(height: shortScreen ? 18 : 24),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : onSubmit,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: const Cubic(0.32, 0.72, 0, 1),
                        child: isLoading
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                key: ValueKey('ready'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Masuk'),
                                  SizedBox(width: 12),
                                  _ButtonIsland(),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: shortScreen ? 16 : 24),
        Align(
          alignment: Alignment.center,
          child: Text(
            'AkademiHub · v1.0.0',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _DoubleBezel extends StatelessWidget {
  final Widget child;
  const _DoubleBezel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withAlpha(18)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withAlpha(12),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final bool inverse;
  const _BrandMark({this.inverse = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: inverse ? Colors.white.withAlpha(20) : AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(CupertinoIcons.book, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 12),
        Text(
          'AKADEMIHUB',
          style: TextStyle(
            color: inverse ? Colors.white : AppColors.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ButtonIsland extends StatelessWidget {
  const _ButtonIsland();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: const Icon(CupertinoIcons.arrow_right, size: 14),
    );
  }
}
