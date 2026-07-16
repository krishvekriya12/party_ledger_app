import 'package:flutter/material.dart';
import 'party_list_screen.dart';
import 'karigar_list_screen.dart';
import 'partner_list_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ledger App')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _moduleCard(
              context,
              title: 'Dashboard',
              subtitle: 'Outstanding, Payroll, Monthly Reports',
              icon: Icons.dashboard,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              ),
            ),
            const SizedBox(height: 20),
            _moduleCard(
              context,
              title: 'Party',
              subtitle: 'Bill, Payment, Outstanding',
              icon: Icons.store,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PartyListScreen()),
              ),
            ),
            const SizedBox(height: 20),
            _moduleCard(
              context,
              title: 'Karigar',
              subtitle: 'Work, Upad (Advance), Net Payable',
              icon: Icons.build,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KarigarListScreen()),
              ),
            ),
            const SizedBox(height: 20),
            _moduleCard(
              context,
              title: 'Partners',
              subtitle: 'Paisa Diya, Kharcha Record',
              icon: Icons.groups,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PartnerListScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
