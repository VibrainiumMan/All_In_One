import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardsPage extends StatefulWidget {
  final int currentPoints; // Points passed from HomePage

  RewardsPage({required this.currentPoints});

  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  List<String> redeemedRewards = []; // List to store redeemed rewards
  List<Map<String, dynamic>> availableVouchers = []; // Store vouchers with their status

  @override
  void initState() {
    super.initState();
    _loadVouchers(); // Load vouchers when page loads
  }

  // Function to load vouchers from Firestore
  void _loadVouchers() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      // Fetch the user's vouchers from Firestore
      var vouchersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('vouchers')
          .get();

      setState(() {
        availableVouchers = vouchersSnapshot.docs.map((doc) {
          return {
            'title': doc['voucher'],
            'isRedeemed': doc['isRedeemed'],
            'id': doc.id // Voucher ID for reference
          };
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rewards"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Display user's current points
            Text(
              'Your Points: ${widget.currentPoints}', // Accessing currentPoints from widget
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),

            // Display vouchers
            if (availableVouchers.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: availableVouchers.length,
                  itemBuilder: (context, index) {
                    var voucher = availableVouchers[index];
                    return ListTile(
                      title: Text(voucher['title']),
                      subtitle: Text(voucher['isRedeemed'] ? 'Redeemed' : 'Not Redeemed'),
                      trailing: !voucher['isRedeemed']
                          ? ElevatedButton(
                        onPressed: () {
                          _redeemVoucher(voucher['id']);
                        },
                        child: Text('Redeem'),
                      )
                          : null,
                    );
                  },
                ),
              ),
            ] else ...[
              Text("No vouchers available. Keep studying to earn rewards!")
            ],
          ],
        ),
      ),
    );
  }

  // Function to redeem a voucher and update Firestore
  Future<void> _redeemVoucher(String voucherId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      // Update Firestore to mark the voucher as redeemed
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('vouchers')
          .doc(voucherId)
          .update({'isRedeemed': true});

      // Reload vouchers after redemption
      _loadVouchers();
    }
  }
}
