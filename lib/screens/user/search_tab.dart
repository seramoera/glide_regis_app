import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:org_registration_app/models/orgs.dart';
import 'package:org_registration_app/screens/user/org_details.dart';
import 'package:org_registration_app/screens/user/notifications_page.dart';
import 'package:org_registration_app/screens/user/user_shell.dart';
import 'package:org_registration_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchTab extends StatefulWidget {
  final AuthService auth;
  const SearchTab({super.key, required this.auth});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  List<String> recentSearches = [];
  String searchQuery = "";
  final double horizontalPadding = 12;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<int> registeredOrgIds = [];
  Set<String> dismissedNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadRegisteredOrgs();
    _loadDismissedNotifications();
    _loadRecentSearches();
  }

  Future<void> _loadRegisteredOrgs() async {
    final user = widget.auth.currentUser;
    if (user != null) {
      final registered = await widget.auth.getUserRegisteredOrgs(user.uid);
      setState(() {
        registeredOrgIds = registered.map((o) => o.id).toList();
      });
    }
  }

  Future<void> _loadDismissedNotifications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection("users").doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data["dismissedNotifications"] != null) {
        setState(() {
          dismissedNotifications =
              Set<String>.from(data["dismissedNotifications"]);
        });
      }
    }
  }

  /// Load recent searches from Firestore
  Future<void> _loadRecentSearches() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection("users").doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data["recentSearches"] != null) {
        setState(() {
          recentSearches = List<String>.from(data["recentSearches"]);
        });
      }
    }
  }

  /// Save updated recent searches to Firestore
  Future<void> _saveRecentSearches() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection("users").doc(uid).update({
      "recentSearches": recentSearches,
    });
  }

  /// Same real-time notification stream from UserHome
  Stream<bool> _hasNewNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return _firestore
        .collection("posts")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.where((doc) {
        if (dismissedNotifications.contains(doc.id)) return false;

        final data = doc.data() as Map<String, dynamic>;
        final audience = data["audience"] ?? "all";

        final postOrgId = data["orgId"] is int
            ? data["orgId"] as int
            : int.tryParse(data["orgId"].toString()) ?? 0;

        if (audience == "all") return true;
        if (audience == "org-members" && postOrgId != 0) {
          return registeredOrgIds.contains(postOrgId);
        }
        return false;
      }).toList();

      return posts.isNotEmpty;
    });
  }

  Widget buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: const Divider(
        color: Colors.white24,
        thickness: 1,
      ),
    );
  }

  void navigateBackWithAnimation() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            UserShell(auth: widget.auth),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = FadeTransition(opacity: animation, child: child);
          final scale = ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: fade,
          );
          return scale;
        },
      ),
    );
  }

  List<Org> get filteredOrgs {
    if (searchQuery.isEmpty) return [];
    return allOrgs
        .where(
            (org) => org.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  void addToRecent(String orgName) {
    setState(() {
      if (recentSearches.contains(orgName)) {
        recentSearches.remove(orgName);
      }
      recentSearches.insert(0, orgName);
      if (recentSearches.length > 10) {
        recentSearches.removeLast();
      }
    });
    _saveRecentSearches();
  }

  void removeFromRecent(int index) {
    setState(() {
      recentSearches.removeAt(index);
    });
    _saveRecentSearches();
  }

  void clearAllRecent() {
    setState(() {
      recentSearches.clear();
    });
    _saveRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row (Back + Title + Bell with red dot)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: navigateBackWithAnimation,
                        ),
                        const Text(
                          "Search",
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        StreamBuilder<bool>(
                          stream: _hasNewNotifications(),
                          builder: (context, snapshot) {
                            final hasNew = snapshot.data ?? false;

                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsPage(),
                                      ),
                                    );
                                    await _loadDismissedNotifications();
                                    setState(() {});
                                  },
                                ),
                                if (hasNew)
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              buildDivider(),
              const SizedBox(height: 12),

              // Search Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            style: const TextStyle(
                              fontFamily: 'Afacad',
                              color: Colors.white,
                            ),
                            decoration: const InputDecoration(
                              hintText: "Search for orgs...",
                              hintStyle: TextStyle(
                                fontFamily: 'Afacad',
                                color: Colors.white54,
                              ),
                              border: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Search Results or Recent Searches
              if (searchQuery.isNotEmpty)
                Expanded(
                  child: filteredOrgs.isEmpty
                      ? const Center(
                          child: Text(
                            "No organizations found",
                            style: TextStyle(
                              color: Colors.white54,
                              fontFamily: 'Afacad',
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredOrgs.length,
                          separatorBuilder: (context, index) => buildDivider(),
                          itemBuilder: (context, index) {
                            final org = filteredOrgs[index];
                            return ListTile(
                              title: Text(
                                org.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Afacad',
                                ),
                              ),
                              onTap: () {
                                addToRecent(org.name);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrgDetailsPage(org: org),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                )
              else
                Expanded(
                  child: recentSearches.isEmpty
                      ? const Center(
                          child: Text(
                            "No recent searches",
                            style: TextStyle(
                              color: Colors.white54,
                              fontFamily: 'Afacad',
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Recent Searches",
                                  style: TextStyle(
                                    fontFamily: 'Afacad',
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: clearAllRecent,
                                  child: const Text(
                                    "Clear all",
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.separated(
                                itemCount: recentSearches.length,
                                separatorBuilder: (context, index) =>
                                    buildDivider(),
                                itemBuilder: (context, index) {
                                  final search = recentSearches[index];
                                  return ListTile(
                                    title: Text(
                                      search,
                                      style: const TextStyle(
                                        fontFamily: 'Afacad',
                                        color: Colors.white,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.white70),
                                      onPressed: () {
                                        removeFromRecent(index);
                                      },
                                    ),
                                    onTap: () {
                                      setState(() {
                                        searchQuery = search;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
