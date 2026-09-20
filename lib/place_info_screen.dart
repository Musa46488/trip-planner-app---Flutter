import 'package:venture_scape/pano_view.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:venture_scape/storage_service.dart';
import 'dashboard.dart';
import 'favourite.dart';
import 'profile_page.dart';

class PlaceInfoScreen extends StatefulWidget {
  final Map<String, String> place;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;

  const PlaceInfoScreen({
    super.key,
    required this.place,
    required this.onToggleFavorite,
    required this.isFavorite,
  });

  @override
  _PlaceInfoScreenState createState() => _PlaceInfoScreenState();
}

class _PlaceInfoScreenState extends State<PlaceInfoScreen> {
  bool showOverview = true;

  Widget _buildErrorContainer() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.error,
          color: Colors.grey,
          size: 50,
        ),
      ),
    );
  }

  Widget _buildPlaceholderContainer(String placeName) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image,
              color: Colors.grey,
              size: 50,
            ),
            const SizedBox(height: 8),
            Text(
              placeName,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int rating = double.tryParse(widget.place['rating'] ?? '0')?.round() ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: widget.onToggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Card(
                elevation: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 400,
                    width: MediaQuery.of(context).size.width,
                    child: _buildImageWidget(),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    textAlign: TextAlign.center,
                    widget.place['name'] ?? 'Place Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    textAlign: TextAlign.center,
                    widget.place['location'] ?? 'Location',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
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
                    children: const <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text('Overview', textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text('Details', textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      showOverview
                          ? widget.place['overview'] ??
                          'Overview of the place is not available.'
                          : 'Detailed History: This place boasts a rich history dating back centuries, featuring architectural marvels and cultural significance. Visitor Information: Open daily from 9 AM to 5 PM, with guided tours available. Best time to visit is during the cooler months. Additional Facts: Known for its intricate designs and historical events, it attracts millions of tourists annually. Nearby attractions include local markets and museums.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (!showOverview)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavouritePage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder:(context) => PlacePanoView(place: widget.place)
          ));
        },
        label:
        const Text('Virtual Tour', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.play_arrow_sharp, color: Colors.white),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
  Widget _buildImageWidget() {
    final assetPath = widget.place['assetPath']; // This contains Firebase Storage path
    final storage = StorageService();
    // If we have a Firebase Storage path, use FutureBuilder to get the download URL
    if (assetPath != null && assetPath.isNotEmpty) {
      return FutureBuilder<String?>(
        future: storage.getImageUrl(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            print("FutureBuilder error: ${snapshot.error}");
            return _buildErrorContainer();
          }

          final imageUrl = snapshot.data;
          if (imageUrl == null || imageUrl.isEmpty) {
            return _buildErrorContainer();
          }

          // Check if it's the fallback placeholder URL
          if (imageUrl.contains('placeholder')) {
            return _buildPlaceholderContainer(widget.place['name'] ?? 'Image');
          }

          return CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) {
              print("CachedNetworkImage error: $error");
              print("Failed URL: $url");
              return _buildErrorContainer();
            },
            httpHeaders: const {
              'Cache-Control': 'no-cache',
            },
            fadeInDuration: const Duration(milliseconds: 500),
            fadeOutDuration: const Duration(milliseconds: 500),
          );
        },
      );
    }

    // Fallback to placeholder if no storage path is provided
    return _buildPlaceholderContainer(widget.place['name'] ?? 'Image');
  }
}