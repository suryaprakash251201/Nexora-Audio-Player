import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../ui/theme.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});
  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _controller = TextEditingController();
  bool _testing = false;
  String? _status;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = ref.read(secureStorageProvider);
    final url = await s.getServerUrl();
    if (url != null && mounted) _controller.text = url;
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _status = null;
    });
    final api = ref.read(apiClientProvider);
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() {
        _testing = false;
        _status = 'error';
        _msg = 'Enter server URL (e.g. http://192.168.1.5)';
      });
      return;
    }
    final ok = await api.testConnection(url);
    String details = '';
    if (ok) {
      try {
        final probe = await api.probeServer(url);
        final version =
            probe['/healthz'] is Map && (probe['/healthz']['body'] is Map)
            ? (probe['/healthz']['body']['version'] ?? 'ok')
            : 'ok';
        details = '\nVersion: $version\nNormalized: ${probe['normalized']}';
      } catch (_) {}
    } else {
      try {
        final probe = await api.probeServer(url);
        details = '\nProbe: ${probe.toString().substring(0, 200)}';
      } catch (e) {
        details = '\nError: $e';
      }
    }
    setState(() {
      _testing = false;
      _status = ok ? 'success' : 'error';
      _msg = ok
          ? '✓ Server reachable & API compatible$details'
          : '✗ Could not reach server.\nCheck:\n• Phone & server same Wi-Fi\n• URL is http://192.168.1.5 (no extra path needed)\n• Firewall allows port 80$details';
    });
  }

  Future<void> _save() async {
    final storage = ref.read(secureStorageProvider);
    final url = _controller.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter server URL')));
      return;
    }
    await storage.saveServerUrl(url);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Server saved: $url')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Server')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('NEXORA SERVER'),
                  const SizedBox(height: 8),
                  Text(
                    'Self-hosted or LAN server',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Label('SERVER URL'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    style: TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(
                      hintText:
                          'http://192.168.1.5  or  https://music.example.com',
                    ),
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (_status == 'success'
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _status == 'success'
                              ? AppColors.success
                              : AppColors.error,
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        _msg ?? '',
                        style: TextStyle(
                          color: _status == 'success'
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _testing ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering_rounded),
                      label: const Text('Test Connection'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save & Connect'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tip: For LAN, use http://192.168.x.x:PORT. For production, HTTPS is enforced.',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
