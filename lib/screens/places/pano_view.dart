import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:venture_scape/services/storage_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PlacePanoView extends StatefulWidget {
  final Map<String, String> place;

  const PlacePanoView({required this.place});

  @override
  _PlaceInfoScreenState createState() => _PlaceInfoScreenState();
}

class _PlaceInfoScreenState extends State<PlacePanoView> {
  bool showOverview = true;
  bool showWebView = true;
  static final String apiKey = dotenv.env['GOOGLE_API_KEY']!;
  final Map<String, String> streetViewLinks = {
    'Badshahi Mosque': 'https://www.google.com/maps/embed/v1/streetview?key=${apiKey}&location=31.5880,74.3096&heading=239.89&pitch=0&fov=100',
    'Wagah Border': 'https://www.google.com/maps/embed/v1/streetview?key=${apiKey}&location=31.6049,74.5759&heading=90&pitch=0&fov=100',
    'Grand Jamia Masjid': 'https://www.google.com/maps/embed/v1/streetview?key=${apiKey}&location=31.5880,74.3096&heading=90&pitch=0&fov=100',
    'Lahore Museum': 'https://www.google.com/maps/embed/v1/streetview?key=${apiKey}&location=31.5880,74.3096&heading=90&pitch=0&fov=100',
    'Shalimar Gardens': 'https://www.google.com/maps/embed/v1/streetview?key=${apiKey}&location=31.5880,74.3096&heading=90&pitch=0&fov=100',
  };

  @override
  void initState() {
    super.initState();
    final placeName = widget.place['name'] ?? '';
    if (streetViewLinks.containsKey(placeName)) {
      showWebView = true;
    } else {
      showWebView = false;
    }
  }

  Widget _buildImageWidget() {
    if (showWebView) return Container();

    final assetPath = widget.place['assetPath'];
    final storage = StorageService();

    if (assetPath != null && assetPath.isNotEmpty) {
      return FutureBuilder<String?>(
        future: storage.getImageUrl(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _buildErrorContainer();
          }

          final imageUrl = snapshot.data!;
          return CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => _buildErrorContainer(),
          );
        },
      );
    }
    return _buildPlaceholderContainer(widget.place['name'] ?? 'Image');
  }

  Widget _buildErrorContainer() {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.error, color: Colors.grey, size: 50)),
    );
  }

  Widget _buildPlaceholderContainer(String placeName) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, color: Colors.grey, size: 50),
            const SizedBox(height: 8),
            Text(placeName, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Create HTML content with an iframe for the Street View URL
  String _buildStreetViewHtml(String streetViewUrl) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          html, body, iframe {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            border: none;
            overflow: hidden;
          }
        </style>
      </head>
      <body>
        <iframe src="$streetViewUrl" width="100%" height="100%" style="border:0;" allowfullscreen="" loading="lazy"></iframe>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (showWebView) {
      final placeName = widget.place['name'] ?? '';
      final streetViewUrl = streetViewLinks[placeName]!;

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Virtual Tour - $placeName',
            style: const TextStyle(color: Colors.black),
          ),
        ),
        body: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setUserAgent(
                'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (url) => print('Loading: $url'),
                onPageFinished: (url) => print('Loaded: $url'),
                onWebResourceError: (error) {
                  print('Error: ${error.description}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to load: ${error.description}')),
                  );
                },
              ),
            )
            ..loadHtmlString(_buildStreetViewHtml(streetViewUrl)),
        ),
      );
    }

    int rating = int.tryParse(widget.place['rating'] ?? '') ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: _buildImageWidget(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place['name'] ?? 'Place Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  Text(
                    widget.place['location'] ?? 'Location',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ToggleButtons(
                    borderColor: Colors.grey,
                    fillColor: Colors.black,
                    borderWidth: 2,
                    selectedBorderColor: Colors.black,
                    selectedColor: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    onPressed: (int index) {
                      setState(() {
                        showOverview = index == 0;
                      });
                    },
                    isSelected: [showOverview, !showOverview],
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text('Overview'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text('Details'),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      showOverview
                          ? widget.place['overview'] ?? 'No overview available.'
                          : 'No details available',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (!showOverview)
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        );
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}