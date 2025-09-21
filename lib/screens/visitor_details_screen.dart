import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visitor_model.dart';
import '../services/visitor_service.dart';
import 'checkout_screen.dart';
import '../widgets/qr_code_widget.dart';
import 'package:provider/provider.dart';

class VisitorDetailsScreen extends StatelessWidget {
  final Visitor visitor;
  final FirebaseServices _firebaseServices = FirebaseServices();

  VisitorDetailsScreen({super.key, required this.visitor});

  @override
  Widget build(BuildContext context) {
    final String qrData = visitor.qrCode ?? visitor.id ?? '';
    final bool isAdmin = Provider.of<AuthService>(context, listen: false).role == 'admin';
    final bool isReceptionist = Provider.of<AuthService>(context, listen: false).role == 'receptionist';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Visitor Details'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (qrData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.qr_code, size: 24),
              tooltip: 'Show QR',
              onPressed: () => _showQrDialog(context, qrData),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          if (visitor.status == 'pending' && (isAdmin || isReceptionist))
            IconButton(
              icon: Icon(Icons.check, color: Colors.green[300], size: 24),
              onPressed: () => _approveVisitor(context),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          if (visitor.status == 'pending' && (isAdmin || isReceptionist))
            IconButton(
              icon: Icon(Icons.close, color: Colors.red[300], size: 24),
              onPressed: () => _rejectVisitor(context),
              padding: const EdgeInsets.only(right: 12, left: 0),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey[900]!, Colors.black],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[850]!,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey[800]!.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[700]!,
                      backgroundImage: (visitor.photoUrl != null && visitor.photoUrl!.isNotEmpty)
                          ? NetworkImage(visitor.photoUrl!)
                          : (visitor.idImageUrl != null && visitor.idImageUrl!.isNotEmpty)
                              ? NetworkImage(visitor.idImageUrl!)
                              : null,
                      child: ((visitor.photoUrl == null || visitor.photoUrl!.isEmpty) && (visitor.idImageUrl == null || visitor.idImageUrl!.isEmpty))
                          ? Text(
                              visitor.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(fontSize: 32, color: Colors.grey[100], fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      visitor.name,
                      style: TextStyle(fontSize: 24, color: Colors.grey[100], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusChip(visitor.status),
                    if ((visitor.photoUrl != null && visitor.photoUrl!.isNotEmpty) || (visitor.idImageUrl != null && visitor.idImageUrl!.isNotEmpty)) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          (visitor.photoUrl != null && visitor.photoUrl!.isNotEmpty) ? visitor.photoUrl! : visitor.idImageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Visitor QR section (fixed QR)
              if (qrData.isNotEmpty)
                _buildSection('Visitor QR', [
                  Center(
                    child: CustomQRCodeWidget(
                      data: qrData,
                      size: 180,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      errorMessage: 'QR unavailable',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showQrDialog(context, qrData),
                        icon: const Icon(Icons.fullscreen),
                        label: const Text('Open QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ]),

              // Personal Information
              _buildSection('Personal Information', [
                _buildInfoTile(Icons.phone, 'Contact', visitor.contact),
                _buildInfoTile(Icons.email, 'Email', visitor.email),
                _buildInfoTile(Icons.work, 'Host', visitor.hostName),
                _buildInfoTile(Icons.description, 'Purpose', visitor.purpose),
              ]),

              const SizedBox(height: 20),

              // Visit Information
              _buildSection('Visit Information', [
                _buildInfoTile(Icons.calendar_today, 'Visit Date', DateFormat('EEEE, MMMM dd, yyyy').format(visitor.visitDate)),
                _buildInfoTile(Icons.access_time, 'Check-in Time', DateFormat('EEEE, MMMM dd, yyyy HH:mm').format(visitor.checkIn)),
                if (visitor.checkOut != null)
                  _buildInfoTile(Icons.exit_to_app, 'Check-out Time', DateFormat('EEEE, MMMM dd, yyyy HH:mm').format(visitor.checkOut!)),
                if (visitor.checkOut != null)
                  _buildInfoTile(Icons.timer, 'Duration', _calculateDuration(visitor.checkIn, visitor.checkOut!)),
              ]),

              if (visitor.meetingNotes != null && visitor.meetingNotes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSection('Meeting Notes', [
                  _buildInfoTile(Icons.note, 'Notes', visitor.meetingNotes!),
                ]),
              ],

              // Show checkout request status if applicable
              if (visitor.checkoutRequested == true) ...[
                const SizedBox(height: 16),
                _buildSection('Checkout Status', [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[700]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pending_actions, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Checkout Requested',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (visitor.checkoutRequestedAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Requested: ${DateFormat('MMM d, y HH:mm').format(visitor.checkoutRequestedAt!)}',
                                    style: const TextStyle(color: Colors.blue, fontSize: 12, height: 1.2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isAdmin || isReceptionist) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _approveCheckout(context, visitor),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Approve', 
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => _rejectCheckout(context, visitor),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Reject',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]),
              ],

              if (visitor.checkoutApproved == true) ...[
                const SizedBox(height: 16),
                _buildSection('Checkout Status', [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[900]!.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[700]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Checkout Approved',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (visitor.checkoutApprovedAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Approved: ${DateFormat('MMM d, y HH:mm').format(visitor.checkoutApprovedAt!)}',
                                    style: const TextStyle(color: Colors.green, fontSize: 12, height: 1.2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],

              if (visitor.checkoutRejected == true) ...[
                const SizedBox(height: 16),
                _buildSection('Checkout Status', [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[900]!.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[700]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.cancel, color: Colors.red, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Checkout Rejected',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (visitor.checkoutRejectedAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Rejected: ${DateFormat('MMM d, y HH:mm').format(visitor.checkoutRejectedAt!)}',
                                    style: const TextStyle(color: Colors.red, fontSize: 12, height: 1.3),
                                  ),
                                ),
                              if (visitor.checkoutRejectionReason?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Reason: ${visitor.checkoutRejectionReason}',
                                    style: const TextStyle(color: Colors.red, fontSize: 12, height: 1.3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 20),

              // Action buttons
              if (visitor.status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveVisitor(context),
                        icon: Icon(Icons.check),
                        label: Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectVisitor(context),
                        icon: Icon(Icons.close),
                        label: Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),

              if (visitor.status == 'approved' && visitor.checkOut == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _checkOutVisitor(context),
                    icon: Icon(Icons.exit_to_app),
                    label: Text('Check-out Visitor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]!,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey[800]!.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey[100], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: Colors.grey[100]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        chipColor = Colors.orange[700]!;
        statusText = 'Pending Approval';
        statusIcon = Icons.schedule;
        break;
      case 'approved':
        chipColor = Colors.green[700]!;
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
        break;
      case 'checked-in':
        chipColor = Colors.blue[700]!;
        statusText = 'Checked In';
        statusIcon = Icons.login;
        break;
      case 'rejected':
        chipColor = Colors.red[700]!;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        chipColor = Colors.grey[600]!;
        statusText = 'Completed';
        statusIcon = Icons.done_all;
        break;
      default:
        chipColor = Colors.grey[600]!;
        statusText = status;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(statusIcon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  String _calculateDuration(DateTime checkIn, DateTime checkOut) {
    final duration = checkOut.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hours $minutes minutes';
    } else {
      return '$minutes minutes';
    }
  }

  void _approveVisitor(BuildContext context) async {
    try {
      await _firebaseServices.approveVisitor(visitor.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Visitor approved successfully'), backgroundColor: Colors.green[700]),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve visitor: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  void _rejectVisitor(BuildContext context) async {
    try {
      await _firebaseServices.rejectVisitor(visitor.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Visitor rejected'), backgroundColor: Colors.red[700]),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject visitor: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  void _checkOutVisitor(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutScreen(visitor: visitor)),
    );
  }

  void _showQrDialog(BuildContext context, String qrData) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QRCodeDialog(
        qrData: qrData,
        visitorName: visitor.name,
        visitorContact: visitor.contact,
        visitorPurpose: visitor.purpose,
        onDone: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _approveCheckout(BuildContext context, Visitor visitor) async {
    try {
      await FirebaseServices().approveCheckout(visitor.id!, null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve checkout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectCheckout(BuildContext context, Visitor visitor) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter the reason for rejection...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = (context as Element).findRenderObject() as TextField;
              Navigator.pop(context, reason.controller?.text ?? '');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await FirebaseServices().rejectCheckout(visitor.id!, reason);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checkout rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject checkout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
