class Room {
  final int? id;
  final int hotelId;
  final String roomNumber;
  final String type;
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
      'hotel_id': hotelId,
      'room_number': roomNumber,
      'type': type,
      'price': price,
      'status': isAvailable ? 'Available' : 'Maintenance', // Đồng bộ với DB
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      hotelId: map['hotel_id'] ?? 0,
      roomNumber: map['room_number'] ?? '',
      type: map['type'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isAvailable: map['status'] == 'Available',
    );
  }
}
