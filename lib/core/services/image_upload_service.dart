import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ImageUploadService {
  const ImageUploadService();

  Future<String?> uploadMenuImage(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dwsslesdj/image/upload'),
      )
        ..fields['upload_preset'] = 'lelahanoi'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final body =
          jsonDecode(String.fromCharCodes(await response.stream.toBytes()));
      return response.statusCode == 200 ? body['secure_url'] as String? : null;
    } catch (_) {
      return null;
    }
  }
}
