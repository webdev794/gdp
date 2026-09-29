import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class OtpVerificationSheet extends StatefulWidget {
  final String emailOrPhone;
  final String purpose; // 'login', 'register', 'order_verify'
  final VoidCallback onVerified;

  const OtpVerificationSheet({
    super.key,
    required this.emailOrPhone,
    this.purpose = 'login',
    required this.onVerified,
  });

  @override
  State<OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<OtpVerificationSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  int _secondsRemaining = 45;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 45;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    String code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _errorMessage = 'Please enter the 4-digit verification code.');
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final res = await ApiService.verifyOtp(
      email: widget.emailOrPhone,
      code: code,
      purpose: widget.purpose,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      widget.onVerified();
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Invalid code. Please try again.';
      });
    }
  }

  void _resendCode() async {
    HapticFeedback.lightImpact();
    _startCountdown();
    await ApiService.resendOtp(widget.emailOrPhone);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new 4-digit verification code was sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Responsive.maxContainer(
        context: context,
        maxWidth: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppTheme.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock, color: AppTheme.emeraldPrimary, size: 30),
              ),
              const SizedBox(height: 16),

              const Text(
                'Enter Verification Code',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
              ),
              const SizedBox(height: 6),

              Text(
                'We sent a 4-digit code to ${widget.emailOrPhone}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.slateMuted),
              ),
              const SizedBox(height: 24),

              // OTP Input Field
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(fontSize: 28, letterSpacing: 14, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  hintStyle: const TextStyle(letterSpacing: 14, color: AppTheme.slateMuted),
                  fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.emeraldPrimary, width: 2),
                  ),
                ),
                onSubmitted: (_) => _verifyOtp(),
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: AppTheme.errorRed, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('VERIFY & CONTINUE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _secondsRemaining > 0
                        ? 'Resend code in ${_secondsRemaining}s'
                        : "Didn't receive code? ",
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.slateMuted),
                  ),
                  if (_secondsRemaining == 0)
                    TextButton(
                      onPressed: _resendCode,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Resend OTP', style: TextStyle(color: AppTheme.emeraldPrimary, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
