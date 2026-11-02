import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:org_registration_app/services/auth_service.dart';
import 'package:org_registration_app/screens/user/user_home.dart';
import 'package:org_registration_app/screens/user/search_tab.dart';
import 'package:org_registration_app/screens/user/saved_tab.dart';
import 'package:org_registration_app/screens/user/account_tab.dart';

class UserShell extends StatefulWidget {
  final AuthService auth;
  const UserShell({super.key, required this.auth});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      UserHome(auth: widget.auth),
      SearchTab(auth: widget.auth),
      SavedTab(auth: widget.auth),
      AccountTab(auth: widget.auth),
    ];

    return Scaffold(
      extendBody: true, // allow transparent nav bar overlay
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),

      // Frosted Glass Floating Navigation Bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: 371, // fixed width
          height: 79, // fixed height
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Material(
                color: Colors.white.withOpacity(0.05), // frosted glass effect
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: Colors.transparent,
                      indicatorColor: Colors.white.withOpacity(0.2),
                      labelTextStyle:
                          MaterialStateProperty.resolveWith<TextStyle>(
                        (states) => TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: states.contains(MaterialState.selected)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: states.contains(MaterialState.selected)
                              ? Colors.white
                              : Colors.white70,
                        ),
                      ),
                      iconTheme:
                          MaterialStateProperty.resolveWith<IconThemeData>(
                        (states) => IconThemeData(
                          size: 26,
                          color: states.contains(MaterialState.selected)
                              ? Colors.white
                              : Colors.white70,
                        ),
                      ),
                    ),
                    child: NavigationBar(
                      height: 79,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      selectedIndex: _index,
                      onDestinationSelected: (i) => setState(() => _index = i),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined, size: 26),
                          selectedIcon: Icon(Icons.home, size: 26),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.search_outlined, size: 26),
                          selectedIcon: Icon(Icons.search, size: 26),
                          label: 'Search',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.bookmark_border, size: 26),
                          selectedIcon: Icon(Icons.bookmark, size: 26),
                          label: 'Saved',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline, size: 26),
                          selectedIcon: Icon(Icons.person, size: 26),
                          label: 'Account',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
