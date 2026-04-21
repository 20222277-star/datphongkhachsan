import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class AdminLocationManagementScreen extends StatefulWidget {
  @override
  _AdminLocationManagementScreenState createState() => _AdminLocationManagementScreenState();
}

class _AdminLocationManagementScreenState extends State<AdminLocationManagementScreen> {
  late Future<List<Map<String, dynamic>>> _locationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLocations();
  }

  void _refreshLocations() {
    setState(() {
      _locationsFuture = DatabaseHelper.instance.getLocationsRaw();
    });
  }

  void _showLocationForm({Map<String, dynamic>? location}) {
    final controller = TextEditingController(text: location != null ? location['name'] : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(location == null ? 'Thêm Địa danh mới' : 'Sửa Địa danh'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Tên địa danh (VD: Đà Lạt)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('HỦY')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                if (location == null) {
                  await DatabaseHelper.instance.addLocation(controller.text);
                } else {
                  await DatabaseHelper.instance.updateLocation(location['id'], controller.text);
                }
                Navigator.pop(context);
                _refreshLocations();
              }
            },
            child: Text('LƯU'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QUẢN LÝ ĐỊA DANH'), backgroundColor: Colors.red[900], foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _locationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          final locations = snapshot.data ?? [];
          if (locations.isEmpty) return Center(child: Text('Chưa có địa danh nào. Hãy thêm mới!'));

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final loc = locations[index];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.location_on, color: Colors.red[900]),
                  title: Text(loc['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit, color: Colors.orange), onPressed: () => _showLocationForm(location: loc)),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text('Xác nhận'), content: Text('Xóa địa danh này?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Hủy')), TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Xóa'))]));
                          if (confirm == true) {
                            await DatabaseHelper.instance.deleteLocation(loc['id']);
                            _refreshLocations();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationForm(),
        icon: Icon(Icons.add),
        label: Text('Thêm địa danh'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
    );
  }
}
