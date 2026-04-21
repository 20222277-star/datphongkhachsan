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
    _selectedImageUrl = widget.hotel.imageUrl;
    _loadAvailableRooms();
    _loadReviews();
  }

  void _loadAvailableRooms() {
    setState(() {
      if (_selectedDateRange == null) {
        _roomsFuture = DatabaseHelper.instance.getRoomsByHotel(widget.hotel.id!);
      } else {
        _roomsFuture = DatabaseHelper.instance.getAvailableRooms(widget.hotel.id!, _selectedDateRange!);
      }
    });
  }

  void _loadReviews() {
    setState(() {
      _reviewsFuture = DatabaseHelper.instance.getReviewsByHotel(widget.hotel.id!);
    });
  }

  // WIDGET HIỂN THỊ ẢNH CÓ HIỆU ỨNG LOADING
  Widget _buildNetworkImage(String url, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          child: child,
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          width: width,
          color: Colors.grey[100],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

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
    Navigator.pop(context);

    final booking = Booking(
      userId: user!.id!,
      roomId: room.id!,
      checkInDate: _selectedDateRange!.start,
      checkOutDate: _selectedDateRange!.end,
      totalPrice: finalPrice,
      paymentMethod: method,
      status: method == 'AtHotel' ? 'Confirmed' : 'Pending',
    );

    showDialog(context: context, builder: (c) => Center(child: CircularProgressIndicator()));
    await DatabaseHelper.instance.createBooking(booking);
    Navigator.pop(context);

    if (method == 'Online') {
      _showQRDialog(finalPrice);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đặt phòng thành công! Hẹn gặp bạn tại khách sạn.')));
    }
    _loadAvailableRooms();
  }

  void _showQRDialog(double price) async {
    final qrUrl = await DatabaseHelper.instance.getQRCode();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thanh toán chuyển khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vui lòng quét mã QR để thanh toán:'),
            SizedBox(height: 15),
            _buildNetworkImage(qrUrl, height: 250),
            SizedBox(height: 10),
            Text('Số tiền: ${price.toStringAsFixed(0)}đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[900])),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('TÔI ĐÃ CHUYỂN KHOẢN')),
        ],
      ),
    );
  }

  void _showAddReviewDialog() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')));
      return;
    }

    final commentController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Viết đánh giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.orange, size: 30),
                  onPressed: () => setDialogState(() => rating = index + 1),
                )),
              ),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(hintText: 'Nhận xét của bạn...', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('HỦY')),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.isNotEmpty) {
                  await DatabaseHelper.instance.addReview(user.id!, widget.hotel.id!, rating, commentController.text);
                  Navigator.pop(context);
                  _loadReviews();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')));
                }
              },
              child: Text('GỬI'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    final allImages = [widget.hotel.imageUrl, ...widget.hotel.gallery];

    return Scaffold(
      appBar: AppBar(title: Text(widget.hotel.name), backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO IMAGE SECTION
            GestureDetector(
              onTap: () {
                showDialog(context: context, builder: (c) => Dialog.fullscreen(
                  backgroundColor: Colors.black,
                  child: Stack(
                    children: [
                      Center(child: _buildNetworkImage(_selectedImageUrl, fit: BoxFit.contain)),
                      Positioned(top: 20, right: 20, child: IconButton(icon: Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(c))),
                    ],
                  ),
                ));
              },
              child: _buildNetworkImage(_selectedImageUrl, height: 450, width: double.infinity),
            ),
            
            // THUMBNAILS SECTION
            Container(
              height: 100, padding: EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: 10),
                itemCount: allImages.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => setState(() => _selectedImageUrl = allImages[index]),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 5), width: 120,
                    decoration: BoxDecoration(border: Border.all(color: _selectedImageUrl == allImages[index] ? Colors.blue : Colors.grey[300]!, width: 2), borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(6), child: _buildNetworkImage(allImages[index])),
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWeb ? screenWidth * 0.15 : 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('GIỚI THIỆU'),
                      Row(children: [Icon(Icons.location_on, color: Colors.red, size: 18), SizedBox(width: 5), Text(widget.hotel.location, style: TextStyle(color: Colors.grey[700]))]),
                    ],
                  ),
                  Text(widget.hotel.description, style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                  SizedBox(height: 20),
                  
                  _buildSectionTitle('TIỆN NGHI'),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: widget.hotel.amenities.split(',').map((a) => Chip(
                      label: Text(a.trim()),
                      backgroundColor: Colors.blue[50],
                      labelStyle: TextStyle(color: Colors.blue[900], fontSize: 13),
                    )).toList(),
                  ),
                  
                  SizedBox(height: 30),
                  _buildSectionTitle('CHỌN THỜI GIAN NGHỈ DƯỠNG'),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 365)));
                      if (picked != null) {
                        setState(() => _selectedDateRange = picked);
                        _loadAvailableRooms();
                      }
                    },
                    icon: Icon(Icons.calendar_month),
                    label: Text(_selectedDateRange == null ? 'Bấm để chọn ngày Nhận & Trả phòng' : 'Đã chọn: ${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue[900], side: BorderSide(color: Colors.blue[900]!), minimumSize: Size(double.infinity, 50)),
                  ),
                  
                  SizedBox(height: 30),
                  _buildSectionTitle('DANH SÁCH PHÒNG'),
                  FutureBuilder<List<Room>>(
                    future: _roomsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                      final rooms = snapshot.data!;
                      if (rooms.isEmpty) return Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)), child: Center(child: Text('Tiếc quá! Không còn phòng trống trong khoảng thời gian này.', style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold))));

                      return ListView.builder(
                        shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(Icons.king_bed, color: Colors.blue[900], size: 30),
                              title: Text('${room.type} - Phòng ${room.roomNumber}', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${room.price.toStringAsFixed(0)}đ / đêm', style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold)),
                              trailing: ElevatedButton(
                                onPressed: room.isAvailable ? () => _showBookingDialog(room) : null,
                                child: Text(room.isAvailable ? 'ĐẶT NGAY' : 'HẾT PHÒNG'),
                                style: ElevatedButton.styleFrom(backgroundColor: room.isAvailable ? Colors.blue[900] : Colors.grey, foregroundColor: Colors.white),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('ĐÁNH GIÁ TỪ KHÁCH HÀNG'),
                      TextButton.icon(onPressed: _showAddReviewDialog, icon: Icon(Icons.rate_review), label: Text('Viết đánh giá')),
                    ],
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _reviewsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                      final reviews = snapshot.data!;
                      if (reviews.isEmpty) return Center(child: Text('Chưa có đánh giá nào cho khách sạn này.'));

                      return ListView.builder(
                        shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final r = reviews[index];
                          final user = r['users'] ?? {};
                          return Card(
                            margin: EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(user['full_name'] ?? 'Khách ẩn danh', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < (r['rating'] ?? 0) ? Colors.orange : Colors.grey))),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Text(r['comment'] ?? '', style: TextStyle(color: Colors.grey[800])),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 50),
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
