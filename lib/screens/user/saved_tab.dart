import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:org_registration_app/services/auth_service.dart';
import 'package:org_registration_app/models/orgs.dart';
import 'package:org_registration_app/screens/user/org_details.dart';

class SavedTab extends StatefulWidget {
  final AuthService auth;
  const SavedTab({super.key, required this.auth});

  @override
  State<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<SavedTab> {
  Map<String, List<Org>> _savedOrgsByCategory = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedOrgs();
  }

  Future<void> _loadSavedOrgs() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final orgs = await widget.auth.getUserRegisteredOrgs(uid);

    final grouped = <String, List<Org>>{};
    for (var org in orgs) {
      grouped.putIfAbsent(org.category, () => []).add(org);
    }

    setState(() {
      _savedOrgsByCategory = grouped;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 4;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "lib/assets/images/background_1.png",
              fit: BoxFit.cover,
            ),
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _savedOrgsByCategory.isEmpty
                  ? const Center(
                      child: Text(
                        "No registered organizations yet.",
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          color: Colors.white,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
                      itemCount: _savedOrgsByCategory.entries.length,
                      itemBuilder: (context, categoryIndex) {
                        final entry = _savedOrgsByCategory.entries.elementAt(categoryIndex);
                        final category = entry.key;
                        final orgs = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Header
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontFamily: 'Afacad',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero, // Remove extra padding
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: orgs.length,
                              itemBuilder: (context, index) {
                                final org = orgs[index];
                                return GestureDetector(
                                  onTap: () {
                                    final fullOrg = allOrgs.firstWhere(
                                      (o) => o.id == org.id,
                                      orElse: () => org,
                                    );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            OrgDetailsPage(org: fullOrg),
                                      ),
                                    ).then((_) => _loadSavedOrgs());
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: Colors.black.withOpacity(0.6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(12)),
                                            child: Image.asset(
                                              org.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                    Icons.image_not_supported),
                                              ),
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
                                                  fontFamily: 'Afacad',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                org.category,
                                                style: const TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
