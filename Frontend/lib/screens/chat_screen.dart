import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:rise/screens/Utility/file_storage_util.dart';
import 'package:rise/screens/models/chat_history.dart';
import 'package:rise/screens/models/chat_models.dart';
import 'package:rise/screens/settings.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rise/services/openai_service.dart';

/// ChatScreen widget that handles the chat interface and API communication
class ChatScreen extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const ChatScreen({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class Message {
  final String text;
  final bool isUser;
  final List<AttachmentItem>? attachments; // Add this property
  final DateTime timestamp;  // Add timestamp field

  Message({
    required this.text,
    required this.isUser,
    this.attachments, // Add this parameter
    required this.timestamp, // Add this parameter
  });
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  // API endpoint
  static const String _chatApiUrl =
      'https://e52d-122-255-33-126.ngrok-free.app/chat/';

  // Keys and controllers
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isAnalyzing = false;
  bool _isTyping = false;  // This variable will be used to show the typing animation
  bool _sendingMessage = false;  // Added this variable
  Map<String, String> _analysisResults = {};

  // Pickers for image and file selection
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoadingHistory = false;

  // State variables
  final List<Message> _messages = [];
  bool _isFirstMessage = true;
  bool _isLoading = false;

  // Collection of attachments for the current message being composed
  final List<AttachmentItem> _currentAttachments = [];

  final TextEditingController _searchController = TextEditingController();
  List<ChatHistory> _filteredChatHistory = [];

  // Add this method after initState
  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChatHistory = List.from(_chatHistory);
      } else {
        _filteredChatHistory =
            _chatHistory
                .where(
                  (chat) =>
                      chat.title.toLowerCase().contains(query.toLowerCase()) ||
                      chat.lastMessage.toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
      }
    });
  }

  // Add these variables to _ChatScreenState class
  final List<ChatHistory> _chatHistory = [];
  String? _currentChatId;

  // Add this method to _ChatScreenState class
  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      print('Loading chat history...'); // Debug print
      final response = await http.get(
        Uri.parse('${_chatApiUrl}history'),
        headers: {
          'Content-Type': 'application/json',
          'User-Email': widget.userEmail,
        },
      );

      print('Response status code: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Parsed ${data.length} chats'); // Debug print

        setState(() {
          _chatHistory.clear();
          _chatHistory.addAll(
            data.map((json) => ChatHistory.fromJson(json)).toList(),
          );
          _filteredChatHistory = List.from(_chatHistory);
          _isLoadingHistory = false;
        });

        print(
          'Chat history loaded: ${_chatHistory.length} items',
        ); // Debug print
      } else {
        print('Failed to load chats: ${response.statusCode}');
        setState(() {
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('Error loading chats: $e');
      setState(() {
        _isLoadingHistory = false;
      });
      _showErrorSnackBar('Error loading chat history: ${e.toString()}');
    }
  }

  // Add this method to _ChatScreenState class
  Future<void> _createNewChat() async {
    setState(() {
      _currentChatId = null;
      _messages.clear();
      _isFirstMessage = true;
    });
  }

  // Add animation controllers for typing animation
  late final List<AnimationController> _dotControllers;
  late final List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    // Load env file for API key
    dotenv.load(fileName: ".env");

    // Initialize animation controllers for typing dots
    _dotControllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    // Create animations with staggered delays
    _dotAnimations = List.generate(
      3,
      (index) => Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotControllers[index],
          curve: Curves.easeInOut,
        ),
      ),
    );

    // Start animations with staggered delays
    for (int i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _dotControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  // Add method to save chat to local storage
  Future<void> _saveChatToLocalStorage() async {
    try {
      // This is a simple implementation - you can expand this as needed
      print('Saving chat to local storage with id: $_currentChatId');
      
      // If we have no chat ID yet, skip saving
      if (_currentChatId == null) {
        print('No chat ID available, skipping local storage save');
        return;
      }
      
      // In a real implementation, you would save the chat messages to 
      // local storage here using shared_preferences, hive, or another solution
      
    } catch (e) {
      print('❌ Error saving chat to local storage: ${e.toString()}');
    }
  }

  // Update this method to fix the visibility issue of chat history
  Widget _buildChatHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search TextField
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF302F2F),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'TenorSans',
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search chats...',
                    hintStyle: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'TenorSans',
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _filterChats,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _filterChats('');
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),

        // "Chats" label
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Chats",
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'TenorSans',
              fontSize: 14,
            ),
          ),
        ),

        // Chat List - Modified to ensure visibility
        Expanded(
          child:
              _isLoadingHistory
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  )
                  : _filteredChatHistory.isEmpty
                  ? const Center(
                    child: Text(
                      'No chats yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'TenorSans',
                        fontSize: 14,
                      ),
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredChatHistory.length,
                    itemBuilder: (context, index) {
                      final chat = _filteredChatHistory[index];
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[800],
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                size: 20,
                                color: Colors.yellow,
                              ),
                            ),
                            title: Text(
                              chat.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'TenorSans',
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              chat.lastMessage,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontFamily: 'TenorSans',
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              _loadChatMessages(chat.id);
                              Navigator.pop(
                                context,
                              ); // Close drawer after selection
                            },
                          ),
                          if (index < _filteredChatHistory.length - 1)
                            const Divider(
                              color: Colors.grey,
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                        ],
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // Update dispose method
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose(); // Add this line

    // Dispose all animation controllers
    for (var controller in _dotControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // Add this method to _ChatScreenState class
  Future<void> _loadChatMessages(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('${_chatApiUrl}messages/$chatId'),
        headers: {
          'Content-Type': 'application/json',
          'User-Email': widget.userEmail,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _currentChatId = chatId;
          _messages.clear();
          _messages.addAll(
            data
                .map(
                  (json) => Message(
                    text: json['text'] as String,
                    isUser: json['is_user'] as bool,
                    attachments:
                        json['attachments'] != null
                            ? (json['attachments'] as List)
                                .map(
                                  (a) => AttachmentItem.fromJson(
                                    a as Map<String, dynamic>,
                                  ),
                                )
                                .toList()
                            : null,
                    timestamp: DateTime.parse(json['timestamp']), // Add this line
                  ),
                )
                .toList(),
          );
          _isFirstMessage = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading chat messages: ${e.toString()}');
    }
  }

  /// Get first letter of email for avatar
  String get _avatarLetter =>
      widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U';

  /// Handle selecting images from gallery
  /// Allows user to select multiple images (up to 5 total attachments)
  Future<void> _pickImages() async {
    // Check if attachment limit reached
    if (_currentAttachments.length >= 5) {
      _showErrorSnackBar('Maximum 5 attachments allowed.');
      return;
    }

    try {
      // Open image picker
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return;

      // Check if adding these would exceed limit
      if (_currentAttachments.length + images.length > 5) {
        _showErrorSnackBar(
          'Maximum 5 attachments allowed. Please select fewer files.',
        );
        return;
      }

      // Process each selected image
      for (var image in images) {
        // Validate file type
        if (!FileStorageUtil.isAllowedFileType(image.path)) {
          _showErrorSnackBar(
            'File type not supported: ${image.path.split('.').last}',
          );
          continue;
        }

        // Save image to local storage
        final savedPath = await FileStorageUtil.saveFile(File(image.path));
        final url = FileStorageUtil.generateFileUrl(savedPath);
        final fileName = path.basename(image.path);

        // Add to current attachments list
        setState(() {
          _currentAttachments.add(
            AttachmentItem(url: url, type: 'image', name: fileName),
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking images: ${e.toString()}');
    }
  }

  /// Handle selecting document files
  /// Allows user to select multiple files (up to 5 total attachments)
  Future<void> _pickFiles() async {
    // Check if attachment limit reached
    if (_currentAttachments.length >= 5) {
      _showErrorSnackBar('Maximum 5 attachments allowed.');
      return;
    }

    try {
      // Open file picker with allowed file types
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx', 'txt', 'csv', 'pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      // Check if adding these would exceed limit
      if (_currentAttachments.length + result.files.length > 5) {
        _showErrorSnackBar(
          'Maximum 5 attachments allowed. Please select fewer files.',
        );
        return;
      }

      // Process each selected file
      for (var file in result.files) {
        if (file.path == null) continue;

        // Validate file type
        if (!FileStorageUtil.isAllowedFileType(file.path!)) {
          _showErrorSnackBar('File type not supported: ${file.extension}');
          continue;
        }

        // Save file to local storage
        final savedPath = await FileStorageUtil.saveFile(File(file.path!));
        final url = FileStorageUtil.generateFileUrl(savedPath);

        // Add to current attachments list
        setState(() {
          _currentAttachments.add(
            AttachmentItem(url: url, type: 'document', name: file.name),
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking files: ${e.toString()}');
    }
  }

  /// Handle sending a message with attachments
  Future<void> _sendMessage() async {
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty && _currentAttachments.isEmpty) return;

    try {
      // Hide keyboard when sending a message
      FocusScope.of(context).unfocus();
      
      // Store attachments temporarily before clearing them
      final List<AttachmentItem> messageAttachments = 
          _currentAttachments.isNotEmpty ? List.from(_currentAttachments) : [];
      
      // Create a new message
      final newMessage = Message(
        text: messageText,
        isUser: true,
        timestamp: DateTime.now(),
        attachments: messageAttachments.isNotEmpty ? messageAttachments : null,
      );

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
        _isTyping = true;  // Start showing typing animation
        _sendingMessage = true;
        _currentAttachments.clear(); // Clear attachments immediately
      });

      // Start typing animation controllers
      for (int i = 0; i < _dotControllers.length; i++) {
        _dotControllers[i].repeat(reverse: true);
      }

      // Scroll to bottom to show typing indicator
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'message': messageText,
        'role': widget.userRole,
      };

      if (_currentChatId != null) {
        requestBody['chat_id'] = _currentChatId;
      }

      // Add attachments to request if any
      if (messageAttachments.isNotEmpty) {
        List<Map<String, dynamic>> attachmentData = [];

        for (var attachment in messageAttachments) {
          // We don't need to do explicit analysis anymore, just send the attachment
          attachmentData.add({
            'url': attachment.url,
            'type': attachment.type,
            'name': attachment.name,
            'analysis': '', // Empty analysis as we're not doing explicit analysis
          });
        }

        // Add attachment data to request
        requestBody['attachments'] = attachmentData;
      }

      print('📤 Sending request to backend: ${json.encode(requestBody)}');

      // Send request using OpenAIService
      final responseData = await OpenAIService.sendMessageWithAnalysis(
        message: messageText,
        userRole: widget.userRole,
        chatId: _currentChatId,
        attachments: requestBody['attachments'],
      );

      if (!mounted) return;

      final aiResponse = responseData['response'] ?? 'Sorry, I could not process your request.';
      _currentChatId = responseData['chat_id']; 

      // Save chat to local storage
      _saveChatToLocalStorage();

      setState(() {
        _messages.add(Message(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;  // Stop showing typing animation
        _sendingMessage = false;
        _isFirstMessage = false;
      });

      // Stop typing animation controllers
      for (var controller in _dotControllers) {
        controller.reset();
      }

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
    } catch (e) {
      setState(() {
        _isTyping = false;  // Make sure to stop the animation if there's an error
        _sendingMessage = false;
      });

      // Stop typing animation controllers in case of error
      for (var controller in _dotControllers) {
        controller.reset();
      }
      
      _showErrorSnackBar('Failed to send message: ${e.toString()}');
      print('❌ Error sending message: ${e.toString()}');
    }
  }

  /// Build attachment preview for current attachments
  /// Shows thumbnails of images and icons for documents in horizontal list
  Widget _buildAttachmentPreview() {
    // Don't show attachments during sending/typing
    if (_currentAttachments.isEmpty || _sendingMessage || _isTyping) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attachments list
        Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _currentAttachments.length,
            itemBuilder: (context, index) {
              final attachment = _currentAttachments[index];

              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail or file icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          attachment.type == 'image'
                              ? Image.file(
                                File(
                                  attachment.url.replaceFirst('file://', ''),
                                ),
                                fit: BoxFit.cover,
                              )
                              : const Icon(
                                Icons.insert_drive_file,
                                color: Colors.white70,
                              ),
                    ),

                    // Remove button
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentAttachments.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build message item with attachments
  /// Renders a message bubble with any attachments as thumbnails/icons above
  Widget _buildMessageItem(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            // Render attachments if present
            if (message.attachments != null && message.attachments!.isNotEmpty)
              Container(
                margin: EdgeInsets.only(
                  bottom: 8,
                  left: message.isUser ? 0 : 4,
                  right: message.isUser ? 4 : 0,
                ),
                height: 80,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: message.attachments!.length,
                  itemBuilder: (context, idx) {
                    final attachment = message.attachments![idx];
                    return GestureDetector(
                      onTap: () {
                        // Open attachment in full screen or external viewer
                        _openAttachment(attachment);
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: message.isUser 
                              ? const Color(0xFF2E2E2E) 
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Thumbnail or file icon
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                                child: attachment.type == 'image'
                                    ? Image.file(
                                        File(
                                          attachment.url.replaceFirst('file://', ''),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.insert_drive_file,
                                        color: Colors.white70,
                                      ),
                              ),
                            ),
                            // Filename (if not an image)
                            if (attachment.type != 'image' && attachment.name != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4, 
                                  vertical: 2,
                                ),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _getShortFilename(attachment.name ?? ''),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Message text (if present)
            if (message.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      message.isUser
                          ? const Color(0xFF2E2E2E)
                          : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'TenorSans',
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to get shortened filename for display
  String _getShortFilename(String filename) {
    if (filename.length <= 10) return filename;
    final extension = filename.split('.').last;
    final name = filename.substring(0, filename.length - extension.length - 1);
    if (name.length <= 6) return filename;
    return '${name.substring(0, 6)}....$extension';
  }
  
  // Method to open attachment in full screen or external viewer
  void _openAttachment(AttachmentItem attachment) {
    try {
      final file = File(attachment.url.replaceFirst('file://', ''));
      if (attachment.type == 'image') {
        // Show image in full screen dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  backgroundColor: Colors.black87,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    attachment.name ?? 'Image',
                    style: const TextStyle(
                      fontFamily: 'TenorSans',
                      fontSize: 16,
                    ),
                  ),
                  centerTitle: true,
                ),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(file),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // For non-image files, show a snackbar since we can't open them directly
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File: ${attachment.name ?? "Unknown file"}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error opening file: ${e.toString()}');
    }
  }

  // Add a typing indicator widget
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Enhanced typing animation bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildAnimatedDot(index),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced animated dot with proper animation controller
  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _dotControllers[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _dotAnimations[index].value,
          child: Container(
            height: 8,
            width: 8,
            decoration: const BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  /// Scroll chat to bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          textColor: Colors.white,
        ),
      ),
    );
  }

  // Show a dark popup menu with photos and files options
  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // Get screen size for positioning
        final screenSize = MediaQuery.of(context).size;

        return Stack(
          children: [
            Positioned(
              left: 16,
              bottom: 100, // Position above input area
              child: Container(
                width: screenSize.width * 0.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos option
                    ListTile(
                      leading: Image.asset(
                        'assets/images/img.png',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Photos',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'TenorSans',
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImages(); // Call image picker
                      },
                    ),
                    // Files option
                    ListTile(
                      leading: Image.asset(
                        'assets/images/Folder.png',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Files',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'TenorSans',
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickFiles(); // Call file picker
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,

      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 31, 31, 31),
        child: SafeArea(
          child: Column(
            children: [
              // Logo and company name
              ListTile(
                leading: Image.asset(
                  'assets/images/rise_construction01.png',
                  width: 36,
                  height: 36,
                ),
                title: const Text(
                  "Rise Construction",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'TenorSans',
                    fontSize: 16,
                  ),
                ),
              ),

              // Move user role badge to the left side
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF302F2F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        color: Colors.yellow,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.userRole,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'TenorSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // New Chat button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _createNewChat();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text(
                          'New Chat',
                          style: TextStyle(
                            fontFamily: 'TenorSans',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Chat history with search
              Expanded(child: _buildChatHistoryList()),

              // Bottom user profile section
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.yellow,
                      child: Text(
                        _avatarLetter,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'TenorSans',
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          widget.userEmail,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'TenorSans',
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Image.asset('assets/images/Menu.png', width: 24, height: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        centerTitle: true,
        title: const Text(
          "Rise AI",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'TenorSans',
            fontSize: 16,
          ),
        ),
        elevation: 0,
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // Messages or welcome screen
            _messages.isEmpty
                ? Padding(
                  padding: const EdgeInsets.only(bottom: 300),
                  child: Center(
                    child: SingleChildScrollView(
                      // Add this to make content scrollable if needed
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/rise_construction01.png',
                            height: 80,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "How can I help with your construction project?",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'TenorSans',
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _isTyping 
                        ? _messages.length + 1 
                        : _messages.length,
                    itemBuilder: (context, index) {
                      // Show typing indicator when waiting for response
                      if (_isTyping && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
                ),

            // Bottom container with text input and attachment options
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 58, 57, 57),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Attachment preview area - shows selected files/images
                    // Only show if not in sending state
                    if (!_sendingMessage && !_isTyping)
                      _buildAttachmentPreview(),

                    // Text input field
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 15),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: "Chat with Rise Construction...",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'TenorSans',
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'TenorSans',
                          fontSize: 16,
                        ),
                        cursorColor: Colors.white,
                        onSubmitted: (_) => _sendingMessage ? null : _sendMessage(),
                      ),
                    ),

                    // Bottom row with attachment button and send button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Plus icon -> Show the attach options
                        Container(
                          height: 36,
                          width: 36,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 97, 94, 94),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                            // Disable during sending
                            onPressed: _sendingMessage ? null : _showAttachOptions,
                          ),
                        ),

                        // Attachment counter (shows how many files selected)
                        // Only show if not in sending state
                        if (_currentAttachments.isNotEmpty && !_sendingMessage && !_isTyping)
                          Text(
                            '${_currentAttachments.length} attached',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontFamily: 'TenorSans',
                              fontSize: 12,
                            ),
                          ),

                        // Send button
                        Container(
                          height: 36,
                          width: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Image.asset(
                              'assets/images/button.png',
                              width: 36,
                              height: 36,
                            ),
                            // Disable during sending
                            onPressed: _sendingMessage ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
