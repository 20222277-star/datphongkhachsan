class Booking {
  final int? id;
  final int userId;
  final int roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalPrice;
  final String status; // 'Pending', 'Confirmed', 'Cancelled', 'Completed'
  final String? paymentProofUrl;
  final String paymentMethod; // 'Online' or 'AtHotel'

  Booking({
    this.id,
    required this.userId,
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalPrice,
    this.status = 'Pending',
    this.paymentProofUrl,
    this.paymentMethod = 'Online',
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'user_id': userId,
      'room_id': roomId,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'total_price': totalPrice,
      'status': status,
      'payment_proof_url': paymentProofUrl,
      'payment_method': paymentMethod,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      userId: map['user_id'],
      roomId: map['room_id'],
      checkInDate: DateTime.parse(map['check_in_date']),
      checkOutDate: DateTime.parse(map['check_out_date']),
      totalPrice: (map['total_price'] as num).toDouble(),
      status: map['status'] ?? 'Pending',
      paymentProofUrl: map['payment_proof_url'],
      paymentMethod: map['payment_method'] ?? 'Online',
    );
  }
}
