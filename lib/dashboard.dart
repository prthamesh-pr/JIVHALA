import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // Add this import for API requests
import 'dart:convert'; // Add this for JSON parsing
import 'package:shared_preferences/shared_preferences.dart';
import 'vehicle_in.dart';
import 'details.dart';
import 'profile.dart';
import 'dart:io';

class DashboardPage extends StatefulWidget {
  final String username;

  const DashboardPage({super.key, required this.username});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedMonth = 'All';
  String _selectedYear = '2025';
  bool _isLoading = false;
  String? _errorMessage;

  // Stats counters
  int _todayInCount = 0;
  int _todayOutCount = 0;
  int _totalVehiclesCount = 0;

  final List<String> _months = [
    'All',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final List<String> _years = ['2025', '2024', '2023', '2022'];

  // Filtered data
  List<Map<String, dynamic>> _filteredData = [];
  // All vehicle data from API
  List<Map<String, dynamic>> _allVehicleData = [];

  @override
  void initState() {
    super.initState();
    // Load vehicle data when dashboard opens
    _loadVehicleData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== API INTEGRATION ==========

  /*
  // UNCOMMENT THIS SECTION TO USE API FOR FETCHING VEHICLE DATA
  // REQUIREMENTS:
  // 1. Add http package to pubspec.yaml: http: ^1.1.0
  // 2. Replace API_BASE_URL with your actual API endpoint
  // 3. Ensure your backend returns vehicle data in expected format
  // 4. Add proper token handling for authenticated requests
  
  Future<void> _loadVehicleData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // Replace with your actual API endpoint
      final String apiUrl = 'https://your-api-endpoint.com/api/vehicles';
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add auth token if required
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Check if the request was successful
        if (responseData['success'] == true) {
          final List<dynamic> vehiclesData = responseData['vehicles'] ?? [];
          
          setState(() {
            // Convert API response to the format needed by the app
            _allVehicleData = vehiclesData.map((vehicle) {
              // Format date from API (assumes API returns date as ISO string: YYYY-MM-DD)
              String formattedDate = '';
              if (vehicle['vehicleInDate'] != null) {
                final DateTime date = DateTime.parse(vehicle['vehicleInDate']);
                formattedDate = DateFormat('dd/MM/yy').format(date);
              }
              
              // Create a map with the required format
              return {
                'id': vehicle['id'].toString(),
                'vehicleNumber': vehicle['vehicleNumber'] ?? 'Unknown',
                'date': formattedDate,
                // Include all other vehicle details needed for the details page
                'vehicleHp': vehicle['vehicleHp'] ?? '',
                'chassisNumber': vehicle['chassisNumber'] ?? '',
                'engineNumber': vehicle['engineNumber'] ?? '',
                'vehicleName': vehicle['vehicleName'] ?? '',
                'ownerName': vehicle['ownerName'] ?? '',
                'mobileNumber': vehicle['mobileNumber'] ?? '',
                'year': vehicle['modelYear'] ?? '',
                'vehicleType': vehicle['vehicleType'] ?? '',
                'serviceOption': vehicle['ownership'] ?? '1st',
                'isRcSelected': vehicle['hasRc'] == 'true',
                'isPucSelected': vehicle['hasPuc'] == 'true',
                'isNocSelected': vehicle['hasNoc'] == 'true',
                'challan': vehicle['challan'] ?? '',
                'insuranceDate': vehicle['insuranceDate'] != null ? 
                    DateTime.parse(vehicle['insuranceDate']) : null,
                'apiImages': vehicle['images'] ?? [], // Store image URLs from API
                'isOut': vehicle['isOut'] == true, // Add isOut status from API
              };
            }).toList();
            
            // Set filtered data to all data initially
            _filteredData = List.from(_allVehicleData);
            
            // Update stats
            _updateStats();
            
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to load vehicle data';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Handle authentication error
        setState(() {
          _errorMessage = 'Authentication error. Please log in again.';
          _isLoading = false;
        });
        // You might want to redirect to login screen
        _handleAuthError();
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Load vehicle data error: $e');
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }
  */

  // CURRENTLY USING MOCK DATA - Replace with API implementation above
  Future<void> _loadVehicleData() async {
    setState(() {
      _isLoading = true;
      
      // In mock implementation, just use the mock data
      _allVehicleData = _getVehicleData();
      _filteredData = List.from(_allVehicleData);
      
      // Set some mock stats
      _todayInCount = 5;
      _todayOutCount = 3;
      _totalVehiclesCount = 42;
      
      _isLoading = false;
    });
    
    // Return a completed future
    return Future.value();
  }

  // Update stats based on the loaded data
  void _updateStats() {
    // Get today's date in format comparable to our date strings
    final String today = DateFormat('dd/MM/yy').format(DateTime.now());
    
    setState(() {
      // Count vehicles that came in today
      _todayInCount = _allVehicleData.where((vehicle) => 
        vehicle['date'] == today
      ).length;
      
      // Count vehicles that were checked out today
      _todayOutCount = _allVehicleData.where((vehicle) => 
        vehicle['date'] == today && vehicle['isOut'] == true
      ).length;
      
      // Total vehicles in the system
      _totalVehiclesCount = _allVehicleData.length;
    });
  }

  // Get dummy vehicle data - Replace with API data in production
  List<Map<String, dynamic>> _getVehicleData() {
    // This is mock data that will be replaced by API data
    return [
      {'id': '1', 'vehicleNumber': 'MH 11 BH 8960', 'date': '15/03/25', 'isOut': true},
      {'id': '2', 'vehicleNumber': 'MH 12 CD 2345', 'date': '16/03/25', 'isOut': false},
      {'id': '3', 'vehicleNumber': 'MH 13 EF 6789', 'date': '17/03/25', 'isOut': true},
      {'id': '4', 'vehicleNumber': 'MH 14 GH 1012', 'date': '18/03/25', 'isOut': false},
      {'id': '5', 'vehicleNumber': 'MH 15 IJ 3456', 'date': '19/03/25', 'isOut': true},
      {'id': '6', 'vehicleNumber': 'MH 16 KL 7890', 'date': '20/03/25', 'isOut': false},
      {'id': '7', 'vehicleNumber': 'MH 17 MN 1234', 'date': '21/03/25', 'isOut': false},
      {'id': '8', 'vehicleNumber': 'MH 18 OP 5678', 'date': '22/03/25', 'isOut': false},
      {'id': '9', 'vehicleNumber': 'MH 19 QR 9012', 'date': '23/03/25', 'isOut': false},
      {'id': '10', 'vehicleNumber': 'MH 20 ST 3456', 'date': '24/03/25', 'isOut': false},
      {'id': '11', 'vehicleNumber': 'MH 21 UV 7890', 'date': '25/03/25', 'isOut': false},
      {'id': '12', 'vehicleNumber': 'MH 22 WX 1234', 'date': '26/03/25', 'isOut': false},
      {'id': '13', 'vehicleNumber': 'MH 23 YZ 5678', 'date': '27/03/25', 'isOut': false},
      {'id': '14', 'vehicleNumber': 'MH 24 AB 9012', 'date': '28/03/25', 'isOut': false},
      {'id': '15', 'vehicleNumber': 'MH 25 CD 3456', 'date': '29/03/25', 'isOut': false},
      {'id': '16', 'vehicleNumber': 'MH 26 EF 7890', 'date': '30/03/25', 'isOut': true},
      {'id': '17', 'vehicleNumber': 'MH 27 GH 1234', 'date': '31/03/25', 'isOut': false},
      {'id': '18', 'vehicleNumber': 'MH 28 IJ 5678', 'date': '01/04/25', 'isOut': false},
      {'id': '19', 'vehicleNumber': 'MH 29 KL 9012', 'date': '02/04/25', 'isOut': false},
      {'id': '20', 'vehicleNumber': 'MH 30 MN 3456', 'date': '03/04/25', 'isOut': false},
    ];
  }

  // Filter data based on search, month and year
  void _filterData() {
    setState(() {
      _filteredData = _allVehicleData.where((vehicle) {
        // Apply search filter
        final searchMatch =
            _searchController.text.isEmpty ||
            vehicle['vehicleNumber']!.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

        // Apply month filter if not 'All'
        bool monthMatch = true;
        if (_selectedMonth != 'All') {
          // Extract month from date
          final dateParts = vehicle['date']!.split('/');
          if (dateParts.length >= 2) {
            final month = int.parse(dateParts[1]);
            // Convert month name to number (Jan=1, Feb=2, etc)
            final selectedMonthNumber = _months.indexOf(_selectedMonth);
            monthMatch = month == selectedMonthNumber;
          }
        }

        // Apply year filter
        bool yearMatch = true;
        if (_selectedYear != 'All') {
          // Extract year from date
          final dateParts = vehicle['date']!.split('/');
          if (dateParts.length >= 3) {
            final year = '20${dateParts[2]}'; // Convert '25' to '2025'
            yearMatch = year == _selectedYear;
          }
        }

        return searchMatch && monthMatch && yearMatch;
      }).toList();
    });
  }

  // Delete vehicle from list
  void _deleteVehicle(int index) async {
    // Get the vehicle to delete
    final vehicleToDelete = _filteredData[index];
    
    // Remove from filtered list
    setState(() {
      _filteredData.removeAt(index);
    });
    
    // Show a snackbar to confirm deletion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vehicle ${vehicleToDelete['vehicleNumber']} deleted'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // In a real app, you would implement undo functionality here
            setState(() {
              // Reload the data
              _loadVehicleData();
            });
          },
        ),
      ),
    );
    
    /* 
    // UNCOMMENT THIS SECTION TO USE API FOR DELETING VEHICLE
    // API-based deletion
    final String vehicleId = vehicleToDelete['id'];
    final bool success = await _deleteVehicleFromApi(vehicleId);
    
    if (success) {
      // Remove from all data list as well
      setState(() {
        _allVehicleData.removeWhere((vehicle) => vehicle['id'] == vehicleId);
        // Update stats
        _updateStats();
      });
    } else {
      // If deletion failed, restore the vehicle to the filtered list
      setState(() {
        _loadVehicleData(); // Reload data from API
      });
    }
    */
  }

  // Navigate to vehicle details page
  void _navigateToVehicleDetails(Map<String, dynamic> vehicle) {
    // When using API, the vehicle map should already contain all necessary data
    // For the mock implementation, create a more complete data set:
    Map<String, dynamic> completeVehicleData = {
      'vehicleNumber': vehicle['vehicleNumber'],
      'date': vehicle['date'],
      'isOut': vehicle['isOut'] ?? false, // Make sure isOut is included
      // Add placeholder values for other required fields
      'vehicleHp': vehicle['vehicleHp'] ?? '',
      'chassisNumber': vehicle['chassisNumber'] ?? '',
      'engineNumber': vehicle['engineNumber'] ?? '',
      'vehicleName': vehicle['vehicleName'] ?? 'Unknown Vehicle',
      'ownerName': vehicle['ownerName'] ?? 'Unknown Owner',
      'mobileNumber': vehicle['mobileNumber'] ?? '',
      'year': vehicle['year'] ?? '2025',
      'vehicleType': vehicle['vehicleType'] ?? 'Bike',
      'serviceOption': vehicle['serviceOption'] ?? '1st',
      'isRcSelected': vehicle['isRcSelected'] ?? false,
      'isPucSelected': vehicle['isPucSelected'] ?? false,
      'isNocSelected': vehicle['isNocSelected'] ?? false,
      'challan': vehicle['challan'] ?? '',
      'insuranceDate': vehicle['insuranceDate'],
      'images': <File>[], // Explicitly typed as List<File>
      // Include API image URLs if available
      'apiImages': vehicle['apiImages'] ?? [],
    };

    // Navigate to the VehicleDetailsPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VehicleDetailsPage(vehicleData: completeVehicleData),
      ),
    ).then((result) {
      // If result is true, it means the vehicle was checked out
      if (result == true) {
        // Find the vehicle in our data and mark it as out
        final index = _allVehicleData.indexWhere(
          (v) => v['id'] == vehicle['id']
        );
        if (index != -1) {
          setState(() {
            _allVehicleData[index]['isOut'] = true;
            _filterData(); // Refresh the filtered list
            _updateStats(); // Update the statistics
          });
        }
      } else {
        // Just refresh data when returning from details page
        _loadVehicleData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current date
    final String currentDate = DateFormat('dd/MM/yy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Container(
          margin: EdgeInsets.only(top: 15.0),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                // Logo on the left
                Image.asset('assets/logo/logo1.png', height: 40, width: 40),
                SizedBox(width: 8), // Small space between logo and text
                // Company name next to logo
                Text(
                  'JIVHALA MOTORS',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Spacer(), // Push search button to the right
                // Search button on the right
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close : Icons.search,
                      color: Colors.black87,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          // Reset filtered data to all data
                          _filteredData = List.from(_allVehicleData);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.grey[800],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message if any
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                    
                  // Search container
                  if (_isSearching)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Search bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search vehicle number...',
                                prefixIcon: Icon(Icons.search, color: Colors.grey),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close, color: Colors.grey),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _filterData();
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              onChanged: (value) {
                                _filterData();
                              },
                            ),
                          ),

                          SizedBox(height: 16.0),

                          // Filter options
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Month filter
                              Row(
                                children: [
                                  Text(
                                    'Month: ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 6.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _selectedMonth,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.black,
                                      ),
                                      underline: SizedBox(),
                                      isDense: true,
                                      items: _months.map((String month) {
                                        return DropdownMenuItem<String>(
                                          value: month,
                                          child: Text(month),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedMonth = newValue!;
                                          _filterData();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              // Year filter
                              Row(
                                children: [
                                  Text(
                                    'Year: ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 6.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _selectedYear,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.black,
                                      ),
                                      underline: SizedBox(),
                                      isDense: true,
                                      items: _years.map((String year) {
                                        return DropdownMenuItem<String>(
                                          value: year,
                                          child: Text(year),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedYear = newValue!;
                                          _filterData();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Stats container (hidden when searching)
                  if (!_isSearching)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left sub-container (Today's in/out)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 5, top: 5, bottom: 5),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center, // Center align
                                children: [
                                  Text(
                                    'Today\'s in',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 60,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _todayInCount.toString().padLeft(2, '0'), // In count
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Today\'s out',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 60,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _todayOutCount.toString().padLeft(2, '0'), // Out count
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Right sub-container (Date and total vehicles)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center, // Center align
                                children: [
                                  Text(
                                    'Date',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    currentDate,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Total vehicles',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 60,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _totalVehiclesCount.toString(), // Total count
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 20),

                  // List header
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vehicle Number',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Date',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List with vehicle data - with rounded bottom corners and proper scroll effect
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        child: _filteredData.isEmpty
                            ? Center(
                                child: Text(
                                  'No vehicles found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  // Reload data when pulled down
                                  await _loadVehicleData();
                                },
                                child: ListView.separated(
                                  physics: BouncingScrollPhysics(), // Add scroll effect
                                  itemCount: _filteredData.length,
                                  separatorBuilder: (context, index) => Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Divider(
                                      color: Colors.grey.shade300,
                                      height: 1,
                                    ),
                                  ),
                                  itemBuilder: (context, index) {
                                    final isOut = _filteredData[index]['isOut'] == true;
                                    
                                    return Dismissible(
                                      key: Key(_filteredData[index]['id'].toString()),
                                      direction: DismissDirection
                                          .endToStart, // Left swipe only
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.only(right: 20.0),
                                        color: Colors.red,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Delete',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        // Show confirmation dialog
                                        return await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              title: Text(
                                                'Confirm Delete',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete ${_filteredData[index]['vehicleNumber']}?',
                                                style: GoogleFonts.poppins(),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context).pop(false),
                                                  child: Text(
                                                    'CANCEL',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context).pop(true),
                                                  child: Text(
                                                    'DELETE',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      onDismissed: (direction) {
                                        // Delete the item
                                        _deleteVehicle(index);
                                      },
                                      child: InkWell(
                                        onTap: () {
                                          // Navigate to vehicle details
                                          _navigateToVehicleDetails(
                                            _filteredData[index],
                                          );
                                        },
                                        child: Container(
                                          color: isOut ? Colors.grey[200] : Colors.black87,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _filteredData[index]['vehicleNumber'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: isOut ? Colors.black87 : Colors.white,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  if (isOut)
                                                    Container(
                                                      margin: EdgeInsets.only(right: 8),
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[400],
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'OUT',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  Text(
                                                    _filteredData[index]['date'],
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: isOut ? Colors.black87 : Colors.white,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

      // Bottom navigation - Smaller height
      bottomNavigationBar: Container(
        height: 45, // Set explicit smaller height
        margin: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 6.0,
        ), // Reduced vertical margin
        decoration: BoxDecoration(
          color: Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 4.0,
            horizontal: 8.0,
          ), // Reduced vertical padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home text (no icon)
              InkWell(
                onTap: () {
                  // Already on dashboard.dart
                },
                child: Text(
                  'Home',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16, // Slightly smaller font
                  ),
                ),
              ),

              // Add button (center) - smaller size
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(2), // Reduced padding
                child: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ), // Smaller icon
                  onPressed: () {
                    // Navigate to VehicleInPage and refresh data when returning
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VehicleInPage()),
                    ).then((_) {
                      // Refresh data when returning from VehicleInPage
                      _loadVehicleData();
                    });
                  },
                  padding: EdgeInsets.zero, // Minimize internal padding
                  constraints: BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ), // Smaller constraints
                ),
              ),

              // Profile text (no icon)
              InkWell(
                onTap: () {
                  // Navigate to ProfilePage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
                child: Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16, // Slightly smaller font
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