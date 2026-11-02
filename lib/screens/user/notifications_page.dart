import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:org_registration_app/models/orgs.dart';
import 'package:org_registration_app/screens/user/org_details.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<int> userOrgIds = [];
  Set<String> dismissedNotifications = {}; // stored in user's doc

  // New state variable for animation
  bool _clearingAll = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection("users").doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        if (data["registeredOrgs"] != null) {
          userOrgIds = (data["registeredOrgs"] as List)
              .map((org) => org["id"] is int
                  ? org["id"] as int
                  : int.tryParse(org["id"].toString()) ?? 0)
              .where((id) => id != 0)
              .toList();
        }
        if (data["dismissedNotifications"] != null) {
          dismissedNotifications =
              Set<String>.from(data["dismissedNotifications"]);
        }
        setState(() {});
      }
    }
  }

  Future<void> _updateDismissedNotifications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection("users").doc(uid).set({
      "dismissedNotifications": dismissedNotifications.toList(),
    }, SetOptions(merge: true));
  }

  void _deleteNotification(String docId) {
    setState(() {
      dismissedNotifications.add(docId);
    });
    _updateDismissedNotifications();
  }

  void _clearAllNotifications(List<String> docIds) {
    // Trigger fade animation
    setState(() {
      _clearingAll = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        dismissedNotifications.addAll(docIds);
        _clearingAll = false;
      });
      _updateDismissedNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontFamily: "Afacad",
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(
              height: 1,
              color: Colors.white24,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("posts")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs.where((doc) {
            if (dismissedNotifications.contains(doc.id)) return false;

            final data = doc.data() as Map<String, dynamic>;
            final audience = data["audience"] ?? "all";

            final postOrgId = data["orgId"] is int
                ? data["orgId"] as int
                : int.tryParse(data["orgId"].toString()) ?? 0;

            if (audience == "all") return true;
            if (audience == "org-members" && postOrgId != 0) {
              return userOrgIds.contains(postOrgId);
            }
            return false;
          }).toList();

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "You haven't gotten any notifications yet!",
                    style: TextStyle(
                      fontFamily: "Afacad",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(221, 255, 255, 255),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "We'll notify you when something cool happens.",
                    style: TextStyle(
                      fontFamily: "Afacad",
                      fontSize: 15,
                      color: Color.fromARGB(136, 255, 255, 255),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final postIds = posts.map((doc) => doc.id).toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final doc = posts[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final postOrgId = data["orgId"] is int
                        ? data["orgId"] as int
                        : int.tryParse(data["orgId"].toString()) ?? 0;

                    final org = allOrgs.firstWhere(
                      (o) => o.id == postOrgId,
                      orElse: () => Org(
                        id: 0,
                        name: "Unknown Org",
                        status: "",
                        imageUrl: "",
                        description: "",
                        fee: 0,
                        category: "",
                      ),
                    );

                    final content =
                        (data["content"] ?? "").toString().replaceAll("<br>", "\n");

                    // Wrap each notification in AnimatedOpacity for fade effect
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _clearingAll ? 0 : 1,
                      child: Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: const Color.fromARGB(255, 134, 134, 134),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteNotification(doc.id),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: ListTile(
                            title: Text(
                              content,
                              style: const TextStyle(
                                fontFamily: "Afacad",
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              "From: ${org.name}",
                              style: const TextStyle(
                                fontFamily: "Afacad",
                                fontSize: 13,
                              ),
                            ),
                            trailing: Text(
                              data["timestamp"] != null
                                  ? (data["timestamp"] as Timestamp)
                                      .toDate()
                                      .toLocal()
                                      .toString()
                                      .substring(0, 16)
                                  : "",
                              style: const TextStyle(
                                fontFamily: "Afacad",
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              if (org.id != 0) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrgDetailsPage(org: org),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => _clearAllNotifications(postIds),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            "Clear All",
                            style: TextStyle(
                              fontFamily: "Afacad",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
