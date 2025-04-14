import 'package:flutter/material.dart';
import 'package:sustainability_challenge/screens/plugs_screen.dart';
import 'package:sustainability_challenge/screens/screen_occupancy.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationSidebar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingCard(),
                    SizedBox(height: 20),
                    NotificationCard(),
                    SizedBox(height: 20),
                    OverviewChart(),
                    SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: DeviceStatusCards()),
                        SizedBox(width: 20),
                        Expanded(child: EnergyPieChart()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.green.shade600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.power, color: Colors.white),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlugsScreen()),
                ),
          ),
          IconButton(
            icon: Icon(Icons.sensors, color: Colors.white),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OccupancyScreen()),
                ),
          ),
        ],
      ),
    );
  }
}

class GreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, Rosa! 👋",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                "Here is your home today\n${DateTime.now().toString().substring(0, 16)}",
                style: TextStyle(color: Colors.grey[800]),
              ),
            ],
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active, color: Colors.orange, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Update",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "☕ Coffee machine consuming power while you're away!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  "We've noticed your coffee machine is using electricity even though you're not home. "
                  "Unplugging devices when they're not in use can save energy and reduce your bills.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OverviewChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Electricity Consumed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      12,
                      (i) => FlSpot(i.toDouble(), (i * 1000 + 3000).toDouble()),
                    ),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700],
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.3),
                          Colors.green.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceStatusCards extends StatelessWidget {
  final List<Map<String, dynamic>> devices = [
    {'name': 'Fridge', 'status': true},
    {'name': 'Freezer', 'status': true},
    {'name': 'Coffee Machine', 'status': true},
    {'name': 'PC', 'status': false},
    {'name': 'Kettle', 'status': true},
    {'name': 'Washing Machine', 'status': false},
    {'name': 'Dryer', 'status': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          devices.map((device) {
            return Container(
              width: 120,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    device['status']
                        ? Colors.green.shade50
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 32,
                    color: Colors.green.shade700,
                  ),
                  SizedBox(height: 8),
                  Text(
                    device['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: device['status'],
                    onChanged: (_) {},
                    activeColor: Colors.green,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class EnergyPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Electricity Consumed per Device',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 15.1,
                    color: Colors.green,
                    title: 'Fridge',
                  ),
                  PieChartSectionData(
                    value: 13.3,
                    color: Colors.lightGreen,
                    title: 'Freezer',
                  ),
                  PieChartSectionData(
                    value: 3.88,
                    color: Colors.greenAccent,
                    title: 'Coffee',
                  ),
                  PieChartSectionData(
                    value: 4.3,
                    color: Colors.teal,
                    title: 'Kettle',
                  ),
                  PieChartSectionData(
                    value: 17.3,
                    color: Colors.lime,
                    title: 'Washer',
                  ),
                  PieChartSectionData(
                    value: 16.5,
                    color: Colors.lightGreenAccent,
                    title: 'Dryer',
                  ),
                  PieChartSectionData(
                    value: 12.8,
                    color: Colors.tealAccent,
                    title: 'PC',
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
