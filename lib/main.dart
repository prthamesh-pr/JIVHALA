import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dashboard.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if user is already logged in
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final username = prefs.getString('username') ?? '';
  runApp(MyApp(isLoggedIn: isLoggedIn, username: username));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String username;
  
  const MyApp({super.key, required this.isLoggedIn, required this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jivhala Motors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: isLoggedIn ? DashboardPage(username: username) : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  int _retryCount = 0;
  final int _maxRetries = 2;
  
  // API URL configuration with platform detection
  String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000'; // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:5000'; // iOS simulator
    } else {
      // For physical devices, you might want to set this manually
      return 'http://192.168.1.100:5000'; // Replace with your actual IP
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check network connectivity
  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Improved server reachability check
  Future<bool> _isServerReachable() async {
    try {
      // First try a direct HTTP connection
      print('Checking server reachability at: $_baseUrl/api/auth/login');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Accept': 'application/json'}
      ).timeout(const Duration(seconds: 5));
      
      print('Server reachability check: ${response.statusCode}');
      return response.statusCode < 500; // Consider any non-server error as reachable
    } on SocketException catch (e) {
      print('Socket connection failed: $e');
      return false;
    } on TimeoutException catch (e) {
      print('Connection timed out: $e');
      
      // Try an alternative URL if the primary one fails
      try {
        // For Android emulator, try a different approach
        if (Platform.isAndroid) {
          final alternativeUrl = 'http://localhost:5000';
          print('Trying alternative URL: $alternativeUrl/api/auth/login');
          
          final response = await http.get(
            Uri.parse('$alternativeUrl/api/auth/login'),
            headers: {'Accept': 'application/json'}
          ).timeout(const Duration(seconds: 5));
          
          print('Alternative server check: ${response.statusCode}');
          return response.statusCode < 500;
        }
      } catch (e) {
        print('Alternative connection also failed: $e');
      }
      
      return false;
    } catch (e) {
      print('Server reachability error: $e');
      return false;
    }
  }

  Future<bool> _authenticate(String username, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // First check network connectivity
    bool hasNetwork = await _checkConnectivity();
    if (!hasNetwork) {
      setState(() {
        _errorMessage = 'No internet connection. Please check your network.';
        _isLoading = false;
      });
      return false;
    }

    // Then check if server is reachable
    bool isServerUp = await _isServerReachable();
    if (!isServerUp) {
      setState(() {
        _errorMessage = 'Cannot reach server. Please check if the server is running.';
        _isLoading = false;
      });
      return false;
    }

    try {
      final loginUrl = '$_baseUrl/api/auth/login';
      
      print('Connecting to API: $loginUrl');
      
      // Prepare request body
      final requestBody = json.encode({
        'username': username,
        'password': password,
      });
      
      // Make the API request
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 10));
      
      print('API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response
        final dynamic data = json.decode(response.body);
        print('API Response Body: $data');
        
        // Extract token from response
        final String? token = data['token'] as String?;
        
        if (token != null) {
          print('Token received from API');
          
          // Save token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('username', username);
          
          // Also store user data if available
          if (data is Map && data['user'] is Map) {
            final userData = json.encode(data['user']);
            await prefs.setString('userData', userData);
          }
          
          setState(() {
            _isLoading = false;
          });
          return true;
        } else {
          setState(() {
            _errorMessage = 'Authentication failed: Invalid response format';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Invalid username or password';
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'API endpoint not found. Please check server configuration.';
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
      print('Authentication error: $e');
      
      // Implement retry logic for connection issues
      if (_retryCount < _maxRetries) {
        _retryCount++;
        print('Retrying connection, attempt $_retryCount of $_maxRetries');
        await Future.delayed(Duration(seconds: 1));
        return _authenticate(username, password);
      }
      
      // Reset retry count after exhausting retries
      _retryCount = 0;
      
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
      return false;
    }
  }

  void _login() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Basic validation
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Username and password cannot be empty';
      });
      return;
    }
    
    // Reset retry count before attempting login
    _retryCount = 0;
    
    // Authenticate with the backend
    bool success = await _authenticate(
      _usernameController.text, 
      _passwordController.text
    );
      
    if (success) {
      // Navigate to dashboard on successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            username: _usernameController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 100),
                Text(
                  'Welcome to',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF626363),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'JIVHALA MOTORS',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Logo placeholder
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Image.asset(
                    'assets/logo/logo1.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF626363),
                  ),
                ),
                const SizedBox(height: 20),
                // Username field with controller
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your username',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Password field with controller
                TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
                // Display error message if any
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                // Login button with authentication
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD9D9D9),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'LOGIN',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 80),
                // Footer
                // Text(
                //   'Designed and developed by',
                //   style: GoogleFonts.poppins(
                //     fontSize: 12,
                //     color: Colors.grey[600],
                //   ),
                // ),
                // const SizedBox(height: 8),
                // SizedBox(
                //   height: 40,
                //   width: 100,   
                //   child: Image.asset(
                //     'assets/logo/Group 1.png',
                //     fit: BoxFit.contain,
                //   ),
                // ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}