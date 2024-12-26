import 'package:mysql1/mysql1.dart';

class SqlService {
  static final settings = ConnectionSettings(
      host: '10.0.2.2',
      port: 3306,
      user: 'root',
      password: 'Jeffxddowdowdow1234@',
      db: 'lapboost');

  static Future<MySqlConnection> getConnection() async {
    final conn = await MySqlConnection.connect(settings);
    return conn;
  }

  static Future<ResultRow?> getUser(String email, String password) async {
    ResultRow? user;
    final conn = await MySqlConnection.connect(settings);
    try {
      final result = await conn.query('''
    SELECT *
    FROM customers
    WHERE Email = ? AND Password = ?
    ''', [email, password]);

      // If there is at least one result
      if (result.isNotEmpty) {
        // Directly assign the first row (only one expected)
        user = result.first;
        print(user);
        print(
            'Email: ${user['Email']}, Social Media Handle: ${user['Social_Media_Handle']}');
      } else {
        print('No user found with the provided credentials.');
      }
    } catch (e) {
      print('Error retrieving user: $e');
    } finally {
      await conn.close();
    }

    return user;
  }
}
