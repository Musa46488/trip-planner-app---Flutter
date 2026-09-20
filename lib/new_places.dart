import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// class GooglePlacesService {
//   final String apiKey = dotenv.env['GOOGLE_API_KEY']!; // Ensure your API key is in your .env file
//
//   Future<List<dynamic>> getPredictions(String input) async {
//     final String url = 'https://places.googleapis.com/v1/places:autocomplete';
//
//     final Map<String, dynamic> body = {
//       'input': input,
//       'includedRegionCodes': ['pk'],
//     };
//
//     final Map<String, String> headers = {
//       'Content-Type': 'application/json',
//       'X-Goog-Api-Key': apiKey,
//     };
//
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: headers,
//         body: json.encode(body),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['suggestions'] != null) {
//           return data['suggestions'];
//         }
//       } else {
//         print('Error fetching predictions: ${response.body}');
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//     return [];
//   }
// }
//
//
// // In your find_places.dart or wherever you have the search UI
//
// class FindPlaces extends StatefulWidget {
//   @override
//   _FindPlacesState createState() => _FindPlacesState();
//
// }
// // TODO: DONE WITH TO AND FROM, SEND PLACES NAME TO BACKEND AND CALCULAE COST.
// class _FindPlacesState extends State<FindPlaces> {
//   final GooglePlacesService _placesService = GooglePlacesService();
//   List<dynamic> _predictions = [];
//   final TextEditingController _controller = TextEditingController();
//   final TextEditingController _controller2 = TextEditingController();
//
//   void _onSearchChanged(String input) async {
//     if (input.isNotEmpty) {
//       final result = await _placesService.getPredictions(input);
//       setState(() {
//         _predictions = result;
//       });
//     } else {
//       setState(() {
//         _predictions = [];
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text('Find Places')),
//         body: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: TextField(
//                       controller: _controller,
//                       onChanged: _onSearchChanged,
//                       decoration: const InputDecoration(
//                         hintText: 'To',
//                       ),
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: TextField(
//                       controller: _controller2,
//                       onChanged: _onSearchChanged,
//                       decoration: const InputDecoration(
//                         hintText: 'From',
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _predictions.length,
//                 itemBuilder: (context, index) {
//                   final prediction = _predictions[index];
//                   // The new API returns a different structure
//                   final placeName = prediction['placePrediction']['text']['text'];
//                   return ListTile(
//                     title: Text(placeName),
//                     onTap: () {
//                       // Handle selection of the place
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


class GooglePlacesService {
  final String apiKey = dotenv.env['GOOGLE_API_KEY']!; // Ensure your API key is in your .env file

  Future<List<dynamic>> getPredictions(String input) async {
    const String url = 'https://places.googleapis.com/v1/places:autocomplete';

    final Map<String, dynamic> body = {
      'input': input,
      'includedRegionCodes': ['pk'],
    };

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['suggestions'] != null) {
          return data['suggestions'];
        }
      } else {
        print('Error fetching predictions: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
    return [];
  }
}

class FindPlaces extends StatefulWidget {
  final Function(String source, String destination)? onPlacesSelected;

  const FindPlaces({Key? key, this.onPlacesSelected}) : super(key: key);

  @override
  _FindPlacesState createState() => _FindPlacesState();
}

class _FindPlacesState extends State<FindPlaces> {
  final GooglePlacesService _placesService = GooglePlacesService();
  List<dynamic> _predictions = [];
  List<dynamic> _fromPredictions = [];
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();

  bool _isSearchingTo = false;
  bool _isSearchingFrom = false;

  String? _selectedToPlace;
  String? _selectedFromPlace;

  void _onToSearchChanged(String input) async {
    setState(() {
      _isSearchingTo = true;
      _isSearchingFrom = false;
    });

    if (input.isNotEmpty) {
      final result = await _placesService.getPredictions(input);
      setState(() {
        _predictions = result;
      });
    } else {
      setState(() {
        _predictions = [];
      });
    }
  }

  void _onFromSearchChanged(String input) async {
    setState(() {
      _isSearchingFrom = true;
      _isSearchingTo = false;
    });

    if (input.isNotEmpty) {
      final result = await _placesService.getPredictions(input);
      setState(() {
        _fromPredictions = result;
      });
    } else {
      setState(() {
        _fromPredictions = [];
      });
    }
  }

  void _selectToPlace(String placeName) {
    setState(() {
      _selectedToPlace = placeName;
      _toController.text = placeName;
      _predictions = [];
      _isSearchingTo = false;
    });
  }

  void _selectFromPlace(String placeName) {
    setState(() {
      _selectedFromPlace = placeName;
      _fromController.text = placeName;
      _fromPredictions = [];
      _isSearchingFrom = false;
    });
  }

  void _confirmSelection() {
    if (_selectedToPlace != null && _selectedFromPlace != null) {
      if (widget.onPlacesSelected != null) {
        widget.onPlacesSelected!(_selectedFromPlace!, _selectedToPlace!);
      }
      print(_selectedFromPlace);
      print(_selectedToPlace);
      Navigator.pop(context, {
        'source': _selectedFromPlace!,
        'destination': _selectedToPlace!,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both source and destination places'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Select Places'),
          actions: [
            if (_selectedToPlace != null && _selectedFromPlace != null)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: (){
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _confirmSelection;
                  });
                }
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _fromController,
                      onChanged: _onFromSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'From (Source)',
                        prefixIcon: const Icon(Icons.my_location),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: _selectedFromPlace != null
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _toController,
                      onChanged: _onToSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'To (Destination)',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: _selectedToPlace != null
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedToPlace != null && _selectedFromPlace != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Confirm Selection'),
                  ),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _isSearchingTo
                      ? _predictions.length
                      : _isSearchingFrom
                      ? _fromPredictions.length
                      : 0,
                  itemBuilder: (context, index) {
                    final prediction = _isSearchingTo
                        ? _predictions[index]
                        : _fromPredictions[index];
                    final placeName = prediction['placePrediction']['text']['text'];

                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(placeName),
                      onTap: () {
                        if (_isSearchingTo) {
                          _selectToPlace(placeName);
                        } else if (_isSearchingFrom) {
                          _selectFromPlace(placeName);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}