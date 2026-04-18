import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../models/hotel.dart';
import '../providers/user_provider.dart';
import 'hotel_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Hotel>> _hotelsFuture;
  String _searchQuery = '';
  String _selectedCity = 'Tất cả';
  final List<String> _cities = ['Tất cả', 'Vũng Tàu', 'Đà Lạt', 'Đà Nẵng', 'Hà Nội', 'Phú Quốc', 'Sapa', 'Nha Trang'];

  @override
  void initState() {
    super.initState();
    _hotelsFuture = DatabaseHelper.instance.getAllHotels();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('VN-BOOKING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (user != null) Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen())),
              icon: Icon(Icons.person, color: Colors.white),
              label: Text(user.fullName ?? user.username, style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white30)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              userProvider.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner tìm kiếm
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            color: Colors.blue[900],
            child: Column(
              children: [
                Text('Tìm địa điểm nghỉ dưỡng tiếp theo', 
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Container(
                  constraints: BoxConstraints(maxWidth: 800),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Nhập tên khách sạn...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          
          // Thanh chọn địa điểm nhanh
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10),
              itemCount: _cities.length,
              itemBuilder: (context, index) {
                final city = _cities[index];
                final isSelected = _selectedCity == city;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: ChoiceChip(
                    label: Text(city),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCity = city);
                    },
                    selectedColor: Colors.blue[900],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Hotel>>(
              future: _hotelsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                
                final filteredHotels = snapshot.data!.where((h) {
                  final matchesSearch = h.name.toLowerCase().contains(_searchQuery);
                  final matchesCity = _selectedCity == 'Tất cả' || h.location == _selectedCity;
                  return matchesSearch && matchesCity;
                }).toList();

                return GridView.builder(
                  padding: EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWeb ? 3 : 1,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: filteredHotels.length,
                  itemBuilder: (context, index) {
                    final hotel = filteredHotels[index];
                    return _buildHotelCard(hotel);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyBookingsScreen())),
        label: Text('Đơn của tôi'),
        icon: Icon(Icons.list_alt),
        backgroundColor: Colors.blue[900],
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HotelDetailScreen(hotel: hotel))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                hotel.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (c, e, s) => Container(color: Colors.grey, child: Icon(Icons.hotel, size: 50)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotel.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(hotel.location, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(hotel.amenities, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Giá từ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('600.000đ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[900])),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(8)),
                        child: Text('Xem phòng', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
