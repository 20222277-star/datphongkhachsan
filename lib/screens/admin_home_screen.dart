import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'admin_hotel_management_screen.dart';
import 'admin_booking_management_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_location_management_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('QUẢN TRỊ HỆ THỐNG', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        leading: isWeb ? null : IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () {
            print("DEBUG: Refreshing stats...");
            _refreshStats();
          }),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              print("DEBUG: Logging out...");
              userProvider.logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => LoginScreen()), (r) => false);
            },
          ),
        ],
      ),
      drawer: isWeb ? null : Drawer(child: _buildSidebarContent(userProvider, false)),
      body: Row(
        children: [
          if (isWeb) Container(
            width: 260,
            color: Colors.white,
            child: _buildSidebarContent(userProvider, true),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth > 600 ? 30 : 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TỔNG QUAN HỆ THỐNG', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  
                  FutureBuilder<Map<String, dynamic>>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      
                      if (snapshot.hasError) {
                        print("DEBUG: FutureBuilder error: ${snapshot.error}");
                        return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
                      }

                      final stats = snapshot.data ?? {'totalHotels': 0, 'totalBookings': 0, 'totalRevenue': 0, 'totalUsers': 0};
                      
                      return Column(
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: screenWidth > 1200 ? 4 : (screenWidth > 600 ? 2 : 1),
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.6,
                            children: [
                              _buildStatCard('KHÁCH SẠN', stats['totalHotels'].toString(), Icons.hotel, Colors.blue),
                              _buildStatCard('ĐƠN HÀNG', stats['totalBookings'].toString(), Icons.receipt, Colors.green),
                              _buildStatCard('DOANH THU', '${(stats['totalRevenue'] as num).toStringAsFixed(0)}đ', Icons.monetization_on, Colors.orange),
                              _buildStatCard('NGƯỜI DÙNG', stats['totalUsers'].toString(), Icons.people, Colors.purple),
                            ],
                          ),
                          SizedBox(height: 30),
                          _buildRevenueChart(),
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

  Widget _buildSidebarContent(UserProvider provider, bool isSidebar) {
    return Column(
      children: [
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(color: Colors.red[900]),
          accountName: Text(provider.user?.fullName ?? 'Admin'),
          accountEmail: Text(provider.user?.email ?? 'admin@hotel.com'),
          currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, color: Colors.red[900], size: 35)),
        ),
        _buildMenuItem(Icons.dashboard, 'Tổng quan', true, () {
          print("DEBUG: Tab Tổng quan clicked");
          if (!isSidebar) Navigator.pop(context);
        }),
        _buildMenuItem(Icons.hotel, 'Quản lý Khách sạn', false, () {
          print("DEBUG: Tab Quản lý Khách sạn clicked");
          try {
            if (!isSidebar) Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (c) => AdminHotelManagementScreen()))
              .then((_) => _refreshStats());
          } catch (e) {
            print("DEBUG: Error navigating to Hotel Management: $e");
          }
        }),
        _buildMenuItem(Icons.location_on, 'Quản lý Địa danh', false, () {
          print("DEBUG: Tab Quản lý Địa danh clicked");
          try {
            if (!isSidebar) Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (c) => AdminLocationManagementScreen()));
          } catch (e) {
            print("DEBUG: Error navigating to Location Management: $e");
          }
        }),
        _buildMenuItem(Icons.receipt_long, 'Duyệt Đơn hàng', false, () {
          print("DEBUG: Tab Duyệt Đơn hàng clicked");
          try {
            if (!isSidebar) Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (c) => AdminBookingManagementScreen()))
              .then((_) => _refreshStats());
          } catch (e) {
            print("DEBUG: Error navigating to Booking Management: $e");
          }
        }),
        _buildMenuItem(Icons.settings, 'Cài đặt hệ thống', false, () {
          print("DEBUG: Tab Cài đặt hệ thống clicked");
          try {
            if (!isSidebar) Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (c) => AdminSettingsScreen()));
          } catch (e) {
            print("DEBUG: Error navigating to Settings: $e");
          }
        }),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool selected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.red[900] : Colors.grey[700]),
      title: Text(title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      onTap: () {
        print("DEBUG: ListTile '$title' tapped");
        onTap();
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      padding: EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PHÂN TÍCH DOANH THU TUẦN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red[900])),
          SizedBox(height: 30),
          Container(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBar('T2', 0.4), _buildBar('T3', 0.6), _buildBar('T4', 0.3),
                _buildBar('T5', 0.8), _buildBar('T6', 0.5), _buildBar('T7', 1.0, isToday: true),
                _buildBar('CN', 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor, {bool isToday = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 25, height: 130 * heightFactor,
          decoration: BoxDecoration(color: isToday ? Colors.orange : Colors.red[900]!.withOpacity(0.2), borderRadius: BorderRadius.vertical(top: Radius.circular(4))),
        ),
        SizedBox(height: 5),
        Text(day, style: TextStyle(fontSize: 10, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
