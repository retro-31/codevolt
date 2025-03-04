import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashHelper {
  static String hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var digest = sha256.convert(bytes); // Hash using SHA-256
    return digest.toString(); // Convert to hex string
  }
}
