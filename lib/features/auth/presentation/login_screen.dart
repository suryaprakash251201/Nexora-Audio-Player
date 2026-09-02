import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/config/app_config.dart';
import '../../../ui/theme.dart';
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
      const detail = 'Server: configured above';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${failure.message}$code$status',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  detail,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand mark — calm square logo.
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.surfaceRaised,
                      border: Border.all(color: AppColors.border, width: 0.6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.graphic_eq_rounded,
                          size: 26,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'NEXORA',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your music.\nYour control.',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _Label(text: 'SERVER URL'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _serverController,
                    style: TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: 'https://music.example.com',
                      hintStyle: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_savedServerUrl != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Saved: $_savedServerUrl',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _Label(text: 'USERNAME'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userController,
                    style: TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(hintText: 'admin'),
                  ),
                  const SizedBox(height: 20),
                  _Label(text: 'PASSWORD'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passController,
                    obscureText: _obscure,
                    style: TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textDim,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.push('/server-setup'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Test Connection',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onAccent,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                  if (auth.hasError) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.35),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              Failure.fromException(auth.error!).message,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextButton(
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
                                      'Stored session & server cleared.',
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
                    child: const Text(
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
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}
