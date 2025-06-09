import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'vehicle_out.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';

class VehicleDetailsPage extends StatefulWidget {
  // Vehicle data model to store all information
  final Map<String, dynamic> vehicleData;
  
  const VehicleDetailsPage({
    super.key, 
    required this.vehicleData,
  });

  @override
  _VehicleDetailsPageState createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  // Flag to track edit mode
  bool _isEditMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Controllers for text fields
  late TextEditingController _vehicleNumberController;
  late TextEditingController _vehicleHpController;
  late TextEditingController _chassisNumberController;
  late TextEditingController _engineNumberController;
  late TextEditingController _vehicleNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _challanController; // Added Challan controller
  
  // Variables for form state
  late String? _selectedYear;
  late String? _selectedVehicleType;
  late String? _selectedOption;
  late bool _isRcSelected;
  late bool _isPucSelected;
  late bool _isNocSelected; // Added NOC checkbox
  late DateTime? _insuranceDate;
  late DateTime? _vehicleInDate; // Added vehicle in date
  late List<File> _capturedImages;
  late List<String> _apiImages; // For images from API
  
  // Focus nodes for text fields
  final FocusNode _vehicleNumberFocus = FocusNode();
  final FocusNode _vehicleHpFocus = FocusNode();
  final FocusNode _chassisNumberFocus = FocusNode();
  final FocusNode _engineNumberFocus = FocusNode();
  final FocusNode _vehicleNameFocus = FocusNode();
  final FocusNode _ownerNameFocus = FocusNode();
  final FocusNode _mobileNumberFocus = FocusNode();
  final FocusNode _challanFocus = FocusNode(); // Added Challan focus node
  
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

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with data from widget
    _vehicleNumberController = TextEditingController(text: widget.vehicleData['vehicleNumber'] ?? '');
    _vehicleHpController = TextEditingController(text: widget.vehicleData['vehicleHp'] ?? '');
    _chassisNumberController = TextEditingController(text: widget.vehicleData['chassisNumber'] ?? '');
    _engineNumberController = TextEditingController(text: widget.vehicleData['engineNumber'] ?? '');
    _vehicleNameController = TextEditingController(text: widget.vehicleData['vehicleName'] ?? '');
    _ownerNameController = TextEditingController(text: widget.vehicleData['ownerName'] ?? '');
    _mobileNumberController = TextEditingController(text: widget.vehicleData['mobileNumber'] ?? '');
    _challanController = TextEditingController(text: widget.vehicleData['challan'] ?? '');
    
    // Initialize other form state
    _selectedYear = widget.vehicleData['year'];
    _selectedVehicleType = widget.vehicleData['vehicleType'];
    _selectedOption = widget.vehicleData['serviceOption'];
    _isRcSelected = widget.vehicleData['isRcSelected'] ?? false;
    _isPucSelected = widget.vehicleData['isPucSelected'] ?? false;
    _isNocSelected = widget.vehicleData['isNocSelected'] ?? false;
    _insuranceDate = widget.vehicleData['insuranceDate'];
    _capturedImages = widget.vehicleData['images'] ?? [];
    
    // Fix: Convert List<dynamic> to List<String>
    _apiImages = widget.vehicleData['apiImages'] != null 
        ? List<String>.from(widget.vehicleData['apiImages'])
        : [];
    
