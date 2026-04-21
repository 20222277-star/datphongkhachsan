class Hotel {
  final int? id;
  final String name;
  final String location;
  final String description;
  final String amenities;
  final String imageUrl;
  final List<String> gallery;
  final int stars; // Thêm số sao

  Hotel({
    this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.amenities,
    required this.imageUrl,
    this.gallery = const [],
    this.stars = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'amenities': amenities,
      'image_url': imageUrl,
      'gallery': gallery.join(','),
      'stars': stars,
    };
  }

  factory Hotel.fromMap(Map<String, dynamic> map) {
    return Hotel(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      description: map['description'],
      amenities: map['amenities'],
      imageUrl: map['image_url'] ?? '',
      gallery: (map['gallery'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      stars: map['stars'] ?? 3,
    );
  }
}
