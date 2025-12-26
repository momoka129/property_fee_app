import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/glass_container.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bgGradientStart = const Color(0xFFF3F4F6);
    final bgGradientEnd = const Color(0xFFE5E7EB);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
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
              // FAQ Section
              GlassContainer(
                opacity: 0.8,
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.help_outline, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Frequently Asked Questions',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFAQItem(
                      context,
                      'How do I pay my bills?',
                      'Go to the Bills section, select an unpaid bill, and choose your preferred payment method (WeChat Pay, Alipay, or Bank Transfer).',
                    ),
                    _buildDivider(),
                    _buildFAQItem(
                      context,
                      'How do I submit a repair request?',
                      'Navigate to Repairs section, tap "New Request", fill in the details, upload photos if needed, and submit.',
                    ),
                    _buildDivider(),
                    _buildFAQItem(
                      context,
                      'How do I book a facility?',
                      'Visit Amenities section, select the facility you want, check availability, and tap "Book Now" to make a reservation.',
                    ),
                    _buildDivider(),
                    _buildFAQItem(
                      context,
                      'Where can I collect my packages?',
                      'Go to Packages section to see all your packages. The location is shown on each package card. Usually at the Management Office.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contact Section
              GlassContainer(
                opacity: 0.8,
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.contact_support, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Contact Us',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildContactCard(
                      context,
                      'Security Guard House',
                      'For emergencies and security matters',
                      '03-1234-5678',
                      Icons.security,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Links (removed: Resident Handbook, Terms & Conditions, Privacy Policy)
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
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

  Widget _buildContactCard(
    BuildContext context,
    String title,
    String description,
    String phone,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                phone,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _makePhoneCall(phone),
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Call'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }

  void _makePhoneCall(String phone) async {
    // Normalize phone to digits and ensure +60 prefix for calling.
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = digits.startsWith('60') ? '+$digits' : '+60$digits';
    final uri = Uri.parse('tel:$normalized');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }


  // Resident Handbook, Terms & Conditions, and Privacy Policy dialogs removed from Help & Support screen.
}












