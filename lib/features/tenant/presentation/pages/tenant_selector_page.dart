import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../bloc/tenant_bloc.dart';
import '../../domain/entities/tenant_entity.dart';

class TenantSelectorPage extends StatefulWidget {
  const TenantSelectorPage({super.key});

  @override
  State<TenantSelectorPage> createState() => _TenantSelectorPageState();
}

class _TenantSelectorPageState extends State<TenantSelectorPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resolve() {
    if (!_formKey.currentState!.validate()) return;
    context.read<TenantBloc>().add(
      TenantResolveRequested(_controller.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Layar pendek: logo & jarak dikecilkan supaya form + tombol tetap muat.
    final layarPendek = MediaQuery.sizeOf(context).height < 680;
    final sisiLogo = layarPendek ? 60.0 : 80.0;
    final padHalaman = Responsive.pagePadding(context);
    final insetKeyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantActive) {
            context.go(AppRoutes.login);
          }
          if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  // Bisa digulir saat keyboard muncul; padding bawah menyertakan
                  // tinggi keyboard agar tombol tetap terjangkau.
                  padding: EdgeInsets.fromLTRB(
                    padHalaman.left + 8,
                    padHalaman.top,
                    padHalaman.right + 8,
                    padHalaman.bottom + insetKeyboard,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - padHalaman.vertical,
                    ),
                    child: BatasLebarKonten(
                      maxWidth: Responsive.isExpanded(context) ? 420 : 520,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: sisiLogo,
                            height: sisiLogo,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.school,
                              color: Colors.white,
                              size: sisiLogo * 0.55,
                            ),
                          ),
                          SizedBox(height: layarPendek ? 14 : 20),
                          Text(
                            'Temukan sekolah Anda',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: Responsive.fontSize(context, 26),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Masukkan kode sekolah untuk melanjutkan ke ruang belajar yang tepat.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: layarPendek ? 22 : 36),

                          // Input form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _controller,
                                  autocorrect: false,
                                  keyboardType: TextInputType.url,
                                  decoration: const InputDecoration(
                                    labelText: 'Kode sekolah',
                                    hintText: 'contoh: smkn1bdg',
                                    prefixIcon: Icon(Icons.domain),
                                    suffixText: '.akademihub.id',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Kode sekolah wajib diisi';
                                    }
                                    if (!RegExp(
                                      r'^[a-zA-Z0-9\-]+$',
                                    ).hasMatch(val.trim())) {
                                      return 'Hanya huruf, angka, dan tanda hubung';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                if (state is TenantResolved) ...[
                                  _TenantPreviewCard(tenant: state.tenant),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => context
                                        .read<TenantBloc>()
                                        .add(TenantSelected(state.tenant)),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: const Text('Lanjut ke sekolah'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _controller.clear();
                                      context.read<TenantBloc>().add(
                                        TenantLoadSaved(),
                                      );
                                    },
                                    child: const Text('Cari sekolah lain'),
                                  ),
                                ] else ...[
                                  ElevatedButton(
                                    onPressed: state is TenantLoading
                                        ? null
                                        : _resolve,
                                    child: state is TenantLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Temukan sekolah',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          SizedBox(height: layarPendek ? 20 : 32),
                          const _HelpFooter(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TenantPreviewCard extends StatelessWidget {
  final TenantEntity tenant;
  const _TenantPreviewCard({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withAlpha(30),
            child: tenant.logoUrl != null
                ? ClipOval(
                    child: Image.network(
                      tenant.logoUrl!,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.school, color: AppColors.primary),
                    ),
                  )
                : const Icon(Icons.school, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tenant.apiBaseUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}

class _HelpFooter extends StatelessWidget {
  const _HelpFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Tidak tahu kode sekolah Anda?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            // TODO: open browser ke halaman bantuan
          },
          child: const Text(
            'Hubungi Administrator Sekolah',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
