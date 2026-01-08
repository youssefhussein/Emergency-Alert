import 'package:flutter/material.dart';
import '../../models/contact.dart';

class IncomingRequestTile extends StatelessWidget {
  final Contact contact;
  final bool isPending;
  final VoidCallback? onTapAccepted;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  const IncomingRequestTile({
    super.key,
    required this.contact,
    required this.isPending,
    required this.onReject,
    required this.onAccept,
    this.onTapAccepted,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          (contact.name.isNotEmpty ? contact.name[0] : '?').toUpperCase(),
        ),
      ),
      title: Text(contact.name),
      subtitle: Text(
        isPending
            ? 'Sent you a request as emergency contact'
            : 'Saved you as an emergency contact',
      ),
      trailing: isPending
          ? Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Reject',
                  onPressed: onReject,
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Accept',
                  onPressed: onAccept,
                ),
              ],
            )
          : const Icon(Icons.check_circle, color: Colors.green),
      onTap: isPending ? null : onTapAccepted,
    );
  }
}
