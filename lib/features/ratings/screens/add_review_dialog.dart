import 'package:da_crust_app/features/cart/widgets/custom_text_field.dart';
import 'package:da_crust_app/features/ratings/services/review_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

@JS('currentCaptchaToken')
external JSString? get currentCaptchaToken;

@JS('currentCaptchaToken')
external set currentCaptchaToken(JSAny? value);

@JS('forceRenderCaptcha')
external void forceRenderCaptcha(JSString containerId, JSString siteKey);

class AddReviewDialog extends StatefulWidget {
  const AddReviewDialog({super.key});

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _commentController = TextEditingController();
  
  int _selectedRating = 0; 
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    debugPrint("=== RECAPTCHA INIT START ===");
    debugPrint("DotEnv initialized: ${dotenv.isInitialized}");
    debugPrint("Available DotEnv keys: ${dotenv.env.keys.toList()}");

    final siteKey = dotenv.env['RECAPTCHA_SITE_KEY'] ?? '';
    debugPrint("Loaded Site Key: '$siteKey' (Length: ${siteKey.length})");

    final String containerId = 'recaptcha-container-${DateTime.now().millisecondsSinceEpoch}';
    debugPrint("Generated Container ID: $containerId");
    
    ui_web.platformViewRegistry.registerViewFactory('recaptcha-view', (int viewId) {
      debugPrint("Registering View Factory for viewId: $viewId");
      
      final element = web.HTMLDivElement()
        ..id = containerId; 
      
      Future.delayed(const Duration(milliseconds: 100), () {
        debugPrint("Calling JS forceRenderCaptcha with ID: $containerId");
        
        if (siteKey.isEmpty) {
          debugPrint("🚨 CRITICAL ERROR: siteKey is completely empty right before JS call!");
        } else {
          debugPrint("✅ Executing JS interop...");
        }
        
        forceRenderCaptcha(containerId.toJS, siteKey.toJS);
      });
      
      return element;
    });
    
    debugPrint("=== RECAPTCHA INIT END ===");
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _commentController.dispose();
    currentCaptchaToken = null; 
    super.dispose();
  }

  void _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a star rating.")));
      return;
    }
    
    if (_firstNameController.text.trim().isEmpty || 
        _lastNameController.text.trim().isEmpty || 
        _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields."))
      );
      return;
    }

    final String? verifiedToken = currentCaptchaToken?.toDart;
    if (verifiedToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete the reCAPTCHA.")));
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

      await ReviewService.instance.submitReview(
        name: fullName,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        recaptchaToken: verifiedToken, 
      );
      
      if (!mounted) return;
      
      Navigator.pop(context, true); 
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review published!"), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isSubmitting = false);
      currentCaptchaToken = null; 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // 🌟 FIX 1: Provide breathing room around the dialog on small screens
      insetPadding: const EdgeInsets.all(16), 
      // 🌟 FIX 2: Use ConstrainedBox instead of a hardcoded width of 450
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        // 🌟 FIX 3: SingleChildScrollView prevents the keyboard from crashing the layout
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Leave a Review", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              const Text("Tap to Rate", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              
              // 🌟 FIX 4: Wrapped the stars in a FittedBox to guarantee they shrink instead of overflowing!
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      iconSize: 40,
                      icon: Icon(
                        index < _selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() => _selectedRating = index + 1);
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstNameController,
                      labelText: "First Name",
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastNameController,
                      labelText: "Last Name",
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _commentController,
                labelText: "What did you think?",
                isRequired: true,
                maxLength: 500, 
                maxLines: 4,
                minLines: 4, 
              ),
              const SizedBox(height: 16),
              
              // 🌟 FIX 5: Center the Captcha box so it stays aligned
              Center(
                child: const SizedBox(
                  height: 78, 
                  width: 304, 
                  child: HtmlElementView(viewType: 'recaptcha-view'),
                ),
              ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Publish Review", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}