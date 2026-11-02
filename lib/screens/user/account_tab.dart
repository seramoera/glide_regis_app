import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:org_registration_app/services/auth_service.dart';
import 'package:org_registration_app/screens/auth/login_screen.dart';
import 'package:org_registration_app/screens/user/user_shell.dart';
import 'package:org_registration_app/screens/user/notifications_page.dart';
import 'package:org_registration_app/models/orgs.dart';
import 'package:org_registration_app/screens/user/org_details.dart';

// Global route observer
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class AccountTab extends StatefulWidget {
  final AuthService auth;
  const AccountTab({super.key, required this.auth});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> with RouteAware {
  File? _profileImage;
  bool _isPickingImage = false;
  bool _loadingOrgs = true;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _hasUnreadNotifications = false;
  List<int> userOrgIds = [];
  Map<String, String> userData = {
    "First Name": "",
    "Last Name": "",
    "Email": "",
    "Contact": "",
    "Date of Birth": "",
    "Address": "",
  };
  List<Org> joinedOrgs = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadJoinedOrgs();
    _listenToNotifications();
    _loadLocalProfileImage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadJoinedOrgs();
  }

  Future<void> _loadLocalProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${user.uid}_profile.jpg';
    final file = File(path);
    if (await file.exists()) {
      setState(() => _profileImage = file);
    }
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final data = await widget.auth.getUserRegistration(user.uid);
      if (data != null) {
        setState(() {
          userData = {
            "First Name": data["firstName"] ?? "",
            "Last Name": data["lastName"] ?? "",
            "Email": data["email"] ?? "",
            "Contact": data["contact"] ?? "",
            "Address":
                "${data["street"] ?? ""}, ${data["barangay"] ?? ""}, ${data["city"] ?? ""}",
            "Date of Birth": data["dob"] ?? "",
          };
        });
      }
    }
  }

  Future<void> _loadJoinedOrgs() async {
    setState(() => _loadingOrgs = true);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final orgs = await widget.auth.getUserRegisteredOrgs(uid);
      setState(() {
        joinedOrgs = orgs;
        userOrgIds = orgs.map((o) => o.id).toList();
        _loadingOrgs = false;
      });
    }
  }

  void _listenToNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _firestore.collection("users").doc(uid).snapshots().listen((userDoc) {
      if (!userDoc.exists) return;
      final dismissed =
          List<String>.from(userDoc.data()?["dismissedNotifications"] ?? []);

      _firestore
          .collection("posts")
          .orderBy("timestamp", descending: true)
          .snapshots()
          .listen((snapshot) {
        final posts = snapshot.docs.where((doc) {
          if (dismissed.contains(doc.id)) return false;
          final data = doc.data();
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

        setState(() {
          _hasUnreadNotifications = posts.isNotEmpty;
        });
      });
    });
  }

  Future<void> _pickProfileImage() async {
    setState(() => _isPickingImage = true);
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        final user = _auth.currentUser;
        if (user == null) return;
        final directory = await getApplicationDocumentsDirectory();
        final localPath = '${directory.path}/${user.uid}_profile.jpg';
        final File localImage = await File(picked.path).copy(localPath);
        setState(() => _profileImage = localImage);
      }
    } catch (e) {
      debugPrint("Error picking or saving image: $e");
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(auth: widget.auth),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print("Sign out error: $e");
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete",
            style: TextStyle(fontFamily: 'Afacad')),
        content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
            style: TextStyle(fontFamily: 'Afacad')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text("Cancel", style: TextStyle(fontFamily: 'Afacad'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text("Delete", style: TextStyle(fontFamily: 'Afacad'))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await widget.auth.deleteUser(user.uid);
          await user.delete();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => LoginScreen(auth: widget.auth),
              ),
              (route) => false,
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error deleting account: $e")));
      }
    }
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Afacad',
                fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontFamily: 'Afacad'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liquidCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/background_1.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              // ---------- TRANSPARENT FROSTED GLASS HEADER ----------
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: kToolbarHeight + MediaQuery.of(context).padding.top,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: 12,
                      right: 12,
                    ),
                    color: Colors.white.withOpacity(0.15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserShell(auth: widget.auth),
                              ),
                            );
                          },
                        ),
                        const Text(
                          "Account",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Afacad",
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                                );
                              },
                            ),
                            if (_hasUnreadNotifications)
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomPadding), // <-- dynamic bottom padding
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white24,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _isPickingImage
                              ? const CircularProgressIndicator(color: Colors.white)
                              : (_profileImage == null
                                  ? const Icon(Icons.person, size: 60, color: Colors.white54)
                                  : null),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _liquidCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Account Details",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Afacad',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            const SizedBox(height: 12),
                            ...userData.entries
                                .map((entry) => _buildUserInfoRow(entry.key, entry.value))
                                .toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Joined Organizations
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Joined Organizations",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Afacad',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _loadingOrgs
                              ? const Center(
                                  child: CircularProgressIndicator(color: Colors.white))
                              : joinedOrgs.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Center(
                                        child: Text(
                                          "No organizations joined yet.",
                                          style: TextStyle(
                                              color: Colors.white70, fontFamily: 'Afacad'),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: joinedOrgs.map((org) {
                                        final fullOrg = allOrgs.firstWhere(
                                          (o) => o.id == org.id,
                                          orElse: () => org,
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 6),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                    color: Colors.white.withOpacity(0.2)),
                                              ),
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  radius: 22,
                                                  backgroundImage: AssetImage(
                                                    fullOrg.imageUrl.isNotEmpty
                                                        ? fullOrg.imageUrl
                                                        : "lib/assets/images/placeholder.png",
                                                  ),
                                                  backgroundColor: Colors.white24,
                                                ),
                                                title: Text(
                                                  fullOrg.name,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Afacad',
                                                      fontWeight: FontWeight.w600),
                                                ),
                                                trailing: const Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Colors.white54,
                                                  size: 16,
                                                ),
                                                onTap: () async {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            OrgDetailsPage(org: fullOrg)),
                                                  );
                                                  _loadJoinedOrgs();
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              minimumSize: const Size(140, 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _signOut,
                            child: const Text(
                              "Sign Out",
                              style: TextStyle(fontFamily: 'Afacad'),
                            ),
                          ),
                          const SizedBox(width: 20),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              minimumSize: const Size(140, 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _deleteAccount,
                            child: const Text(
                              "Delete Account",
                              style: TextStyle(color: Colors.redAccent, fontFamily: 'Afacad'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
