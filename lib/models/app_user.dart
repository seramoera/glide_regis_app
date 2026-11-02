class AppUser {
  final int id;
  final String email;
  final String name;
  final bool isAdmin;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isAdmin,
  });

  factory AppUser.fromRow(Map<String, dynamic> row) => AppUser(
        id: row['id'] as int,
        email: row['email'] as String,
        name: row['name'] as String,
        isAdmin: (row['is_admin'] as int) == 1,
      );
}
