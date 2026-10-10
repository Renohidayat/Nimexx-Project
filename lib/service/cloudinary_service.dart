import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  // TODO: UBAH CLOUD NAME DAN UPLOAD PRESET INI SESUAI DENGAN AKUN CLOUDINARY ANDA
  static const String cloudName = 'upg6pew9'; // Ganti dengan cloud name Anda (contoh: dhvwthnxq)
  static const String uploadPreset = 'nimexx_preset'; // Ganti dengan upload preset Anda (harus disetting Unsigned di Cloudinary)

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonMap['secure_url'];
      } else {
        debugPrint('Cloudinary Error: ${jsonMap['error']['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary Exception: $e');
      return null;
    }
  }
}
