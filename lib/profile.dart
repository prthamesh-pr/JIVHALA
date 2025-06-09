import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Add these imports for API integration
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController(
    text: 'Admin User',
  );
  final TextEditingController _usernameController = TextEditingController(
    text: 'admin',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'admin123',
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ========== API INTEGRATION FOR USER PROFILE ==========
  
  /* 
  // UNCOMMENT THIS SECTION TO USE API FOR FETCHING USER PROFILE
  // REQUIREMENTS:
  // 1. Add http package to pubspec.yaml: http: ^1.1.0
  // 2. Replace API_BASE_URL with your actual API endpoint
  // 3. Ensure your backend returns user data in expected format
  // 4. Add proper token handling for authenticated requests

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    // Get auth token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId'); // If your API requires user ID
    
    // Replace with your actual API endpoint
    final String apiUrl = 'https://your-api-endpoint.com/api/users/profile';
    // OR if your API requires user ID in the URL:
    // final String apiUrl = 'https://your-api-endpoint.com/api/users/$userId';
    
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add auth token if required
        },
      );
      
      // Debug API response (remove in production)
      print('API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Adjust this based on your API's response structure
        if (data['success'] == true) {
          return data['user'] ?? data; // Return user data
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load profile';
          });
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid - handle authentication error
        setState(() {
          _errorMessage = 'Authentication error';
        });
        // You might want to redirect to login screen
        _logout();
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
      
      return null;
    } catch (e) {
      print('Profile fetch error: $e');
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
      return null;
    }
  }
  
  // UNCOMMENT THIS SECTION TO USE API FOR UPDATING USER PROFILE
  Future<bool> _updateUserProfile(String name, String username, String password) async {
    // Get auth token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId'); // If your API requires user ID
    
    // Replace with your actual API endpoint
    final String apiUrl = 'https://your-api-endpoint.com/api/users/profile';
    // OR if your API requires user ID in the URL:
    // final String apiUrl = 'https://your-api-endpoint.com/api/users/$userId';
    
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add auth token if required
        },
        body: jsonEncode({
          'name': name,
          'username': username,
          'password': password,
          // Add any additional fields your API requires
        }),
      );
      
      // Debug API response (remove in production)
      print('API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Adjust this based on your API's response structure
        if (data['success'] == true) {
          // Update local storage with new values
          await prefs.setString('username', username);
          // Don't store password in production!
          await prefs.setString('password', password);
          
          // If API returns a new token, update it
          if (data['token'] != null) {
            await prefs.setString('token', data['token']);
          }
          
          return true;
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to update profile';
          });
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid - handle authentication error
        setState(() {
          _errorMessage = 'Authentication error';
        });
        // You might want to redirect to login screen
        _logout();
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
      
      return false;
    } catch (e) {
      print('Profile update error: $e');
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
      return false;
    }
  }
  */

  // CURRENT METHOD - Using SharedPreferences (Replace with API when ready)
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'admin';
    final password = prefs.getString('password') ?? 'admin123';
    
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      // You can also load the name if you store it during login
      _nameController.text = prefs.getString('name') ?? 'Admin User'; // Default name for admin
    });
    
    /* 
    // UNCOMMENT THIS SECTION TO USE API FOR LOADING USER DATA
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final userData = await _fetchUserProfile();
    
    if (userData != null) {
      setState(() {
        // Adjust these field names based on your API response structure
        _nameController.text = userData['name'] ?? 'Admin User';
        _usernameController.text = userData['username'] ?? username;
        _passwordController.text = password; // API should not return password
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        // Keep the SharedPreferences data as fallback
      });
    }
    */
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // CURRENT METHOD - Using SharedPreferences (Replace with API when ready)
  void _saveProfile() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 800));
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('name', _nameController.text);
    
    /* 
    // UNCOMMENT THIS SECTION TO USE API FOR SAVING PROFILE
    final success = await _updateUserProfile(
      _nameController.text,
      _usernameController.text,
      _passwordController.text,
    );
    
    if (!success) {
      setState(() {
        _isLoading = false;
        // _errorMessage should already be set by _updateUserProfile
      });
      return;
    }
    */
    
    // Update UI state
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  void _logout() async {
    // Clear login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('name');
    await prefs.remove('token'); // Also remove API token if you're using one
    
    /* 
    // UNCOMMENT THIS SECTION TO USE API FOR LOGOUT
    // If your API has a logout endpoint
    try {
      final token = prefs.getString('token');
      final String apiUrl = 'https://your-api-endpoint.com/api/logout';
      
      await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      // Clear token and other data regardless of API response
      await prefs.remove('token');
      await prefs.remove('userId');
    } catch (e) {
      print('Logout API error: $e');
      // Continue with local logout even if API call fails
    }
    */
    
    // Navigate to login page and remove all routes from stack
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo
            Image.asset('assets/logo/logo1.png', height: 40, width: 40),
            const SizedBox(width: 12),
            // App title
            Text(
              'Jivhala Motors',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          // Close button
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.close, color: Colors.black, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.grey[800],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile image
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Image.asset(
                        'assets/logo/Rectangle.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Error message if any
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                    // Profile details container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name field
                          Text(
                            'Name',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            enabled: _isEditing,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFE5E5E5),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA1A1A1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA1A1A1),
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA1A1A1),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Username field
                          Text(
                            'Username',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            enabled: _isEditing,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFE5E5E5),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA1A1A1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA1A1A1),
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA1A1A1),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password field
                          Text(
                            'Password',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            enabled: _isEditing,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFE5E5E5),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA1A1A1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA1A1A1),
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA1A1A1),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Update/Save button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading 
                                ? null 
                                : (_isEditing ? _saveProfile : _toggleEditMode),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD9D9D9),
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black54,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    _isEditing ? 'SAVE' : 'UPDATE',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Logout button
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[700],
                          disabledBackgroundColor: Colors.red[50]?.withOpacity(0.5),
                          disabledForegroundColor: Colors.red[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'LOGOUT',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}