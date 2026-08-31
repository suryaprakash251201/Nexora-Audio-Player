import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/failures.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/config/app_config.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/glass_surface.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _serverController = TextEditingController();
  final _userController = TextEditingController(text: 'admin');
  final _passController = TextEditingController();
  bool _obscure = true;
  String? _savedServerUrl;

  @override
  void initState() {
    super.initState();
    _loadSavedServer();
  }

  Future<void> _loadSavedServer() async {
    final storage = ref.read(secureStorageProvider);
    final url = await storage.getServerUrl();
    if (mounted && url != null) {
      setState(() => _savedServerUrl = url);
      // Prefill input with user-friendly short form (strip /api/v1 for display)
      final display = url.replaceAll('/api/v1', '').replaceAll('/api', '');
      _serverController.text = display;
    }
  }

  Future<void> _handleLogin() async {
    final serverRaw = _serverController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text;
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and password required')),
      );
      return;
    }
    // Determine effective server URL for diagnostics
    String effectiveServer = serverRaw;
    if (effectiveServer.isEmpty) {
      final storage = ref.read(secureStorageProvider);
      final saved = await storage.getServerUrl();
      effectiveServer = saved ?? AppConfig.fallbackBaseUrl;
      if (effectiveServer.isEmpty) effectiveServer = 'http://192.168.1.5';
    } else {
      effectiveServer = AppConfig.normalizeUrl(effectiveServer);
    }

    try {
      await ref.read(authStateProvider.notifier).login(user, pass, serverRaw);
      if (mounted) context.go('/');
    } catch (e) {
      final failure = Failure.fromException(e);
      final code = failure.code != null ? ' [${failure.code}]' : '';
      final status = failure.statusCode != null
          ? ' (${failure.statusCode})'
          : '';
      final detail = 'Server: $effectiveServer';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${failure.message}$code$status',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (failure.message.toLowerCase().contains('invalid') ||
                    failure.message.toLowerCase().contains('unauthorized'))
                  const Text(
                    'Hint: For Nexora, username is "admin" and check password. Ensure server is http://192.168.1.5',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isLoading = auth.isLoading;

    return Scaffold(
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
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nexora',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Audiophile Player',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (_savedServerUrl != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Saved: $_savedServerUrl',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _field(
                      controller: _serverController,
                      hint: 'http://192.168.1.5',
                      icon: Icons.dns_outlined,
                      helper:
                          'LAN: http://192.168.1.5  •  Leave empty to use saved',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => context.push('/server-setup'),
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          label: const Text(
                            'Configure Server',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.push('/server-setup'),
                          child: const Text(
                            'Test Connection',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    _field(
                      controller: _userController,
                      hint: 'Username (admin)',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passController,
                      obscureText: _obscure,
                      style: const TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: AppColors.textDim),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.textMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Try admin / amma@123 for testing',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Connect & Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (auth.hasError)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                Failure.fromException(auth.error!).message,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Self-hosted • LAN supported • Offline ready\nIf login fails, check server is http://192.168.1.5 and both devices on same Wi-Fi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const Key('clear-stored-session'),
                      onPressed: isLoading
                          ? null
                          : () async {
                              try {
                                final storage = ref.read(secureStorageProvider);
                                await storage.deleteToken();
                                await storage.deleteServerUrl();
                                if (mounted) {
                                  setState(() {
                                    _savedServerUrl = null;
                                    _serverController.clear();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Stored session & server cleared. Re-enter server URL and log in.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Clear failed: $e')),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.cleaning_services, size: 14),
                      label: const Text(
                        'Clear stored session',
                        style: TextStyle(fontSize: 11),
                      ),
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

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(color: AppColors.textDim, fontSize: 10),
          ),
        ],
      ],
    );
  }
}
