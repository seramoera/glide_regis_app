import 'dart:ui'; // For BackdropFilter blur effect
import 'package:flutter/material.dart';
import 'package:org_registration_app/models/orgs.dart';
import 'package:org_registration_app/screens/user/org_details.dart';
import 'package:org_registration_app/screens/user/notifications_page.dart';
import 'package:org_registration_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHome extends StatefulWidget {
  final AuthService auth;
  const UserHome({super.key, required this.auth});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String selectedFilter = "All";
  final List<String> filters = ["All", "SOC", "Uniwide"];
  String searchQuery = "";
  int _currentIndex = 0; // for bottom navbar

  List<int> registeredOrgIds = [];
  Set<String> dismissedNotifications = {};

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- ADDED FOR HIDING NAVBAR WHEN SEARCH FOCUSED ----------
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _loadRegisteredOrgs();
    _loadDismissedNotifications();

    // Listen to focus changes on the search bar
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
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
          dismissedNotifications = Set<String>.from(data["dismissedNotifications"]);
        });
      }
    }
  }

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

  final List<Org> orgs = [
    Org(
      id: 1,
      name: "Access Point",
      status: "Open",
      imageUrl: "lib/assets/images/ACCESS_POINT.jpg",
      description:
          "The official journalism and news club of SOC, covering events and stories for the community.",
      fee: 100,
      category: "SOC",
    ),
    Org(
      id: 2,
      name: "Code Geeks",
      status: "Open",
      imageUrl: "lib/assets/images/CODE_GEEKS.jpg",
      description: "A hub for students passionate about coding and software.",
      fee: 150,
      category: "SOC",
    ),
    Org(
      id: 3,
      name: "CSIA - Cybersecurity Intelligence Alliance",
      status: "Open",
      imageUrl: "lib/assets/images/CSIA.jpg",
      description:
          "Dedicated to exploring, learning, and sharing cybersecurity skills.",
      fee: 200,
      category: "SOC",
    ),
    Org(
      id: 4,
      name: "LOOP - League of Outstanding Programmers",
      status: "Closed",
      imageUrl: "lib/assets/images/LOOP.jpg",
      description:
          "A league for outstanding SOC programmers to collaborate and grow.",
      fee: 180,
      category: "SOC",
    ),
    Org(
      id: 5,
      name: "MAFIA - Multimedia Aficionados For Interested Artists",
      status: "Closed",
      imageUrl: "lib/assets/images/MAFIA.jpg",
      description:
          "Bringing together creative students who love multimedia and design.",
      fee: 120,
      category: "SOC",
    ),
    Org(
      id: 6,
      name: "GDSC - Google Developer Students Club",
      status: "Open",
      imageUrl: "lib/assets/images/GDSC.jpg",
      description:
          "Part of Google’s global community for student developers and innovators.",
      fee: 0,
      category: "Uniwide",
    ),
    Org(
      id: 7,
      name: "HAU Debate Congress",
      status: "Open",
      imageUrl: "lib/assets/images/HAU_DEBATE_CONGRESS.jpg",
      description:
          "Sharpen your skills in debate, public speaking, and critical thinking.",
      fee: 50,
      category: "Uniwide",
    ),
    Org(
      id: 8,
      name: "Juris Orbis",
      status: "Open",
      imageUrl: "lib/assets/images/JURIS_ORBIS.jpg",
      description:
          "An academic circle for students interested in law and legal studies.",
      fee: 75,
      category: "Uniwide",
    ),
    Org(
      id: 9,
      name: "Apl.de.Ap Music Studio",
      status: "Open",
      imageUrl: "lib/assets/images/APL_DE_AP.jpg",
      description:
          "A creative studio for aspiring musicians and performing artists at HAU.",
      fee: 200,
      category: "Uniwide",
    ),
    Org(
      id: 10,
      name: "AWS Learning Club",
      status: "Open",
      imageUrl: "lib/assets/images/AWS.jpg",
      description:
          "A student-led community focused on learning Amazon Web Services (AWS) cloud technologies and certifications.",
      fee: 100,
      category: "Uniwide",
    ),
  ];

  List<Org> get filteredOrgs {
    List<Org> filtered = selectedFilter == "All"
        ? orgs
        : orgs.where((org) => org.category == selectedFilter).toList();

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((org) =>
              org.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTextStyle(
        style: const TextStyle(fontFamily: "Afacad"),
        child: Stack(
          children: [
            // BACKGROUND IMAGE
            Positioned.fill(
              child: Image.asset(
                "lib/assets/images/background_1.png",
                fit: BoxFit.cover,
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // HEADER (Discover Orgs + Bell with real-time red dot)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Discover Orgs",
                          style: TextStyle(
                            fontFamily: "Afacad",
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        StreamBuilder<bool>(
                          stream: _hasNewNotifications(),
                          builder: (context, snapshot) {
                            final hasNew = snapshot.data ?? false;

                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications,
                                      color: Colors.white),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const NotificationsPage(),
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

                  // SEARCH BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            focusNode: _searchFocusNode, // <-- ADDED
                            textAlign: TextAlign.left,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: "Afacad",
                            ),
                            cursorColor: Colors.white,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.transparent,
                              hintText: "Search for orgs...",
                              hintStyle: TextStyle(
                                color: Colors.white70,
                                fontFamily: "Afacad",
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.white),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // FILTER CHIPS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: filters.map((filter) {
                        final isSelected = filter == selectedFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: ChoiceChip(
                                label: Text(
                                  filter,
                                  style: const TextStyle(
                                    fontFamily: "Afacad",
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    selectedFilter = filter;
                                  });
                                },
                                selectedColor: Colors.white.withOpacity(0.6),
                                backgroundColor: Colors.white.withOpacity(0.15),
                                checkmarkColor: Colors.black,
                                labelStyle: TextStyle(
                                  fontFamily: "Afacad",
                                  color: isSelected
                                      ? const Color.fromARGB(255, 56, 56, 56)
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ORG GRID
                  Expanded(
                    child: filteredOrgs.isEmpty
                        ? const Center(
                            child: Text(
                              "No organizations available",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "Afacad",
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3 / 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredOrgs.length,
                            itemBuilder: (context, index) {
                              final org = filteredOrgs[index];
                              final isRegistered =
                                  registeredOrgIds.contains(org.id);

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrgDetailsPage(
                                      org: org,
                                      onStatusChanged: (bool registered) {
                                        setState(() {
                                          if (registered) {
                                            registeredOrgIds.add(org.id);
                                          } else {
                                            registeredOrgIds.remove(org.id);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Card(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: Image.asset(
                                                org.imageUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  org.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontFamily: "Afacad",
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  org.status,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: "Afacad",
                                                    color: org.status == "Open"
                                                        ? Colors.white
                                                        : Colors.red,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  org.category,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                    fontFamily: "Afacad",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isRegistered)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            "Registered",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontFamily: "Afacad",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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

      // ---------- TRANSPARENT, FROSTED GLASS USER SHELL NAVBAR ----------
      bottomNavigationBar: _isSearchFocused
          ? null // <-- hides navbar when search focused
          : ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.transparent,
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    type: BottomNavigationBarType.fixed,
                    currentIndex: _currentIndex,
                    selectedItemColor: Colors.blue,
                    unselectedItemColor: Colors.white70,
                    elevation: 0,
                    onTap: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    items: const [
                      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                      BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
                      BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Saved"),
                      BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
