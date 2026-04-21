import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../models/hotel.dart';
import '../providers/user_provider.dart';
import 'hotel_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Hotel>> _hotelsFuture;

  @override
  void initState() {
    super.initState();
    _hotelsFuture = DatabaseHelper.instance.getAllHotels();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('VN-BOOKING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.search, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SearchScreen())),
            tooltip: 'Tìm kiếm phòng',
          ),
          if (user != null && screenWidth > 700) TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProfileScreen())),
            icon: Icon(Icons.person, color: Colors.white),
            label: Text(user.fullName ?? user.username, style: TextStyle(color: Colors.white)),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[800],
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1445013544686-8301b8918cb4?w=1200'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bạn muốn đi đâu?', 
                    style: TextStyle(color: Colors.white, fontSize: screenWidth > 600 ? 36 : 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 30),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SearchScreen())),
                    child: Container(
                      width: screenWidth * 0.9,
                      constraints: BoxConstraints(maxWidth: 700),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.blue[900]),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              'Nhấn để tìm theo Thành phố, Số sao, Ngày ở...', 
                              style: TextStyle(color: Colors.grey[600], fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(25)),
                            child: Text('TÌM KIẾM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(screenWidth > 600 ? 40.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('ĐỊA ĐIỂM NỔI BẬT'),
                  SizedBox(height: 20),
                  Container(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCityCard('Vũng Tàu', 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400'),
                        _buildCityCard('Đà Lạt', 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400'),
                        _buildCityCard('Đà Nẵng', 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400'),
                        _buildCityCard('Sapa', 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=400'),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 50),
                  _buildSectionHeader('GỢI Ý CHO BẠN (Đặt nhiều nhất)'),
                  SizedBox(height: 20),
                  FutureBuilder<List<Hotel>>(
                    future: _hotelsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                      final hotels = snapshot.data!.take(4).toList();
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth > 1200 ? 4 : (screenWidth > 600 ? 2 : 1), 
                          crossAxisSpacing: 20, 
                          mainAxisSpacing: 20, 
                          childAspectRatio: 0.8
                        ),
                        itemCount: hotels.length,
                        itemBuilder: (context, index) => _buildHotelCard(hotels[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyBookingsScreen())),
        label: Text('Đơn đặt phòng'),
        icon: Icon(Icons.list_alt),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white, // SỬA MÀU CHỮ Ở ĐÂY
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900]));
  }

  Widget _buildCityCard(String name, String url) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SearchScreen())),
      child: Container(
        width: 220,
        margin: EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.black38),
          child: Center(child: Text(name, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return Card(
      elevation: 5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => HotelDetailScreen(hotel: hotel))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                hotel.imageUrl, fit: BoxFit.cover, width: double.infinity,
                errorBuilder: (c,e,s) => Container(color: Colors.grey[200], child: Icon(Icons.hotel, size: 50, color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotel.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(Icons.star, color: i < hotel.stars ? Colors.orange : Colors.grey[300], size: 14)),
                      Spacer(),
                      Icon(Icons.location_on, color: Colors.red, size: 14),
                      Text(' ${hotel.location}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
