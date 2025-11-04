class Perfume {
  final int id;
  final String name;
  final double price;
  final String description;
  final String category;
  final String image;
  final List<String> tags; 

  Perfume({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.tags, 
  });

  factory Perfume.fromMap(Map<String, dynamic> map) {
    return Perfume(
      id: map['id'],
      name: map['title'],
      price: (map['price'] as num).toDouble(),
      description: map['description'],
      category: map['category'],
      image: map['image'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}
