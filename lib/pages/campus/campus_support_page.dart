import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/campus_support_config.dart';
import '../../widgets/feedback_sheet.dart';

class CampusSupportPage extends StatelessWidget {
  const CampusSupportPage({super.key});

  Future<void> _launchTel(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dial $number')),
      );
    }
  }

  Future<void> _launchMail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $email')),
      );
    }
  }

  Future<void> _launchWeb(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety & support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.red.withOpacity(0.2),
            child: ListTile(
              leading: const Icon(Icons.emergency, color: Colors.redAccent),
              title: const Text('Emergency'),
              subtitle: Text(CampusSupportConfig.nationalEmergency),
              trailing: const Icon(Icons.call),
              onTap: () => _launchTel(context, CampusSupportConfig.nationalEmergency),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Campus security'),
            subtitle: Text(CampusSupportConfig.campusSecurity),
            trailing: const Icon(Icons.call),
            onTap: () => _launchTel(context, CampusSupportConfig.campusSecurity),
          ),
          ListTile(
            leading: const Icon(Icons.medical_services_outlined),
            title: const Text('Medical'),
            subtitle: Text(CampusSupportConfig.campusMedical),
            trailing: const Icon(Icons.call),
            onTap: () => _launchTel(context, CampusSupportConfig.campusMedical),
          ),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('Student support'),
            subtitle: Text(CampusSupportConfig.studentSupportEmail),
            trailing: const Icon(Icons.email_outlined),
            onTap: () => _launchMail(context, CampusSupportConfig.studentSupportEmail),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report issue'),
            subtitle: Text(CampusSupportConfig.reportIssueEmail),
            trailing: const Icon(Icons.email_outlined),
            onTap: () => _launchMail(context, CampusSupportConfig.reportIssueEmail),
          ),
          ListTile(
            leading: const Icon(Icons.public_outlined),
            title: const Text('IIITD main website'),
            subtitle: Text(CampusSupportConfig.instituteWebsite),
            trailing: const Icon(Icons.open_in_new),
            onTap: () =>
                _launchWeb(context, CampusSupportConfig.instituteWebsite),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => showCampusFeedbackSheet(context),
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('Give app feedback'),
          ),
        ],
      ),
    );
  }
}
