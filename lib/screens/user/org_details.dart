import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:org_registration_app/models/orgs.dart';
import 'package:org_registration_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class OrgDetailsPage extends StatefulWidget {
  Org org; // removed final to allow updating
  final void Function(bool isNowRegistered)? onStatusChanged;

  OrgDetailsPage({super.key, required this.org, this.onStatusChanged});

  @override
  State<OrgDetailsPage> createState() => _OrgDetailsPageState();
}

class _OrgDetailsPageState extends State<OrgDetailsPage>
    with AutomaticKeepAliveClientMixin<OrgDetailsPage> {
  final AuthService _authService = AuthService();

  bool _loading = true;
  bool _isRegistered = false;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _allPostsStream;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _cachedPosts;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _allPostsStream = FirebaseFirestore.instance
        .collection("posts")
        .orderBy("timestamp", descending: true)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        )
        .snapshots();

    _checkIfRegistered().then((_) {
      _fetchFullOrgIfNeeded();
    });
  }

  Future<void> _fetchFullOrgIfNeeded() async {
    if (widget.org.description.isEmpty ||
        widget.org.imageUrl.isEmpty ||
        widget.org.fee == 0 ||
        widget.org.status.isEmpty ||
        widget.org.category.isEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection("orgs")
          .doc(widget.org.id.toString())
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          widget.org = Org(
            id: widget.org.id,
            name: data['name'] ?? widget.org.name,
            description: data['description'] ?? widget.org.description,
            imageUrl: data['imageUrl'] ?? widget.org.imageUrl,
            status: data['status'] ?? widget.org.status,
            fee: data['fee'] ?? widget.org.fee,
            category: data['category'] ?? widget.org.category,
          );
        });
      }
    }
  }

  Future<void> _checkIfRegistered() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final orgs = await _authService.getUserRegisteredOrgs(uid);
    if (!mounted) return;

    final currentOrgId = widget.org.id.toString();
    setState(() {
      _isRegistered =
          orgs.any((o) => o.id.toString() == currentOrgId);
      _loading = false;
    });
  }

  Future<void> _toggleRegistration() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (_isRegistered) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Unregister?", style: TextStyle(fontFamily: "Afacad")),
          content: Text("Are you sure you want to unregister from ${widget.org.name}?", style: const TextStyle(fontFamily: "Afacad")),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel", style: TextStyle(fontFamily: "Afacad"))),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes", style: TextStyle(fontFamily: "Afacad"))),
          ],
        ),
      );

      if (confirm == true) {
        final uidRegisteredOrgs = await _authService.getUserRegisteredOrgs(uid);
        final orgToUnregister = uidRegisteredOrgs.firstWhere(
          (o) => o.id == widget.org.id,
          orElse: () => widget.org,
        );

        await _authService.unregisterFromOrg(uid, orgToUnregister);
        if (!mounted) return;
        setState(() => _isRegistered = false);
        widget.onStatusChanged?.call(false);
      }
    } else {
      await _authService.registerToOrg(uid, widget.org);
      if (!mounted) return;
      setState(() => _isRegistered = true);
      widget.onStatusChanged?.call(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registered for ${widget.org.name}!", style: const TextStyle(fontFamily: "Afacad"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: const Border(
                    bottom: BorderSide(color: Colors.white24, width: 1)),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(widget.org.name,
                    style: const TextStyle(fontFamily: "Afacad")),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Theme(
              data: Theme.of(context).copyWith(
                textTheme:
                    Theme.of(context).textTheme.apply(fontFamily: 'Afacad'),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset('lib/assets/images/background_1.png',
                        fit: BoxFit.cover),
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  widget.org.imageUrl.isNotEmpty
                                      ? widget.org.imageUrl
                                      : "assets/images/placeholder.png",
                                  fit: BoxFit.cover,
                                  width: 341,
                                  height: 341,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      width: 341,
                                      height: 341,
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          size: 50),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.org.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: "Afacad"),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    widget.org.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                            color: Colors.white70,
                                            fontFamily: "Afacad"),
                                    textAlign: TextAlign.start,
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Status: ${widget.org.status}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: widget.org.status == "Open"
                                          ? Colors.white
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "Afacad",
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  if (_isRegistered)
                                    _buildFrostedCard(
                                      context,
                                      title: "Announcements & Events",
                                      icon: Icons.announcement_outlined,
                                      content: StreamBuilder<
                                          QuerySnapshot<Map<String, dynamic>>>(
                                        stream: _allPostsStream,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                                  ConnectionState.waiting &&
                                              _cachedPosts == null) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          if (snapshot.hasData) {
                                            _cachedPosts = snapshot.data!.docs;
                                          }

                                          final orgIdStr =
                                              widget.org.id.toString();

                                          final filtered = (_cachedPosts ?? [])
                                              .where((doc) {
                                            final data = doc.data();
                                            final postOrgId =
                                                data["orgId"]?.toString() ?? "";

                                            if (postOrgId != orgIdStr) return false;

                                            final audience =
                                                (data["audience"] ?? "all")
                                                    .toString();

                                            if (audience == "all") return true;
                                            if (audience == "org-members" &&
                                                _isRegistered) return true;

                                            return false;
                                          }).toList();

                                          if (filtered.isEmpty) {
                                            return const Text(
                                              "No announcements or events yet.",
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontFamily: "Afacad"),
                                            );
                                          }

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: filtered.map((doc) {
                                              final data = doc.data();
                                              final isEvent =
                                                  data["type"] == "event";
                                              final contentText = (data["content"] ??
                                                      "")
                                                  .toString()
                                                  .replaceAll("<br>", "\n");
                                              final titleText =
                                                  isEvent ? (data["title"] ?? "") : null;

                                              DateTime? when;
                                              final eventDate = data["eventDate"];
                                              final ts = data["timestamp"];
                                              if (eventDate is Timestamp) {
                                                when = eventDate.toDate().toLocal();
                                              } else if (eventDate is String) {
                                                when = DateTime.tryParse(eventDate)
                                                    ?.toLocal();
                                              } else if (ts is Timestamp) {
                                                when = ts.toDate().toLocal();
                                              }

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.only(bottom: 12),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      isEvent
                                                          ? "[Event] ${titleText ?? ''}"
                                                          : contentText,
                                                      style: TextStyle(
                                                        color: isEvent
                                                            ? Colors.white
                                                            : Colors.white70,
                                                        fontWeight: isEvent
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        fontFamily: "Afacad",
                                                      ),
                                                    ),
                                                    if (when != null)
                                                      Text(
                                                        isEvent
                                                            ? "Date: ${when.toString().substring(0, 16)}"
                                                            : "Posted: ${when.toString().substring(0, 16)}",
                                                        style: const TextStyle(
                                                            color: Colors.white54,
                                                            fontSize: 12,
                                                            fontFamily: "Afacad"),
                                                      ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Audience: ${(data["audience"] ?? 'All').toString()}",
                                                      style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 12,
                                                          fontFamily: "Afacad"),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 16),

                                  if (_isRegistered)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.blue.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Pay membership fee to access this organization.",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontFamily: "Afacad",
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: 160,
                                                height: 36,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors
                                                        .blueAccent
                                                        .withOpacity(0.85),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    final uri = Uri.parse(
                                                        "https://forms.gle/YOUR_GOOGLE_FORM_LINK");
                                                    if (await canLaunchUrl(
                                                        uri)) {
                                                      await launchUrl(
                                                        uri,
                                                        mode: LaunchMode
                                                            .externalApplication,
                                                      );
                                                    }
                                                  },
                                                  child: const Text(
                                                    "Pay Membership",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: "Afacad",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_isRegistered) const SizedBox(height: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 20, left: 16, right: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // button to rightmost
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Registration",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[300],
                                              fontWeight: FontWeight.w500,
                                              fontFamily: "Afacad",
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Php ${widget.org.fee}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontFamily: "Afacad"),
                                      ),
                                    ],
                                  ),
                                 ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.org.status == "Open"
                                        ? (_isRegistered
                                            ? Colors.red.withOpacity(0.85)
                                            : Colors.white.withOpacity(0.85))
                                        : Colors.grey.withOpacity(0.6), // greyed out if closed
                                    foregroundColor: widget.org.status == "Open"
                                        ? (_isRegistered ? Colors.white : Colors.black87)
                                        : Colors.white70, // text color if closed
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: widget.org.status == "Open" ? _toggleRegistration : null, // disabled if closed
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _isRegistered ? "Unregister" : "Register",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Afacad",
                                      ),
                                    ),
                                  ),
                                ),

                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFrostedCard(
    BuildContext context, {
    required String title,
    IconData? icon,
    required Widget content,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) Icon(icon, color: Colors.white, size: 20),
                  if (icon != null) const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: "Afacad",
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              content,
            ],
          ),
        ),
      ),
    );
  }
}
