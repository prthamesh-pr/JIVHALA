import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// Add these imports for API integration
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Import for handling multipart requests for image upload
import 'package:http_parser/http_parser.dart';

class VehicleInPage extends StatefulWidget {
  const VehicleInPage({super.key});

  @override
  _VehicleInPageState createState() => _VehicleInPageState();
}

class _VehicleInPageState extends State<VehicleInPage> {
  // Controllers for text fields
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _vehicleHpController = TextEditingController();
  final TextEditingController _chassisNumberController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _vehicleNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  // Add controller for Challan
  final TextEditingController _challanController = TextEditingController();

  // Focus nodes for text fields
  final FocusNode _vehicleNumberFocus = FocusNode();
  final FocusNode _vehicleHpFocus = FocusNode();
  final FocusNode _chassisNumberFocus = FocusNode();
  final FocusNode _engineNumberFocus = FocusNode();
  final FocusNode _vehicleNameFocus = FocusNode();
  final FocusNode _ownerNameFocus = FocusNode();
  final FocusNode _mobileNumberFocus = FocusNode();
  // Add focus node for Challan
  final FocusNode _challanFocus = FocusNode();

  // Variables for dropdowns
  String? _selectedYear;
  String? _selectedVehicleType;
  
  // Variables for checkboxes
  String? _selectedOption; // Can be "1st", "2nd", or "3rd"
  bool _isRcSelected = false;
  bool _isPucSelected = false;
  // Add NOC checkbox
  bool _isNocSelected = false;
  
  // Variable for insurance date
  DateTime? _insuranceDate;
  
  // Variable for vehicle in date (current date)
  final DateTime _vehicleInDate = DateTime.now();
  
  // List of captured images (increased capacity for 6+ photos)
  final List<File> _capturedImages = [];
  
  // Loading state for API operations
  bool _isLoading = false;
  String? _errorMessage;
  
  // Generate list of years for dropdown (last 30 years)
  List<String> _generateYearsList() {
    final int currentYear = DateTime.now().year;
    return List.generate(30, (index) => (currentYear - index).toString());
  }
  
  // Vehicle types for dropdown
  final List<String> _vehicleTypes = [
    'Bike', 
    'Scooty', 
    'SUV', 
    'Sedan', 
    'Hatchback', 
    'MUV',
    'Commercial'
  ];
  
