import 'package:flutter/material.dart';
import '../../domain/entities/tv_snapshot.dart';
import 'tv_focusable.dart';

class TvSettingsDialog extends StatelessWidget {
  final TvDeviceSummary device;
  final VoidCallback onUnpair;

  const TvSettingsDialog({
    super.key,
    required this.device,
    required this.onUnpair,
  });

  static Future<void> show(
    BuildContext context, {
    required TvDeviceSummary device,
    required VoidCallback onUnpair,
  }) {
    return showDialog(
      context: context,
      builder: (_) => TvSettingsDialog(device: device, onUnpair: onUnpair),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF102A43),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF243B53), width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Pengaturan Perangkat TV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF243B53), height: 28),
              _buildInfoRow('Nama Layar', device.name),
              const SizedBox(height: 12),
              _buildInfoRow('ID Perangkat', '#${device.id}'),
              const SizedBox(height: 12),
              _buildInfoRow('Mode Layar', device.mode.toUpperCase()),
              const SizedBox(height: 28),
              Center(
                child: TvFocusable(
                  autofocus: true,
                  onSelect: () => _confirmUnpair(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB43C46),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_off, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Putuskan Tautan Layar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _confirmUnpair(BuildContext context) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        backgroundColor: const Color(0xFF102A43),
        title: const Text(
          'Konfirmasi Putus Tautan',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Apakah Anda yakin ingin memutuskan layar ini dari sekolah?\n'
          'Anda harus melakukan pairing ulang untuk menghubungkannya kembali.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmContext).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB43C46),
            ),
            onPressed: () {
              Navigator.of(confirmContext).pop();
              Navigator.of(context).pop();
              onUnpair();
            },
            child: const Text(
              'Ya, Putuskan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
