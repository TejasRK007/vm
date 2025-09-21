import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/visitor_service.dart';
import '../services/auth_service.dart';
import '../models/visitor_model.dart';

class CheckoutRequestsScreen extends StatelessWidget {
  const CheckoutRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseServices firebaseServices = FirebaseServices();
    final auth = Provider.of<AuthService>(context, listen: false);
    final role = auth.role ?? 'admin';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Checkout Requests'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey[900]!, Colors.black],
          ),
        ),
        child: StreamBuilder<List<Visitor>>(
          stream: firebaseServices.getCheckoutRequests(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading checkout requests',
                  style: TextStyle(color: Colors.red[300]),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return const Center(
                child: Text(
                  'No pending checkout requests',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final visitor = requests[index];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              visitor.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Requested: ${DateFormat('MMM d, y HH:mm').format(visitor.checkoutRequestedAt ?? DateTime.now())}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Host: ${visitor.hostName}',
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check-in: ${DateFormat('MMM d, y HH:mm').format(visitor.checkIn)}',
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                        if (visitor.checkoutNotes?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Notes: ${visitor.checkoutNotes}',
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _rejectCheckout(context, visitor),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red[300],
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _approveCheckout(context, visitor),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _approveCheckout(BuildContext context, Visitor visitor) async {
    try {
      final notes = await _showNotesDialog(context, 'Approve Checkout');
      if (notes != null) {
        await FirebaseServices().approveCheckout(visitor.id!, notes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checkout approved'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
    try {
      final reason = await _showNotesDialog(context, 'Rejection Reason');
      if (reason != null) {
        await FirebaseServices().rejectCheckout(visitor.id!, reason);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checkout rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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

  Future<String?> _showNotesDialog(BuildContext context, String title) async {
    final notesController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Enter notes...',
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
            onPressed: () => Navigator.pop(context, notesController.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
