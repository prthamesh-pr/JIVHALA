import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleOutPage extends StatefulWidget {
  final Map<String, dynamic> vehicleData;
  
  const VehicleOutPage({
    super.key,
    required this.vehicleData,
  });

  @override
  _VehicleOutPageState createState() => _VehicleOutPageState();
}

class _VehicleOutPageState extends State<VehicleOutPage> {
  // Controllers for buyer information
  final TextEditingController _buyerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _rtoChargesController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _receivedPriceController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _mailIdController = TextEditingController();
  final TextEditingController _aadharNumberController = TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();
  final TextEditingController _challanController = TextEditingController(); // Added challan

  // Focus nodes for text fields
  final FocusNode _buyerNameFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final FocusNode _rtoChargesFocus = FocusNode();
  final FocusNode _commissionFocus = FocusNode();
  final FocusNode _tokenFocus = FocusNode();
  final FocusNode _receivedPriceFocus = FocusNode();
  final FocusNode _balanceFocus = FocusNode();
  final FocusNode _mailIdFocus = FocusNode();
  final FocusNode _aadharNumberFocus = FocusNode();
  final FocusNode _panNumberFocus = FocusNode();
  final FocusNode _challanFocus = FocusNode(); // Added challan focus

  // Variables for checkboxes
  bool _isIdProofSelected = false;
  bool _isRcSelected = false; // Added from vehicle_in
  bool _isPucSelected = false; // Added from vehicle_in
  bool _isNocSelected = false; // Added from vehicle_in
  
  // Variable for out date
  DateTime? _outDate;
  
  // Variable for vehicle in date (from incoming data)
  DateTime? _vehicleInDate;
  
  // List of captured images
  final List<File> _capturedImages = [];
  
  // API loading state
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    // Parse vehicle in date if available
    if (widget.vehicleData['date'] != null) {
      final dateString = widget.vehicleData['date'];
      try {
        final dateParts = dateString.split('/');
        if (dateParts.length == 3) {
          // Format is dd/MM/yy
          _vehicleInDate = DateTime(
            2000 + int.parse(dateParts[2]), // Convert YY to YYYY
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
          );
        }
      } catch (e) {
        // If parsing fails, use current date
        _vehicleInDate = DateTime.now();
      }
    } else {
      _vehicleInDate = DateTime.now();
    }
    
    // Set default out date to today
    _outDate = DateTime.now();
    
