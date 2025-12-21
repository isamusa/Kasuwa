import 'package:flutter/material.dart';
import 'package:kasuwa/theme/app_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  // Mock current language. Replace with Provider/Bloc state later.
  String _selectedLanguageCode = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'ha', 'name': 'Hausa', 'native': 'Harshen Hausa'},
    {'code': 'fr', 'name': 'French', 'native': 'Français'},
    {'code': 'yo', 'name': 'Yoruba', 'native': 'Yorùbá'},
    {'code': 'ig', 'name': 'Igbo', 'native': 'Asụsụ Igbo'},
  ];

  void _handleLanguageChange(String code) {
    setState(() {
      _selectedLanguageCode = code;
    });

    // TODO: Call your LocalizationProvider here to update app locale
    // Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(code));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Language changed to ${_languages.firstWhere((l) => l['code'] == code)['name']}"),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Language",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _languages.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = lang['code'] == _selectedLanguageCode;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                  : Border.all(color: Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ListTile(
              onTap: () => _handleLanguageChange(lang['code']!),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey[100],
                child: Text(
                  lang['code']!.toUpperCase(),
                  style: TextStyle(
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                lang['name']!,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(lang['native']!),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
