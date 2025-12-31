import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/pages/auth/profile_page.dart';
import 'package:flutter_boilerplate/pages/family/family_list_page.dart';
import 'package:flutter_boilerplate/pages/fridge/fridge_page.dart';
import 'package:flutter_boilerplate/pages/home/home_page.dart';
import 'package:flutter_boilerplate/pages/recipe/recipe_list_page.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart'; // Import FamilyProvider
import 'package:flutter_boilerplate/providers/fridge_provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = <Widget>[
    const HomePage(),
    const FamilyListPage(), 
    const FridgePage(),
    const RecipeListPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    final familyProvider = context.read<FamilyProvider>();

    // Special handling for the Fridge tab
    if (index == 2) { // Index 2 is the Fridge tab
      final selectedFamily = familyProvider.selectedFamily;
      
      // If no family is selected, show a message and switch to the Family tab
      if (selectedFamily == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn một nhóm để xem tủ lạnh.'),
            backgroundColor: Colors.amber,
          ),
        );
        // Switch to the Family tab (index 1)
        setState(() {
          _selectedIndex = 1;
        });
        return; // Stop further execution
      }
      
      // If a family is selected, fetch its fridge items
      context.read<FridgeProvider>().fetchFridgeItems(selectedFamily.id, isRefresh: true);
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Nhóm'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen_outlined), activeIcon: Icon(Icons.kitchen), label: 'Tủ lạnh'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Thực Đơn'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Tài Khoản'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFF26F21),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
