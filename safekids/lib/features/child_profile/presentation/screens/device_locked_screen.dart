import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/lock_service.dart';

class DeviceLockedScreen extends StatefulWidget {
  const DeviceLockedScreen({super.key});

  @override
  State<DeviceLockedScreen> createState() => _DeviceLockedScreenState();
}

class _DeviceLockedScreenState extends State<DeviceLockedScreen> {
  final List<String> _code = [];
  bool _isVerifying = false;
  bool _hasError = false;
  final LockService _lockService = LockService();

  void _addDigit(String digit) {
    if (_code.length >= 6) return;
    setState(() {
      _code.add(digit);
      _hasError = false;
    });
    if (_code.length == 6) _verifyCode();
  }

  void _removeDigit() {
    if (_code.isEmpty) return;
    setState(() => _code.removeLast());
  }

  Future<void> _verifyCode() async {
    setState(() => _isVerifying = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _isVerifying = false; _hasError = true; _code.clear(); });
      return;
    }

    final success = await _lockService.verifyUnlockCode(
      childId: uid,
      code: _code.join(),
    );

    setState(() => _isVerifying = false);

    if (!success) {
      setState(() { _hasError = true; _code.clear(); });
    }
    // Si es exitoso, el stream de childProfile detecta el cambio
    // y child_home_screen.dart deja de mostrar esta pantalla
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2340),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Ícono de candado
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  color: Color(0xFFFF6B6B), size: 52),
            ),

            const SizedBox(height: 28),

            const Text(
              'Dispositivo bloqueado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tu padre/madre bloqueó este dispositivo.\nIngresá el código que te indique para desbloquearlo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Indicadores del código
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _code.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError
                        ? const Color(0xFFFF6B6B)
                        : filled
                            ? const Color(0xFF7B9FFF)
                            : Colors.white24,
                  ),
                );
              }),
            ),

            if (_hasError) ...[
              const SizedBox(height: 16),
              const Text(
                'Código incorrecto. Intentá de nuevo.',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFFFF6B6B)),
              ),
            ],

            const SizedBox(height: 48),

            // Teclado numérico
            if (_isVerifying)
              const CircularProgressIndicator(color: Color(0xFF7B9FFF))
            else
              _buildKeypad(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3'].map(_buildKey).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6'].map(_buildKey).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9'].map(_buildKey).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72),
              _buildKey('0'),
              SizedBox(
                width: 72,
                height: 72,
                child: TextButton(
                  onPressed: _removeDigit,
                  child: const Icon(Icons.backspace_outlined,
                      color: Colors.white54, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit) {
    return GestureDetector(
      onTap: () => _addDigit(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}