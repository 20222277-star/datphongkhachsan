import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'admin_hotel_management_screen.dart';
import 'admin_booking_management_screen.dart';
import 'admin_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = DatabaseHelper.instance.getAdminStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = DatabaseHelper.instance.getAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('ADMIN DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshStats),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              userProvider.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWeb) Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Colors.red[900]),
                  currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, color: Colors.red[900])),
                  accountName: Text('Quản trị viên'),
                  accountEmail: Text(userProvider.user?.email ?? 'admin@hotel.com'),
                ),
                ListTile(
                  leading: Icon(Icons.dashboard),
                  title: Text('Tổng quan'),
                  selected: true,
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.hotel),
                  title: Text('Quản lý Khách sạn'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminHotelManagementScreen())).then((_) => _refreshStats()),
                ),
                ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text('Quản lý Đơn hàng'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminBookingManagementScreen())),
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Cài đặt hệ thống'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminSettingsScreen())),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chào mừng quay lại, Admin!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),
                  
                  FutureBuilder<Map<String, dynamic>>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return LinearProgressIndicator();
                      final stats = snapshot.data!;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: isWeb ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard('KHÁCH SẠN', stats['totalHotels'].toString(), Icons.hotel, Colors.blue),
                          _buildStatCard('ĐƠN HÀNG', stats['totalBookings'].toString(), Icons.receipt, Colors.green),
                          _buildStatCard('DOANH THU', '${stats['totalRevenue'].toStringAsFixed(0)}đ', Icons.monetization_on, Colors.orange),
                          _buildStatCard('NGƯỜI DÙNG', stats['totalUsers'].toString(), Icons.people, Colors.purple),
                        ],
                      );
                    },
                  ),
                  
                  SizedBox(height: 40),
                  Text('Truy cập nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildQuickAction(context, 'Thêm Khách sạn', Icons.add_business, Colors.blue, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminHotelManagementScreen()));
                      }),
                      _buildQuickAction(context, 'Duyệt Đơn hàng', Icons.list_alt, Colors.green, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminBookingManagementScreen()));
                      }),
                      _buildQuickAction(context, 'Cài đặt QR', Icons.qr_code, Colors.orange, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminSettingsScreen()));
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
