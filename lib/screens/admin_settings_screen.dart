import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class AdminSettingsScreen extends StatefulWidget {
  @override
  _AdminSettingsScreenState createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  String _qrCodeUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final url = await DatabaseHelper.instance.getQRCode();
    setState(() {
      _qrCodeUrl = url;
      _isLoading = false;
    });
  }

  void _pickAndUploadQR() {
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
          final fileName = 'system_qr_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          setState(() => _isLoading = true);
          final url = await DatabaseHelper.instance.uploadImage(bytes, fileName);
          
          if (url != null) {
            await DatabaseHelper.instance.updateQRCode(url);
            setState(() {
              _qrCodeUrl = url;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật mã QR thành công!')));
          }
        });
        reader.readAsArrayBuffer(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cài đặt hệ thống'), backgroundColor: Colors.red[900], foregroundColor: Colors.white),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Text('QUẢN LÝ MÃ QR THANH TOÁN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text('Đây là mã QR khách hàng sẽ thấy khi chọn "Chuyển khoản ngay"', textAlign: TextAlign.center),
                      SizedBox(height: 20),
                      if (_isLoading) 
                        CircularProgressIndicator()
                      else
                        Image.network(_qrCodeUrl, height: 250, errorBuilder: (c,e,s) => Icon(Icons.qr_code, size: 100)),
                      SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _pickAndUploadQR,
                        icon: Icon(Icons.upload),
                        label: Text('UPLOAD MÃ QR MỚI'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Colors.red[900],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
