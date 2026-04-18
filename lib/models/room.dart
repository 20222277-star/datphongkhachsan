class Room {
  final int? id;
  final int hotelId;
  final String roomNumber;
  final String type; // e.g., "Single", "Double", "Suite"
  final double price;
  final bool isAvailable;

  Room({
    this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.type,
    required this.price,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hotelId': hotelId,
      'roomNumber': roomNumber,
      'type': type,
      'price': price,
      'isAvailable': isAvailable ? 1 : 0,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      hotelId: map['hotelId'],
      roomNumber: map['roomNumber'],
      type: map['type'],
      price: map['price'],
      isAvailable: map['isAvailable'] == 1,
    );
  }
}
