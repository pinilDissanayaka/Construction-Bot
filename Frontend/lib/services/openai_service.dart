import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class OpenAIService {
  static String? get _apiKey => dotenv.env['OPENAI_API_KEY'];
  
  /// Analyzes an image using OpenAI's Vision model and returns the description
  static Future<String> analyzeImage(String imagePath, {String userMessage = ''}) async {
    try {
      if (_apiKey == null) {
        throw Exception('OpenAI API key not found. Please check your .env file.');
      }

      // Log for debugging
      debugPrint('⚡ Analyzing image: $imagePath with user context: "$userMessage"');
      
      // Handle different file path formats
      String normalizedPath = imagePath;
      if (normalizedPath.startsWith('file://')) {
        normalizedPath = normalizedPath.replaceFirst('file://', '');
        // On Windows, also handle the extra slash
        if (Platform.isWindows && normalizedPath.startsWith('/')) {
          normalizedPath = normalizedPath.substring(1);
        }
      }
      
      final file = File(normalizedPath);
      if (!file.existsSync()) {
        throw Exception('Image file not found at path: $imagePath (normalized to: $normalizedPath)');
      }
      
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';
      
      // Log for debugging
      debugPrint('📤 Sending image to OpenAI API (${bytes.length / 1024} KB)');
      
      // Build a context-aware prompt with the user's message
      String promptText = 'You are a construction industry expert for Rise Construction. ';
      
      if (userMessage.isNotEmpty) {
        promptText += 'The user asks: "$userMessage". Please specifically address this question/request in your analysis. ';
      }
      
      promptText += 'Analyze this image in detail, focusing on construction elements, structural features, materials, potential issues, and provide professional insights relevant to construction work.';
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a construction industry expert working for Rise Construction. Provide detailed, professional analysis focused on construction aspects.',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': promptText,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 500,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      // Log the complete response for debugging
      debugPrint('📥 OpenAI API Response: ${const JsonEncoder.withIndent('  ').convert(responseData)}');
      
      if (response.statusCode == 200) {
        final analysisResult = responseData['choices'][0]['message']['content'];
        debugPrint('✅ Image analysis successful: ${analysisResult.substring(0, min(100, analysisResult.length))}...');
        return analysisResult;
      } else {
        final errorMessage = responseData['error']['message'];
        debugPrint('❌ Failed to analyze image: $errorMessage');
        throw Exception('Failed to analyze image: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Error analyzing image: ${e.toString()}');
      return 'Error analyzing image: ${e.toString()}';
    }
  }

  /// Analyzes a document file using OpenAI's model
  static Future<String> analyzeDocument(String filePath, {String userMessage = ''}) async {
    try {
      if (_apiKey == null) {
        throw Exception('OpenAI API key not found. Please check your .env file.');
      }

      // Log for debugging
      debugPrint('⚡ Analyzing document: $filePath with user context: "$userMessage"');
      
      final file = File(filePath.replaceFirst('file://', ''));
      if (!file.existsSync()) {
        throw Exception('Document file not found at path: $filePath');
      }
      
      final fileExtension = path.extension(filePath).toLowerCase();
      
      // Include user's message as context if provided
      String systemPrompt = 'You are a construction document specialist for Rise Construction. Provide professional analysis focused on the construction industry.';
      
      String userPrompt = '';
      if (userMessage.isNotEmpty) {
        userPrompt = 'User question/request: $userMessage\n\nPlease specifically address this question/request in your analysis.\n\n';
      }
      
      // For text-based files we can read directly
      if (['.txt', '.csv'].contains(fileExtension)) {
        final content = await file.readAsString();
        
        // Log for debugging
        debugPrint('📤 Sending text content to OpenAI API (${content.length} chars)');
        
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-4-turbo',
            'messages': [
              {
                'role': 'system',
                'content': systemPrompt,
              },
              {
                'role': 'user',
                'content': userPrompt + 'Please analyze this document content for a construction project:\n\n' + content,
              },
            ],
            'max_tokens': 500,
          }),
        );
        
        final responseData = jsonDecode(response.body);
        
        // Log the complete response for debugging
        debugPrint('📥 OpenAI API Response: ${const JsonEncoder.withIndent('  ').convert(responseData)}');
        
        if (response.statusCode == 200) {
          final analysisResult = responseData['choices'][0]['message']['content'];
          debugPrint('✅ Document analysis successful: ${analysisResult.substring(0, min(100, analysisResult.length))}...');
          return analysisResult;
        } else {
          final errorMessage = responseData['error']['message'];
          debugPrint('❌ Failed to analyze document: $errorMessage');
          throw Exception('Failed to analyze document: $errorMessage');
        }
      } 
      // For PDFs and other documents, we'll use file summarization approach
      else {
        // Start by sending a request with file metadata
        final fileSize = await file.length();
        final fileName = path.basename(filePath);
        
        // Log for debugging
        debugPrint('📤 Sending document metadata to OpenAI API for ${fileName} (${fileSize / 1024} KB)');
        
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-4-turbo',
            'messages': [
              {
                'role': 'system',
                'content': systemPrompt,
              },
              {
                'role': 'user',
                'content': userPrompt + 'This is a document with filename: $fileName, size: ${(fileSize / 1024).toStringAsFixed(2)} KB, and type: $fileExtension. Please provide a professional analysis of what this document contains and how it might be relevant to the user\'s question/request in the context of a construction project for Rise Construction.',
              },
            ],
            'max_tokens': 500,
          }),
        );
        
        final responseData = jsonDecode(response.body);
        
        // Log the complete response for debugging
        debugPrint('📥 OpenAI API Response: ${const JsonEncoder.withIndent('  ').convert(responseData)}');
        
        if (response.statusCode == 200) {
          final analysisResult = responseData['choices'][0]['message']['content'];
          debugPrint('✅ Document metadata analysis successful: ${analysisResult.substring(0, min(100, analysisResult.length))}...');
          return analysisResult;
        } else {
          final errorMessage = responseData['error']['message'];
          debugPrint('❌ Failed to analyze document metadata: $errorMessage');
          throw Exception('Failed to analyze document metadata: $errorMessage');
        }
      }
    } catch (e) {
      debugPrint('❌ Error analyzing document: ${e.toString()}');
      return 'Error analyzing document: ${e.toString()}';
    }
  }
  
  /// Sends a message along with analysis results to the backend
  static Future<Map<String, dynamic>> sendMessageWithAnalysis({
    required String message,
    required String userRole,
    String? chatId,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      // The backend chat API endpoint
      final String chatApiUrl = 'https://e52d-122-255-33-126.ngrok-free.app/chat/';
      
      debugPrint('📤 Sending message with analysis to backend');

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'message': message,
        'role': userRole,
      };

      // Add chat ID if available
      if (chatId != null) {
        requestBody['chat_id'] = chatId;
      }

      // Add attachments data if available
      if (attachments != null && attachments.isNotEmpty) {
        requestBody['attachments'] = attachments;
        debugPrint('📎 Sending ${attachments.length} attachments with analysis');
        
        // Log the first few characters of each attachment analysis for debugging
        for (var attachment in attachments) {
          final analysis = attachment['analysis'] as String;
          debugPrint('📄 Attachment: ${attachment['name']}, Analysis preview: ${analysis.substring(0, min(100, analysis.length))}...');
        }
      }

      // Log the request payload for debugging
      debugPrint('📦 Request payload: ${const JsonEncoder.withIndent('  ').convert(requestBody)}');

      // Send the HTTP request to the backend
      final response = await http.post(
        Uri.parse(chatApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Parse and return the response
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        debugPrint('✅ Backend response successful: ${response.statusCode}');
        return responseData;
      } else {
        debugPrint('❌ Backend request failed: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
        throw Exception('Failed to send message: ${responseData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('❌ Error sending message with analysis: ${e.toString()}');
      throw Exception('Failed to send message to backend: ${e.toString()}');
    }
  }
  
  // Helper function to get min value
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}