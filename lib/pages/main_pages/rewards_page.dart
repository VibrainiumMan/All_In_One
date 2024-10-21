import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardsPage extends StatefulWidget {
  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  int currentPoints = 0; // Points are now loaded from Firestore
  List<Map<String, dynamic>> availableVouchers = []; // Store vouchers with their status

  @override
  void initState() {
    super.initState();
    _loadVouchers();// Load vouchers when page loads
    _loadCurrentPoints();
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

  // Function to load current points from Firestore
  void _loadCurrentPoints() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      // Fetch the user's points from Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      setState(() {
        currentPoints = userDoc.data()?['points'] ?? 0; // Load points or default to 0
      });
    }
  }

  // Function to update points in Firestore when the user earns points
  Future<void> _updatePoints(int pointsToAdd) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      setState(() {
        currentPoints += pointsToAdd;
      });

      // Update points in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'currentPoints': currentPoints});
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
              'Your Points: $currentPoints', // Accessing currentPoints from widget
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Button background color
                          foregroundColor: Colors.white, // Button text color
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding
                          textStyle: const TextStyle(fontSize: 16), // Font size
                        ),
                        onPressed: () {
                          _redeemVoucher(voucher['id']);
                        },
                        child: const Text('Redeem'),
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

      // Reset points to 0 after voucher redemption
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'currentPoints': 0});

      // Reload vouchers after redemption
      _loadVouchers();
    }
  }
}
