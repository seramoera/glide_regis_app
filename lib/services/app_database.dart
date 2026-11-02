import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  Database get db => _db!;

  bool get isWeb => kIsWeb;

  Future<void> init() async {
    if (isWeb) {
      // nothing to init for SharedPreferences
      return;
    }

    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'org_registration.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            name TEXT NOT NULL,
            is_admin INTEGER NOT NULL DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL UNIQUE,
            date_of_birth TEXT,
            contact_number TEXT,
            address_line TEXT,
            barangay TEXT,
            city TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE clubs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            fee INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'Open'
          );
        ''');

        await db.execute('''
          CREATE TABLE registrations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            club_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(user_id, club_id),
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(club_id) REFERENCES clubs(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            club_id INTEGER NOT NULL,
            UNIQUE(user_id, club_id)
          );
        ''');

        // Seed admin
        await db.insert('users', {
          'email': 'admin@school.edu',
          'password': 'admin123',
          'name': 'Admin User',
          'is_admin': 1,
        });

        // Seed clubs
        final seedClubs = [
          {
            'name': 'AWS Learning Club - HAU',
            'description': 'Cloud study jams and certifications.',
            'fee': 150,
            'status': 'Open',
          },
          {
            'name': 'Code Geeks',
            'description': 'Coding meetups, projects, and reviews.',
            'fee': 150,
            'status': 'Open',
          },
          {
            'name': 'LOOP',
            'description': 'Open source and Linux enthusiasts.',
            'fee': 0,
            'status': 'Closed',
          },
          {
            'name': 'CSIA',
            'description': 'Cybersecurity initiative and awareness.',
            'fee': 100,
            'status': 'Open',
          },
        ];
        for (final c in seedClubs) {
          await db.insert('clubs', c);
        }
      },
    );
  }

  // -------------------- USERS --------------------
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    if (isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getStringList("users") ?? [];
      for (final u in users) {
        final data = jsonDecode(u);
        if (data["email"] == email.trim()) {
          return Map<String, dynamic>.from(data);
        }
      }
      return null;
    }

    final rows =
        await db.query('users', where: 'email = ?', whereArgs: [email.trim()]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> createUser({
    required String email,
    required String password,
    required String name,
    bool isAdmin = false,
  }) async {
    if (isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getStringList("users") ?? [];
      final id = users.length + 1;
      final user = {
        "id": id,
        "email": email.trim(),
        "password": password,
        "name": name.trim(),
        "is_admin": isAdmin ? 1 : 0,
      };
      users.add(jsonEncode(user));
      await prefs.setStringList("users", users);
      return id;
    }

    final id = await db.insert('users', {
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      'is_admin': isAdmin ? 1 : 0,
    });
    await db.insert('profiles', {'user_id': id});
    return id;
  }

  // -------------------- PROFILES --------------------
  Future<Map<String, dynamic>?> profileOf(int userId) async {
    if (isWeb) {
      // simplified for demo – web stores only users
      return {};
    }

    final rows =
        await db.query('profiles', where: 'user_id = ?', whereArgs: [userId]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveProfile({
    required int userId,
    String? dobIso,
    String? contact,
    String? address,
    String? barangay,
    String? city,
  }) async {
    if (isWeb) return; // skip for web

    await db.update(
      'profiles',
      {
        'date_of_birth': dobIso,
        'contact_number': contact,
        'address_line': address,
        'barangay': barangay,
        'city': city,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // -------------------- CLUBS --------------------
  Future<List<Map<String, dynamic>>> allClubs(
      {String? query, String? status}) async {
    if (isWeb) {
      // demo clubs (static for web)
      final clubs = [
        {
          "id": 1,
          "name": "AWS Learning Club - HAU",
          "description": "Cloud study jams and certifications.",
          "fee": 150,
          "status": "Open",
        },
        {
          "id": 2,
          "name": "Code Geeks",
          "description": "Coding meetups, projects, and reviews.",
          "fee": 150,
          "status": "Open",
        },
      ];
      return clubs;
    }

    String where = '';
    final args = <dynamic>[];
    if (query != null && query.trim().isNotEmpty) {
      where += '${where.isEmpty ? '' : ' AND '}name LIKE ?';
      args.add('%${query.trim()}%');
    }
    if (status != null && status.isNotEmpty) {
      where += '${where.isEmpty ? '' : ' AND '}status = ?';
      args.add(status);
    }
    return db.query('clubs',
        where: where.isEmpty ? null : where,
        whereArgs: args,
        orderBy: 'name ASC');
  }

  // (favorites, registrations etc. can stay as-is; you can no-op them for web if needed)
}
