import 'activities.dart';

class Destination {
  String imageUrl;
  String name;
  String mainCategory;
  String address;
  String description;
  double rating;
  List<Activity> activities;

  Destination({
    required this.imageUrl,
    required this.name,
    required this.mainCategory,
    required this.address,
    required this.description,
    required this.rating,
    required this.activities,
  });
}

List<Activity> activities = [
  Activity(
    imageUrl: 'lib/assets/images/camping_vandri.jpg',
    name: 'Camping',
    type: 'Camping',
    startTimes: ['9:00 am', '1:00 am'],
    rating: 5,
    price: 30,
  ),
  Activity(
    imageUrl: 'lib/assets/images/cycling_vandri.jpg',
    name: 'Cycling tour',
    type: 'Sightseeing',
    startTimes: ['1:00 pm', '6:00 pm'],
    rating: 4,
    price: 210,
  ),
  Activity(
    imageUrl: 'lib/assets/images/picnicspot_vandri.jpg',
    name: 'Picnic Spot',
    type: 'Stay for 2 days',
    startTimes: ['8:30 am', '8:00 pm'],
    rating: 3,
    price: 125,
  ),
];

List<Destination> destinations = [
  Destination(
    imageUrl: 'lib/assets/images/suruchi.jpg',
    name: 'Suruchi',
    mainCategory: 'Beach',
    address: 'Vasai',
    description: 'Suruchi beach in vasai great picnic spot',
    rating: 4.0,
    activities: activities,
  ),
  Destination(
    imageUrl: 'lib/assets/images/vandrilake.png',
    name: 'Vandri',
    mainCategory: 'Lake',
    address: 'Palghar',
    description: 'Vandri lake good for camping and cycling.',
    rating: 4.5,
    activities: activities,
  ),
  Destination(
    imageUrl: 'lib/assets/images/Pelhar.jpg',
    name: 'Pelhar',
    mainCategory: 'Dam',
    address: 'Virar',
    description: 'Pelhar Dam great tourist destination',
    rating: 4.0,
    activities: activities,
  ),
  Destination(
    imageUrl: 'lib/assets/images/BuddhaStupa.jpg',
    name: 'Buddha Stupa',
    mainCategory: 'Historical',
    address: 'Nallasopara',
    description: '2500 year old buddha stupa',
    rating: 5.0,
    activities: activities,
  ),
  Destination(
    imageUrl: 'lib/assets/images/Vajreshwari.jpg',
    name: 'Vajreshwari Temple',
    mainCategory: 'Temple',
    address: 'Vajreshwari',
    description: 'Visit temple for devotion and peace',
    rating: 4.5,
    activities: activities,
  ),
];
