import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/destinationCarousel.dart';
import '../widgets/hotelCarousel.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _currentTab = 0;

  final List<IconData> _icons = [
    FontAwesomeIcons.compass, // تم تغييرها لتعبر عن الاستكشاف والسياحة
    FontAwesomeIcons.hotel,
    FontAwesomeIcons.mountain, // لتناسب الطبيعة الصحراوية
    FontAwesomeIcons.camera,   // لتناسب التقاط الصور والمعالم
  ];

  Widget _buildIcon(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        height: 60.0,
        width: 60.0,
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? Theme.of(context).colorScheme.secondary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Icon(
          _icons[index],
          size: 24.0,
          color: _selectedIndex == index
              ? Theme.of(context).primaryColor
              : Colors.orange[800],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 30.0),
          children: <Widget>[ // تم إصلاح الخطأ الإملائي هنا
            // عنوان التطبيق المميز
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Souf Tour 🌴',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  CircleAvatar(
                    radius: 20.0,
                    backgroundColor: Colors.orange[100],
                    child: Icon(Icons.person, color: Colors.orange[900]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.0),
            
            // النص الترحيبي بتطبيقك الجديد
            Padding(
              padding: EdgeInsets.only(left: 20.0, right: 80.0),
              child: Text(
                'What would you like to explore in Souf?',
                style: TextStyle(
                  fontSize: 26.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 25.0),
            
            // أيقونات التصنيفات السريعة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _icons
                  .asMap()
                  .entries
                  .map(
                    (map) => _buildIcon(map.key),
                  )
                  .toList(),
            ),
            SizedBox(height: 30.0),
            
            // عرض المعالم السياحية (Destination Carousel)
            DestinationCarousel(),
            
            SizedBox(height: 20.0),
            
            // عرض الفنادق أو أماكن الإقامة (Hotel Carousel)
            HotelCarousel(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        selectedItemColor: Colors.orange[900],
        unselectedItemColor: Colors.grey,
        onTap: (int value) {
          setState(() {
            _currentTab = value;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 28.0),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28.0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28.0),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}