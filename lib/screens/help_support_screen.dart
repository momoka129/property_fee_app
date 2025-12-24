import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Section
          _buildSection(
            context,
            'Frequently Asked Questions',
            Icons.help_outline,
            [
              _buildFAQItem(
                context,
                'How do I pay my bills?',
                'Go to the Bills section, select an unpaid bill, and choose your preferred payment method (WeChat Pay, Alipay, or Bank Transfer).',
              ),
              _buildFAQItem(
                context,
                'How do I submit a repair request?',
                'Navigate to Repairs section, tap "New Request", fill in the details, upload photos if needed, and submit.',
              ),
              _buildFAQItem(
                context,
                'How do I book a facility?',
                'Visit Amenities section, select the facility you want, check availability, and tap "Book Now" to make a reservation.',
              ),
              _buildFAQItem(
                context,
                'Where can I collect my packages?',
                'Go to Packages section to see all your packages. The location is shown on each package card. Usually at the Management Office.',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact Section
          _buildSection(
            context,
            'Contact Us',
            Icons.contact_support,
            [
              _buildContactCard(
                context,
                'Management Office',
                'For general inquiries and assistance',
                '012-345-6789',
                'management@property.com',
                Icons.business,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildContactCard(
                context,
                'Emergency Hotline',
                '24/7 emergency service',
                '999',
                'emergency@property.com',
                Icons.emergency,
                Colors.red,
              ),
              const SizedBox(height: 12),
              _buildContactCard(
                context,
                'Maintenance Team',
                'For repair and maintenance issues',
                '012-345-6788',
                'maintenance@property.com',
                Icons.build,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Links
          _buildSection(
            context,
            'Quick Links',
            Icons.link,
            [
              _buildLinkTile(
                context,
                'Community Guidelines',
                Icons.description,
                () {
                  _showGuidelines(context);
                },
              ),
              _buildLinkTile(
                context,
                'Terms & Conditions',
                Icons.gavel,
                () {
                  _showTerms(context);
                },
              ),
              _buildLinkTile(
                context,
                'Privacy Policy',
                Icons.privacy_tip,
                () {
                  _showPrivacy(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String title,
    String description,
    String phone,
    String email,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(phone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _sendEmail(email),
                    icon: const Icon(Icons.email, size: 16),
                    label: const Text('Email'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Inquiry from Property App');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showGuidelines(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Community Guidelines'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Respect your neighbors and maintain quiet hours (10 PM - 7 AM)\n\n'
            '2. Keep common areas clean and tidy\n\n'
            '3. Follow parking regulations and park only in assigned spaces\n\n'
            '4. Dispose of waste properly in designated areas\n\n'
            '5. Report any maintenance issues promptly\n\n'
            '6. Follow facility booking rules and cancel if unable to attend\n\n'
            '7. Keep pets on leash in common areas\n\n'
            '8. No smoking in common areas',
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
            '• Pay all fees and charges on time\n'
            '• Follow all community rules and regulations\n'
            '• Respect the privacy of other residents\n'
            '• Report any security concerns immediately\n\n'
            'The management reserves the right to suspend or terminate access for violations.',
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
            '• Payment information is processed securely\n'
            '• You can access and update your information anytime\n'
            '• We use encryption to protect sensitive data\n'
            '• Activity logs are kept for security purposes only\n\n'
            'For questions about your privacy, contact the management office.',
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












