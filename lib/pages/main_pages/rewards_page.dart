import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Firebase Firestore import
import 'package:firebase_auth/firebase_auth.dart';    // Firebase Auth import

class RewardsPage extends StatelessWidget {
  final int currentPoints; // Points passed from HomePage

  RewardsPage({required this.currentPoints});

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
              'Your Points: $currentPoints',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            // Display rewards based on current points
            if (currentPoints >= 10) ...[
              _buildRewardTile("Free Coffee", context),
            ],
            if (currentPoints >= 20) ...[
              _buildRewardTile("Free Fries", context),
            ],
            if (currentPoints >= 30) ...[
              _buildRewardTile("Movie Ticket", context),
            ],
            const SizedBox(height: 20),
            Text(
              "Keep studying to earn more rewards!",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build reward tiles
  Widget _buildRewardTile(String reward, BuildContext context) {
    return ListTile(
      title: Text(reward),
      leading: Icon(Icons.card_giftcard),
      trailing: ElevatedButton(
        onPressed: () {
          _showRedeemDialog(reward, context);
        },
        child: const Text('Redeem'),
      ),
    );
  }

  // Show dialog to confirm reward redemption
  void _showRedeemDialog(String reward, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Redeem $reward'),
          content: Text('Are you sure you want to redeem $reward?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _redeemReward(reward);  // Call function to redeem reward
                Navigator.of(context).pop();
              },
              child: const Text("Redeem"),
            ),
          ],
        );
      },
    );
  }

  // Function to redeem reward and update Firestore
  Future<void> _redeemReward(String reward) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;
      // Reference the user's document in Firestore
      DocumentReference userDoc =
      FirebaseFirestore.instance.collection('users').doc(userId);

      // Update Firestore with the redeemed reward
      await userDoc.update({
        'redeemedRewards': FieldValue.arrayUnion([reward]),  // Add reward to redeemed rewards
      });

      // Optionally, you could also subtract points from the user's points field here
      await userDoc.update({
        'points': FieldValue.increment(-10),  // Subtract points after redemption
      });
    }
  }
}
