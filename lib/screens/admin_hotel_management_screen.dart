import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/hotel.dart';
import '../models/room.dart';

class AdminHotelManagementScreen extends StatefulWidget {
  @override
  _AdminHotelManagementScreenState createState() => _AdminHotelManagementScreenState();
}

class _AdminHotelManagementScreenState extends State<AdminHotelManagementScreen> {
  late Future<List<Hotel>> _hotelsFuture;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  void _loadHotels() {
    setState(() {
      _hotelsFuture = DatabaseHelper.instance.getAllHotels();
    });
  }

  // HÀM NÉN ẢNH CHUYÊN NGHIỆP TRÊN WEB
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final Completer<Uint8List> completer = Completer();
    
    // Sử dụng HTML5 Canvas để nén ảnh (Tối ưu cho Web)
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final img = html.ImageElement();
    img.src = url;
    
    img.onLoad.listen((_) {
      final canvas = html.CanvasElement();
      final ctx = canvas.context2D;
      
      // Giới hạn kích thước tối đa 1200px để ảnh vẫn nét mà dung lượng cực nhẹ
      double maxWidth = 1200;
      double width = img.width!.toDouble();
      double height = img.height!.toDouble();
      
      if (width > maxWidth) {
        height = (maxWidth / width) * height;
        width = maxWidth;
      }
      
      canvas.width = width.toInt();
      canvas.height = height.toInt();
      ctx.drawImageScaled(img, 0, 0, canvas.width!, canvas.height!);
      
      // Xuất ra JPEG với chất lượng 0.7 (Nén 70% - Rất tối ưu)
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.7);
      final base64String = dataUrl.split(',')[1];
      completer.complete(base64Decode(base64String));
      html.Url.revokeObjectUrl(url);
    });
    
    return completer.future;
  }

  void _pickAndUploadImage(Function(String) onUploaded) {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files!.length == 1) {
        final file = files[0];
        final reader = html.FileReader();
        reader.onLoadEnd.listen((e) async {
          final rawBytes = reader.result as Uint8List;
          
          showDialog(context: context, barrierDismissible: false, builder: (context) => Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 10), Text("Đang nén và tải ảnh lên...", style: TextStyle(color: Colors.white))],
          )));

          // NÉN ẢNH TRƯỚC KHI TẢI LÊN
          final compressedBytes = await _compressImage(rawBytes);
          final fileName = 'hotel_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          final url = await DatabaseHelper.instance.uploadImage(compressedBytes, fileName);
          Navigator.pop(context); // Tắt loading
          
          if (url != null) { onUploaded(url); }
        });
        reader.readAsArrayBuffer(file);
      }
    });
  }

  void _pickMultipleImages(Function(List<String>) onUploaded) {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.multiple = true;
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        showDialog(context: context, barrierDismissible: false, builder: (context) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 10), Text("Đang nén và tải lên ${files.length} ảnh...", style: TextStyle(color: Colors.white))],
        )));

        List<String> uploadedUrls = [];
        for (var file in files) {
          final reader = html.FileReader();
          final completer = Completer<Uint8List>();
          reader.onLoadEnd.listen((e) => completer.complete(reader.result as Uint8List));
          reader.readAsArrayBuffer(file);
          
          final rawBytes = await completer.future;
          // NÉN TỪNG ẢNH TRONG GALLERY
          final compressedBytes = await _compressImage(rawBytes);
          final fileName = 'gallery_${DateTime.now().microsecondsSinceEpoch}.jpg';
          
          final url = await DatabaseHelper.instance.uploadImage(compressedBytes, fileName);
          if (url != null) uploadedUrls.add(url);
        }

        Navigator.pop(context);
        if (uploadedUrls.isNotEmpty) onUploaded(uploadedUrls);
      }
    });
  }

  void _showHotelForm({Hotel? hotel}) {
    final nameController = TextEditingController(text: hotel?.name);
    final locationController = TextEditingController(text: hotel?.location);
    final descController = TextEditingController(text: hotel?.description);
    final amenitiesController = TextEditingController(text: hotel?.amenities);
    String currentImageUrl = hotel?.imageUrl ?? '';
    List<String> currentGallery = List.from(hotel?.gallery ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(hotel == null ? 'Thêm Khách sạn mới' : 'Sửa Khách sạn'),
          content: SingleChildScrollView(
            child: Container(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ảnh đại diện', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity, height: 150,
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[400]!)),
                          child: currentImageUrl.isNotEmpty 
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(currentImageUrl, fit: BoxFit.cover))
                            : Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                        ),
                        Positioned(
                          bottom: 5, right: 5,
                          child: FloatingActionButton.small(
                            onPressed: () => _pickAndUploadImage((url) => setDialogState(() => currentImageUrl = url)),
                            child: Icon(Icons.edit),
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bộ sưu tập ảnh (${currentGallery.length})', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () => _pickMultipleImages((urls) => setDialogState(() => currentGallery.addAll(urls))),
                        icon: Icon(Icons.add_photo_alternate),
                        label: Text('Thêm ảnh'),
                      ),
                    ],
                  ),
                  Container(
                    height: 100,
                    child: currentGallery.isEmpty 
                      ? Center(child: Text('Chưa có ảnh gallery', style: TextStyle(fontSize: 12, color: Colors.grey)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: currentGallery.length,
                          itemBuilder: (context, i) => Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 8),
                                width: 100, height: 100,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
                                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(currentGallery[i], fit: BoxFit.cover)),
                              ),
                              Positioned(
                                top: 0, right: 8,
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => currentGallery.removeAt(i)),
                                  child: Container(color: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 20)),
                                ),
                              )
                            ],
                          ),
                        ),
                  ),

                  Divider(height: 30),
                  TextField(controller: nameController, decoration: InputDecoration(labelText: 'Tên khách sạn', border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  TextField(controller: locationController, decoration: InputDecoration(labelText: 'Địa điểm', border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  TextField(controller: descController, maxLines: 3, decoration: InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  TextField(controller: amenitiesController, decoration: InputDecoration(labelText: 'Tiện nghi (Wifi, Hồ bơi,...)', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('HỦY')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newHotel = Hotel(
                    id: hotel?.id, 
                    name: nameController.text, 
                    location: locationController.text, 
                    description: descController.text, 
                    amenities: amenitiesController.text, 
                    imageUrl: currentImageUrl, 
                    gallery: currentGallery
                  );
                  if (hotel == null) await DatabaseHelper.instance.addHotel(newHotel);
                  else await DatabaseHelper.instance.updateHotel(newHotel);
                  Navigator.pop(context);
                  _loadHotels();
                }
              },
              child: Text(hotel == null ? 'THÊM MỚI' : 'CẬP NHẬT'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý Khách sạn'), backgroundColor: Colors.red[900], foregroundColor: Colors.white),
      body: FutureBuilder<List<Hotel>>(
        future: _hotelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('Chưa có khách sạn nào.'));
          
          final hotels = snapshot.data!;
          return ListView.builder(
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final hotel = hotels[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: NetworkImage(hotel.imageUrl.isNotEmpty ? hotel.imageUrl : 'https://via.placeholder.com/80'), fit: BoxFit.cover)),
                  ),
                  title: Text(hotel.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hotel.location, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${hotel.gallery.length} ảnh trong bộ sưu tập', style: TextStyle(fontSize: 12, color: Colors.blue[800])),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.meeting_room, color: Colors.blue), tooltip: 'Quản lý phòng', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => AdminRoomManagementScreen(hotel: hotel)))),
                      IconButton(icon: Icon(Icons.edit, color: Colors.orange), tooltip: 'Sửa', onPressed: () => _showHotelForm(hotel: hotel)),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), tooltip: 'Xóa', onPressed: () async {
                        final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text('Xác nhận'), content: Text('Xóa khách sạn này?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Hủy')), TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Xóa', style: TextStyle(color: Colors.red)))]));
                        if (confirm == true) {
                          await DatabaseHelper.instance.deleteHotel(hotel.id!);
                          _loadHotels();
                        }
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHotelForm(), 
        icon: Icon(Icons.add), 
        label: Text('Thêm khách sạn'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
    );
  }
}

class AdminRoomManagementScreen extends StatefulWidget {
  final Hotel hotel;
  AdminRoomManagementScreen({required this.hotel});
  @override
  _AdminRoomManagementScreenState createState() => _AdminRoomManagementScreenState();
}

class _AdminRoomManagementScreenState extends State<AdminRoomManagementScreen> {
  late Future<List<Room>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    setState(() { _roomsFuture = DatabaseHelper.instance.getRoomsByHotel(widget.hotel.id!); });
  }

  void _showAddRoomDialog() {
    final numController = TextEditingController();
    final typeController = TextEditingController(text: 'Tiêu chuẩn');
    final priceController = TextEditingController(text: '500000');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm phòng mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numController, decoration: InputDecoration(labelText: 'Số phòng')),
            TextField(controller: typeController, decoration: InputDecoration(labelText: 'Loại phòng')),
            TextField(controller: priceController, decoration: InputDecoration(labelText: 'Giá tiền'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('HỦY')),
          ElevatedButton(onPressed: () async {
            await DatabaseHelper.instance.addRoom(Room(hotelId: widget.hotel.id!, roomNumber: numController.text, type: typeController.text, price: double.parse(priceController.text)));
            Navigator.pop(context);
            _loadRooms();
          }, child: Text('THÊM')),
        ],
      ),
    );
  }

  void _toggleRoomStatus(Room room) async {
    String nextStatus = room.isAvailable ? 'Maintenance' : 'Available';
    await DatabaseHelper.instance.updateRoomStatus(room.id!, nextStatus);
    _loadRooms();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật trạng thái phòng ${room.roomNumber}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý phòng: ${widget.hotel.name}'), backgroundColor: Colors.red[900], foregroundColor: Colors.white),
      body: FutureBuilder<List<Room>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final rooms = snapshot.data!;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.bed, color: room.isAvailable ? Colors.green : Colors.red),
                  title: Text('Phòng ${room.roomNumber} (${room.type})'),
                  subtitle: Text('${room.price.toStringAsFixed(0)}đ'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _toggleRoomStatus(room),
                        style: ElevatedButton.styleFrom(backgroundColor: room.isAvailable ? Colors.blue : Colors.orange),
                        child: Text(room.isAvailable ? 'ĐÓNG (SỬA)' : 'MỞ (TRỐNG)'),
                      ),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () async {
                        await DatabaseHelper.instance.deleteRoom(room.id!);
                        _loadRooms();
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddRoomDialog, child: Icon(Icons.add)),
    );
  }
}
