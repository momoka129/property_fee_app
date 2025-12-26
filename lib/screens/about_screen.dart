import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bgGradientStart = const Color(0xFFF3F4F6);
    final bgGradientEnd = const Color(0xFFE5E7EB);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 10),

              // App Info Section
              GlassContainer(
                opacity: 0.8,
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    // App Logo/Icon
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 60,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Name
                    Center(
                      child: Text(
                        'Resident Connect',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Version
                    Center(
                      child: Text(
                        'Version $_version',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Legal Menu
              GlassContainer(
                opacity: 0.8,
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildLegalItem(
                      context,
                      'Resident Handbook',
                      Icons.description,
                      () => _showResidentHandbook(context),
                    ),
                    _buildDivider(),
                    _buildLegalItem(
                      context,
                      'Terms & Conditions',
                      Icons.gavel,
                      () => _showTerms(context),
                    ),
                    _buildDivider(),
                    _buildLegalItem(
                      context,
                      'Privacy Policy',
                      Icons.privacy_tip,
                      () => _showPrivacy(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // About This App
              GlassContainer(
                opacity: 0.8,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About This App',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Resident Connect is a comprehensive property management mobile application designed to streamline property fee management, maintenance requests, and community services for residential communities.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Developer Info
              GlassContainer(
                opacity: 0.8,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Developer Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Developer', 'Huang Tianjing'),
                      _buildInfoRow('Student ID', 'SWE2209518'),
                      _buildInfoRow('Institution', 'Xiamen University Malaysia'),
                      _buildInfoRow('Program', 'Software Engineering'),
                      _buildInfoRow('Email', 'swe2209518@xmu.edu.my'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final primaryColor = Theme.of(context).primaryColor;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.withOpacity(0.2),
      indent: 56,
      endIndent: 20,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showResidentHandbook(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resident Handbook'),
        content: const SingleChildScrollView(
          child: Text(
            'Welcome to our community! This handbook contains important information for all residents:\n\n'
            'HOUSING REGULATIONS:\n'
            '• Maintenance fees are due on the 1st of each month\n'
            '• Late payment fees: RM 50 after due date\n'
            '• Visitors must register at security desk\n'
            '• Parking permits required for all vehicles\n\n'
            'COMMUNITY RULES:\n'
            '• Quiet hours: 10:00 PM - 7:00 AM\n'
            '• Common areas must be kept clean\n'
            '• Report maintenance issues within 24 hours\n'
            '• Pets must be on leash in common areas\n\n'
            'EMERGENCY CONTACTS:\n'
            '• Security Guard House: 03-1234-5678\n'
            '• Fire Department: 994\n'
            '• Police: 999\n'
            '• Hospital: 03-1234-5679',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'By using this Property Management App, you agree to:\n\n'
            '• Use the app only for legitimate property management purposes\n'
            '• Provide accurate information when submitting requests\n'
            '• Pay all maintenance fees and charges on time\n'
            '• Follow all community rules and regulations\n'
            '• Respect the privacy of other residents\n'
            '• Report any security concerns immediately\n'
            '• Keep your account information secure\n\n'
            'The management reserves the right to suspend or terminate access for violations.\n\n'
            'All maintenance fees are non-refundable once paid.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We are committed to protecting your privacy:\n\n'
            '• Your personal information is used only for property management purposes\n'
            '• We do not share your data with third parties without consent\n'
            '• Payment information is processed securely through licensed payment providers\n'
            '• You can access and update your information anytime through the app\n'
            '• We use encryption to protect sensitive data\n'
            '• Activity logs are kept for security and maintenance purposes only\n'
            '• Visitor pass applications are stored securely for security records\n\n'
            'For questions about your privacy, contact the Security Guard House.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}