    // Load checkbox values if they exist in vehicle data
    _isRcSelected = widget.vehicleData['isRcSelected'] ?? false;
    _isPucSelected = widget.vehicleData['isPucSelected'] ?? false;
    _isNocSelected = widget.vehicleData['isNocSelected'] ?? false;
  }
  
  // Method to pick image from camera
  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        _capturedImages.add(File(image.path));
      });
    }
  }
  
  // Method to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _capturedImages.add(File(image.path));
      });
    }
  }
  
  // Method to show date picker
  Future<void> _selectOutDate(BuildContext context) async {
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
      initialDate: _outDate ?? DateTime.now(),
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
        _outDate = picked;
      });
    }
  }
  
  // ========== API INTEGRATION FOR VEHICLE OUT ==========
  
  /*
  // UNCOMMENT THIS SECTION TO USE API FOR SAVING VEHICLE OUT DATA
  // REQUIREMENTS:
  // 1. Add http package to pubspec.yaml: http: ^1.1.0
  // 2. Replace API_BASE_URL with your actual API endpoint
  // 3. Ensure your backend can handle vehicle out data including images
  // 4. Add proper token handling for authenticated requests
  
  Future<bool> _saveVehicleOutData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // Get vehicle ID from data
      final String vehicleId = widget.vehicleData['id'].toString();
      
      // Replace with your actual API endpoint
      final String apiUrl = 'https://your-api-endpoint.com/api/vehicles/$vehicleId/out';
      
      // Format date for API
      final String formattedOutDate = _outDate != null 
          ? DateFormat('yyyy-MM-dd').format(_outDate!) 
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Create multipart request for sending both data and images
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      
      // Add headers including auth token
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        // Add any other required headers
      });
      
      // Add buyer information fields
      request.fields['buyerName'] = _buyerNameController.text;
      request.fields['address'] = _addressController.text;
      request.fields['price'] = _priceController.text;
      request.fields['rtoCharges'] = _rtoChargesController.text;
      request.fields['commission'] = _commissionController.text;
      request.fields['token'] = _tokenController.text;
      request.fields['receivedPrice'] = _receivedPriceController.text;
      request.fields['balance'] = _balanceController.text;
      request.fields['mailId'] = _mailIdController.text;
      request.fields['aadharNumber'] = _aadharNumberController.text;
      request.fields['panNumber'] = _panNumberController.text;
      request.fields['outDate'] = formattedOutDate;
      request.fields['isIdProofVerified'] = _isIdProofSelected.toString();
      request.fields['challan'] = _challanController.text;
      
      // Add checkboxes from vehicle details
      request.fields['isRcSelected'] = _isRcSelected.toString();
      request.fields['isPucSelected'] = _isPucSelected.toString();
      request.fields['isNocSelected'] = _isNocSelected.toString();
      
      // Add buyer image if any
      for (int i = 0; i < _capturedImages.length; i++) {
        final file = _capturedImages[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        
        // Create multipart file
        final multipartFile = http.MultipartFile(
          'buyerImages[$i]', // Use array notation for multiple files
          stream,
          length,
          filename: 'buyer_image_$i.jpg',
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
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Check if the request was successful
        if (data['success'] == true) {
          setState(() {
            _isLoading = false;
          });
          return true;
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to save vehicle out data';
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
      print('Vehicle out data save error: $e');
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
      return false;
    }
  }
  */
  
  // Process vehicle out (in-memory implementation for now)
  void _processVehicleOut() {
    // Save vehicle out data
    // In a real app, call _saveVehicleOutData() API method
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Vehicle check-out processed successfully'),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    
    // Navigate back to the previous screen
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(true); // Return true to indicate successful checkout
    });
  }

  // Custom widget for read-only info display
  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  // Custom widget for text field rows with tap interaction
  Widget _buildTextFieldRow({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(': '),
        ),
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(focusNode);
            },
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        height: 1,
        color: Colors.grey[300],
      ),
    );
  }
    @override
  Widget build(BuildContext context) {
    // Get vehicle in date formatted 
    String vehicleInDateFormatted = _vehicleInDate != null
        ? DateFormat('dd MMM yyyy').format(_vehicleInDate!)
        : DateFormat('dd MMM yyyy').format(DateTime.now());
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar with vehicle in date
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
                        "In: $vehicleInDateFormatted", // Vehicle in date
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
                    // First container: Vehicle Details (Non-editable)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                          const Text(
                            'Vehicle Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Vehicle details grid
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Vehicle Number',
                                  value: widget.vehicleData['Vehicle Number'] ?? '',
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Vehicle HP',
                                  value: widget.vehicleData['Vehicle HP'] ?? '',
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Chassis Number',
                                  value: widget.vehicleData['Chassis Number'] ?? '',
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Engine Number',
                                  value: widget.vehicleData['Engine Number'] ?? '',
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Vehicle Name',
                                  value: widget.vehicleData['Vehicle Name'] ?? '',
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Model',
                                  value: widget.vehicleData['Model'] ?? '',
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Owner Name',
                                  value: widget.vehicleData['Owner Name'] ?? '',
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Mobile Number',
                                  value: widget.vehicleData['Mobile Number'] ?? '',
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Insurance Date',
                                  value: widget.vehicleData['Insurance Date'] ?? '',
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: _buildInfoRow(
                                  label: 'Challan',
                                  value: widget.vehicleData['Challan'] ?? '',
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Checkboxes from vehicle in
                          Wrap(
                            spacing: 20,
                            children: [
                              _buildRegularCheckbox(
                                label: 'RC',
                                value: _isRcSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isRcSelected = value ?? false;
                                  });
                                },
                              ),
                              _buildRegularCheckbox(
                                label: 'PUC',
                                value: _isPucSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isPucSelected = value ?? false;
                                  });
                                },
                              ),
                              _buildRegularCheckbox(
                                label: 'NOC',
                                value: _isNocSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isNocSelected = value ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Second container: Buyer Information
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                          const Text(
                            'Buyer Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Buyer Name
                          _buildTextFieldRow(
                            label: 'Buyer\'s Name',
                            controller: _buyerNameController,
                            focusNode: _buyerNameFocus,
                            hintText: 'Enter buyer name',
                          ),
                          
                          // Address
                          _buildTextFieldRow(
                            label: 'Address',
                            controller: _addressController,
                            focusNode: _addressFocus,
                            hintText: 'Enter address',
                            maxLines: 2,
                          ),
                          
                          _buildSeparator(),
                          
                          // Price
                          _buildTextFieldRow(
                            label: 'Price',
                            controller: _priceController,
                            focusNode: _priceFocus,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter price',
                          ),
                          
                          _buildSeparator(),
                          
                          // RTO Charges
                          _buildTextFieldRow(
                            label: 'RTO Charges',
                            controller: _rtoChargesController,
                            focusNode: _rtoChargesFocus,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter RTO charges',
                          ),
                          
                          _buildSeparator(),
                          
                          // Commission
                          _buildTextFieldRow(
                            label: 'Commission',
                            controller: _commissionController,
                            focusNode: _commissionFocus,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter commission',
                          ),
                          
                          _buildSeparator(),
                          
                          // Token
                          _buildTextFieldRow(
                            label: 'Token',
                            controller: _tokenController,
                            focusNode: _tokenFocus,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter token amount',
                          ),
                          
                          _buildSeparator(),
                          
                          // Received Price
                          _buildTextFieldRow(
                            label: 'Received Price',
                            controller: _receivedPriceController,
                            focusNode: _receivedPriceFocus,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter received amount',
                          ),
                          
                          _buildSeparator(),
                          
                          // Balance
                          _buildTextFieldRow(
                            label: 'Balance',
                            controller: _balanceController,
                            focusNode: _balanceFocus,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter balance amount',
                          ),
                          
                          _buildSeparator(),
                          
                          // Challan
                          _buildTextFieldRow(
                            label: 'Challan',
                            controller: _challanController,
                            focusNode: _challanFocus,
                            hintText: 'Enter challan details',
                          ),
                          
                          _buildSeparator(),
                          
                          // ID Proof/Address Proof
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 2,
                                  child: Text(
                                    'ID Proof/Address Proof',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Text(': '),
                                Expanded(
                                  flex: 3,
                                  child: _buildRegularCheckbox(
                                    label: 'Verified',
                                    value: _isIdProofSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isIdProofSelected = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          _buildSeparator(),
                          
                          // Aadhar Card Number
                          _buildTextFieldRow(
                            label: 'Aadhar Card',
                            controller: _aadharNumberController,
                            focusNode: _aadharNumberFocus,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter Aadhar number',
                          ),
                          
                          _buildSeparator(),
                          
                          // PAN Card Number
                          _buildTextFieldRow(
                            label: 'PAN Card',
                            controller: _panNumberController,
                            focusNode: _panNumberFocus,
                            keyboardType: TextInputType.text,
                            hintText: 'Enter PAN number',
                          ),
                          
                          _buildSeparator(),
                          
                          // Mail ID
                          _buildTextFieldRow(
                            label: 'Mail ID',
                            controller: _mailIdController,
                            focusNode: _mailIdFocus,
                            keyboardType: TextInputType.emailAddress,
                            hintText: 'Enter email address',
                          ),
                          
                          _buildSeparator(),
                          
                          // Out Date
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Out Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Text(': '),
                                Expanded(
                                  flex: 3,
                                  child: GestureDetector(
                                    onTap: () => _selectOutDate(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Colors.grey),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _outDate == null
                                                ? 'Select Date'
                                                : DateFormat('dd/MM/yyyy').format(_outDate!),
                                            style: TextStyle(
                                              color: _outDate == null ? Colors.grey[400] : Colors.black,
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
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Photo upload section
                          Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 28,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Add buyer photos',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Show selected images if any
                          if (_capturedImages.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _capturedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
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
                                            width: 80,
                                            height: 80,
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
                                                size: 14,
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
                    
                    // Vehicle Out Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _processVehicleOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Vehicle Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Generate PDF Button
                    ElevatedButton(
                      onPressed: _generatePdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Generate PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
  
  // Method to generate PDF report of vehicle out details
  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    
    // Load logo image for PDF
    final ByteData logoData = await rootBundle.load('assets/logo/logo1.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);
    
    // Load vehicle images if available
    List<pw.Widget> vehicleImageWidgets = [];
    
    // Try to add images if available
    try {
      if (_capturedImages.isNotEmpty) {
        for (int i = 0; i < _capturedImages.length && i < 3; i++) {
          final File imageFile = _capturedImages[i];
          final Uint8List imageBytes = await imageFile.readAsBytes();
          vehicleImageWidgets.add(
            pw.Container(
              width: 120,
              height: 80,
              margin: const pw.EdgeInsets.only(right: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.cover,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading images for PDF: $e');
    }
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo and title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Image(logoImage, width: 60, height: 60),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'JIVHALA MOTORS',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Vehicle Out Report',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Vehicle In: ${_vehicleInDate != null ? DateFormat('dd/MM/yyyy').format(_vehicleInDate!) : "N/A"}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Vehicle Out: ${_outDate != null ? DateFormat('dd/MM/yyyy').format(_outDate!) : DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Vehicle details in a box
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VEHICLE DETAILS',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Divider(thickness: 1, color: PdfColors.grey300),
                    pw.SizedBox(height: 10),
                    
                    // Vehicle details in two columns
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfInfoRow('Vehicle Number', widget.vehicleData['Vehicle Number'] ?? ''),
                              _buildPdfInfoRow('Chassis Number', widget.vehicleData['Chassis Number'] ?? ''),
                              _buildPdfInfoRow('Vehicle Name', widget.vehicleData['Vehicle Name'] ?? ''),
                              _buildPdfInfoRow('Owner Name', widget.vehicleData['Owner Name'] ?? ''),
                              _buildPdfInfoRow('Mobile Number', widget.vehicleData['Mobile Number'] ?? ''),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        // Right column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfInfoRow('Vehicle HP', widget.vehicleData['Vehicle HP'] ?? ''),
                              _buildPdfInfoRow('Engine Number', widget.vehicleData['Engine Number'] ?? ''),
                              _buildPdfInfoRow('Model', widget.vehicleData['Model'] ?? ''),
                              _buildPdfInfoRow('Insurance Date', widget.vehicleData['Insurance Date'] ?? ''),
                              _buildPdfInfoRow('Challan', widget.vehicleData['Challan'] ?? ''),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    pw.SizedBox(height: 10),
                    
                    // Checkboxes in a row
                    pw.Row(
                      children: [
                        _buildPdfCheckbox('RC', _isRcSelected),
                        pw.SizedBox(width: 15),
                        _buildPdfCheckbox('PUC', _isPucSelected),
                        pw.SizedBox(width: 15),
                        _buildPdfCheckbox('NOC', _isNocSelected),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Buyer details in a box
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BUYER DETAILS',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Divider(thickness: 1, color: PdfColors.grey300),
                    pw.SizedBox(height: 10),
                    
                    // Buyer details in two columns
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfInfoRow('Buyer\'s Name', _buyerNameController.text),
                              _buildPdfInfoRow('Address', _addressController.text),
                              _buildPdfInfoRow('Price', _priceController.text),
                              _buildPdfInfoRow('RTO Charges', _rtoChargesController.text),
                              _buildPdfInfoRow('Commission', _commissionController.text),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        // Right column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfInfoRow('Token', _tokenController.text),
                              _buildPdfInfoRow('Received Price', _receivedPriceController.text),
                              _buildPdfInfoRow('Balance', _balanceController.text),
                              _buildPdfInfoRow('Aadhar Number', _aadharNumberController.text),
                              _buildPdfInfoRow('PAN Number', _panNumberController.text),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    pw.SizedBox(height: 5),
                    
                    _buildPdfInfoRow('Mail ID', _mailIdController.text),
                    _buildPdfInfoRow('Challan', _challanController.text),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        _buildPdfCheckbox('ID Proof Verified', _isIdProofSelected),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Buyer image if available
              if (vehicleImageWidgets.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BUYER IMAGES',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(thickness: 1, color: PdfColors.grey300),
                      pw.SizedBox(height: 10),
                      
                      // Display images in a row
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: vehicleImageWidgets,
                      ),
                    ],
                  ),
                ),
              ],
              
              pw.Spacer(),
              
              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Jivhala Motors | Contact: +91 9876543210',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    // Handle different platforms
    if (kIsWeb) {
      // For web platform
      final bytes = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'vehicle_out_details.pdf',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // For mobile platforms
      try {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/vehicle_out_details.pdf');
        await file.writeAsBytes(await pdf.save());
        
        await Share.shareFiles([file.path], text: 'Vehicle Out Details');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Helper method for PDF information rows
  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '-' : value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method for PDF checkboxes
  pw.Widget _buildPdfCheckbox(String label, bool isChecked) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
            color: isChecked ? PdfColors.black : PdfColors.white,
          ),
          child: isChecked
              ? pw.Center(
                  child: pw.Text(
                    '✓',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                )
              : pw.SizedBox(),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    // Dispose of controllers and focus nodes
    _buyerNameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _rtoChargesController.dispose();
    _commissionController.dispose();
    _tokenController.dispose();
    _receivedPriceController.dispose();
    _balanceController.dispose();
    _mailIdController.dispose();
    _aadharNumberController.dispose();
    _panNumberController.dispose();
    _challanController.dispose();
    
    _buyerNameFocus.dispose();
    _addressFocus.dispose();
    _priceFocus.dispose();
    _rtoChargesFocus.dispose();
    _commissionFocus.dispose();
    _tokenFocus.dispose();
    _receivedPriceFocus.dispose();
    _balanceFocus.dispose();
    _mailIdFocus.dispose();
    _aadharNumberFocus.dispose();
    _panNumberFocus.dispose();
    _challanFocus.dispose();
    
    super.dispose();
  }
}