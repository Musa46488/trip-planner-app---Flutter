import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:venture_scape/services/storage_service.dart';
import 'package:venture_scape/screens/dashboard.dart';
import 'package:venture_scape/screens/places/hotel_info_screen.dart';
import 'package:venture_scape/screens/places/place_info_screen.dart';
import 'package:venture_scape/screens/profile/profile_page.dart';
import 'package:venture_scape/services/auth_service.dart';

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  _FavouritePageState createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  final int _currentIndex = 1;
  final AuthService _authService = AuthService();

  // New: Fetch favorites from Firestore
  Stream<QuerySnapshot> _getFavoritesStream() {
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      return FirebaseFirestore.instance
          .collection('favorites')
          .doc(userId)
          .collection('items')
          .snapshots();
    }
    return Stream.empty();
  }

  // New: Remove favorite
  Future<void> _removeFavorite(String itemId) async {
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('favorites')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .delete();
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Favourites',
          style: TextStyle(fontSize: 24),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.grey),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, color: Colors.black),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.grey),
            label: 'Profile',
          ),
        ],
        onTap: _onNavItemTapped,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFavoritesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No favorites yet.'));
          }
          final items = snapshot.data!.docs;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              final itemId = items[index].id;
              final storagePath = item['assetPath'] ?? '';
              final storage = StorageService();

              return ListTile(
                leading: FutureBuilder<String>(
                  future: storage.getImageUrl(storagePath),
                  builder: (context, urlSnapshot) {
                    if (urlSnapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 50,
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Card(
                      elevation: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: urlSnapshot.data ?? 'https://via.placeholder.com/400x200',
                          width: 60,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                title: Text(item['name'] ?? 'Unknown'),
                subtitle: Text(item['location'] ?? 'Unknown'),
                trailing: IconButton(
                  icon: Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => _removeFavorite(itemId),
                ),
                onTap: () {
                  if (item['assetPath'].toString().contains('places')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceInfoScreen(
                          place: Map<String, String>.from(item),
                          onToggleFavorite: () => _removeFavorite(itemId),
                          isFavorite: true,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HotelInfoScreen(
                          hotel: Map<String, String>.from(item),
                          onToggleFavorite: () => _removeFavorite(itemId),
                          isFavorite: true,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      )
    );
  }
}