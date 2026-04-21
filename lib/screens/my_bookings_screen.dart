import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../providers/user_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late Future<List<Map<String, dynamic>>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      setState(() {
        _bookingsFuture = DatabaseHelper.instance.getUserBookings(user.id!);
      });
    }
  }

  void _pickAndUploadBill(int bookingId) {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files!.length == 1) {
        final file = files[0];
        final reader = html.FileReader();

        reader.onLoadEnd.listen((e) async {
          final bytes = reader.result as Uint8List;
          final fileName = 'bill_${bookingId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(child: CircularProgressIndicator()),
          );

          final url = await DatabaseHelper.instance.uploadImage(bytes, fileName);
          Navigator.pop(context);

          if (url != null) {
            await DatabaseHelper.instance.submitPaymentBill(bookingId, url);
            _loadBookings();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi minh chứng thành công!')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi upload ảnh minh chứng')));
          }
        });
        reader.readAsArrayBuffer(file);
      }
    });
  }

  void _cancelBooking(int bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận hủy'),
        content: Text('Bạn có chắc chắn muốn hủy đơn đặt phòng này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Không')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hủy đơn', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.cancelBooking(bookingId);
      _loadBookings();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã hủy đơn thành công!')));
    }
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
      appBar: AppBar(
        title: Text('ĐƠN ĐẶT PHÒNG CỦA TÔI'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          
          final bookings = snapshot.data!;
          if (bookings.isEmpty) return Center(child: Text('Bạn chưa có đơn đặt phòng nào.'));

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              
              // MAPPING DỮ LIỆU TỪ SUPABASE (Nested Objects)
              final int bookingId = b['id'];
              final String status = b['status'] ?? 'Pending';
              final double totalPrice = (b['total_price'] ?? 0).toDouble();
              final String? billUrl = b['payment_proof_url'];
              final String checkIn = b['check_in_date']?.toString().split(' ')[0] ?? 'N/A';
              final String checkOut = b['check_out_date']?.toString().split(' ')[0] ?? 'N/A';

              // Lấy thông tin phòng và khách sạn lồng nhau
              final room = b['rooms'] ?? {};
              final String roomNumber = room['room_number']?.toString() ?? 'N/A';
              final String hotelName = (room['hotels'] != null) ? room['hotels']['name'] : 'Khách sạn ẩn';

              final canCancel = status == 'Pending';
              final hasBill = billUrl != null && billUrl.isNotEmpty;

              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Đơn hàng #$bookingId', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status, style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Divider(height: 24),
                      Text(hotelName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Phòng: $roomNumber', style: TextStyle(fontSize: 16, color: Colors.blue[900])),
                      SizedBox(height: 8),
                      Text('Lịch trình: $checkIn ➔ $checkOut'),
                      Text('Tổng thanh toán: ${totalPrice.toStringAsFixed(0)}đ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[900])),
                      SizedBox(height: 20),
                      
                      if (hasBill)
                        Container(
                          padding: EdgeInsets.all(8),
                          margin: EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Expanded(child: Text('Đã gửi minh chứng thanh toán', style: TextStyle(color: Colors.green[800], fontSize: 13))),
                              TextButton(onPressed: () {
                                showDialog(context: context, builder: (c) => AlertDialog(content: Image.network(billUrl)));
                              }, child: Text('XEM LẠI'))
                            ],
                          ),
                        ),
                        
                      Row(
                        children: [
                          if (status == 'Pending')
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _pickAndUploadBill(bookingId),
                                icon: Icon(Icons.upload_file),
                                label: Text(hasBill ? 'GỬI LẠI BILL' : 'GỬI BILL'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                              ),
                            ),
                          if (canCancel) ...[
                            SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _cancelBooking(bookingId),
                                icon: Icon(Icons.cancel),
                                label: Text('HỦY ĐƠN'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              ),
                            ),
                          ],
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
