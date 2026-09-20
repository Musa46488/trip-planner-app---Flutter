// tour_place.dart
class TourPlace {
  final String name;
  final String location;
  final String rating;
  final String image;

  TourPlace({
    required this.name,
    required this.location,
    required this.rating,
    required this.image,
  });

  // Static list of tour places data
  static List<TourPlace> get tourPlaces => [
    TourPlace(
      name: 'Badshahi Mosque',
      location: 'Lahore, Pakistan',
      rating: '4.5',
      image: 'https://via.placeholder.com/300x200.png?text=Badshahi+Mosque',
    ),
    TourPlace(
      name: 'Lahore Fort',
      location: 'Lahore, Pakistan',
      rating: '4.7',
      image: 'https://via.placeholder.com/300x200.png?text=Lahore+Fort',
    ),
    TourPlace(
      name: 'Shalimar Gardens',
      location: 'Lahore, Pakistan',
      rating: '4.6',
      image: 'https://via.placeholder.com/300x200.png?text=Shalimar+Gardens',
    ),
    TourPlace(
      name: 'Minar-e-Pakistan',
      location: 'Lahore, Pakistan',
      rating: '4.3',
      image: 'https://via.placeholder.com/300x200.png?text=Minar-e-Pakistan',
    ),
    TourPlace(
      name: 'Wagah Border',
      location: 'Lahore, Pakistan',
      rating: '4.8',
      image: 'https://via.placeholder.com/300x200.png?text=Wagah+Border',
    ),
  ];
}
