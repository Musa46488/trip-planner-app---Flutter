import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class PlacesExtractor {
  late final FlutterGooglePlacesSdk _places;

  PlacesExtractor(String apiKey) {
    _places = FlutterGooglePlacesSdk(apiKey);
  }

  // Extract places from text using Google Places SDK
  Future<List<AutocompletePrediction>> extractPlacesFromText(String inputText) async {
    try {
      print('🔍 Extracting places from: "$inputText"');
      print('─' * 50);

      // Use findAutocompletePredictions to get place suggestions
      final response = await _places.findAutocompletePredictions(
        inputText,
        countries: ['pk'], // Restrict to Pakistan
        locationBias: null, // You can add location bias if needed
        locationRestriction: null, // You can add location restriction if needed
        origin: null, // You can add origin for distance calculations
        newSessionToken: null, // You can add session token for billing optimization
      );

      if (response.predictions.isNotEmpty) {
        print('✅ Found ${response.predictions.length} places:');
        print('');

        for (int i = 0; i < response.predictions.length; i++) {
          final place = response.predictions[i];
          print('📍 Place ${i + 1}:');
          print('   Description: ${place.fullText}');
          print('   Primary Text: ${place.primaryText}');
          print('   Secondary Text: ${place.secondaryText ?? 'N/A'}');
          print('   Place ID: ${place.placeId}');
          print('   Types: ${place.placeTypes?.join(', ') ?? 'N/A'}');
          print('   Distance: ${place.distanceMeters ?? 'N/A'} meters');
          print('');
        }
        return response.predictions;
      } else {
        print('❌ No places found in the text');
        return [];
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return [];
    }
  }

  // Enhanced method for extracting specific places with better regex patterns
  Future<List<AutocompletePrediction>> extractSpecificPlaces(String inputText) async {
    try {
      print('🔍 Analyzing text for specific places: "$inputText"');
      print('─' * 50);

      List<AutocompletePrediction> allPredictions = [];

      // Split the text and look for location keywords
      List<String> potentialPlaces = [];

      final patterns = [
        RegExp(r'from\s+([^to]+?)(?:\s+to|\s*$)', caseSensitive: false),
        RegExp(r'to\s+([^from]+?)(?:\s+from|\s*$)', caseSensitive: false),
        RegExp(r'in\s+([A-Za-z\s]+)', caseSensitive: false),
        RegExp(r'at\s+([A-Za-z\s]+)', caseSensitive: false),
        RegExp(r'near\s+([A-Za-z\s]+)', caseSensitive: false),
      ];


      for (final pattern in patterns) {
        final matches = pattern.allMatches(inputText);
        for (final match in matches) {
          if (match.group(1) != null) {
            String place = match.group(1)!.trim();
            // Clean up the place name
            place = place.replaceAll(RegExp(r'\s+'), ' '); // Remove multiple spaces
            if (place.isNotEmpty && place.length > 2 && !potentialPlaces.contains(place.toLowerCase())) {
              potentialPlaces.add(place);
            }
          }
        }
      }

      print('🔍 Extracted potential places: ${potentialPlaces.join(', ')}');

      // Search for each potential place individually
      for (String place in potentialPlaces) {
        print('🔍 Searching for: "$place"');
        final placeResults = await _getPlacePredictions(place);
        allPredictions.addAll(placeResults);
      }

      // Also search for the complete text if no specific places found
      if (potentialPlaces.isEmpty) {
        print('🔍 No specific places found, searching full text...');
        final fullTextResults = await _getPlacePredictions(inputText);
        allPredictions.addAll(fullTextResults);
      }

      // Remove duplicates based on placeId
      final uniquePredictions = <String, AutocompletePrediction>{};
      for (final prediction in allPredictions) {
        uniquePredictions[prediction.placeId] = prediction;
      }

      final uniqueList = uniquePredictions.values.toList();
      print('🎯 Total unique places found: ${uniqueList.length}');

      return uniqueList;

    } catch (e) {
      print('❌ Exception in extractSpecificPlaces: $e');
      return [];
    }
  }

  // Helper method to get place predictions with enhanced parameters
  Future<List<AutocompletePrediction>> _getPlacePredictions(String query) async {
    try {
      final response = await _places.findAutocompletePredictions(
        query,
        countries: ['pk'], // Restrict to Pakistan
        // You can uncomment and customize these parameters as needed:
        // locationBias: LocationBias.circle(
        //   center: LatLng(31.5204, 74.3587), // Lahore coordinates
        //   radius: 50000, // 50km radius
        // ),
        // placeTypes: [PlaceType.establishment, PlaceType.geocode],
      );

      if (response.predictions.isNotEmpty) {
        print('   ✅ Found ${response.predictions.length} results for "$query"');
        for (int i = 0; i < response.predictions.length && i < 3; i++) {
          final place = response.predictions[i];
          print('      ${i + 1}. ${place.fullText}');
        }
      } else {
        print('   ❌ No results for "$query"');
      }

      return response.predictions;

    } catch (e) {
      print('❌ Error getting predictions for "$query": $e');
      return [];
    }
  }

  // Get detailed place information by Place ID with more fields
  Future<Place?> getPlaceDetails(String placeId) async {
    try {
      print('🔍 Getting details for Place ID: $placeId');

      final response = await _places.fetchPlace(
        placeId,
        fields: [
          PlaceField.Name,
          PlaceField.Address,
          PlaceField.Location,
          PlaceField.Types,
          PlaceField.PhoneNumber,
          PlaceField.Rating,
          PlaceField.UserRatingsTotal,
          PlaceField.PriceLevel,
          PlaceField.OpeningHours,
          // PlaceField.Website,
          PlaceField.Viewport,
        ],
      );

      if (response.place != null) {
        final place = response.place!;
        print('📍 Place Details:');
        print('   Name: ${place.name}');
        print('   Address: ${place.address}');
        print('   Location: ${place.latLng?.lat}, ${place.latLng?.lng}');
        print('   Types: ${place.types?.join(', ') ?? 'N/A'}');
        print('   Phone: ${place.phoneNumber ?? 'N/A'}');
        print('   Rating: ${place.rating ?? 'N/A'} (${place.userRatingsTotal ?? 0} reviews)');
        print('   Price Level: ${place.priceLevel ?? 'N/A'}');
        // print('   Website: ${place.website ?? 'N/A'}');
        // print('   Open Now: ${place.openingHours?.isOpen ?? 'Unknown'}');
        return place;
      }

      return null;
    } catch (e) {
      print('❌ Error getting place details: $e');
      return null;
    }
  }

  // New method to search places with specific types
  Future<List<AutocompletePrediction>> searchPlacesByType(
      String query,
      List<PlaceType> placeTypes,
      ) async {
    try {
      print('🔍 Searching for places of type: ${placeTypes.join(', ')}');

      final response = await _places.findAutocompletePredictions(
        query,
        countries: ['pk'],
        // placeTypes: placeTypes,
      );

      return response.predictions;
    } catch (e) {
      print('❌ Error searching places by type: $e');
      return [];
    }
  }

  // New method to get places near a specific location
  Future<List<AutocompletePrediction>> getPlacesNearLocation(
      String query,
      LatLng location,
      double radiusMeters,
      ) async {
    try {
      print('🔍 Searching for places near: ${location.lat}, ${location.lng}');

      final response = await _places.findAutocompletePredictions(
        query,
        countries: ['pk'],
        // locationBias: LocationBias.circle(
        //   center: location,
        //   radius: radiusMeters,
        // ),
      );

      return response.predictions;
    } catch (e) {
      print('❌ Error getting places near location: $e');
      return [];
    }
  }
}

// Enhanced Flutter widget with better UI and functionality
class PlacesExtractorDemo extends StatefulWidget {
  @override
  _PlacesExtractorDemoState createState() => _PlacesExtractorDemoState();
}

class _PlacesExtractorDemoState extends State<PlacesExtractorDemo> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late PlacesExtractor _placesExtractor;
  List<AutocompletePrediction> _predictions = [];
  List<AutocompletePrediction> _extractedPlaces = [];
  bool _isLoading = false;
  String? _selectedApiKey;

  @override
  void initState() {
    super.initState();
    _initializePlacesExtractor();
    // Set default text
    _textController.text = "Plan me a trip from bahria town to androon lahore";
  }

  void _initializePlacesExtractor() {
    try {
      final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        print('❌ Google API Key not found in .env file');
        return;
      }
      _placesExtractor = PlacesExtractor(apiKey);
      _selectedApiKey = apiKey;
      print('✅ Places Extractor initialized successfully');
    } catch (e) {
      print('❌ Error initializing Places Extractor: $e');
    }
  }

  Future<void> _extractPlaces() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _extractedPlaces.clear();
    });

    try {
      final results = await _placesExtractor.extractSpecificPlaces(_textController.text);
      setState(() {
        _extractedPlaces = results;
      });
    } catch (e) {
      print('❌ Error extracting places: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error extracting places: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Places Extractor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Places Extractor Demo'),
          backgroundColor: Colors.blue,
          elevation: 2,
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // API Key status indicator
              if (_selectedApiKey != null)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'API Key Configured',
                        style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 16),

              // Text input for extraction
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Enter text to extract places from',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Plan me a trip from Lahore to Karachi...',
                  prefixIcon: Icon(Icons.text_fields),
                ),
              ),

              SizedBox(height: 10),

              // Extract button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _extractPlaces,
                icon: _isLoading
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(Icons.location_searching),
                label: Text(_isLoading ? 'Extracting...' : 'Extract Places'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              SizedBox(height: 20),

              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search for places',
                  border: OutlineInputBorder(),
                  hintText: 'Type to search places...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _predictions.clear();
                      });
                    },
                  )
                      : null,
                ),
                onChanged: (value) async {
                  if (value.isNotEmpty && value.length > 2) {
                    final results = await _placesExtractor._getPlacePredictions(value);
                    setState(() {
                      _predictions = results.take(5).toList();
                    });
                  } else {
                    setState(() {
                      _predictions.clear();
                    });
                  }
                },
              ),

              SizedBox(height: 20),

              // Results section
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Extracted places from text
                      if (_extractedPlaces.isNotEmpty) ...[
                        Text(
                          'Extracted Places (${_extractedPlaces.length}):',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        ..._extractedPlaces.map((place) => Card(
                          margin: EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              child: Icon(Icons.location_on, color: Colors.red),
                            ),
                            title: Text(
                              place.primaryText,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (place.secondaryText != null)
                                  Text(place.secondaryText!),
                                if (place.placeTypes != null && place.placeTypes!.isNotEmpty)
                                  Text(
                                    place.placeTypes!.take(3).join(', '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.info_outline, color: Colors.blue),
                              onPressed: () async {
                                await _placesExtractor.getPlaceDetails(place.placeId);
                              },
                            ),
                          ),
                        )).toList(),
                        SizedBox(height: 20),
                      ],

                      // Search predictions
                      if (_predictions.isNotEmpty) ...[
                        Text(
                          'Search Results (${_predictions.length}):',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        ..._predictions.map((place) => Card(
                          margin: EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.search, color: Colors.blue),
                            ),
                            title: Text(place.primaryText),
                            subtitle: Text(place.secondaryText ?? ''),
                            onTap: () async {
                              _searchController.text = place.fullText;
                              setState(() {
                                _predictions.clear();
                              });
                              await _placesExtractor.getPlaceDetails(place.placeId);
                            },
                          ),
                        )).toList(),
                      ],

                      // Empty state
                      if (_extractedPlaces.isEmpty && _predictions.isEmpty && !_isLoading)
                        Center(
                          child: Column(
                            children: [
                              SizedBox(height: 40),
                              Icon(
                                Icons.location_searching,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No places found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                'Try extracting places from text or searching above',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 Tip: Check the console/debug output for detailed place information!',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

