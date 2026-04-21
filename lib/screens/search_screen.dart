import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/hotel.dart';
import '../models/room.dart';
import 'hotel_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCity;

  SearchScreen({this.initialCity});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Hotel> _results = [];
  bool _isLoading = false;
  
  late String _selectedCity;
  int _selectedStars = 0;
  DateTimeRange? _dateRange;
  
  // BIẾN LỌC GIÁ MỚI
  String _priceFilter = 'Tất cả'; 
  final List<String> _priceOptions = ['Tất cả', 'Dưới 500k', '500k - 1tr', '1tr - 2tr', 'Trên 2tr'];

  final List<String> _cities = ['Tất cả', 'Vũng Tàu', 'Đà Lạt', 'Đà Nẵng', 'Hà Nội', 'Phú Quốc', 'Sapa', 'Nha Trang', 'TP.HCM'];

  void _performSearch() async {
    setState(() => _isLoading = true);
    
    List<Hotel> hotels;
    if (_dateRange != null) {
      hotels = await DatabaseHelper.instance.getAvailableHotels(_dateRange!);
    } else {
      hotels = await DatabaseHelper.instance.getAllHotels();
    }
    
    List<Hotel> finalFiltered = [];
    
    for (var h in hotels) {
      final matchesCity = _selectedCity == 'Tất cả' || h.location.trim().toLowerCase() == _selectedCity.trim().toLowerCase();
      final matchesStars = _selectedStars == 0 || h.stars == _selectedStars;
      
      if (matchesCity && matchesStars) {
        final rooms = await DatabaseHelper.instance.getRoomsByHotel(h.id!);
        
        bool hasRoomInPriceRange = false;
        if (_priceFilter == 'Tất cả') {
          hasRoomInPriceRange = true;
        } else {
          for (var r in rooms) {
            if (_priceFilter == 'Dưới 500k' && r.price < 500000) hasRoomInPriceRange = true;
            else if (_priceFilter == '500k - 1tr' && r.price >= 500000 && r.price <= 1000000) hasRoomInPriceRange = true;
            else if (_priceFilter == '1tr - 2tr' && r.price > 1000000 && r.price <= 2000000) hasRoomInPriceRange = true;
            else if (_priceFilter == 'Trên 2tr' && r.price > 2000000) hasRoomInPriceRange = true;
          }
        }
        
        if (hasRoomInPriceRange || rooms.isEmpty) {
          finalFiltered.add(h);
        }
      }
    }
    
    setState(() {
      _results = finalFiltered;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity ?? 'Tất cả';
    _performSearch();
  }

  Widget _buildNetworkImage(String url, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    return Image.network(
      url, height: height, width: width, fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(child: child, opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 500));
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(height: height, width: width, color: Colors.grey[100], child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
      },
      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: Icon(Icons.hotel, color: Colors.grey[400])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tìm kiếm nâng cao'), 
        backgroundColor: Colors.blue[900], 
        foregroundColor: Colors.white,
        actions: [
          if (isMobile) Builder(builder: (c) => IconButton(icon: Icon(Icons.filter_list), onPressed: () => Scaffold.of(c).openEndDrawer()))
        ],
      ),
      endDrawer: isMobile ? Drawer(child: SingleChildScrollView(child: _buildFilterSidebar())) : null,
      body: Row(
        children: [
          if (!isMobile) Container(
            width: 300,
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
                      Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                      SizedBox(height: 10),
                      Text('Không tìm thấy kết quả phù hợp.', style: TextStyle(color: Colors.grey)),
                    ],
                  ))
                : GridView.builder(
                    padding: EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth > 1200 ? 3 : (screenWidth > 600 ? 2 : 1),
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
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
          SizedBox(height: 10),
          Text('BỘ LỌC TÌM KIẾM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 16)),
          Divider(),
          
          _buildFilterLabel('Điểm đến'),
          DropdownButtonFormField<String>(
            value: _cities.contains(_selectedCity) ? _selectedCity : 'Tất cả',
            decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
            items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) => setState(() { _selectedCity = v!; _performSearch(); }),
          ),

          _buildFilterLabel('Khoảng giá'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _priceOptions.map((option) {
              final isSelected = _priceFilter == option;
              return ChoiceChip(
                label: Text(option, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                selected: isSelected,
                selectedColor: Colors.blue[900],
                backgroundColor: Colors.grey[100],
                onSelected: (selected) {
                  if (selected) {
                    setState(() { _priceFilter = option; _performSearch(); });
                  }
                },
              );
            }).toList(),
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
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45), backgroundColor: _dateRange == null ? Colors.grey[100] : Colors.blue[50], foregroundColor: Colors.blue[900]),
          ),
          
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => setState(() { _selectedCity = 'Tất cả'; _selectedStars = 0; _dateRange = null; _priceFilter = 'Tất cả'; _performSearch(); }),
            child: Text('XÓA TẤT CẢ LỌC'),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45), backgroundColor: Colors.red[50], foregroundColor: Colors.red),
          )
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));
  }

  Widget _buildResultCard(Hotel hotel) {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => HotelDetailScreen(hotel: hotel))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildNetworkImage(hotel.imageUrl)),
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
