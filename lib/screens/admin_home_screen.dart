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
    _refreshStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = DatabaseHelper.instance.getAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isWeb = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('QUẢN TRỊ HỆ THỐNG', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshStats),
          IconButton(icon: Icon(Icons.logout), onPressed: () => userProvider.logout()),
        ],
      ),
      body: Row(
        children: [
          if (isWeb) _buildSidebar(context, userProvider),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TỔNG QUAN HÔM NAY', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 25),
                  
                  // Stats Grid
                  FutureBuilder<Map<String, dynamic>>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return LinearProgressIndicator();
                      final stats = snapshot.data!;
                      return Column(
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: isWeb ? 4 : 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.5,
                            children: [
                              _buildStatCard('KHÁCH SẠN', stats['totalHotels'].toString(), Icons.hotel, Colors.blue),
                              _buildStatCard('ĐƠN HÀNG', stats['totalBookings'].toString(), Icons.receipt, Colors.green),
                              _buildStatCard('DOANH THU', '${stats['totalRevenue'].toStringAsFixed(0)}đ', Icons.monetization_on, Colors.orange),
                              _buildStatCard('NGƯỜI DÙNG', stats['totalUsers'].toString(), Icons.people, Colors.purple),
                            ],
                          ),
                          SizedBox(height: 40),
                          _buildRevenueChart(stats['totalRevenue']), // THÊM BIỂU ĐỒ TRỰC QUAN
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, UserProvider provider) {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.red[900]),
            accountName: Text(provider.user?.fullName ?? 'Admin'),
            accountEmail: Text(provider.user?.email ?? ''),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, color: Colors.red[900], size: 40)),
          ),
          _buildMenuItem(Icons.dashboard, 'Tổng quan', true, () {}),
          _buildMenuItem(Icons.hotel, 'Quản lý Khách sạn', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => AdminHotelManagementScreen())).then((_) => _refreshStats())),
          _buildMenuItem(Icons.receipt_long, 'Duyệt Đơn hàng', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => AdminBookingManagementScreen())).then((_) => _refreshStats())),
          _buildMenuItem(Icons.settings, 'Cài đặt hệ thống', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => AdminSettingsScreen()))),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool selected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.red[900] : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      onTap: onTap,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 35),
          SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // BIỂU ĐỒ DOANH THU TỰ VẼ BẰNG FLUTTER WIDGETS
  Widget _buildRevenueChart(double revenue) {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PHÂN TÍCH DOANH THU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red[900])),
          SizedBox(height: 30),
          Container(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBar('T2', 0.3),
                _buildBar('T3', 0.5),
                _buildBar('T4', 0.2),
                _buildBar('T5', 0.8),
                _buildBar('T6', 0.6),
                _buildBar('T7', 1.0, isToday: true), // Cột cao nhất giả định cho hôm nay
                _buildBar('CN', 0.4),
              ],
            ),
          ),
          SizedBox(height: 10),
          Center(child: Text('Biểu đồ tăng trưởng doanh thu theo tuần', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor, {bool isToday = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 35,
          height: 150 * heightFactor,
          decoration: BoxDecoration(
            color: isToday ? Colors.orange : Colors.red[900]!.withOpacity(0.3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
        SizedBox(height: 8),
        Text(day, style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
