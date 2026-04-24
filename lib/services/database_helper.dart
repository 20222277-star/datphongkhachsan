import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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

  void _log(String func, http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      print('✅ [SUCCESS] $func: ${res.statusCode}');
    } else {
      print('❌ [FAILED] $func: ${res.statusCode} - ${res.body}');
    }
  }

  // --- QUẢN LÝ ĐỊA DANH ---
  Future<List<String>> getLocations() async {
    try {
      final res = await http.get(Uri.parse('$_restUrl/locations?select=name&order=name.asc'), headers: _headers);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((item) => item['name'] as String).toList();
      }
    } catch (e) { print("Error getLocations: $e"); }
    return [];
  }

  Future<List<Map<String, dynamic>>> getLocationsRaw() async {
    final res = await http.get(Uri.parse('$_restUrl/locations?select=*&order=id.desc'), headers: _headers);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(res.body));
    return [];
  }

  Future<void> addLocation(String name) async {
    final res = await http.post(Uri.parse('$_restUrl/locations'), headers: _headers, body: json.encode({'name': name}));
    _log('addLocation', res);
  }

  Future<void> updateLocation(int id, String newName) async {
    final res = await http.patch(Uri.parse('$_restUrl/locations?id=eq.$id'), headers: _headers, body: json.encode({'name': newName}));
    _log('updateLocation', res);
  }

  Future<void> deleteLocation(int id) async {
    final res = await http.delete(Uri.parse('$_restUrl/locations?id=eq.$id'), headers: _headers);
    _log('deleteLocation', res);
  }

  // --- HỆ THỐNG (UPLOAD & QR) ---
  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    try {
      final url = '$_baseUrl/storage/v1/object/hotel-images/$fileName';
      final res = await http.post(Uri.parse(url), headers: {'apikey': _key, 'Authorization': 'Bearer $_key', 'Content-Type': 'image/jpeg'}, body: bytes);
      if (res.statusCode == 200 || res.statusCode == 201) return '$_baseUrl/storage/v1/object/public/hotel-images/$fileName';
    } catch (e) { print(e); }
    return null;
  }

  Future<String> getQRCode() async {
    try {
      final res = await http.get(Uri.parse('$_restUrl/settings?key=eq.qr_code_url&select=value'), headers: _headers);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        if (data.isNotEmpty) return data.first['value'];
      }
    } catch (e) {}
    return 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=STK_DEFAULT';
  }

  Future<void> updateQRCode(String newUrl) async {
    final res = await http.patch(Uri.parse('$_restUrl/settings?key=eq.qr_code_url'), headers: _headers, body: json.encode({'value': newUrl}));
    _log('updateQRCode', res);
  }

  // --- NGƯỜI DÙNG ---
  Future<User?> login(String username, String password) async {
    final res = await http.get(Uri.parse('$_restUrl/users?username=eq.$username&password=eq.$password'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      if (data.isNotEmpty) return User.fromMap(data.first);
    }
    return null;
  }

  Future<void> register(User user) async {
    final data = user.toMap();
    data.remove('id');
    final res = await http.post(Uri.parse('$_restUrl/users'), headers: _headers, body: json.encode(data));
    _log('register', res);
  }

  Future<void> updateUser(User user) async {
    final data = user.toMap();
    data.remove('id');
    final res = await http.patch(Uri.parse('$_restUrl/users?id=eq.${user.id}'), headers: _headers, body: json.encode(data));
    _log('updateUser', res);
  }

  // --- YÊU THÍCH ---
  Future<void> toggleFavorite(int userId, int hotelId, bool isFavorite) async {
    if (isFavorite) {
      await http.post(Uri.parse('$_restUrl/favorites'), headers: _headers, body: json.encode({'user_id': userId, 'hotel_id': hotelId}));
    } else {
      await http.delete(Uri.parse('$_restUrl/favorites?user_id=eq.$userId&hotel_id=eq.$hotelId'), headers: _headers);
    }
  }

  Future<List<int>> getUserFavorites(int userId) async {
    final res = await http.get(Uri.parse('$_restUrl/favorites?user_id=eq.$userId&select=hotel_id'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((f) => f['hotel_id'] as int).toList();
    }
    return [];
  }

  // --- KHÁCH SẠN ---
  Future<List<Hotel>> getAllHotels() async {
    final res = await http.get(Uri.parse('$_restUrl/hotels?select=*&order=id.desc'), headers: _headers);
    if (res.statusCode == 200) return (json.decode(res.body) as List).map((h) => Hotel.fromMap(h)).toList();
    return [];
  }

  Future<void> addHotel(Hotel h) async {
    final data = h.toMap();
    data.remove('id');
    final res = await http.post(Uri.parse('$_restUrl/hotels'), headers: _headers, body: json.encode(data));
    _log('addHotel', res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Không thể thêm khách sạn: ${res.body}');
    }
  }

  Future<void> updateHotel(Hotel h) async {
    final data = h.toMap();
    final id = data.remove('id');
    final res = await http.patch(Uri.parse('$_restUrl/hotels?id=eq.$id'), headers: _headers, body: json.encode(data));
    _log('updateHotel', res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Không thể cập nhật khách sạn: ${res.body}');
    }
  }

  Future<void> deleteHotel(int id) async {
    final res = await http.delete(Uri.parse('$_restUrl/hotels?id=eq.$id'), headers: _headers);
    _log('deleteHotel', res);
  }

  // --- PHÒNG ---
  Future<List<Room>> getRoomsByHotel(int hotelId) async {
    final res = await http.get(Uri.parse('$_restUrl/rooms?hotel_id=eq.$hotelId&order=room_number.asc'), headers: _headers);
    if (res.statusCode == 200) return (json.decode(res.body) as List).map((r) => Room.fromMap(r)).toList();
    return [];
  }

  Future<void> addRoom(Room r) async {
    final data = r.toMap();
    data.remove('id');
    final res = await http.post(Uri.parse('$_restUrl/rooms'), headers: _headers, body: json.encode(data));
    _log('addRoom', res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Không thể thêm phòng: ${res.body}');
    }
  }

  Future<void> updateRoomStatus(int roomId, String status) async {
    final res = await http.patch(Uri.parse('$_restUrl/rooms?id=eq.$roomId'), headers: _headers, body: json.encode({'status': status}));
    _log('updateRoomStatus', res);
  }

  Future<void> deleteRoom(int roomId) async {
    final res = await http.delete(Uri.parse('$_restUrl/rooms?id=eq.$roomId'), headers: _headers);
    _log('deleteRoom', res);
  }

  // --- ĐẶT PHÒNG ---
  Future<void> createBooking(Booking b) async {
    final data = b.toMap();
    data.remove('id');
    final res = await http.post(Uri.parse('$_restUrl/bookings'), headers: _headers, body: json.encode(data));
    _log('createBooking', res);
  }

  Future<List<Map<String, dynamic>>> getUserBookings(int userId) async {
    final res = await http.get(Uri.parse('$_restUrl/bookings?user_id=eq.$userId&select=*,rooms(id,room_number,hotels(id,name))&order=id.desc'), headers: _headers);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(res.body));
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllBookingsAdmin() async {
    final res = await http.get(Uri.parse('$_restUrl/bookings?select=*,users(username,full_name,phone),rooms(id,room_number,hotels(id,name))&order=id.desc'), headers: _headers);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(res.body));
    return [];
  }

  Future<void> updateBookingStatus(int bookingId, String status) async {
    final res = await http.patch(Uri.parse('$_restUrl/bookings?id=eq.$bookingId'), headers: _headers, body: json.encode({'status': status}));
    _log('updateBookingStatus', res);
  }

  Future<void> submitPaymentBill(int bookingId, String billUrl) async {
    final res = await http.patch(Uri.parse('$_restUrl/bookings?id=eq.$bookingId'), headers: _headers, body: json.encode({'payment_proof_url': billUrl}));
    _log('submitPaymentBill', res);
  }

  Future<void> cancelBooking(int bookingId) async {
    final res = await http.patch(Uri.parse('$_restUrl/bookings?id=eq.$bookingId'), headers: _headers, body: json.encode({'status': 'Cancelled'}));
    _log('cancelBooking', res);
  }

  // --- ĐÁNH GIÁ & THỐNG KÊ ---
  Future<List<Map<String, dynamic>>> getReviewsByHotel(int hotelId) async {
    final res = await http.get(Uri.parse('$_restUrl/reviews?hotel_id=eq.$hotelId&select=*,users(full_name,username)&order=created_at.desc'), headers: _headers);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(res.body));
    return [];
  }

  Future<void> addReview(int userId, int hotelId, int rating, String comment) async {
    await http.post(Uri.parse('$_restUrl/reviews'), headers: _headers, body: json.encode({'user_id': userId, 'hotel_id': hotelId, 'rating': rating, 'comment': comment}));
  }

  Future<List<Map<String, dynamic>>> getPopularHotels() async {
    final res = await http.get(Uri.parse('$_restUrl/bookings?select=rooms(hotel_id)'), headers: _headers);
    if (res.statusCode != 200) return [];
    final List bookings = json.decode(res.body);
    Map<int, int> counts = {};
    for (var b in bookings) { if (b['rooms'] != null) { int hid = b['rooms']['hotel_id']; counts[hid] = (counts[hid] ?? 0) + 1; } }
    var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final hotels = await getAllHotels();
    List<Map<String, dynamic>> results = [];
    for (var entry in sorted.take(4)) { try { final h = hotels.firstWhere((h) => h.id == entry.key); results.add({'hotel': h, 'count': entry.value}); } catch (e) {} }
    return results;
  }

  // --- LỌC PHÒNG NÂNG CAO ---
  Future<List<Room>> getAvailableRooms(int hotelId, DateTimeRange range) async {
    final rooms = await getRoomsByHotel(hotelId);
    final res = await http.get(Uri.parse('$_restUrl/bookings?room_id=in.(${rooms.map((r) => r.id).join(",")})&status=neq.Cancelled'), headers: _headers);
    if (res.statusCode == 200) {
      final List bData = json.decode(res.body);
      final List<int> occupied = [];
      for (var b in bData) {
        if (DateTime.parse(b['check_in_date']).isBefore(range.end) && DateTime.parse(b['check_out_date']).isAfter(range.start)) occupied.add(b['room_id']);
      }
      return rooms.map((r) => Room(id: r.id, hotelId: r.hotelId, roomNumber: r.roomNumber, type: r.type, price: r.price, isAvailable: r.isAvailable && !occupied.contains(r.id))).toList();
    }
    return rooms;
  }

  Future<List<Hotel>> getAvailableHotels(DateTimeRange range) async {
    final hotels = await getAllHotels();
    final resR = await http.get(Uri.parse('$_restUrl/rooms?select=*'), headers: _headers);
    final resB = await http.get(Uri.parse('$_restUrl/bookings?status=neq.Cancelled'), headers: _headers);
    if (resR.statusCode != 200 || resB.statusCode != 200) return hotels;
    final List rData = json.decode(resR.body);
    final List bData = json.decode(resB.body);
    final List<int> occupied = [];
    for (var b in bData) { if (DateTime.parse(b['check_in_date']).isBefore(range.end) && DateTime.parse(b['check_out_date']).isAfter(range.start)) occupied.add(b['room_id']); }
    List<Hotel> available = [];
    for (var h in hotels) { if (rData.where((r) => r['hotel_id'] == h.id).any((r) => !occupied.contains(r['id']) && r['status'] == 'Available')) available.add(h); }
    return available;
  }

  // --- THỐNG KÊ ADMIN ---
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final countHeaders = {..._headers, 'Prefer': 'count=exact'};
      final hRes = await http.get(Uri.parse('$_restUrl/hotels?select=id'), headers: countHeaders);
      final bRes = await http.get(Uri.parse('$_restUrl/bookings?select=id'), headers: countHeaders);
      final uRes = await http.get(Uri.parse('$_restUrl/users?select=id'), headers: countHeaders);
      final revRes = await http.get(Uri.parse('$_restUrl/bookings?select=total_price&status=eq.Completed'), headers: _headers);
      double rev = 0; if (revRes.statusCode == 200) for (var d in json.decode(revRes.body)) rev += (d['total_price'] as num).toDouble();
      return {'totalHotels': _parseCount(hRes), 'totalBookings': _parseCount(bRes), 'totalRevenue': rev, 'totalUsers': _parseCount(uRes) > 0 ? _parseCount(uRes) - 1 : 0};
    } catch (e) { return {'totalHotels': 0, 'totalBookings': 0, 'totalRevenue': 0, 'totalUsers': 0}; }
  }

  int _parseCount(http.Response res) {
    final range = res.headers['content-range'];
    if (range != null && range.contains('/')) return int.parse(range.split('/').last);
    return 0;
  }

  Future<void> init() async {}
}
