import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class RiderReviewDialog extends StatefulWidget {
  final String orderId;
  final String riderName;
  final Function(double rating, String comment) onReviewSubmitted;

  const RiderReviewDialog({
    super.key,
    required this.orderId,
    required this.riderName,
    required this.onReviewSubmitted,
  });

  @override
  State<RiderReviewDialog> createState() => _RiderReviewDialogState();
}

class _RiderReviewDialogState extends State<RiderReviewDialog> {
  double _selectedRating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() async {
    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    final saved = await ApiService.submitRiderReview(
      widget.orderId,
      _selectedRating,
      _commentController.text.trim(),
    );

    if (!saved) {
      // Store refused (e.g. the order isn't on its way yet) or no connection.
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your rating could not be saved. You can rate the rider once the order is on its way.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }

    if (mounted) {
      widget.onReviewSubmitted(_selectedRating, _commentController.text.trim());
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your delivery partner review has been recorded. 🌟'),
          backgroundColor: AppTheme.emeraldPrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Responsive.maxContainer(
        context: context,
        maxWidth: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delivery_dining, color: AppTheme.emeraldPrimary, size: 36),
              ),
              const SizedBox(height: 14),
              const Text(
                'Rate Your Delivery Partner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'How was your experience with ${widget.riderName}?',
                style: const TextStyle(fontSize: 13, color: AppTheme.slateMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Star Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  int star = index + 1;
                  return IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      star <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 38,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedRating = star.toDouble());
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'How was the delivery? (optional — only the store sees this)',
                  hintStyle: const TextStyle(fontSize: 13, color: AppTheme.slateMuted),
                  fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Maybe Later', style: TextStyle(color: AppTheme.slateMuted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SUBMIT REVIEW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
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
