import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../bloc/auth_bloc.dart';

const _night = Color(0xFF061A2C);
const _electricCyan = Color(0xFF18D5C4);
const _sunset = Color(0xFFFFC857);
const _ultraviolet = Color(0xFF7479FF);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const _motionCurve = Cubic(0.32, 0.72, 0, 1);

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
    final shortScreen = MediaQuery.sizeOf(context).height < 680;
    final pagePadding = Responsive.pagePadding(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: _night,
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
            const Positioned.fill(child: _FutureBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSplit = constraints.maxWidth >= 840;
                  final form = _LoginContent(
                    formKey: _formKey,
                    usernameController: _usernameCtrl,
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
    return Container(
      height: 560,
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 56),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123B59), Color(0xFF092338)],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Color(0x3318D5C4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4418D5C4),
            blurRadius: 56,
            spreadRadius: -24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(inverse: true),
          const Spacer(),
          Text(
            'Masa depanmu\ndimulai hari ini.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontSize: 38,
              height: 1.08,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Semua aktivitas sekolah terhubung dalam satu orbit digital.',
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
                  'Koneksi data sekolah terenkripsi',
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
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool shortScreen;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _LoginContent({
    required this.formKey,
    required this.usernameController,
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
          'Selamat datang\nkembali.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontSize: 36,
            height: 1.04,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Masuk ke pusat kendali belajarmu.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white60),
        ),
        SizedBox(height: shortScreen ? 24 : 36),
        _DoubleBezel(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: usernameController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(CupertinoIcons.person, size: 20),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white38,
              letterSpacing: 1,
            ),
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
        color: _electricCyan.withAlpha(12),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _electricCyan.withAlpha(50)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xEE102A40),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
            const BoxShadow(color: Color(0x3318D5C4), blurRadius: 24),
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
            gradient: const LinearGradient(
              colors: [_electricCyan, _ultraviolet],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(CupertinoIcons.book, color: _night, size: 21),
        ),
        const SizedBox(width: 12),
        Text(
          'AKADEMIHUB',
          style: TextStyle(
            color: Colors.white,
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

class _FutureBackground extends StatelessWidget {
  const _FutureBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: Stack(
        children: const [
          Positioned(
            left: -120,
            top: -100,
            child: _GlowOrb(color: _electricCyan),
          ),
          Positioned(
            right: -150,
            top: 220,
            child: _GlowOrb(color: _ultraviolet),
          ),
          Positioned(left: 40, bottom: -190, child: _GlowOrb(color: _sunset)),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  const _GlowOrb({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 360,
    height: 360,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withAlpha(50), color.withAlpha(0)],
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(7)
      ..strokeWidth = 1;
    const gap = 42.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
