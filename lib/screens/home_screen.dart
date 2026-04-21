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
  late Future<List<String>> _locationsFuture;
  List<Hotel> _allHotels = [];
  List<Hotel> _filteredHotels = [];
  List<int> _favoriteIds = [];
  
  bool _showOnlyFavorites = false;
  String _searchQuery = '';
  String _selectedCity = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadData();
    _locationsFuture = DatabaseHelper.instance.getLocations();
  }

  void _loadData() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _hotelsFuture = DatabaseHelper.instance.getAllHotels();
    _allHotels = await _hotelsFuture;
    if (user != null) {
      _favoriteIds = await DatabaseHelper.instance.getUserFavorites(user.id!);
    }
    if (mounted) _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredHotels = _allHotels.where((h) {
        final matchesSearch = h.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesFavorite = !_showOnlyFavorites || _favoriteIds.contains(h.id);
        final matchesCity = _selectedCity == 'Tất cả' || h.location.trim().toLowerCase() == _selectedCity.trim().toLowerCase();
        return matchesSearch && matchesFavorite && matchesCity;
      }).toList();
    });
  }

  void _toggleFavorite(int hotelId) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng đăng nhập để yêu thích')));
      return;
    }

    bool isCurrentlyFav = _favoriteIds.contains(hotelId);
    await DatabaseHelper.instance.toggleFavorite(user.id!, hotelId, !isCurrentlyFav);
    
    setState(() {
      if (isCurrentlyFav) _favoriteIds.remove(hotelId);
      else _favoriteIds.add(hotelId);
      _applyFilters();
    });
  }

  Widget _buildMenuContent(bool isDrawer) {
    return Column(
      children: [
        if (isDrawer) DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue[900]),
          child: Center(child: Text('VN-BOOKING', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
        ),
        SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.explore, color: (!_showOnlyFavorites && _selectedCity == 'Tất cả') ? Colors.blue[900] : Colors.grey),
          title: Text('Khám phá', style: TextStyle(fontWeight: (!_showOnlyFavorites && _selectedCity == 'Tất cả') ? FontWeight.bold : FontWeight.normal)),
          onTap: () {
            setState(() { 
              _showOnlyFavorites = false; 
              _selectedCity = 'Tất cả';
              _applyFilters(); 
            });
            if (isDrawer) Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.favorite, color: _showOnlyFavorites ? Colors.red : Colors.grey),
          title: Text('Yêu thích của tôi', style: TextStyle(fontWeight: _showOnlyFavorites ? FontWeight.bold : FontWeight.normal)),
          onTap: () {
            setState(() { _showOnlyFavorites = true; _applyFilters(); });
            if (isDrawer) Navigator.pop(context);
          },
        ),
        Divider(),

        // CẬP NHẬT: BIẾN ĐỊA ĐIỂM THÀNH DANH SÁCH ĐÓNG MỞ (ExpansionTile)
        FutureBuilder<List<String>>(
          future: _locationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator());
            final cities = snapshot.data ?? [];
            
            return ExpansionTile(
              initiallyExpanded: true, // Mặc định mở ra
              leading: Icon(Icons.location_city, color: Colors.blue[900]),
              title: Text('ĐỊA ĐIỂM GỢI Ý', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700])),
              children: cities.map((city) {
                final isSelected = _selectedCity == city;
                return ListTile(
                  contentPadding: EdgeInsets.only(left: 32), // Đẩy lùi vào trong để phân biệt với mục chính
                  selected: isSelected,
                  selectedTileColor: Colors.blue[50],
                  leading: Icon(Icons.location_on, color: isSelected ? Colors.red : Colors.grey, size: 16),
                  title: Text(city, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blue[900] : Colors.black87)),
                  onTap: () {
                    setState(() {
                      _selectedCity = city;
                      _showOnlyFavorites = false;
                      _applyFilters();
                    });
                    if (isDrawer) Navigator.pop(context);
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('VN-BOOKING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        leading: isWeb ? null : Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SearchScreen())),
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
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
            },
          ),
        ],
      ),
      drawer: isWeb ? null : Drawer(
        child: _buildMenuContent(true),
      ),
      body: Row(
        children: [
          if (isWeb) Container(
            width: 250,
            color: Colors.grey[50],
            child: _buildMenuContent(false),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBanner(screenWidth),
                  
                  Padding(
                    padding: EdgeInsets.all(screenWidth > 600 ? 40.0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          _showOnlyFavorites 
                            ? 'DANH SÁCH YÊU THÍCH' 
                            : (_selectedCity == 'Tất cả' ? 'KHÁCH SẠN NỔI BẬT' : 'KHÁCH SẠN TẠI $_selectedCity')
                        ),
                        SizedBox(height: 25),
                        _filteredHotels.isEmpty 
                          ? Center(child: Padding(
                              padding: const EdgeInsets.all(50.0),
                              child: Column(
                                children: [
                                  Icon(Icons.hotel_class, size: 60, color: Colors.grey[300]),
                                  SizedBox(height: 10),
                                  Text('Không tìm thấy khách sạn nào phù hợp.', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: screenWidth > 1400 ? 5 : (screenWidth > 1100 ? 4 : (screenWidth > 700 ? 2 : 1)), 
                                crossAxisSpacing: 20, 
                                mainAxisSpacing: 20, 
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _filteredHotels.length,
                              itemBuilder: (context, index) => _buildHotelCard(_filteredHotels[index]),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyBookingsScreen())),
        label: Text('Đơn đặt phòng'),
        icon: Icon(Icons.list_alt),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildNetworkImage(String url, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    return Image.network(
      url, height: height, width: width, fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(child: child, opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(height: height, width: width, color: Colors.grey[100], child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
      },
      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: Icon(Icons.hotel, color: Colors.grey[400])),
    );
  }

  Widget _buildBanner(double screenWidth) {
    return Container(
      height: 250, width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[800],
        image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1445013544686-8301b8918cb4?w=1200'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Bạn muốn đi đâu?', style: TextStyle(color: Colors.white, fontSize: screenWidth > 600 ? 32 : 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SearchScreen())),
            child: Container(
              width: screenWidth * 0.9, constraints: BoxConstraints(maxWidth: 600),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.blue[900]),
                  SizedBox(width: 15),
                  Expanded(child: Text('Tìm khách sạn, thành phố, ngày ở...', style: TextStyle(color: Colors.grey[600], fontSize: 14), overflow: TextOverflow.ellipsis)),
                  Container(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(25)), child: Text('TÌM KIẾM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900]));
  }

  Widget _buildHotelCard(Hotel hotel) {
    bool isFav = _favoriteIds.contains(hotel.id);
    return Card(
      elevation: 2, clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => HotelDetailScreen(hotel: hotel))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: Stack(children: [Positioned.fill(child: _buildNetworkImage(hotel.imageUrl)), Positioned(right: 5, top: 5, child: Material(color: Colors.white.withOpacity(0.9), shape: CircleBorder(), child: IconButton(constraints: BoxConstraints(maxWidth: 35, maxHeight: 35), icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey, size: 18), onPressed: () => _toggleFavorite(hotel.id!))))])),
            Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(10.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(hotel.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), SizedBox(height: 4), Row(children: [...List.generate(5, (i) => Icon(Icons.star, color: i < hotel.stars ? Colors.orange : Colors.grey[300], size: 12)), SizedBox(width: 4), Text('${hotel.stars}.0', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])]), Row(children: [Icon(Icons.location_on, color: Colors.redAccent, size: 12), SizedBox(width: 4), Expanded(child: Text(hotel.location, style: TextStyle(color: Colors.grey[600], fontSize: 11), overflow: TextOverflow.ellipsis))]), Text('Xem chi tiết →', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 11))]))),
          ],
        ),
      ),
    );
  }
}
