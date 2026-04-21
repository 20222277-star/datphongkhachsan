import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class AdminBookingManagementScreen extends StatefulWidget {
  @override
  _AdminBookingManagementScreenState createState() => _AdminBookingManagementScreenState();
}

class _AdminBookingManagementScreenState extends State<AdminBookingManagementScreen> {
  late Future<List<Map<String, dynamic>>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = DatabaseHelper.instance.getAllBookingsAdmin();
    });
  }

  // CẬP NHẬT: Xử lý dữ liệu Supabase lồng nhau (Nested data)
  void _updateStatus(int bookingId, int roomId, String newStatus) async {
    print("DEBUG: Updating Booking $bookingId, Room $roomId to $newStatus");
    
    showDialog(context: context, barrierDismissible: false, builder: (c) => Center(child: CircularProgressIndicator()));
    
    try {
      await DatabaseHelper.instance.updateBookingStatus(bookingId, newStatus);
      
      // LOGIC TỰ ĐỘNG HÓA TRẠNG THÁI PHÒNG
      if (newStatus == 'Confirmed' || newStatus == 'Checked-in') {
        await DatabaseHelper.instance.updateRoomStatus(roomId, 'Occupied');
      } else if (newStatus == 'Completed' || newStatus == 'Cancelled') {
        await DatabaseHelper.instance.updateRoomStatus(roomId, 'Available');
      }

      if (mounted) {
        Navigator.pop(context); // Tắt loading
        _loadBookings();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật đơn hàng thành: $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _viewBill(String? url) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Khách hàng chưa gửi minh chứng thanh toán')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Minh chứng thanh toán'),
        content: Container(
          width: 500, height: 500,
          child: Image.network(url, fit: BoxFit.contain, errorBuilder: (c,e,s) => Center(child: Text('Không thể tải ảnh bill'))),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('ĐÓNG'))],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Confirmed': return Colors.blue;
      case 'Checked-in': return Colors.purple;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DUYỆT ĐƠN ĐẶT PHÒNG'), backgroundColor: Colors.red[900], foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          
          final bookings = snapshot.data!;
          if (bookings.isEmpty) return Center(child: Text('Chưa có đơn đặt nào.'));

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              
              // MAPPING DỮ LIỆU TỪ SUPABASE (Nested Objects)
              final int bookingId = b['id'];
              final String status = b['status'] ?? 'Pending';
              final double totalPrice = (b['total_price'] ?? 0).toDouble();
              
              // Lấy thông tin user từ quan hệ lồng
              final user = b['users'] ?? {};
              final String customerName = user['full_name'] ?? user['username'] ?? 'Ẩn danh';
              final String customerPhone = user['phone'] ?? 'Không có SĐT';

              // Lấy thông tin phòng và khách sạn từ quan hệ lồng
              final room = b['rooms'] ?? {};
              final int roomId = room['id'] ?? 0;
              final String roomNumber = room['room_number']?.toString() ?? 'N/A';
              final String hotelName = (room['hotels'] != null) ? room['hotels']['name'] : 'N/A';

              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Đơn hàng #$bookingId', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(status, style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Divider(),
                      Text('$hotelName - Phòng $roomNumber', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text('Khách hàng: $customerName'),
                      Text('SĐT: $customerPhone'),
                      Text('Giá: ${totalPrice.toStringAsFixed(0)}đ'),
                      SizedBox(height: 20),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _viewBill(b['payment_proof_url']),
                              icon: Icon(Icons.receipt_long),
                              label: Text('XEM BILL'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                            ),
                            SizedBox(width: 10),
                            
                            if (status == 'Pending') ...[
                              ElevatedButton(
                                onPressed: () => _updateStatus(bookingId, roomId, 'Confirmed'),
                                child: Text('XÁC NHẬN BILL'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => _updateStatus(bookingId, roomId, 'Cancelled'),
                                child: Text('HỦY ĐƠN'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              ),
                            ],
                            
                            if (status == 'Confirmed') 
                              ElevatedButton.icon(
                                onPressed: () => _updateStatus(bookingId, roomId, 'Checked-in'),
                                icon: Icon(Icons.login),
                                label: Text('NHẬN PHÒNG (CHECK-IN)'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                              ),
                              
                            if (status == 'Checked-in')
                              ElevatedButton.icon(
                                onPressed: () => _updateStatus(bookingId, roomId, 'Completed'),
                                icon: Icon(Icons.logout),
                                label: Text('TRẢ PHÒNG (CHECK-OUT)'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
