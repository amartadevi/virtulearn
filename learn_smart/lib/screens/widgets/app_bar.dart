import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../view_models/auth_view_model.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final Function(String)? onSearchChanged; // Accept the search function

  const CustomAppBar({
    required this.title,
    this.onMenuPressed,
    this.onSearchChanged,
  });

  bool get _isHome => title == 'Home';

  // Maximum length for the title before truncating
  final int titleMaxLength = 20;

  String truncateWithEllipsis(int cutoff, String myString) {
    return (myString.length <= cutoff)
        ? myString
        : '${myString.substring(0, cutoff)}...';
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;
    String? baseUrl = 'http://10.0.2.2:8000/';
    final profileImage = user.imageUrl != null
        ? baseUrl + user.imageUrl.toString()
        : 'assets/icons/default_profile.png';

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isHome)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                if (_isHome)
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/profile');
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : const AssetImage('assets/icons/default_profile.png')
                              as ImageProvider,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isHome)
                          Text(
                            'Hello ${user.username},',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        Text(
                          _isHome
                              ? 'Good Morning'
                              : truncateWithEllipsis(titleMaxLength,
                                  title), // Truncate title if needed
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isHome)
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white),
                    onPressed: onMenuPressed ??
                        () {
                          Get.toNamed('/notifications');
                        },
                  ),
              ],
            ),
          ),
          if (_isHome)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SearchBar(
                  onSearchChanged: onSearchChanged), // Pass the search method
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize =>
      _isHome ? const Size.fromHeight(180) : const Size.fromHeight(80);
}

class SearchBar extends StatelessWidget {
  final Function(String)? onSearchChanged;

  const SearchBar({this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        onChanged: onSearchChanged, // Call the function when the query changes
        decoration: const InputDecoration(
          hintText: 'Search Course',
          suffixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
      ),
    );
  }
}
