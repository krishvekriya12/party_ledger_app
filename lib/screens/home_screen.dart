import 'package:flutter/material.dart';
import 'party_list_screen.dart';
import 'karigar_list_screen.dart';
import 'partner_list_screen.dart';
import 'dashboard_screen.dart';
import 'online_dashboard_screen.dart';
import 'challan_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Header
            const Text(
              'Ledger App',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _todayStr(),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 28),

            // Module cards
            _ModuleCard(
              title: 'Dashboard',
              subtitle: 'Outstanding, Payroll, Monthly Reports',
              icon: Icons.bar_chart_rounded,
              accent: const Color(0xFF5C35CC),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen())),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              title: 'Party',
              subtitle: 'Bill, Payment, Outstanding',
              icon: Icons.store_outlined,
              accent: const Color(0xFF1A6DFF),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PartyListScreen())),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              title: 'Challan',
              subtitle: 'Bill of Supply, Dynamic Sizes, PDF & Share',
              icon: Icons.receipt_long_outlined,
              accent: const Color(0xFFE91E63),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChallanListScreen())),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              title: 'Workers',
              subtitle: 'Work, Advance, Net Payable, PDF',
              icon: Icons.handyman_outlined,
              accent: const Color(0xFFE07B1A),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const KarigarListScreen())),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              title: 'Partners',
              subtitle: 'Contributions, Expenses History',
              icon: Icons.people_outline,
              accent: const Color(0xFF27AE60),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PartnerListScreen())),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              title: 'Online',
              subtitle: 'Flipkart, Meesho — Purchase & Sale',
              icon: Icons.shopping_bag_outlined,
              accent: const Color(0xFF009688),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OnlineDashboardScreen())),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }


  String _todayStr() {
    final now = DateTime.now();
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
                  'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month]} ${now.year}';
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0DED8)),
          ),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: accent.withOpacity(0.6), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
