import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/hotel.dart';
import '../models/room.dart';
import '../models/booking.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  final String _baseUrl = 'https://ohhqhpogxofywohjamde.supabase.co';
  final String _restUrl = 'https://ohhqhpogxofywohjamde.supabase.co/rest/v1';
  final String _key = 'sb_publishable_MXLoIMjCuF0T1QtqHUGKcw_8Bu_9BB5';

  DatabaseHelper._init();

  Map<String, String> get _headers => {
    'apikey': _key,
    'Authorization': 'Bearer $_key',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // --- UPLOAD IMAGE ---
  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    try {
      final uploadUrl = '$_baseUrl/storage/v1/object/hotel-images/$fileName';
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'apikey': _key,
          'Authorization': 'Bearer $_key',
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$_baseUrl/storage/v1/object/public/hotel-images/$fileName';
      }
    } catch (e) {
      print('DEBUG: Lỗi upload: $e');
    }
    return null;
  }

  // --- SYSTEM SETTINGS (QR CODE) ---
  Future<String> getQRCode() async {
    final response = await http.get(Uri.parse('$_restUrl/settings?key=eq.qr_code_url&select=value'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) return data.first['value'];
    }
    return 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=VCB_STK123456';
  }

  Future<void> updateQRCode(String newUrl) async {
    await http.patch(
      Uri.parse('$_restUrl/settings?key=eq.qr_code_url'),
      headers: _headers,
      body: json.encode({'value': newUrl}),
    );
  }

  // --- USER METHODS ---
  Future<User?> login(String username, String password) async {
    final response = await http.get(Uri.parse('$_restUrl/users?username=eq.$username&password=eq.$password'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) return User.fromMap(data.first);
    }
    return null;
  }

  Future<void> register(User user) async {
    await http.post(Uri.parse('$_restUrl/users'), headers: _headers, body: json.encode(user.toMap()));
  }

  Future<void> updateUser(User user) async {
    await http.patch(Uri.parse('$_restUrl/users?id=eq.${user.id}'), headers: _headers, body: json.encode(user.toMap()));
  }

  // --- REVIEW METHODS ---
  Future<List<Map<String, dynamic>>> getReviewsByHotel(int hotelId) async {
    final response = await http.get(Uri.parse('$_restUrl/reviews?hotel_id=eq.$hotelId&select=*,users(full_name,username)&order=created_at.desc'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((r) => {
        'id': r['id'], 'rating': r['rating'], 'comment': r['comment'], 'createdAt': r['created_at'], 'userName': r['users']['full_name'] ?? r['users']['username'],
      }).toList();
    }
    return [];
  }

  Future<void> addReview(int userId, int hotelId, int rating, String comment) async {
    await http.post(Uri.parse('$_restUrl/reviews'), headers: _headers, body: json.encode({'user_id': userId, 'hotel_id': hotelId, 'rating': rating, 'comment': comment}));
  }

  // --- HOTEL & ROOM METHODS ---
  Future<List<Hotel>> getAllHotels() async {
    final response = await http.get(Uri.parse('$_restUrl/hotels?select=*&order=id.desc'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((h) => Hotel.fromMap(h)).toList();
    }
    return [];
  }

  Future<void> addHotel(Hotel hotel) async {
    await http.post(Uri.parse('$_restUrl/hotels'), headers: _headers, body: json.encode(hotel.toMap()));
  }

  Future<void> updateHotel(Hotel hotel) async {
    await http.patch(Uri.parse('$_restUrl/hotels?id=eq.${hotel.id}'), headers: _headers, body: json.encode(hotel.toMap()));
  }

  Future<void> deleteHotel(int id) async {
    await http.delete(Uri.parse('$_restUrl/hotels?id=eq.$id'), headers: _headers);
  }

  Future<List<Room>> getRoomsByHotel(int hotelId) async {
    final response = await http.get(Uri.parse('$_restUrl/rooms?hotel_id=eq.$hotelId&order=room_number.asc'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((r) => Room(
        id: r['id'], 
        hotelId: r['hotel_id'], 
        roomNumber: r['room_number'], 
        type: r['type'], 
        price: (r['price'] as num).toDouble(), 
        isAvailable: r['status'] == 'Available'
      )).toList();
    }
    return [];
  }

  Future<void> addRoom(Room room) async {
    await http.post(Uri.parse('$_restUrl/rooms'), headers: _headers, body: json.encode({
      'hotel_id': room.hotelId, 
      'room_number': room.roomNumber, 
      'type': room.type, 
      'price': room.price, 
      'status': 'Available'
    }));
  }

  Future<void> updateRoomStatus(int roomId, String status) async {
    await http.patch(Uri.parse('$_restUrl/rooms?id=eq.$roomId'), headers: _headers, body: json.encode({'status': status}));
  }

  Future<void> deleteRoom(int roomId) async {
    await http.delete(Uri.parse('$_restUrl/rooms?id=eq.$roomId'), headers: _headers);
  }

  // --- BOOKING METHODS ---
  Future<void> createBooking(Booking booking) async {
    await http.post(Uri.parse('$_restUrl/bookings'), headers: _headers, body: json.encode(booking.toMap()));
  }

  Future<List<Map<String, dynamic>>> getUserBookings(int userId) async {
    final response = await http.get(Uri.parse('$_restUrl/bookings?user_id=eq.$userId&select=*,rooms(id,room_number,hotels(id,name))&order=id.desc'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((b) => {
        'id': b['id'], 
        'userId': b['user_id'], 
        'roomId': b['room_id'], 
        'hotelId': b['rooms']['hotels']['id'],
        'checkInDate': b['check_in_date'],
        'checkOutDate': b['check_out_date'], 
        'totalPrice': b['total_price'], 
        'status': b['status'],
        'paymentProofUrl': b['payment_proof_url'],
        'roomNumber': b['rooms']['room_number'], 
        'hotelName': b['rooms']['hotels']['name'],
      }).toList();
    }
    return [];
  }

  Future<void> submitPaymentBill(int bookingId, String billUrl) async {
    await http.patch(Uri.parse('$_restUrl/bookings?id=eq.$bookingId'), headers: _headers, body: json.encode({'payment_proof_url': billUrl}));
  }

  Future<void> cancelBooking(int bookingId) async {
    await http.patch(Uri.parse('$_restUrl/bookings?id=eq.$bookingId'), headers: _headers, body: json.encode({'status': 'Cancelled'}));
  }

  // --- ADMIN STATS ---
  Future<Map<String, dynamic>> getAdminStats() async {
    final hRes = await http.get(Uri.parse('$_restUrl/hotels?select=id'), headers: {'apikey': _key, 'Prefer': 'count=exact'});
    final bRes = await http.get(Uri.parse('$_restUrl/bookings?select=id'), headers: {'apikey': _key, 'Prefer': 'count=exact'});
    final uRes = await http.get(Uri.parse('$_restUrl/users?select=id'), headers: {'apikey': _key, 'Prefer': 'count=exact'});
    final revRes = await http.get(Uri.parse('$_restUrl/bookings?select=total_price&status=eq.Completed'), headers: _headers);
    double rev = 0;
    if (revRes.statusCode == 200) { for (var b in json.decode(revRes.body)) { rev += (b['total_price'] as num).toDouble(); } }
    
    final rangeH = hRes.headers['content-range'];
    final rangeB = bRes.headers['content-range'];
    final rangeU = uRes.headers['content-range'];
    
    return {
      'totalHotels': rangeH != null ? int.parse(rangeH.split('/').last) : 0,
      'totalBookings': rangeB != null ? int.parse(rangeB.split('/').last) : 0,
      'totalRevenue': rev,
      'totalUsers': rangeU != null ? int.parse(rangeU.split('/').last) - 1 : 0,
    };
  }

  Future<void> updateBookingStatus(int bookingId, String status) async {
    await http.patch(Uri.parse('$_restUrl/bookings?id=eq.$bookingId'), headers: _headers, body: json.encode({'status': status}));
  }

  Future<List<Map<String, dynamic>>> getAllBookingsAdmin() async {
    final response = await http.get(Uri.parse('$_restUrl/bookings?select=*,users(username,full_name,phone),rooms(room_number,hotels(id,name))&order=id.desc'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((b) => {
        'id': b['id'], 'userId': b['user_id'], 'roomId': b['room_id'], 'hotelId': b['rooms']['hotels']['id'], 'checkInDate': b['check_in_date'], 'checkOutDate': b['check_out_date'], 'totalPrice': b['total_price'], 'status': b['status'], 'paymentProofUrl': b['payment_proof_url'], 'username': b['users']['username'], 'fullName': b['users']['full_name'], 'phone': b['users']['phone'], 'roomNumber': b['rooms']['room_number'], 'hotelName': b['rooms']['hotels']['name'],
      }).toList();
    }
    return [];
  }

  Future<void> init() async {}
}
