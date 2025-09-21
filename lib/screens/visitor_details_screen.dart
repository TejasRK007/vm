import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/visitor_model.dart';
import '../services/visitor_service.dart';
import '../services/auth_service.dart';
import '../widgets/qr_code_widget.dart';
import 'checkout_screen.dart';

class VisitorDetailsScreen extends StatefulWidget {
  final Visitor visitor;
  
  const VisitorDetailsScreen({super.key, required this.visitor});

  @override
  State<VisitorDetailsScreen> createState() => _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends State<VisitorDetailsScreen> {
  final VisitorService _visitorService = Undefined cclass 'VisitorService'.VisitorService();
  bool _isLoading = false;

  Future<void> _approveVisitor() async {
    setState(() => _isLoading = true);
    try {
      await _visitorService.approveVisitor(widget.visitor.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve visitor: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectVisitor() async {
    setState(() => _isLoading = true);
    try {
      await _visitorService.rejectVisitor(widget.visitor.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject visitor: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestCheckout() async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout Request'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (notes != null) {
      setState(() => _isLoading = true);
      try {
        await _visitorService.requestCheckout(widget.visitor.id!, notes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checkout requested successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to request checkout: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showQrDialog(String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visitor QR Code'),
        content: QrCodeWidget(data: qrData, size: 200),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String qrData = widget.visitor.qrCode ?? widget.visitor.id ?? '';
    final userRole = context.read<AuthService>().role?.toLowerCase().trim() ?? '';
    final isAdmin = userRole == 'admin';
    final isReceptionist = userRole == 'receptionist';
    final isGuard = userRole == 'guard';

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
              onPressed: _isLoading ? null : () => _showQrDialog(qrData),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          if (widget.visitor.status == 'pending' && (isAdmin || isReceptionist))
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green, size: 24),
              onPressed: _isLoading ? null : _approveVisitor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          if (widget.visitor.status == 'pending' && (isAdmin || isReceptionist))
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 24),
              onPressed: _isLoading ? null : _rejectVisitor,
              padding: const EdgeInsets.only(right: 12, left: 0),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    title: 'Visitor Information',
                    children: [
                      _buildInfoRow('Name', widget.visitor.name),
                      if (widget.visitor.email?.isNotEmpty ?? false)
                        _buildInfoRow('Email', widget.visitor.email!),
                      if (widget.visitor.contact?.isNotEmpty ?? false)
                        _buildInfoRow('Contact', widget.visitor.contact!),
                      if (widget.visitor.purpose?.isNotEmpty ?? false)
                        _buildInfoRow('Purpose', widget.visitor.purpose!),
                      if (widget.visitor.hostName?.isNotEmpty ?? false)
                        _buildInfoRow('Host', widget.visitor.hostName!),
                      _buildInfoRow(
                        'Check-in',
                        widget.visitor.checkIn != null
                            ? DateFormat('MMM d, y hh:mm a').format(widget.visitor.checkIn!.toDate())
                            : 'Not checked in',
                      ),
                      if (widget.visitor.checkOut != null)
                        _buildInfoRow(
                          'Check-out',
                          DateFormat('MMM d, y hh:mm a').format(widget.visitor.checkOut!.toDate()),
                        ),
                      _buildInfoRow(
                        'Status',
                        _getStatusText(widget.visitor.status ?? 'pending'),
                        status: widget.visitor.status ?? 'pending',
                      ),
                    ],
                  ),
                  if (widget.visitor.meetingNotes?.isNotEmpty ?? false)
                    _buildInfoCard(
                      title: 'Meeting Notes',
                      children: [
                        Text(
                          widget.visitor.meetingNotes!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  if (widget.visitor.status != 'completed' &&
                      widget.visitor.status != 'rejected' &&
                      !widget.visitor.checkoutRequested &&
                      (isAdmin || isReceptionist || isGuard))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(visitor: widget.visitor),
                                  ),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Process Checkout',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (widget.visitor.status != 'completed' &&
                      widget.visitor.status != 'rejected' &&
                      !widget.visitor.checkoutRequested &&
                      !isAdmin &&
                      !isReceptionist &&
                      !isGuard)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Request Checkout',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (widget.visitor.checkoutRequested &&
                      !widget.visitor.checkoutApproved &&
                      !widget.visitor.checkoutRejected)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Center(
                        child: Text(
                          'Checkout Request Pending',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.grey, height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {String? status}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: status != null ? _getStatusColor(status) : Colors.white,
                fontSize: 14,
                fontWeight: status != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'checked-in':
        return 'Checked In';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'checked-in':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}
