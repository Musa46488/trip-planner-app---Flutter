import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:venture_scape/screens/places/new_places.dart';


class MyChatbot extends StatelessWidget {
  const MyChatbot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatScreen();
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

// Enum to track conversation state
enum ConversationState {
  initial,
  waitingForPlaceConfirmation,
  waitingForPlaceDetails,
  waitingForCarDetails,
  completed
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final _textController = TextEditingController();
  final List<types.Message> _messages = [];
  late types.User _user;
  late types.User _bot;
  late AutoScrollController _scrollController;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State management variables
  ConversationState _currentState = ConversationState.initial;
  Map<String, dynamic>? _lastTextProcessingResult;
  List<String>? _confirmedPlaces;
  String? _lastUserInput;
  bool _isProcessing = false;

  User? get currentUser => _auth.currentUser;
  String? getCurrentUserId() => _auth.currentUser?.uid;

  final String link = "https://9a669ecfdba6.ngrok-free.app";

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();

    final userId = _auth.currentUser?.uid ?? 'default_user';
    _user = types.User(
      id: userId,
      firstName: _auth.currentUser?.displayName ?? 'You',
    );

    _bot = const types.User(
      id: 'bot_1',
      firstName: 'Plan with AI',
    );

    // Add welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addBotMessage('Hello! I can help you plan trips and find directions. What would you like to do today?');
    });
  }

  Future<void> makeApiCalls(String userInput) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Handle different conversation states
    switch (_currentState) {
      case ConversationState.initial:
        await _handleInitialInput(userInput);
        break;
      case ConversationState.waitingForPlaceConfirmation:
        await _handlePlaceConfirmation(userInput);
        break;
      case ConversationState.waitingForPlaceDetails:
        await _handlePlaceDetails(userInput);
        break;
      case ConversationState.waitingForCarDetails:
        await _handleCarDetails(userInput);
        break;
      case ConversationState.completed:
        await _handleInitialInput(userInput); // Reset and start new conversation
        break;
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _handleInitialInput(String userInput) async {
    final loadingMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    _addBotMessage('Processing your request...', id: loadingMessageId);

    try {
      // Call text_processing endpoint
      final encodedInput = Uri.encodeComponent(userInput);
      final response = await http.get(
        Uri.parse('$link/text_processing?user_input=$encodedInput'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 25));

      // Remove loading message
      setState(() {
        _messages.removeWhere((m) => m.id == loadingMessageId);
      });

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          _lastTextProcessingResult = responseData;
          _lastUserInput = userInput;
          print(responseData);

          if (responseData['intent'] == 'Plan Trip Intent') {
            await _handlePlanTripIntent(responseData);
          } else if (responseData['intent'] == 'Places Intent') {
            await _handlePlacesIntent(responseData);
          } else {
            // Handle irrelevant intent
            _addBotMessage('I understand you want to: ${responseData['intent']}. However, I can currently help with trip planning and finding directions between places. Please ask me to plan a trip or get directions between two places.');
            _resetConversationState();
          }
        } catch (e) {
          _addBotMessage('Received response but had trouble processing it.');
          debugPrint('Response parsing error: $e\nResponse body: ${response.body}');
          _resetConversationState();
        }
      } else {
        _addBotMessage('Sorry, the server responded with an error (${response.statusCode})');
        debugPrint('Server error: ${response.statusCode}\n${response.body}');
        _resetConversationState();
      }
    } catch (e) {
      _handleApiError(loadingMessageId, 'An error occurred: ${e.toString()}');
      _resetConversationState();
    }
  }

  Future<void> _handlePlanTripIntent(Map<String, dynamic> responseData) async {
    try {
      // Call plan_trip endpoint
      final encodedData = Uri.encodeComponent(jsonEncode(responseData));
      final response = await http.get(
        Uri.parse('$link/plan_trip?detail=$encodedData'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 50));

      if (response.statusCode == 200) {
        final tripData = jsonDecode(response.body);
        print(tripData);
        print(tripData.runtimeType);

        // Format and display trip plan
        String formattedPlan = _formatTripPlan(tripData);
        _addBotMessage(formattedPlan);

      } else {
        _addBotMessage('Sorry, I couldn\'t generate your trip plan right now.');
        _resetConversationState();
      }
    } catch (e) {
      _addBotMessage('Error generating trip plan: ${e.toString()}');
      _resetConversationState();
    }
  }

  Future<void> _handlePlacesIntent(Map<String, dynamic> responseData) async {
    // Check if places are available in response
    final places = responseData['places'];
    print(places);
    print(places.runtimeType);

    if (places != null && places['source'] != null && places['destination'] != null) {
      // Places are available, use them directly
      _confirmedPlaces = [places['source'], places['destination']];
      _addBotMessage("Great! I found these places:\nFrom: ${places['source']}\nTo: ${places['destination']}\n\nAre these correct? (yes/no)");
      print("Confirmed Places are");
      print(_confirmedPlaces);
      _currentState = ConversationState.waitingForPlaceConfirmation;
    } else {
      // Places are not clear, navigate to places selection screen
      _addBotMessage(responseData['message'] ?? 'I couldn\'t identify your source and destination clearly. Please select your places from the places selection screen.');
      _addBotMessage('Opening places selection screen...');

      // Navigate to FindPlaces screen
      _navigateToPlacesScreen();
    }
  }

  Future<void> _handlePlaceConfirmation(String userInput) async {
    final input = userInput.toLowerCase().trim();

    if (input.contains('yes') || input.contains('correct') || input.contains('right')) {
      _addBotMessage('Perfect! Now please provide your car details for fuel cost calculation (e.g., "Honda Civic with 12 km/l fuel average")');
      _currentState = ConversationState.waitingForCarDetails;
    } else if (input.contains('no') || input.contains('wrong') || input.contains('incorrect')) {
      _addBotMessage('No problem! Let me help you select the correct places.');
      _navigateToPlacesScreen();
    } else {
      _addBotMessage('Please answer with "yes" or "no" - are the places correct?');
    }
  }

  Future<void> _handlePlaceDetails(String userInput) async {
    // This would be called if user provides place details manually
    // For now, we'll process it as initial input
    await _handleInitialInput(userInput);
  }

  Future<void> _handleCarDetails(String userInput) async {
    if (_confirmedPlaces == null || _confirmedPlaces!.length < 2) {
      _addBotMessage('Something went wrong with the places. Let\'s start over.');
      _resetConversationState();
      return;
    }

    final loadingMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    _addBotMessage('Calculating directions and fuel costs...', id: loadingMessageId);
    print(userInput);
    print(_confirmedPlaces);
    try {
      // Call get_directions endpoint
      final encodedInput = Uri.encodeComponent(userInput);
      final encodedPlaces = Uri.encodeComponent(jsonEncode(_confirmedPlaces));

      final response = await http.get(
        Uri.parse('$link/get_directions?user_input=$encodedInput&places=$encodedPlaces'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 50));

      // Remove loading message
      setState(() {
        _messages.removeWhere((m) => m.id == loadingMessageId);
      });

      if (response.statusCode == 200) {
        final directionsData = jsonDecode(response.body);

        if (directionsData['status'] == 'success') {
          String formattedDirections = _formatDirectionsResponse(directionsData);
          _addBotMessage(formattedDirections, id: "10");

          _addBotMessage('Completed.', id:  "11");
          _currentState = ConversationState.completed;
        } else {
          _addBotMessage('Sorry, I couldn\'t calculate the directions and costs right now.');
          _resetConversationState();
        }
      } else {
        _addBotMessage('Sorry, there was an error calculating your route.');
        _resetConversationState();
      }
    } catch (e) {
      _handleApiError(loadingMessageId, 'Error calculating directions: ${e.toString()}');
      _resetConversationState();
    }
  }

  void _navigateToPlacesScreen() async {
    final result = await navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => FindPlaces(
          onPlacesSelected: (source, destination) {
            _confirmedPlaces = [source, destination];
            _addBotMessage('Great! Route set from $source to $destination.');
            _addBotMessage('Now provide car details (e.g., "Honda City Model 2020")');
            _currentState = ConversationState.waitingForCarDetails;
          },
        ),
      ),
    );

    // Handle result if returned from navigation
    if (result != null && result is Map<String, String>) {
      _confirmedPlaces = [result['source']!, result['destination']!];
      print(_confirmedPlaces);
      _addBotMessage('Great! I\'ve set your route from ${result['source']} to ${result['destination']}.');
      _addBotMessage('Now provide car details (e.g., "Honda City Model 2020")');
      _currentState = ConversationState.waitingForCarDetails;
    }
  }

  String _formatTripPlan(dynamic tripData) {
    if (tripData is Map) {
      String formatted = '🎯 Here\'s your trip plan:\n\n';

      tripData.forEach((key, value) {
        formatted += '📍 $key:\n';
        if (value is List) {
          for (var item in value) {
            formatted += '  • $item\n';
          }
        } else {
          formatted += '  • $value\n';
        }
        formatted += '\n';
      });

      return formatted;
    } else if (tripData is String) {
      return '🎯 Here\'s your trip plan:\n\n$tripData';
    } else {
      return '🎯 Here\'s your trip plan:\n\n${tripData.toString()}';
    }
  }

  String _formatDirectionsResponse(Map<String, dynamic> data) {
    try {
      String formatted = '';

      // Handle directions - could be string, map, or list
      if (data['directions'] != null) {
        String directionsText = _formatDirections(data['directions']);
        formatted += '📍 Directions:\n$directionsText\n\n';
      }

      // Handle routes - could be string, map, or list
      if (data['routes'] != null) {
        String routesText = _formatRoutes(data['routes']);
        formatted += '🗺️ Optimized Route:\n$routesText\n\n';
      }

      // Handle distance - should be a number or string
      if (data['distance'] != null) {
        formatted += '📏 Total Distance: ${data['distance']}\n\n';
      }

      // Handle cost - should be a number or string
      if (data['cost'] != null) {
        formatted += '💰 Estimated Fuel Cost: ${data['cost']}\n\n';
      }

      formatted += 'Have a safe journey! 🛣️';

      return formatted;
    } catch (e) {
      debugPrint('Error formatting directions response: $e');
      return 'Route information received but formatting failed. Please try again.';
    }
  }

  String _formatDirections(dynamic directions) {
    if (directions == null) return 'No directions available';

    if (directions is String) {
      return directions;
    } else if (directions is Map) {
      // Handle Google Directions API response
      if (directions.containsKey('routes') && directions['routes'] is List) {
        List routes = directions['routes'];
        if (routes.isNotEmpty) {
          var route = routes[0];
          if (route.containsKey('legs') && route['legs'] is List) {
            List legs = route['legs'];
            String result = '';
            for (var leg in legs) {
              if (leg.containsKey('steps') && leg['steps'] is List) {
                List steps = leg['steps'];
                for (int i = 0; i < steps.length; i++) {
                  var step = steps[i];
                  if (step.containsKey('html_instructions')) {
                    // Remove HTML tags and decode HTML entities
                    String instruction = step['html_instructions']
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .replaceAll('&nbsp;', ' ')
                        .replaceAll('&amp;', '&')
                        .replaceAll('&lt;', '<')
                        .replaceAll('&gt;', '>')
                        .replaceAll('&quot;', '"');

                    result += '${i + 1}. $instruction\n';
                  }
                }
              }
            }
            return result.isNotEmpty ? result : 'Directions available but could not parse steps';
          }
        }
      }
      return 'Directions: ${directions.toString()}';
    } else if (directions is List) {
      return directions.map((item) => '• $item').join('\n');
    } else {
      return directions.toString();
    }
  }

  String _formatRoutes(dynamic routes) {
    if (routes == null) return 'No route information available';

    if (routes is String) {
      return routes;
    } else if (routes is Map) {
      // Format map data nicely
      String result = '';
      routes.forEach((key, value) {
        result += '• $key: $value\n';
      });
      return result.isNotEmpty ? result : routes.toString();
    } else if (routes is List) {
      return routes.map((item) => '• $item').join('\n');
    } else {
      return routes.toString();
    }
  }

  void _resetConversationState() {
    _currentState = ConversationState.initial;
    _lastTextProcessingResult = null;
    _confirmedPlaces = null;
    _lastUserInput = null;
  }

  void _handleApiError(String loadingMessageId, String errorMessage) {
    setState(() {
      _messages.removeWhere((m) => m.id == loadingMessageId);
    });
    _addBotMessage(errorMessage);
    debugPrint('API Error: $errorMessage');
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {String? id}) {
    if (_isDisposed) return;

    try {
      final trimmedText = text.trim();
      if (trimmedText.isEmpty) {
        debugPrint('Attempted to add empty message');
        return;
      }

      final message = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: id ?? 'bot_${DateTime.now().millisecondsSinceEpoch}',
        text: trimmedText,
      );

      if (!mounted || _isDisposed) return;

      setState(() {
        _messages.insert(0, message);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isDisposed) return;
        try {
          _scrollController.scrollToIndex(
            0,
            duration: const Duration(milliseconds: 300),
          );
        } catch (e) {
          debugPrint('Scroll error: $e');
        }
      });
    } catch (e, stack) {
      debugPrint('Error adding bot message: $e\n$stack');
      if (!mounted || _isDisposed) return;

      setState(() {
        _messages.insert(0, types.TextMessage(
          author: _bot,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          text: 'New message',
        ));
      });
    }
  }

  void _handleSendPressed(types.PartialText text) {
    if (text.text.trim().isEmpty || _isDisposed || _isProcessing) return;

    try {
      final userMessage = types.TextMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        text: text.text.trim(),
      );

      if (!mounted || _isDisposed) return;

      setState(() {
        _messages.insert(0, userMessage);
        _textController.clear();
      });

      makeApiCalls(text.text.trim());

    } catch (e, stack) {
      debugPrint('Error handling send: $e\n$stack');
      if (!mounted || _isDisposed) return;
      _addBotMessage('Sorry, something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'Plan with AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DancingScript',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Chat(
                messages: _messages,
                onSendPressed: (types.PartialText text) {
                  _handleSendPressed(text);
                  FocusScope.of(context).unfocus();
                },
                user: _user,
                scrollController: _scrollController,
                theme: DefaultChatTheme(
                  inputBackgroundColor: Colors.grey.shade100,
                  sendButtonIcon: const Icon(Icons.send,
                      color: Colors.white,
                      size: 18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !_isProcessing, // Disable input while processing
                      decoration: InputDecoration(
                        hintText: _isProcessing ? 'Processing...' : 'Send a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onSubmitted: (text) {
                        if (!_isProcessing) {
                          _handleSendPressed(types.PartialText(text: text));
                        }
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: _isProcessing ? null : () {
                      if (_textController.text.isNotEmpty) {
                        _handleSendPressed(
                            types.PartialText(text: _textController.text));
                      }
                    },
                    icon: _isProcessing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send),
                    color: _isProcessing ? Colors.grey : Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}