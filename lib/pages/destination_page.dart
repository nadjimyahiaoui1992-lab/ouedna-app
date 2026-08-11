import 'package:flutter/material.dart';
import '../models/destination.dart';

class DestinationPage extends StatefulWidget {
  final Destination destination;

  DestinationPage({Key? key, required this.destination}) : super(key: key);

  @override
  _DestinationPageState createState() => _DestinationPageState();
}

Text _buildRatingStars(double rating) {
  String stars = '';
  for (int i = 0; i < rating.toInt(); i++) {
    stars += '⭐';
  }
  return Text(stars);
}

class _DestinationPageState extends State<DestinationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: <Widget>[
          // رأس الصفحة مع الصورة وخيارات الرجوع
          Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0.0, 4.0),
                      blurRadius: 8.0,
                    ),
                  ],
                ),
                child: Hero(
                  tag: widget.destination.imageUrl,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.0)),
                    child: Image.asset(
                      widget.destination.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.orange[200],
                        child: Center(child: Icon(Icons.image, size: 50, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              // أزرار التنقل العلوي
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          child: IconButton(
                            icon: Icon(Icons.search, color: Colors.black),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // معلومات المكان (الاسم والعنوان) فوق الصورة
              Positioned(
                left: 20.0,
                bottom: 20.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[900],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        widget.destination.mainCategory,
                        style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      widget.destination.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Icon(Icons.location_on, size: 14.0, color: Colors.white70),
                        SizedBox(width: 5.0),
                        Text(
                          widget.destination.address,
                          style: TextStyle(color: Colors.white70, fontSize: 16.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // قسم الوصف والتفاصيل
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20.0),
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حول المعلم',
                      style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.orange[900]),
                    ),
                    _buildRatingStars(widget.destination.rating),
                  ],
                ),
                SizedBox(height: 10.0),
                Text(
                  widget.destination.description,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[700], height: 1.5),
                ),
                SizedBox(height: 25.0),
                Text(
                  'المميزات والخدمات',
                  style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.orange[900]),
                ),
                SizedBox(height: 15.0),
                // بطاقة إضافية توضح حالة المكان أو معلوماته
                Container(
                  padding: EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, spreadRadius: 2)],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 30),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('معلم موثق في Souf Tour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('متاح للزيارة طوال أيام الأسبوع', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}