import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venture_scape/services/storage_service.dart';
import 'package:venture_scape/screens/places/hotel_info_screen.dart';
import 'package:venture_scape/screens/places/place_info_screen.dart';
import 'package:venture_scape/screens/dashboard.dart';
import 'package:venture_scape/screens/favorites/favourite.dart';
import 'package:venture_scape/screens/profile/profile_page.dart';
import 'package:venture_scape/services/auth_service.dart';

class SeeAllScreen extends StatelessWidget {
  final List<Map<String, String>> items;
  final String type;

  const SeeAllScreen({
    super.key,
    required this.items,
    required this.type,
  });

  Future<void> _toggleFavorite(Map<String, String> item, BuildContext context) async {
    final authService = AuthService();
    final userId = authService.getCurrentUserId();
    if (userId != null) {
      final docRef = FirebaseFirestore.instance
          .collection('favorites')
          .doc(userId)
          .collection('items')
          .doc(item['id']);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          type == 'place' ? 'All Places' : 'All Hotels',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .doc(authService.getCurrentUserId())
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          Set<String> favorites = {};
          if (snapshot.hasData) {
            favorites = snapshot.data!.docs.map((doc) => doc.id).toSet();
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              // IMPORTANT: Assume item['assetPath'] NOW HOLDS THE FIREBASE STORAGE PATH
              // e.g., "places/image_name.jpg" or "hotels/hotel_pic.png"
              final String? imageStoragePath = item['assetPath'];
              final storage = StorageService();

              return ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: FutureBuilder<String?>(
                  future: storage.getImageUrl(imageStoragePath!), // Call the helper
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                      );
                    }
                    if (imageSnapshot.hasError || !imageSnapshot.hasData || imageSnapshot.data == null) {
                      // Display a placeholder or error icon if URL fetch fails or path is invalid
                      return const SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(child: Icon(Icons.broken_image, size: 30)),
                      );
                    }
                    // We have a valid download URL from Firebase Storage
                    return Card(
                      elevation: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageSnapshot.data!,
                          width: 60,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                          ),
                          errorWidget: (context, url, error) => const SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(child: Icon(Icons.error, size: 30)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                title: Text(
                  item['name'] ?? 'Unnamed Item', // Add null check for safety
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'DancingScript'),
                ),
                subtitle: Text(item['location'] ?? 'Unknown Location'), // Add null check
                trailing: IconButton(
                  icon: Icon(
                    favorites.contains(item['id']) ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () => _toggleFavorite(item, context),
                ),
                onTap: () {
                  // Ensure 'id' exists and is not null before using it
                  final String? itemId = item['id'];
                  if (itemId == null) {
                    print("Error: Item ID is null. Cannot navigate.");
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Cannot open item: Missing ID.")));
                    return;
                  }

                  if (type == 'place') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceInfoScreen(
                          place: item,
                          onToggleFavorite: () => _toggleFavorite(item, context),
                          isFavorite: favorites.contains(itemId),
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HotelInfoScreen(
                          hotel: item,
                          onToggleFavorite: () => _toggleFavorite(item, context),
                          isFavorite: favorites.contains(itemId),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.grey),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, color: Colors.grey),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.grey),
            label: 'Profile',
          ),
        ],
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
    );
  }
}