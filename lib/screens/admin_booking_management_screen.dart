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

  void _updateStatus(int bookingId, String status) async {
    await DatabaseHelper.instance.updateBookingStatus(bookingId, status);
    _loadBookings();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật trạng thái: $status')));
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
          width: 500,
          height: 500,
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
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Duyệt đơn đặt phòng'), backgroundColor: Colors.red[900], foregroundColor: Colors.white),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _viewBill(b['paymentProofUrl']),
                            icon: Icon(Icons.receipt_long),
                            label: Text('XEM BILL'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                          ),
                          if (b['status'] == 'Pending') Row(
                            children: [
                              IconButton(icon: Icon(Icons.check_circle, color: Colors.green, size: 35), onPressed: () => _updateStatus(b['id'], 'Confirmed')),
                              IconButton(icon: Icon(Icons.cancel, color: Colors.red, size: 35), onPressed: () => _updateStatus(b['id'], 'Cancelled')),
                            ],
                          ),
                          if (b['status'] == 'Confirmed') ElevatedButton(
                            onPressed: () => _updateStatus(b['id'], 'Completed'),
                            child: Text('HOÀN THÀNH'),
                          ),
                        ],
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
