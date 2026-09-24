import 'package:cached_network_image/cached_network_image.dart';
import 'package:venture_scape/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:venture_scape/screens/dashboard.dart';
import 'package:venture_scape/screens/favorites/favourite.dart';
import 'package:venture_scape/screens/profile/profile_page.dart';

class HotelInfoScreen extends StatefulWidget {
  final Map<String, String> hotel;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;

  const HotelInfoScreen({
    super.key,
    required this.hotel,
    required this.onToggleFavorite,
    required this.isFavorite,
  });

  @override
  _HotelInfoScreenState createState() => _HotelInfoScreenState();
}

class _HotelInfoScreenState extends State<HotelInfoScreen> {
  bool showOverview = true;

  @override
  Widget build(BuildContext context) {
    int rating = double.tryParse(widget.hotel['rating'] ?? '0')?.round() ?? 0;

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
            Card(
              elevation: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 400,
                  width: MediaQuery.of(context).size.width,
                  child: _buildImageWidget()
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
                    widget.hotel['name'] ?? 'Hotel Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    widget.hotel['location'] ?? 'Location',
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
                          ? widget.hotel['overview'] ??
                          'Overview of the hotel is not available.'
                          : 'Detailed Amenities: This hotel offers spacious rooms, a fitness center, a rooftop pool, and a 24/7 restaurant. Booking Information: Reservations can be made online or by calling +92-123-4567890. Check-in at 2 PM, check-out at 12 PM. Guest Reviews: Highly praised for its staff hospitality and clean facilities, with an average stay duration of 3 nights. Additional Services: Complimentary breakfast and Wi-Fi included.',
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
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {},
      //   label: const Text('Reserve Now', style: TextStyle(color: Colors.white)),
      //   icon: const Icon(Icons.book_online, color: Colors.white),
      //   backgroundColor: Colors.black,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(15),
      //   ),
      // ),
    );
  }
  Widget _buildImageWidget() {
    final assetPath = widget.hotel['assetPath']; // This contains Firebase Storage path
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
            return _buildPlaceholderContainer(widget.hotel['name'] ?? 'Image');
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
    return _buildPlaceholderContainer(widget.hotel['name'] ?? 'Image');
  }

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
}
