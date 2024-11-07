import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';
import 'package:learn_smart/screens/widgets/bottom_navigation.dart';
import 'package:motion_tab_bar_v2/motion-tab-controller.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late MotionTabBarController _motionTabBarController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isSaveButtonEnabled = false;
  String? _initialName;
  String? _initialEmail;
  String? _userImage;

  @override
  void initState() {
    super.initState();
    _motionTabBarController = MotionTabBarController(
      initialIndex: 3, // Set the Profile tab as the selected one
      length: 4,
      vsync: this,
    );

    // Initialize with current user data
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _initialName = authViewModel.user.username;
    _initialEmail = authViewModel.user.email;
    _userImage = authViewModel.user.imageUrl;

    _nameController = TextEditingController(text: _initialName);
    _emailController = TextEditingController(text: _initialEmail);

    _nameController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _motionTabBarController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Enable save button if any changes are made
    setState(() {
      _isSaveButtonEnabled = (_nameController.text != _initialName) ||
          (_emailController.text != _initialEmail);
    });
  }

  Future<void> _saveChanges() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    try {
      final apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      // await apiService.updateProfile(
      //   username: _nameController.text,
      //   email: _emailController.text,
      // );

      // Update user details in AuthViewModel
      // authViewModel.updateUserDetails(
      //   username: _nameController.text,
      //   email: _emailController.text,
      // );

      setState(() {
        _initialName = _nameController.text;
        _initialEmail = _emailController.text;
        _isSaveButtonEnabled = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
      );
    }
  }

  void _logout() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage('http://10.0.2.2:8000' +
                      _userImage.toString()), // Update this URL
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    onPressed: () {
                      // Handle profile picture change
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            _buildTextField('Name', _nameController),
            SizedBox(height: 20),
            _buildTextField('Email', _emailController),
            SizedBox(height: 30),
            ElevatedButton(
              child: Text('Save changes'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _isSaveButtonEnabled ? _saveChanges : null,
            ),
            SizedBox(height: 20),
            OutlinedButton(
              child: Text('LOGOUT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _logout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        controller: _motionTabBarController,
        currentIndex: 3, // Profile Tab index
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(),
      ),
      controller: controller,
    );
  }
}
