import 'package:flutter/material.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart'; // Optional: Add to pubspec.yaml for real calls

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock Data for FAQs
  final List<Map<String, String>> _faqs = [
    {
      "question": "How do I track my order?",
      "answer":
          "Go to 'My Orders' in your profile, select the active order, and you will see the current status and tracking details."
    },
    {
      "question": "What is the return policy?",
      "answer":
          "You can return items within 7 days of delivery. Ensure the item is unused and in its original packaging with all tags intact."
    },
    {
      "question": "How do I become a seller?",
      "answer":
          "Go to your Profile and click on 'Become a Seller'. Fill in your shop details and submit for verification."
    },
    {
      "question": "I forgot my password.",
      "answer":
          "On the Login screen, click 'Forgot Password?'. Enter your email address to receive a password reset link."
    },
    {
      "question": "Can I cancel my order?",
      "answer":
          "Yes, you can cancel your order from the 'Order Details' screen as long as the payment status is 'Pending' or 'Unpaid'."
    },
  ];

  // Filtered FAQs based on search
  List<Map<String, String>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _faqs;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = _faqs;
      } else {
        _filteredFaqs = _faqs.where((faq) {
          return faq['question']!.toLowerCase().contains(query) ||
              faq['answer']!.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // Helper to open dialer/email (requires url_launcher package)
  Future<void> _launchContact(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback or show snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Could not launch action")));
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Help Center",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTopicGrid(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Frequently Asked Questions",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _buildFAQList(),
            const SizedBox(height: 30),
            _buildContactSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          const Text("How can we help you?",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search for help topics...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicGrid() {
    final topics = [
      {'icon': Icons.local_shipping_outlined, 'label': 'Shipping'},
      {'icon': Icons.assignment_return_outlined, 'label': 'Returns'},
      {'icon': Icons.payment_outlined, 'label': 'Payments'},
      {'icon': Icons.person_outline, 'label': 'Account'},
      {'icon': Icons.storefront_outlined, 'label': 'Selling'},
      {'icon': Icons.security_outlined, 'label': 'Safety'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildTopicCard(
            topics[index]['icon'] as IconData,
            topics[index]['label'] as String,
          );
        },
      ),
    );
  }

  Widget _buildTopicCard(IconData icon, String label) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          // Filter FAQ or Navigate to specific topic page
          _searchController.text = label; // Quick filter trick
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQList() {
    if (_filteredFaqs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No matching answers found."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredFaqs.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                _filteredFaqs[index]['question']!,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _filteredFaqs[index]['answer']!,
                  style: TextStyle(
                      color: Colors.grey[700], height: 1.5, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          const Text("Still need help?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Our support team is available 24/7",
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat_bubble_outline,
                  label: "Chat",
                  color: AppTheme.primaryColor,
                  onTap: () {
                    // Open Live Chat (Mock)
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Connecting to agent...")));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.email_outlined,
                  label: "Email",
                  color: Colors.blueGrey,
                  onTap: () {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'support@kasuwa.com',
                      query: 'subject=Kasuwa App Support',
                    );
                    _launchContact(emailLaunchUri);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }
}
