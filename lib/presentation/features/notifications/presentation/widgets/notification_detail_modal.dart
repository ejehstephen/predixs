import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../domain/entities/notification.dart';

class NotificationDetailModal extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailModal({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            notification.title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Date
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, yyyy • h:mm a').format(notification.date),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(height: 0.2),
          const SizedBox(height: 24),

          // Body
          Flexible(
            child: SingleChildScrollView(
              child: SelectableText(
                notification.body,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Close Button
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: () => Navigator.pop(context),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppColors.primary,
          //       foregroundColor: Colors.white,
          //       padding: const EdgeInsets.symmetric(vertical: 16),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(16),
          //       ),
          //       elevation: 0,
          //     ),
          //     child: Text(
          //       'Close',
          //       style: GoogleFonts.inter(
          //         fontSize: 16,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
