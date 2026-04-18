import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _fullNameController.text = user.fullName ?? '';
      _phoneController.text = user.phone ?? '';
      _emailController.text = user.email;
    }
  }

  void _saveProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;

    final updatedUser = User(
      id: user.id,
      username: user.username,
      email: _emailController.text.trim(),
      password: user.password,
      role: user.role,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    try {
      await DatabaseHelper.instance.updateUser(updatedUser);
      userProvider.setUser(updatedUser); // Cập nhật lại provider và localStorage
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thông tin thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: Không thể cập nhật thông tin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin cá nhân'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[900],
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                user?.username ?? 'Tên người dùng',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                user?.role == 'admin' ? 'Quản trị viên' : 'Thành viên',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 30),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildInfoField(
                        controller: _fullNameController,
                        label: 'Họ và tên',
                        icon: Icons.badge,
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 15),
                      _buildInfoField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        icon: Icons.phone,
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 15),
                      _buildInfoField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 30),
                      if (!_isEditing)
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: Icon(Icons.edit),
                          label: Text('CHỈNH SỬA THÔNG TIN'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Colors.blue[900],
                            foregroundColor: Colors.white,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _isEditing = false),
                                child: Text('HỦY'),
                                style: OutlinedButton.styleFrom(minimumSize: Size(0, 50)),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                child: Text('LƯU THÔNG TIN'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(0, 50),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildInfoField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}
