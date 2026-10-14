class Procedure {
  final String id;
  final String name;
  final String description;
  final double price;

  Procedure({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  factory Procedure.fromJson(Map<String, dynamic> json) {
    return Procedure(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
  };
}
