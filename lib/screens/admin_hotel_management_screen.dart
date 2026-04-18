import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
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
          final bytes = reader.result as Uint8List;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          showDialog(context: context, barrierDismissible: false, builder: (context) => Center(child: CircularProgressIndicator()));
          final url = await DatabaseHelper.instance.uploadImage(bytes, fileName);
          Navigator.pop(context);
          if (url != null) { onUploaded(url); }
        });
        reader.readAsArrayBuffer(file);
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
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentImageUrl.isNotEmpty) Image.network(currentImageUrl, height: 100, fit: BoxFit.cover),
                  ElevatedButton.icon(
                    onPressed: () => _pickAndUploadImage((url) => setDialogState(() => currentImageUrl = url)),
                    icon: Icon(Icons.image), label: Text('Chọn ảnh đại diện'),
                  ),
                  TextField(controller: nameController, decoration: InputDecoration(labelText: 'Tên khách sạn')),
                  TextField(controller: locationController, decoration: InputDecoration(labelText: 'Địa điểm')),
                  TextField(controller: descController, maxLines: 2, decoration: InputDecoration(labelText: 'Mô tả')),
                  TextField(controller: amenitiesController, decoration: InputDecoration(labelText: 'Tiện nghi')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('HỦY')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newHotel = Hotel(id: hotel?.id, name: nameController.text, location: locationController.text, description: descController.text, amenities: amenitiesController.text, imageUrl: currentImageUrl, gallery: currentGallery);
                  if (hotel == null) await DatabaseHelper.instance.addHotel(newHotel);
                  else await DatabaseHelper.instance.updateHotel(newHotel);
                  Navigator.pop(context);
                  _loadHotels();
                }
              },
              child: Text(hotel == null ? 'THÊM' : 'CẬP NHẬT'),
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
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final hotels = snapshot.data!;
          return ListView.builder(
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final hotel = hotels[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: hotel.imageUrl.isNotEmpty ? Image.network(hotel.imageUrl, width: 50, fit: BoxFit.cover) : Icon(Icons.hotel),
                  title: Text(hotel.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(hotel.location),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.meeting_room, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => AdminRoomManagementScreen(hotel: hotel)))),
                      IconButton(icon: Icon(Icons.edit, color: Colors.orange), onPressed: () => _showHotelForm(hotel: hotel)),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () async {
                        await DatabaseHelper.instance.deleteHotel(hotel.id!);
                        _loadHotels();
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showHotelForm(), child: Icon(Icons.add)),
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
