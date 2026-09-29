import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<String?> uploadToCloudinaryManual(File imageFile) async {
  // Thay bằng thông tin của bạn
  String cloudName = "dwsslesdj";
  String uploadPreset = "lelahanoi";

  var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

  var request = http.MultipartRequest("POST", uri);

  // Thêm file ảnh
  var file = await http.MultipartFile.fromPath('file', imageFile.path);
  request.files.add(file);

  // Thêm các thông số preset
  request.fields['upload_preset'] = uploadPreset;
  request.fields['folder'] = 'menu_images';

  var response = await request.send();

  if (response.statusCode == 200) {
    var responseData = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);
    var jsonMap = jsonDecode(responseString);
    return jsonMap['secure_url']; // Trả về link https
  } else {
    print("Upload thất bại. Mã lỗi: ${response.statusCode}");
    return null;
  }
}
