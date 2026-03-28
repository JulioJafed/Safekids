import 'package:flutter/material.dart';

class LinkDeviceScreen extends StatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  State<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends State<LinkDeviceScreen> {
  final List<TextEditingController> _controllers =
      List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());
  bool _isLoading = false;
  bool _isLinked = false;
  String _errorMessage = '';

  String get _code =>
      _controllers.map((c) => c.text.toUpperCase()).join();

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 7) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _errorMessage = '');
  }

  Future<void> _verifyCode() async {
    final raw = _code.replaceAll('-', '');
    if (raw.length < 8) {
      setState(() => _errorMessage = 'Ingresá el código completo de 8 caracteres');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });
    await Future.delayed(const Duration(seconds: 2));
    setState(() { _isLoading = false; _isLinked = true; });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF2D3A6B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Vincular dispositivo',
            style: TextStyle(
                color: Color(0xFF2D3A6B),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isLinked ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF7B9FFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.phonelink_rounded,
              color: Color(0xFF7B9FFF), size: 40),
        ),

        const SizedBox(height: 20),

        const Text(
          'Ingresá el código del hijo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3A6B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pedile a tu hijo/a que abra SafeKids y te muestre el código de vinculación',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13, color: Color(0xFF8A94B2), height: 1.5),
        ),

        const SizedBox(height: 36),

        // Campos del código (4 + guión + 4)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B9FFF).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Primeros 4 dígitos
                  ...List.generate(4, (i) => _CodeBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (v) => _onCodeChanged(v, i),
                  )),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—',
                        style: TextStyle(
                            fontSize: 24, color: Color(0xFF8A94B2))),
                  ),
                  // Últimos 4 dígitos
                  ...List.generate(4, (i) => _CodeBox(
                    controller: _controllers[i + 4],
                    focusNode: _focusNodes[i + 4],
                    onChanged: (v) => _onCodeChanged(v, i + 4),
                  )),
                ],
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFFF6B6B)),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B9FFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Vincular dispositivo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Pasos de ayuda
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('¿Cómo obtener el código?',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3A6B))),
              SizedBox(height: 14),
              _HelpStep(num: '1', text: 'Abrí SafeKids en el celular del hijo/a'),
              _HelpStep(num: '2', text: 'Tocá "Vincular dispositivo"'),
              _HelpStep(num: '3', text: 'Aparecerá el código de 8 caracteres'),
              _HelpStep(num: '4', text: 'Ingresalo aquí antes de que expire'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF6ECFB5).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF6ECFB5), size: 60),
        ),

        const SizedBox(height: 24),

        const Text('¡Dispositivo vinculado!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3A6B))),
        const SizedBox(height: 8),
        const Text(
          'Ya podés controlar el celular de tu hijo/a desde esta app',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14, color: Color(0xFF8A94B2), height: 1.5),
        ),

        const SizedBox(height: 32),

        // Info del dispositivo vinculado
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF6ECFB5).withOpacity(0.4)),
          ),
          child: Column(
            children: [
              _LinkedInfo(
                  icon: Icons.phone_android_rounded,
                  label: 'Dispositivo',
                  value: 'Android de Sofía'),
              const Divider(height: 20, color: Color(0xFFF0F4FF)),
              _LinkedInfo(
                  icon: Icons.shield_rounded,
                  label: 'Estado',
                  value: 'Protección activa'),
              const Divider(height: 20, color: Color(0xFFF0F4FF)),
              _LinkedInfo(
                  icon: Icons.access_time_rounded,
                  label: 'Límite diario',
                  value: '2 horas'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B9FFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Ir al panel de control',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;

  const _CodeBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focusNode.hasFocus
              ? const Color(0xFF7B9FFF)
              : const Color(0xFFE8ECF8),
          width: focusNode.hasFocus ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        maxLength: 1,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3A6B),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String num;
  final String text;
  const _HelpStep({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF7B9FFF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B9FFF))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF8A94B2))),
          ),
        ],
      ),
    );
  }
}

class _LinkedInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _LinkedInfo(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6ECFB5), size: 20),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF8A94B2))),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3A6B))),
      ],
    );
  }
}