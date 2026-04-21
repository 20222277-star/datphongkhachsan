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

  // NÂNG CẤP: Tự động hóa thay đổi trạng thái phòng khi đổi trạng thái đơn hàng
  void _updateStatus(int bookingId, int roomId, String newStatus) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => Center(child: CircularProgressIndicator()));
    
    await DatabaseHelper.instance.updateBookingStatus(bookingId, newStatus);
    
    // LOGIC TỰ ĐỘNG HÓA
    if (newStatus == 'Checked-in') {
      // Khách nhận phòng -> Đổi phòng sang trạng thái Occupied
      await DatabaseHelper.instance.updateRoomStatus(roomId, 'Occupied');
    } else if (newStatus == 'Completed') {
      // Khách trả phòng -> Đổi phòng về trạng thái Available
      await DatabaseHelper.instance.updateRoomStatus(roomId, 'Available');
    } else if (newStatus == 'Cancelled') {
      // Hủy đơn -> Đổi phòng về Available
      await DatabaseHelper.instance.updateRoomStatus(roomId, 'Available');
    }

    Navigator.pop(context); // Tắt loading
    _loadBookings();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật: $newStatus')));
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
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final bookings = snapshot.data!;
          if (bookings.isEmpty) return Center(child: Text('Chưa có đơn đặt nào.'));

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
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
                          Text('Đơn hàng #${b['id']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _getStatusColor(b['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(b['status'], style: TextStyle(color: _getStatusColor(b['status']), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Divider(),
                      Text('${b['hotelName']} - Phòng ${b['roomNumber']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text('Khách hàng: ${b['fullName']}'),
                      Text('SĐT: ${b['phone']}'),
                      Text('Giá: ${b['totalPrice'].toStringAsFixed(0)}đ'),
                      SizedBox(height: 20),
                      
                      // NÚT HÀNH ĐỘNG THEO QUY TRÌNH
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _viewBill(b['paymentProofUrl']),
                              icon: Icon(Icons.receipt_long),
                              label: Text('XEM BILL'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                            ),
                            SizedBox(width: 10),
                            
                            if (b['status'] == 'Pending') ...[
                              ElevatedButton(
                                onPressed: () => _updateStatus(b['id'], b['roomId'], 'Confirmed'),
                                child: Text('XÁC NHẬN BILL'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => _updateStatus(b['id'], b['roomId'], 'Cancelled'),
                                child: Text('HỦY ĐƠN'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              ),
                            ],
                            
                            if (b['status'] == 'Confirmed') 
                              ElevatedButton.icon(
                                onPressed: () => _updateStatus(b['id'], b['roomId'], 'Checked-in'),
                                icon: Icon(Icons.login),
                                label: Text('NHẬN PHÒNG (CHECK-IN)'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                              ),
                              
                            if (b['status'] == 'Checked-in')
                              ElevatedButton.icon(
                                onPressed: () => _updateStatus(b['id'], b['roomId'], 'Completed'),
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
