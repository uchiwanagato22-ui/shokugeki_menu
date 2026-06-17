import 'package:flutter/material.dart';

import 'restaurant_app_config.dart';
import 'staff_access_service.dart';

class StaffCodeLoginScreen extends StatefulWidget {
  const StaffCodeLoginScreen({
    super.key,
    required this.restaurantId,
    required this.onAccessGranted,
  });

  final String restaurantId;
  final void Function(StaffAccessResult result) onAccessGranted;

  @override
  State<StaffCodeLoginScreen> createState() => _StaffCodeLoginScreenState();
}

class _StaffCodeLoginScreenState extends State<StaffCodeLoginScreen> {
  final _codeController = TextEditingController();
  final _service = StaffAccessService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.verifyCode(
      restaurantId: widget.restaurantId,
      code: _codeController.text,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _error = result.allowed ? null : result.errorMessage;
    });

    if (result.allowed) {
      widget.onAccessGranted(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Acces personnel'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 54),
                  const SizedBox(height: 20),
                  Text(
                    'Code secret personnel',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez le code a 4 chiffres donne par le directeur.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '0000',
                      errorText: _error,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) => _loading ? null : _submit(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(_loading ? 'Verification...' : 'Entrer'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
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
