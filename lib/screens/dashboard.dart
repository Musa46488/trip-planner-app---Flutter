import 'package:cached_network_image/cached_network_image.dart';
import 'package:venture_scape/screens/chat/chatbot.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:venture_scape/services/storage_service.dart';
import 'package:venture_scape/screens/auth/login_page.dart';
import 'package:venture_scape/screens/places/see_all.dart';
import 'package:venture_scape/screens/places/hotel_info_screen.dart';
import 'package:venture_scape/screens/places/place_info_screen.dart';
import 'package:venture_scape/screens/favorites/favourite.dart';
import 'package:venture_scape/screens/profile/profile_page.dart';
import 'package:venture_scape/services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  List<Map<String, String>> _filteredPlaces = [];
  List<Map<String, String>> _filteredHotels = [];
  Set<String> _favorites = {};
  bool _isLoading = true;

  final List<Map<String, String>> tourPlaces = [
    {
      'id': '1',
      'name': 'Badshahi Mosque',
      'location': 'Lahore, Pakistan',
      'rating': '4.5',
      'assetPath': 'places/badshah img.jpg',
      'overview':
      'A majestic Mughal-era mosque renowned for its stunning architecture and historical significance in Lahore.',
    },
    {
      'id': '2',
      'name': 'Lahore Fort',
      'location': 'Lahore, Pakistan',
      'rating': '4.7',
      'assetPath': 'places/lahorefort.webp',
      'overview':
      'A UNESCO World Heritage Site featuring exquisite Mughal architecture and a rich historical legacy.',
    },
    {
      'id': '3',
      'name': 'Shalimar Gardens',
      'location': 'Lahore, Pakistan',
      'rating': '4.6',
      'assetPath': 'places/shalimargarden.jpg',
      'overview':
      'A serene Mughal garden known for its beautiful fountains, pavilions, and lush greenery.',
    },
    {
      'id': '4',
      'name': 'Minar-e-Pakistan',
      'location': 'Lahore, Pakistan',
      'rating': '4.3',
      'assetPath': 'places/Minar-e-Pakistan-scaled.jpg',
      'overview':
      'A monumental tower commemorating the Lahore Resolution and the birth of Pakistan.',
    },
    {
      'id': '5',
      'name': 'Wagah Border',
      'location': 'Lahore, Pakistan',
      'rating': '4.8',
      'assetPath': 'places/wahgaborder.jfif',
      'overview':
      'A famous border ceremony site offering a vibrant display of patriotism and military precision.',
    },
  ];

  final List<Map<String, String>> hotels = [
    {
      'id': '6',
      'name': 'Pearl Continental',
      'location': 'Lahore, Pakistan',
      'rating': '4.7',
      'assetPath': 'hotels/hotel1.jpg',
      'overview':
      'A luxurious hotel offering modern amenities and stunning views of Lahore.',
    },
    {
      'id': '7',
      'name': 'Avari Hotel',
      'location': 'Lahore, Pakistan',
      'rating': '4.6',
      'assetPath': 'hotels/awari.jpg',
      'overview':
      'A premium hotel known for its exceptional hospitality and elegant accommodations.',
    },
    {
      'id': '8',
      'name': 'Faletti\'s Hotel',
      'location': 'Lahore, Pakistan',
      'rating': '4.5',
      'assetPath': 'hotels/hotel3.jfif',
      'overview':
      'A historic hotel blending colonial charm with contemporary comforts.',
    },
    {
      'id': '9',
      'name': 'The Nishat Hotel',
      'location': 'Lahore, Pakistan',
      'rating': '4.9',
      'assetPath': 'hotels/download.jfif',
      'overview':
      'A modern hotel providing top-notch facilities and a central location in Lahore.',
    },
    {
      'id': '10',
      'name': 'Heritage Luxury Suites',
      'location': 'Lahore, Pakistan',
      'rating': '4.8',
      'assetPath': 'hotels/hotel5.jpg',
      'overview':
      'Luxurious suites offering personalized services and a sophisticated ambiance.',
    },
  ];
  List<Map<String, String>> _places = [];
  List<Map<String, String>> _hotels = [];
  bool _isDataLoading = true;

  Future<void> _populateFirestoreWithHardcodedData() async {
    try {
      print('🚀 Starting Firestore population...');

      // Check if data already exists to avoid duplicates
      final placesSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .limit(1)
          .get();

      final hotelsSnapshot = await FirebaseFirestore.instance
          .collection('hotels')
          .limit(1)
          .get();

      // Only populate if collections are empty
      if (placesSnapshot.docs.isEmpty) {
        // Add places to Firestore with auto-generated UIDs
        for (var place in tourPlaces) {
          await FirebaseFirestore.instance
              .collection('places')
              .add({  // Use .add() instead of .doc(place['id']).set()
            'name': place['name'],
            'location': place['location'],
            'rating': double.parse(place['rating']!),
            'assetPath': place['assetPath'],
            'overview': place['overview'],
            'originalId': place['id'], // Keep original ID as a field if needed
          });
          print('✅ Added place: ${place['name']}');
        }
      } else {
        print('ℹ️ Places collection already has data, skipping...');
      }

      if (hotelsSnapshot.docs.isEmpty) {
        // Add hotels to Firestore with auto-generated UIDs
        for (var hotel in hotels) {
          await FirebaseFirestore.instance
              .collection('hotels')
              .add({  // Use .add() instead of .doc(hotel['id']).set()
            'name': hotel['name'],
            'location': hotel['location'],
            'rating': double.parse(hotel['rating']!),
            'assetPath': hotel['assetPath'],
            'overview': hotel['overview'],
            'originalId': hotel['id'], // Keep original ID as a field if needed
          });
          print('✅ Added hotel: ${hotel['name']}');
        }
      } else {
        print('ℹ️ Hotels collection already has data, skipping...');
      }

      print('🎉 Firestore population completed successfully!');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firestore populated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('❌ Error populating Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error populating Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Update your initState method
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // _populateFirestoreWithHardcodedData();
    _fetchData();
  }


// Add this method to fetch data from Firestore
  Future<void> _fetchData() async {
    try {
      // Fetch places from Firestore
      QuerySnapshot placesSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .get();

      // Fetch hotels from Firestore
      QuerySnapshot hotelsSnapshot = await FirebaseFirestore.instance
          .collection('hotels')
          .get();

      setState(() {
        _places = placesSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return <String, String>{
            'id': doc.id,
            'name': data['name']?.toString() ?? '',
            'location': data['location']?.toString() ?? '',
            'rating': data['rating']?.toString() ?? '',
            'assetPath': data['assetPath']?.toString() ?? '',
            'overview': data['overview']?.toString() ?? '', // Changed from 'description' to 'overview'
          };
        }).toList();

        _hotels = hotelsSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return <String, String>{
            'id': doc.id,
            'name': data['name']?.toString() ?? '',
            'location': data['location']?.toString() ?? '',
            'rating': data['rating']?.toString() ?? '',
            'assetPath': data['assetPath']?.toString() ?? '',
            'overview': data['overview']?.toString() ?? '', // Changed from 'description' to 'overview'
          };
        }).toList();

        // If Firestore is empty, use hardcoded data as fallback
        if (_places.isEmpty) {
          _places = tourPlaces;
        }
        if (_hotels.isEmpty) {
          _hotels = hotels;
        }

        _filteredPlaces = _places;
        _filteredHotels = _hotels;
        _isDataLoading = false;
      });

      // Fetch favorites after data is loaded
      await _fetchFavorites();
    } catch (e) {
      print('Error fetching data: $e');
      // Use hardcoded data as fallback
      setState(() {
        _places = tourPlaces;
        _hotels = hotels;
        _filteredPlaces = _places;
        _filteredHotels = _hotels;
        _isDataLoading = false;
      });
      await _fetchFavorites();
    }
  }

