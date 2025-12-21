import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasuwa/providers/order_details_provider.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ReturnRequestScreen extends StatefulWidget {
  final int orderId;
  const ReturnRequestScreen({super.key, required this.orderId});

  @override
  State<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends State<ReturnRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedReason;
  File? _evidenceImage;
  bool _isLoading = false;

  final List<String> _returnReasons = [
    "Item is defective or doesn't work",
    "Received wrong item",
    "Item arrived damaged",
    "Missing parts or accessories",
    "Item doesn't match description"
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Optimize image size
      );
      if (pickedFile != null) {
        setState(() {
          _evidenceImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Could not pick image. Check permissions.")),
      );
    }
  }

  Future<void> _submitReturnRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_evidenceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload a photo of the issue."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Assuming OrderDetailsProvider has a submitReturnRequest method
      // You will need to add this method to your provider (see step 2 below)
      final success =
          await Provider.of<OrderDetailsProvider>(context, listen: false)
              .submitReturnRequest(
        orderId: widget.orderId,
        reason: _selectedReason!,
        comment: _commentController.text,
        evidence: _evidenceImage!,
      );

      if (!mounted) return;

      if (success) {
        // Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text("Request Submitted",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              "Your return request has been received. Our team will review your evidence and contact you within 24 hours.",
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back to Order Details
                },
                child: const Text("OK",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to submit request. Please try again."),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Request Return",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Returns are only accepted for defective items within 12 hours of delivery.",
                        style: TextStyle(
                            color: Colors.orange.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Select Reason
              const Text("Reason for Return",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  hintText: "Select a reason",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _returnReasons.map((reason) {
                  return DropdownMenuItem(
                      value: reason,
                      child:
                          Text(reason, style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: (val) => setState(() => _selectedReason = val),
                validator: (val) =>
                    val == null ? "Please select a reason" : null,
              ),

              const SizedBox(height: 24),

              // 2. Comments
              const Text("Additional Comments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Describe the defect in detail...",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                    val!.isEmpty ? "Please provide details" : null,
              ),

              const SizedBox(height: 24),

              // 3. Upload Evidence
              const Text("Upload Evidence",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Please upload a clear photo showing the defect.",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.grey[300]!, style: BorderStyle.solid),
                    image: _evidenceImage != null
                        ? DecorationImage(
                            image: FileImage(_evidenceImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _evidenceImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text("Tap to upload photo",
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500)),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 16),
                              ),
                            )
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReturnRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Submit Request",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
