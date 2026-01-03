import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:predixs/core/constants/app_colors.dart';

class HelpSupportModal extends StatelessWidget {
  const HelpSupportModal({super.key});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24).copyWith(bottom: 48),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(24),
            Text(
              'Help & Support',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              'How can we assist you today?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(32),

            Text(
              'FAQ',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const Gap(16),
            _FaqTile(
              question: 'How do I make a trade?',
              answer:
                  '1. Browse the Markets tab to find an event.\n2. Select an outcome: "Yes" (Event will happen) or "No" (Event won\'t happen).\n3. Enter the amount you want to stake.\n4. Swipe or Tap to confirm your trade.',
            ),
            _FaqTile(
              question: 'How does trading work?',
              answer:
                  'Predixs allows you to trade shares based on the probability of an event. Share prices fluctuate between ₦1 and ₦99. \n\nIf the event happens (Resolves YES), Yes shares redeem at ₦100. If it doesn\'t (Resolves NO), No shares redeem at ₦100.',
            ),
            _FaqTile(
              question: 'How do I withdraw winnings?',
              answer:
                  'Go to your Wallet and tap "Withdraw". Enter the amount and your bank account details. \n\nWithdrawals are processed manually by our team to ensure security and usually arrive within 1-24 hours.',
            ),
            _FaqTile(
              question: 'How do I deposit funds?',
              answer:
                  'Go to your Wallet and tap "Deposit". You can easily fund your wallet using Bank Transfer, USSD, or Card via Paystack.',
            ),
            _FaqTile(
              question: 'When do markets resolve?',
              answer:
                  'Each market has a specific resolution source and deadline. Check the "Rules" tab on any market content to see exactly when and how it will be settled.',
            ),

            const Gap(32),
            Text(
              'Contact Us',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const Gap(16),

            Row(
              children: [
                Expanded(
                  child: _ContactButton(
                    icon: Icons.email_outlined,
                    label: 'Email Support',
                    onTap: () => _launchUrl('mailto:predixs5@gmail.com'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _ContactButton(
                    // Icons.message is good for generic, or use a custom asset if available.
                    // Since we don't have FA/Community icons easily, use a chat bubble.
                    icon: Icons.chat_bubble_outline,
                    label: 'WhatsApp',
                    // Format: https://wa.me/2348134351762
                    onTap: () => _launchUrl('https://wa.me/2348134351762'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 300.ms,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded ? AppColors.primary : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            title: Text(
              widget.question,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: GoogleFonts.inter(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor; // Optional custom color

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 28),
            const Gap(8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: iconColor ?? AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