// Update your _onSearchChanged method
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPlaces = _places
          .where((place) =>
      place['name']!.toLowerCase().contains(query) ||
          place['location']!.toLowerCase().contains(query))
          .toList();
      _filteredHotels = _hotels
          .where((hotel) =>
      hotel['name']!.toLowerCase().contains(query) ||
          hotel['location']!.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _fetchFavorites() async {
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(userId)
          .collection('items')
          .get();
      setState(() {
        _favorites = snapshot.docs.map((doc) => doc.id).toSet();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Map<String, String> item) async {
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      final docRef = FirebaseFirestore.instance
          .collection('favorites')
          .doc(userId)
          .collection('items')
          .doc(item['id']);
      if (_favorites.contains(item['id'])) {
        await docRef.delete();
        setState(() {
          _favorites.remove(item['id']);
        });
      } else {
        await docRef.set(item);
        setState(() {
          _favorites.add(item['id']!);
        });
      }
    }
  }

  void _onCardTap(int index, String type) {
    if (type == 'hotel') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelInfoScreen(
            hotel: _filteredHotels[index],
            onToggleFavorite: () => _toggleFavorite(_filteredHotels[index]),
            isFavorite: _favorites.contains(_filteredHotels[index]['id']),
          ),
        ),
      );
    } else if (type == 'place') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaceInfoScreen(
            place: _filteredPlaces[index],
            onToggleFavorite: () => _toggleFavorite(_filteredPlaces[index]),
            isFavorite: _favorites.contains(_filteredPlaces[index]['id']),
          ),
        ),
      );
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (_currentIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (_currentIndex == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FavouritePage()),
      );
    } else if (_currentIndex == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const CircleAvatar(
              radius: 20,
              child: Icon(
                Icons.account_circle,
                size: 40,
                color: Colors.grey,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Logout') {
                  _authService.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                } else if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return {'Profile', 'Logout'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                'Adventure Scape',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'DancingScript',
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavouritePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                _authService.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyChatbot(),
              ));
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.message, color: Colors.black),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 10,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: _currentIndex == 0 ? Colors.black : Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.favorite,
              color: _currentIndex == 1 ? Colors.black : Colors.grey,
            ),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _currentIndex == 2 ? Colors.black : Colors.grey,
            ),
            label: 'Profile',
          ),
        ],
        onTap: _onNavItemTapped,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search places or hotels',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Popular Places',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeeAllScreen(
                            items: _filteredPlaces, type: 'place'),
                      ),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SliderSection(
              items: _filteredPlaces,
              onCardTap: (index) => _onCardTap(index, 'place'),
              onToggleFavorite: _toggleFavorite,
              favorites: _favorites,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Discover Lahore\'s iconic landmarks, each offering a unique blend of history and beauty. Visit during cooler months for a pleasant experience, and consider guided tours for deeper insights into their cultural importance.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Recommended Hotels',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeeAllScreen(
                            items: _filteredHotels, type: 'hotel'),
                      ),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ),
            SliderSection(
              items: _filteredHotels,
              onCardTap: (index) => _onCardTap(index, 'hotel'),
              onToggleFavorite: _toggleFavorite,
              favorites: _favorites,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Experience luxury and comfort in Lahore\'s finest hotels, featuring modern amenities and exceptional service. Advance bookings are recommended during peak times to secure the best rates and availability.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SliderSection extends StatelessWidget {
  final List<Map<String, String>> items;
  final Function(int) onCardTap;
  final Function(Map<String, String>) onToggleFavorite;
  final Set<String> favorites;

  const SliderSection({
    super.key,
    required this.items,
    required this.onCardTap,
    required this.onToggleFavorite,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final String? imageStoragePath = item['assetPath'];
          final storage = StorageService();

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => onCardTap(index),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                color: Colors.transparent, // Make card background transparent
                child: SizedBox(
                  width: 220,
                  child: Stack( // Changed from Column to Stack to overlay content
                    children: [
                      // Full image background
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16), // Apply border radius to entire card
                          child: FutureBuilder<String?>(
                            future: storage.getImageUrl(imageStoragePath!),
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
                                return _buildPlaceholderContainer(item['name'] ?? 'Image');
                              }

                              return CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover, // This will fill the entire card
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
                                // Add these parameters to help with image loading
                                httpHeaders: const {
                                  'Cache-Control': 'no-cache',
                                },
                                // Add retry mechanism
                                fadeInDuration: const Duration(milliseconds: 500),
                                fadeOutDuration: const Duration(milliseconds: 500),
                              );
                            },
                          ),
                        ),
                      ),
                      // Content overlay at the bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            // Semi-transparent gradient for better text readability
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // Changed to white for better visibility
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['location'] ?? 'No Location',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70, // Changed to white70 for better visibility
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['rating'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white, // Changed to white for better visibility
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Favorite button overlay
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            favorites.contains(item['id'])
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                          onPressed: () => onToggleFavorite(item),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderContainer(String name) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 50,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}