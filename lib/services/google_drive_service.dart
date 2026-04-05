import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class GoogleDriveService {
  // Ensure this URL is exactly what you got after setting "Who has access" to "Anyone"
  static const String _scriptUrl = 'https://script.google.com/macros/s/AKfycbympfS3Ahed29Sq_wZzkMti1h6sWAkbRU0GGJDPrLhk3aQHqhPgufHTUW0ibkYLVpoj9w/exec';

  Future<String?> uploadFile(File file) async {
    try {
      // 1. Prepare data
      List<int> fileBytes = await file.readAsBytes();
      String base64File = base64Encode(fileBytes);
      String fileName = p.basename(file.path);
      String mimeType = _getMimeType(fileName);

      debugPrint('Uploading to Google Drive via Script Proxy...');

      // 2. Prepare the request
      final body = jsonEncode({
        'base64': base64File,
        'fileName': fileName,
        'mimeType': mimeType,
      });

      // 3. Initial POST request
      var response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // 4. MANUALLY HANDLE 302 REDIRECT
      if (response.statusCode == 302) {
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          if (newUrl.contains('accounts.google.com')) {
            throw Exception("Access Denied: The script is redirecting to a Login Page. Please set 'Who has access' to 'Anyone' in the script deployment.");
          }
          debugPrint('Following redirect to get the result...');
          // Use GET to fetch the result from the redirect URL
          response = await http.get(Uri.parse(newUrl));
        }
      }

      // 5. Process the final response
      debugPrint('Final Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          debugPrint('Upload Successful: ${data['url']}');
          return data['url'];
        } else {
          throw Exception("Script Logic Error: ${data['message']}");
        }
      } else if (response.statusCode == 403) {
        throw Exception("Access Denied (403): Please set 'Who has access' to 'Anyone' in your Apps Script deployment.");
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.reasonPhrase}");
      }
    } catch (e) {
      debugPrint('--- PROXY UPLOAD FAILED ---');
      debugPrint('Error: $e');
      rethrow;
    }
  }

  String _getMimeType(String fileName) {
    String ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.pdf': return 'application/pdf';
      case '.jpg':
      case '.jpeg': return 'image/jpeg';
      case '.png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }
}