  // Method to pick image from camera
  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // Reduced quality for better performance
    );
    
    if (image != null) {
      setState(() {
        _capturedImages.add(File(image.path));
      });
    }
  }
  
  // Method to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Reduced quality for better performance
    );
    
    if (image != null) {
      setState(() {
        _capturedImages.add(File(image.path));
      });
    }
  }
  
  // Method to show date picker with customized theme
  Future<void> _selectInsuranceDate(BuildContext context) async {
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.light(
        primary: Colors.grey[800]!, // header background color
        onPrimary: Colors.white, // header text color
        onSurface: Colors.black, // body text color
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black, // button text color
        ),
      ),
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _insuranceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: theme,
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _insuranceDate = picked;
      });
    }
  }
  
  // ========== API INTEGRATION ==========
  
  /*
  // UNCOMMENT THIS SECTION TO USE API FOR SAVING VEHICLE DATA
  // REQUIREMENTS:
  // 1. Add these packages to pubspec.yaml:
  //    - http: ^1.1.0
  //    - http_parser: ^4.0.2
  // 2. Replace API_BASE_URL with your actual API endpoint
  // 3. Ensure your backend can handle multipart form data for images
  // 4. Add proper token handling for authenticated requests
  
  Future<bool> _saveVehicleData() async {
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
      
      // Format dates for API
      final String formattedInsuranceDate = _insuranceDate != null 
          ? DateFormat('yyyy-MM-dd').format(_insuranceDate!) 
          : '';
      
      final String formattedVehicleInDate = 
          DateFormat('yyyy-MM-dd').format(_vehicleInDate);
      
      // Create multipart request for sending both data and images
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      
      // Add headers including auth token
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        // Add any other required headers
      });
      
      // Add text fields
      request.fields['vehicleNumber'] = _vehicleNumberController.text;
      request.fields['vehicleHp'] = _vehicleHpController.text;
      request.fields['chassisNumber'] = _chassisNumberController.text;
      request.fields['engineNumber'] = _engineNumberController.text;
      request.fields['vehicleName'] = _vehicleNameController.text;
      request.fields['modelYear'] = _selectedYear ?? '';
      request.fields['vehicleType'] = _selectedVehicleType ?? '';
      request.fields['ownerName'] = _ownerNameController.text;
      request.fields['ownership'] = _selectedOption ?? '';
      request.fields['mobileNumber'] = _mobileNumberController.text;
      request.fields['insuranceDate'] = formattedInsuranceDate;
      request.fields['vehicleInDate'] = formattedVehicleInDate;
      request.fields['challan'] = _challanController.text;
      
      // Add boolean fields
      request.fields['hasRc'] = _isRcSelected.toString();
      request.fields['hasPuc'] = _isPucSelected.toString();
      request.fields['hasNoc'] = _isNocSelected.toString();
      
      // Add images
      for (int i = 0; i < _capturedImages.length; i++) {
        final file = _capturedImages[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        
        // Create multipart file
        final multipartFile = http.MultipartFile(
          'images[$i]', // Use array notation for multiple files
          stream,
          length,
          filename: 'vehicle_image_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        
        // Add file to request
        request.files.add(multipartFile);
      }
      
      // Send the request
      final streamedResponse = await request.send();
      
      // Get the response
      final response = await http.Response.fromStream(streamedResponse);
      
      // Debug response
      print('API Response: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Check if the request was successful
        if (data['success'] == true) {
          setState(() {
            _isLoading = false;
          });
          return true;
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to save vehicle data';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Handle authentication error
        setState(() {
          _errorMessage = 'Authentication error. Please log in again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
      
      return false;
    } catch (e) {
      print('Vehicle data save error: $e');
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
      return false;
    }
  }
  */
  
  // Custom widget for text field rows with tap interaction
  Widget _buildTextFieldRow({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () {
              // Focus the text field when row is tapped
              FocusScope.of(context).requestFocus(focusNode);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  hintText: hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Custom checkbox option widget
  Widget _buildCustomCheckbox({
    required String value,
    required String label,
  }) {
    final isSelected = _selectedOption == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            // Toggle selection - if already selected, deselect; otherwise select
            _selectedOption = isSelected ? null : value;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Custom regular checkbox
  Widget _buildRegularCheckbox({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: value,
            activeColor: Colors.black,
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            onChanged: onChanged,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontWeight: value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
  
  // Custom separator
  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Container(
        height: 1,
        color: Colors.grey[400],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Get current date formatted
    String currentDate = DateFormat('dd MMM yyyy').format(_vehicleInDate);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo and date
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.asset(
                          'assets/logo/logo1.png',
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currentDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Close button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Error message if any
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.red[100],
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grey container with form fields
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle Number
                          _buildTextFieldRow(
                            label: 'Vehicle Number',
                            controller: _vehicleNumberController,
                            focusNode: _vehicleNumberFocus,
                            hintText: 'Enter vehicle number',
                          ),
                          
                          _buildSeparator(),
                          
                          // Vehicle HP
                          _buildTextFieldRow(
                            label: 'Vehicle HP',
                            controller: _vehicleHpController,
                            focusNode: _vehicleHpFocus,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter HP',
                          ),
                          
                          _buildSeparator(),
                          
                          // Chassis Number
                          _buildTextFieldRow(
                            label: 'Chassis Number',
                            controller: _chassisNumberController,
                            focusNode: _chassisNumberFocus,
                            hintText: 'Enter chassis number',
                          ),

                          _buildSeparator(),
                          
                          // Engine Number
                          _buildTextFieldRow(
                            label: 'Engine Number',
                            controller: _engineNumberController,
                            focusNode: _engineNumberFocus,
                            hintText: 'Enter engine number',
                          ),

                          _buildSeparator(),
                          
                          // Vehicle Name
                          _buildTextFieldRow(
                            label: 'Vehicle Name',
                            controller: _vehicleNameController,
                            focusNode: _vehicleNameFocus,
                            hintText: 'Enter vehicle name',
                          ),

                          _buildSeparator(),
                          
                          // Model (Year and Type)
                          Row(
                            children: [
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Model',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    // Year dropdown
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: DropdownButton<String>(
                                          value: _selectedYear,
                                          hint: Text('Year', style: TextStyle(color: Colors.grey[400])),
                                          isExpanded: true,
                                          underline: Container(),
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              _selectedYear = newValue;
                                            });
                                          },
                                          items: _generateYearsList()
                                              .map<DropdownMenuItem<String>>((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Vehicle type dropdown
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: DropdownButton<String>(
                                          value: _selectedVehicleType,
                                          hint: Text('Type', style: TextStyle(color: Colors.grey[400])),
                                          isExpanded: true,
                                          underline: Container(),
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              _selectedVehicleType = newValue;
                                            });
                                          },
                                          items: _vehicleTypes
                                              .map<DropdownMenuItem<String>>((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          _buildSeparator(),
                          
                          // Owner Name
                          _buildTextFieldRow(
                            label: 'Owner Name',
                            controller: _ownerNameController,
                            focusNode: _ownerNameFocus,
                            hintText: 'Enter owner name',
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // 1st, 2nd, 3rd checkboxes (mutually exclusive)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                _buildCustomCheckbox(value: "1st", label: "1st"),
                                _buildCustomCheckbox(value: "2nd", label: "2nd"),
                                _buildCustomCheckbox(value: "3rd", label: "3rd"),
                              ],
                            ),
                          ),
                          
                          _buildSeparator(),
                          
                          // Mobile Number
                          _buildTextFieldRow(
                            label: 'Mobile Number',
                            controller: _mobileNumberController,
                            focusNode: _mobileNumberFocus,
                            keyboardType: TextInputType.phone,
                            hintText: 'Enter mobile number',
                          ),

                          _buildSeparator(),
                          
                          // Challan Number (Added)
                          _buildTextFieldRow(
                            label: 'Challan',
                            controller: _challanController,
                            focusNode: _challanFocus,
                            hintText: 'Enter challan details',
                          ),

                          _buildSeparator(),
                          
                          // Insurance Date
                          Row(
                            children: [
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Insurance Date',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: () => _selectInsuranceDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _insuranceDate == null
                                              ? 'Select Date'
                                              : DateFormat('dd/MM/yyyy').format(_insuranceDate!),
                                          style: TextStyle(
                                            color: _insuranceDate == null ? Colors.grey[400] : Colors.black,
                                          ),
                                        ),
                                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          _buildSeparator(),
                          
                          // RC, PUC, and NOC checkboxes (Added NOC)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                // RC checkbox
                                Expanded(
                                  child: _buildRegularCheckbox(
                                    label: 'RC',
                                    value: _isRcSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isRcSelected = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                // PUC checkbox
                                Expanded(
                                  child: _buildRegularCheckbox(
                                    label: 'PUC',
                                    value: _isPucSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isPucSelected = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                // NOC checkbox (Added)
                                Expanded(
                                  child: _buildRegularCheckbox(
                                    label: 'NOC',
                                    value: _isNocSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isNocSelected = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Photo upload section with counter
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                // Only allow up to 6 photos
                                if (_capturedImages.length >= 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Maximum 6 photos allowed'),
                                      backgroundColor: Colors.orange[800],
                                    ),
                                  );
                                  return;
                                }
                                
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (BuildContext context) {
                                    return SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.camera_alt, color: Colors.black),
                                            ),
                                            title: const Text('Take a photo'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImageFromCamera();
                                            },
                                          ),
                                          ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.photo_library, color: Colors.black),
                                            ),
                                            title: const Text('Choose from gallery'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImageFromGallery();
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 32,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Add photos here (${_capturedImages.length}/6)',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to access camera or pick from device',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Show selected images if any
                          if (_capturedImages.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _capturedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Image.file(
                                            _capturedImages[index],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _capturedImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Vehicle In Button
                    ElevatedButton(
                      onPressed: _isLoading 
                      ? null 
                      : () {
                        // UNCOMMENT THIS WHEN USING THE API
                        /*
                        _saveVehicleData().then((success) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 12),
                                    const Text('Vehicle check-in processed successfully'),
                                  ],
                                ),
                                backgroundColor: Colors.black87,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            
                            // Navigate back or to another screen
                            Navigator.pop(context);
                          }
                        });
                        */
                        
                        // Currently using mock success
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                const Text('Vehicle check-in processed successfully'),
                              ],
                            ),
                            backgroundColor: Colors.black87,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Vehicle In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
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
  
  @override
  void dispose() {
    // Dispose of controllers and focus nodes
    _vehicleNumberController.dispose();
    _vehicleHpController.dispose();
    _chassisNumberController.dispose();
    _engineNumberController.dispose();
    _vehicleNameController.dispose();
    _ownerNameController.dispose();
    _mobileNumberController.dispose();
    _challanController.dispose(); // Added
    
    _vehicleNumberFocus.dispose();
    _vehicleHpFocus.dispose();
    _chassisNumberFocus.dispose();
    _engineNumberFocus.dispose();
    _vehicleNameFocus.dispose();
    _ownerNameFocus.dispose();
    _mobileNumberFocus.dispose();
    _challanFocus.dispose(); // Added
    
    super.dispose();
  }
}