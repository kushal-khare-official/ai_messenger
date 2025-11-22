import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/sms_message.dart';

class MessageCard extends StatelessWidget {
  final SmsMessage message;
  final VoidCallback onTap;
  final VoidCallback onMarkAsSpam;

  const MessageCard({
    super.key,
    required this.message,
    required this.onTap,
    required this.onMarkAsSpam,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: message.isRead ? 0 : 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Category icon
                  Text(
                    message.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),

                  // Sender info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.address,
                          style: TextStyle(
                            fontWeight: message.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          message.category.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getCategoryColor(message.category),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Timestamp
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeago.format(message.timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      if (message.isImportant)
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Message preview
              Text(
                message.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: message.isRead ? Colors.grey[700] : Colors.black87,
                ),
              ),

              // Tags
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  if (message.isSpam) _buildTag('Spam', Colors.red),
                  if (message.isImportant)
                    _buildTag('Important', Colors.orange),
                  if (!message.isRead) _buildTag('Unread', Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getCategoryColor(SmsCategory category) {
    switch (category) {
      case SmsCategory.otp:
        return Colors.blue;
      case SmsCategory.bankAlert:
        return Colors.green;
      case SmsCategory.financeAlert:
        return Colors.teal;
      case SmsCategory.offer:
        return Colors.purple;
      case SmsCategory.coupon:
        return Colors.pink;
      case SmsCategory.personal:
        return Colors.indigo;
      case SmsCategory.business:
        return Colors.blueGrey;
      case SmsCategory.promotional:
        return Colors.orange;
      case SmsCategory.spam:
        return Colors.red;
      case SmsCategory.other:
        return Colors.grey;
    }
  }
}
