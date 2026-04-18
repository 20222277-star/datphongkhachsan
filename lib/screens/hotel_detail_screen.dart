import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hotel.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../services/database_helper.dart';
import '../providers/user_provider.dart';

class HotelDetailScreen extends StatefulWidget {
  final Hotel hotel;

  HotelDetailScreen({required this.hotel});

  @override
  _HotelDetailScreenState createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  late Future<List<Room>> _roomsFuture;
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  DateTimeRange? _selectedDateRange;
  String _selectedImageUrl = '';

  @override
  void initState() {
    super.initState();
    _roomsFuture = DatabaseHelper.instance.getRoomsByHotel(widget.hotel.id!);
    _reviewsFuture = DatabaseHelper.instance.getReviewsByHotel(widget.hotel.id!);
    _selectedImageUrl = widget.hotel.imageUrl;
  }

  // Nâng cấp: Quy trình chọn phương thức thanh toán
  void _showBookingDialog(Room room) {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng chọn ngày nhận/trả phòng trước!')));
      return;
    }

    final int nights = _selectedDateRange!.duration.inDays;
    final double totalPrice = room.price * nights;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận đặt phòng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phòng: ${room.roomNumber} (${room.type})'),
            Text('Số đêm: $nights đêm'),
            Text('Tổng tiền: ${totalPrice.toStringAsFixed(0)}đ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900])),
            SizedBox(height: 20),
            Text('CHỌN PHƯƠNG THỨC THANH TOÁN:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.qr_code_scanner, color: Colors.blue[900]),
              title: Text('Chuyển khoản ngay'),
              subtitle: Text('Giảm thêm 5% và giữ chỗ 100%'),
              onTap: () => _confirmBooking(room, 'Online', totalPrice * 0.95),
            ),
            ListTile(
              leading: Icon(Icons.payments, color: Colors.green),
              title: Text('Thanh toán tại khách sạn'),
              subtitle: Text('Trả tiền khi nhận phòng'),
              onTap: () => _confirmBooking(room, 'AtHotel', totalPrice),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBooking(Room room, String method, double finalPrice) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    Navigator.pop(context); // Đóng dialog chọn method

    final booking = Booking(
      userId: user!.id!,
      roomId: room.id!,
      checkInDate: _selectedDateRange!.start,
      checkOutDate: _selectedDateRange!.end,
      totalPrice: finalPrice,
      paymentMethod: method,
      status: method == 'AtHotel' ? 'Confirmed' : 'Pending', // AtHotel thì xác nhận luôn
    );

    showDialog(context: context, builder: (c) => Center(child: CircularProgressIndicator()));
    await DatabaseHelper.instance.createBooking(booking);
    Navigator.pop(context); // Tắt loading

    if (method == 'Online') {
      _showQRDialog(finalPrice);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đặt phòng thành công! Hẹn gặp bạn tại khách sạn.')));
    }
    setState(() { _roomsFuture = DatabaseHelper.instance.getRoomsByHotel(widget.hotel.id!); });
  }

  void _showQRDialog(double price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thanh toán chuyển khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn vui lòng quét mã QR để thanh toán:'),
            SizedBox(height: 15),
            // Giả lập mã VietQR
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
              child: Image.network('https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=VCB_STK123456_AMOUNT_${price.toInt()}', height: 200),
            ),
            SizedBox(height: 10),
            Text('Số tiền: ${price.toStringAsFixed(0)}đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            Text('Nội dung: CK DAT PHONG ${DateTime.now().millisecondsSinceEpoch}', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('XONG')),
          ElevatedButton(onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng vào mục "Đơn của tôi" để gửi ảnh Bill xác nhận.')));
          }, child: Text('TÔI ĐÃ CHUYỂN KHOẢN')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final allImages = [widget.hotel.imageUrl, ...widget.hotel.gallery];

    return Scaffold(
      appBar: AppBar(title: Text(widget.hotel.name), backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(_selectedImageUrl, height: 400, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(height: 400, color: Colors.grey, child: Icon(Icons.image_not_supported, size: 100))),
            Container(
              height: 100, padding: EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: 10),
                itemCount: allImages.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => setState(() => _selectedImageUrl = allImages[index]),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 5), width: 120,
                    decoration: BoxDecoration(border: Border.all(color: _selectedImageUrl == allImages[index] ? Colors.blue : Colors.transparent, width: 3), borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(5), child: Image.network(allImages[index], fit: BoxFit.cover)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWeb ? 100 : 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('GIỚI THIỆU'),
                  Text(widget.hotel.description, style: TextStyle(fontSize: 16, height: 1.6)),
                  SizedBox(height: 20),
                  _buildSectionTitle('CHỌN THỜI GIAN NGHỈ DƯỠNG'),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 365)));
                      if (picked != null) setState(() => _selectedDateRange = picked);
                    },
                    icon: Icon(Icons.calendar_month),
                    label: Text(_selectedDateRange == null ? 'Bấm để chọn ngày Nhận & Trả phòng' : 'Đã chọn thời gian'),
                  ),
                  SizedBox(height: 30),
                  _buildSectionTitle('DANH SÁCH PHÒNG'),
                  FutureBuilder<List<Room>>(
                    future: _roomsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      return ListView.builder(
                        shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final room = snapshot.data![index];
                          return Card(
                            child: ListTile(
                              leading: Icon(Icons.king_bed, color: Colors.blue[900]),
                              title: Text('${room.type} - Room ${room.roomNumber}', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${room.price.toStringAsFixed(0)}đ / đêm'),
                              trailing: ElevatedButton(
                                onPressed: room.isAvailable ? () => _showBookingDialog(room) : null,
                                style: ElevatedButton.styleFrom(backgroundColor: room.isAvailable ? Colors.orange[900] : Colors.grey, foregroundColor: Colors.white),
                                child: Text(room.isAvailable ? 'ĐẶT PHÒNG' : 'HẾT PHÒNG'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])));
  }
}
