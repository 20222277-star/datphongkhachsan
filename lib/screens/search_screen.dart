import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/hotel.dart';
import 'hotel_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Hotel> _results = [];
  bool _isLoading = false;
  
  String _selectedCity = 'Tất cả';
  int _selectedStars = 0;
  DateTimeRange? _dateRange;
  
  final List<String> _cities = ['Tất cả', 'Vũng Tàu', 'Đà Lạt', 'Đà Nẵng', 'Hà Nội', 'Phú Quốc', 'Sapa', 'Nha Trang'];

  void _performSearch() async {
    setState(() => _isLoading = true);
    
    List<Hotel> hotels;
    if (_dateRange != null) {
      // Gọi hàm lọc theo ngày thông minh (Yêu cầu của thầy)
      hotels = await DatabaseHelper.instance.getAvailableHotels(_dateRange!);
    } else {
      // Nếu chưa chọn ngày, lấy tất cả
      hotels = await DatabaseHelper.instance.getAllHotels();
    }
    
    setState(() {
      _results = hotels.where((h) {
        final matchesCity = _selectedCity == 'Tất cả' || h.location == _selectedCity;
        final matchesStars = _selectedStars == 0 || h.stars == _selectedStars;
        return matchesCity && matchesStars;
      }).toList();
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tìm kiếm phòng trống'), 
        backgroundColor: Colors.blue[900], 
        foregroundColor: Colors.white,
        actions: [
          if (isMobile) Builder(builder: (c) => IconButton(icon: Icon(Icons.filter_list), onPressed: () => Scaffold.of(c).openEndDrawer()))
        ],
      ),
      endDrawer: isMobile ? Drawer(child: _buildFilterSidebar()) : null,
      body: Row(
        children: [
          if (!isMobile) Container(
            width: 280,
            decoration: BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Colors.grey[200]!))),
            child: _buildFilterSidebar(),
          ),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator())
              : _results.isEmpty 
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hotel_class, size: 80, color: Colors.grey[300]),
                      SizedBox(height: 10),
                      Text('Không tìm thấy khách sạn nào còn phòng trống.', style: TextStyle(color: Colors.grey)),
                    ],
                  ))
                : GridView.builder(
                    padding: EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth > 1200 ? 3 : (screenWidth > 600 ? 2 : 1),
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, index) => _buildResultCard(_results[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSidebar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 30),
          Text('BỘ LỌC TÌM KIẾM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 16)),
          Divider(),
          _buildFilterLabel('Điểm đến'),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
            items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) => setState(() { _selectedCity = v!; _performSearch(); }),
          ),
          _buildFilterLabel('Xếp hạng sao'),
          Row(
            children: List.generate(5, (index) => IconButton(
              icon: Icon(index < _selectedStars ? Icons.star : Icons.star_border, color: Colors.orange, size: 24),
              onPressed: () => setState(() { _selectedStars = index + 1; _performSearch(); }),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            )),
          ),
          _buildFilterLabel('Ngày nhận/trả phòng'),
          ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 365)));
              if (picked != null) setState(() { _dateRange = picked; _performSearch(); });
            },
            icon: Icon(Icons.date_range),
            label: Text(_dateRange == null ? 'Chọn ngày' : 'Đã chọn'),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: _dateRange == null ? Colors.grey[100] : Colors.blue[50], foregroundColor: Colors.blue[900]),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: () => setState(() { _selectedCity = 'Tất cả'; _selectedStars = 0; _dateRange = null; _performSearch(); }),
            child: Text('XÓA TẤT CẢ LỌC'),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.red[50], foregroundColor: Colors.red),
          )
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Padding(padding: const EdgeInsets.only(top: 25, bottom: 8), child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));
  }

  Widget _buildResultCard(Hotel hotel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => HotelDetailScreen(hotel: hotel))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Image.network(hotel.imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,e,s) => Icon(Icons.hotel, size: 50))),
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
                      Text(' ${hotel.location}', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('Xem phòng trống ➔', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
