import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'AkademiHub',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masukkan kode atau subdomain sekolah Anda',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

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
                              labelText: 'Kode / Subdomain Sekolah',
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
                              onPressed: () => context.read<TenantBloc>().add(
                                TenantSelected(state.tenant),
                              ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Masuk ke Sekolah Ini'),
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
                                      'Cari Sekolah',
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

                    const SizedBox(height: 32),
                    const _HelpFooter(),
                  ],
                ),
              ),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tenant.apiBaseUrl,
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
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            // TODO: open browser ke halaman bantuan
          },
          child: const Text('Hubungi Administrator Sekolah'),
        ),
      ],
    );
  }
}
