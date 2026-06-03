class MenuOption {
  final String optionId;
  final String name;
  final double price;

  MenuOption({
    required this.optionId,
    required this.name,
    required this.price,
  });

  factory MenuOption.fromMap(Map<String, dynamic> map) {
    return MenuOption(
      optionId: (map['optionId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }
}