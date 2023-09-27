import 'package:flutter/material.dart';

class Results extends StatefulWidget {
  const Results({Key? key}) : super(key: key);

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonthIndex =
      0; // Initially, display results for the current month

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _months.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    setState(() {
      _selectedMonthIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Results'),
      ),
      body: Column(
        children: [
          // TabBar to switch between months with the first letter of each month
          TabBar(
            tabs: _months.map((month) => Tab(text: month[0])).toList(),
            controller: _tabController,
            labelColor: Colors.black, // Set the label text color
            unselectedLabelColor:
                Colors.grey, // Set the unselected label text color
          ),
          Expanded(
            child: Center(
              child: Text(
                'Display Results for ${_months[_selectedMonthIndex]}',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
