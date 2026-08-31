import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/glass_surface.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});
  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _controller = TextEditingController();
  bool _testing = false;
  String? _status; // null | success | error
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
        _msg = 'Enter server URL';
      });
      return;
    }
    final ok = await api.testConnection(url);
    setState(() {
      _testing = false;
      _status = ok ? 'success' : 'error';
      _msg = ok
          ? '✓ Server reachable & API compatible'
          : '✗ Could not reach server. Check URL and network.';
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
      appBar: AppBar(title: const Text('Server Configuration')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surfaceRaised,
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassSurface(
              opacity: 0.6,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.dns_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nexora Server',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Self-hosted or LAN server',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'https://music.example.com  or  192.168.1.100:3000',
                        hintStyle: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.link,
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_status != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (_status == 'success'
                                      ? AppColors.success
                                      : AppColors.error)
                                  .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _status == 'success'
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        child: Text(
                          _msg ?? '',
                          style: TextStyle(
                            color: _status == 'success'
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _testing ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering),
                      label: const Text('Test Connection'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save & Connect'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tip: For LAN, use http://192.168.x.x:PORT. For production, HTTPS is enforced.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