    // Parse the date string to DateTime if available
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
  }
  
  // Method to toggle edit mode
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }
  
  // ========== API INTEGRATION FOR VEHICLE UPDATE ==========
  
  /*
  // UNCOMMENT THIS SECTION TO USE API FOR UPDATING VEHICLE DATA
  // REQUIREMENTS:
  // 1. Add http package to pubspec.yaml: http: ^1.1.0
  // 2. Replace API_BASE_URL with your actual API endpoint
  // 3. Ensure your backend can handle vehicle updates including images
  // 4. Add proper token handling for authenticated requests
  
  Future<bool> _updateVehicleData() async {
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
      final String apiUrl = 'https://your-api-endpoint.com/api/vehicles/$vehicleId';
      
      // Format dates for API
      final String formattedInsuranceDate = _insuranceDate != null 
          ? DateFormat('yyyy-MM-dd').format(_insuranceDate!) 
          : '';
      
      final String formattedVehicleInDate = _vehicleInDate != null
          ? DateFormat('yyyy-MM-dd').format(_vehicleInDate!)
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Create multipart request for sending both data and images
      final request = http.MultipartRequest('PUT', Uri.parse(apiUrl));
      
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
      
      // Add new images if any
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
        );
        
        // Add file to request
        request.files.add(multipartFile);
      }
      
      // Keep existing API images
      for (int i = 0; i < _apiImages.length; i++) {
        request.fields['existingImages[$i]'] = _apiImages[i];
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
            _errorMessage = data['message'] ?? 'Failed to update vehicle data';
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
      print('Vehicle data update error: $e');
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
      return false;
    }
  }
  */
  
  // Method to save updated data
  void _saveData() async {
    // For mock implementation, just update the local data
    // In a real app, you would call _updateVehicleData() API method
    
    // Update the vehicle data map
    final updatedData = {
      'vehicleNumber': _vehicleNumberController.text,
      'vehicleHp': _vehicleHpController.text,
      'chassisNumber': _chassisNumberController.text,
      'engineNumber': _engineNumberController.text,
      'vehicleName': _vehicleNameController.text,
      'ownerName': _ownerNameController.text,
      'mobileNumber': _mobileNumberController.text,
      'challan': _challanController.text,
      'year': _selectedYear,
      'vehicleType': _selectedVehicleType,
      'serviceOption': _selectedOption,
      'isRcSelected': _isRcSelected,
      'isPucSelected': _isPucSelected,
      'isNocSelected': _isNocSelected,
      'insuranceDate': _insuranceDate,
      'images': _capturedImages,
      'apiImages': _apiImages,
    };
    
    // Update the widget's vehicleData with the new values
    widget.vehicleData.addAll(updatedData);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Vehicle details updated successfully'),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    
    // Exit edit mode
    setState(() {
      _isEditMode = false;
    });
  }
  
  // Method to process vehicle out - UPDATED to navigate to VehicleOutPage
  void _processVehicleOut() {
    // Create a map of vehicle data to pass to the VehicleOutPage
    final vehicleDataForOut = {
      'Vehicle Number': _vehicleNumberController.text,
      'Vehicle HP': _vehicleHpController.text,
      'Chassis Number': _chassisNumberController.text,
      'Engine Number': _engineNumberController.text,
      'Vehicle Name': _vehicleNameController.text,
      'Model': '${_selectedYear ?? ""} ${_selectedVehicleType ?? ""}'.trim(),
      'Owner Name': _ownerNameController.text,
      'Mobile Number': _mobileNumberController.text,
      'Insurance Date': _insuranceDate != null 
          ? DateFormat('dd/MM/yyyy').format(_insuranceDate!) 
          : '',
      'Challan': _challanController.text,
    };
    
    // Navigate to the VehicleOutPage and pass the vehicle data
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleOutPage(
          vehicleData: vehicleDataForOut,
        ),
      ),
    );
  }
  
  // Method to show date picker with customized theme
  Future<void> _selectInsuranceDate(BuildContext context) async {
    if (!_isEditMode) return; // Only allow date selection in edit mode
    
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
  
  // Method to generate PDF report of vehicle details
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
              width: 180,
              height: 120,
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
      // Create placeholder for images
      vehicleImageWidgets.add(
        pw.Container(
          width: 180,
          height: 120,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Center(
            child: pw.Text(
              'Images not available',
              style: pw.TextStyle(color: PdfColors.grey),
            ),
          ),
        ),
      );
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
                            'Vehicle Details Report',
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
                    child: pw.Text(
                      'Date: ${DateFormat('dd/MM/yyyy').format(_vehicleInDate ?? DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 12),
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
                              _buildPdfInfoRow('Vehicle Number', _vehicleNumberController.text),
                              _buildPdfInfoRow('Chassis Number', _chassisNumberController.text),
                              _buildPdfInfoRow('Vehicle Name', _vehicleNameController.text),
                              _buildPdfInfoRow('Owner Name', _ownerNameController.text),
                              _buildPdfInfoRow('Mobile Number', _mobileNumberController.text),
                              _buildPdfInfoRow('Challan', _challanController.text),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        // Right column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfInfoRow('Vehicle HP', _vehicleHpController.text),
                              _buildPdfInfoRow('Engine Number', _engineNumberController.text),
                              _buildPdfInfoRow('Model', '${_selectedYear ?? ""} ${_selectedVehicleType ?? ""}'.trim()),
                              _buildPdfInfoRow('Ownership', _selectedOption ?? ""),
                              _buildPdfInfoRow('Insurance Date', _insuranceDate != null 
                                ? DateFormat('dd/MM/yyyy').format(_insuranceDate!) 
                                : 'Not specified'),
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
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Vehicle images section
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
                      'VEHICLE IMAGES',
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
      // For web platform, use printing package to display PDF
      final bytes = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'vehicle_details.pdf',
        format: PdfPageFormat.a4,
      );
      
      // Show success message
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
        final file = File('${output.path}/vehicle_details.pdf');
        await file.writeAsBytes(await pdf.save());
        
        // Share or print PDF
        await Share.shareFiles([file.path], text: 'Vehicle Details');
      } catch (e) {
        // Show error message
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
  
  // Widget for text field row
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
              if (_isEditMode) {
                FocusScope.of(context).requestFocus(focusNode);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _isEditMode ? Colors.white : Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                boxShadow: _isEditMode ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                enabled: _isEditMode,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: _isEditMode ? Colors.white : Colors.grey[200],
                  hintText: hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
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
  
  // Custom checkbox option widget
  Widget _buildCustomCheckbox({
    required String value,
    required String label,
  }) {
    final isSelected = _selectedOption == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_isEditMode) {
            setState(() {
              _selectedOption = isSelected ? null : value;
            });
          }
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
            onChanged: _isEditMode ? onChanged : null,
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
            // Custom AppBar with vehicle summary
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
                        vehicleInDateFormatted, // Use vehicle in date here
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Vehicle summary and buttons
                  Row(
                    children: [
                      if (!_isEditMode) // Only show edit button when not in edit mode
                        GestureDetector(
                          onTap: _toggleEditMode,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (_isEditMode) // Done button when in edit mode
                        GestureDetector(
                          onTap: _saveData,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.done,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
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
                                          color: _isEditMode ? Colors.white : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: _isEditMode ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ] : null,
                                        ),
                                        child: DropdownButton<String>(
                                          value: _selectedYear,
                                          hint: Text('Year', style: TextStyle(color: Colors.grey[400])),
                                          isExpanded: true,
                                          underline: Container(),
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                          onChanged: _isEditMode 
                                            ? (String? newValue) {
                                                setState(() {
                                                  _selectedYear = newValue;
                                                });
                                              }
                                            : null,
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
                                          color: _isEditMode ? Colors.white : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: _isEditMode ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ] : null,
                                        ),
                                        child: DropdownButton<String>(
                                          value: _selectedVehicleType,
                                          hint: Text('Type', style: TextStyle(color: Colors.grey[400])),
                                          isExpanded: true,
                                          underline: Container(),
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                          onChanged: _isEditMode 
                                            ? (String? newValue) {
                                                setState(() {
                                                  _selectedVehicleType = newValue;
                                                });
                                              }
                                            : null,
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
                          
                          // Challan field (added)
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
                                      color: _isEditMode ? Colors.white : Colors.grey[200],
                                      boxShadow: _isEditMode ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ] : null,
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
                          
                          // RC, PUC, and NOC checkboxes
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
                                // NOC checkbox (added)
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
                          
                          // Display captured images
                          if (_capturedImages.isNotEmpty || _apiImages.isNotEmpty) ...[
                            _buildSeparator(),
                            
                            const Text(
                              'Vehicle Images',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                        if (_isEditMode)
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
                    
                    // Row with two action buttons
                    Row(
                      children: [
                        // Vehicle Out button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isEditMode ? null : _processVehicleOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Vehicle Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Generate PDF button (added)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isEditMode ? null : _generatePdf,
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
                                Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Generate PDF',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Save Changes button in edit mode
                    if (_isEditMode) ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                      ),
                    ],
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
    _challanController.dispose();
    
    _vehicleNumberFocus.dispose();
    _vehicleHpFocus.dispose();
    _chassisNumberFocus.dispose();
    _engineNumberFocus.dispose();
    _vehicleNameFocus.dispose();
    _ownerNameFocus.dispose();
    _mobileNumberFocus.dispose();
    _challanFocus.dispose();
    
    super.dispose();
  }
}