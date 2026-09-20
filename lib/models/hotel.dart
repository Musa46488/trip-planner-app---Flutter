// hotel.dart
class Hotel {
  final String name;
  final String location;
  final String rating;
  final String image;

  Hotel({
    required this.name,
    required this.location,
    required this.rating,
    required this.image,
  });

  // Static list of hotel data
  static List<Hotel> get hotels => [
    Hotel(
      name: 'Pearl Continental',
      location: 'Lahore, Pakistan',
      rating: '4.7',
      image: 'https://via.placeholder.com/300x200.png?text=Pearl+Continental',
    ),
    Hotel(
      name: 'Avari Hotel',
      location: 'Lahore, Pakistan',
      rating: '4.6',
      image: 'https://via.placeholder.com/300x200.png?text=Avari+Hotel',
    ),
    Hotel(
      name: 'Faletti’s Hotel',
      location: 'Lahore, Pakistan',
      rating: '4.5',
      image: 'https://via.placeholder.com/300x200.png?text=Faletti’s+Hotel',
    ),
    Hotel(
      name: 'The Nishat Hotel',
      location: 'Lahore, Pakistan',
      rating: '4.9',
      image: 'https://via.placeholder.com/300x200.png?text=The+Nishat+Hotel',
    ),
    Hotel(
      name: 'Heritage Luxury Suites',
      location: 'Lahore, Pakistan',
      rating: '4.8',
      image: 'https://via.placeholder.com/300x200.png?text=Heritage+Luxury+Suites',
    ),
  ];
}
