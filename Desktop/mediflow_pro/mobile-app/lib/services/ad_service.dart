import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/ad.dart';
import 'auth_service.dart';
import 'api_service.dart';

class AdService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8000/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static Future<List<Ad>> getAds({String? clinicId}) async {
    try {
      final token = AuthService.authToken;
      
      if (token == null) {
        // Fallback to test ads if not authenticated
        print('⚠️ No auth token, using test ads');
        return _getTestAds();
      }

      final headers = AuthService.getAuthHeaders();
      
      final queryParams = <String, dynamic>{};
      if (clinicId != null && clinicId.isNotEmpty) {
        queryParams['clinic_id'] = clinicId;
      }

      final response = await ApiService.get(
        '/ads',
        queryParameters: queryParams,
        headers: headers,
      );

      if (response != null) {
        final List<dynamic> adsJson = response.data;
        return adsJson.map((json) => Ad.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching ads: $e');
      // Fallback to test ads on error
      return _getTestAds();
    }
  }

  // NEW: Test ads for demonstration
  static List<Ad> getTestAds() {
    return [
      Ad(
        id: 'test1',
        title: 'Special Consultation Offer - 20% OFF',
        imageUrl: '', // Empty to test placeholder
        localAssetPath: 'assets/ads/sample_ad.svg', // Local asset
        adType: 'banner',
        isActive: true,
        priority: 10,
      ),
      Ad(
        id: 'test2',
        title: 'New Diagnostic Equipment Available',
        imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400&h=120&fit=crop', // Network image
        adType: 'banner',
        isActive: true,
        priority: 5,
      ),
      Ad(
        id: 'test3',
        title: 'Free Health Checkup Camp This Weekend',
        imageUrl: '', // Will show placeholder
        adType: 'banner',
        isActive: true,
        priority: 3,
      ),
    ];
  }

  // Deprecated: Use getTestAds() instead
  static List<Ad> _getTestAds() => getTestAds();

  static Future<Ad> createAd(Ad ad) async {
    try {
      final token = AuthService.authToken;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final headers = AuthService.getAuthHeaders();
      
      final response = await ApiService.post(
        '/ads',
        ad.toJson(),
        headers: headers,
      );

      if (response != null && response.data != null) {
        return Ad.fromJson(response.data);
      }
      
      throw Exception('Failed to create ad');
    } catch (e) {
      print('Error creating ad: $e');
      rethrow;
    }
  }

  static Future<Ad> updateAd(String adId, Ad ad) async {
    try {
      final token = AuthService.authToken;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final headers = AuthService.getAuthHeaders();
      
      final response = await ApiService.put(
        '/ads/$adId',
        ad.toJson(),
        headers: headers,
      );

      if (response != null && response.data != null) {
        return Ad.fromJson(response.data);
      }
      
      throw Exception('Failed to update ad');
    } catch (e) {
      print('Error updating ad: $e');
      rethrow;
    }
  }

  static Future<void> deleteAd(String adId) async {
    try {
      final token = AuthService.authToken;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final headers = AuthService.getAuthHeaders();
      
      final response = await ApiService.delete(
        '/ads/$adId',
        headers: headers,
      );

      if (response == null) {
        throw Exception('Failed to delete ad');
      }
    } catch (e) {
      print('Error deleting ad: $e');
      rethrow;
    }
  }

  // Mock ad data for demonstration
  static final List<String> _bannerAds = [
    'Special Offer: 20% off on medical consultations',
    'New: Advanced diagnostic equipment available',
    'Free health checkup for first-time patients',
    'Book your appointment online and save time',
    'Emergency services available 24/7',
  ];

  static final List<String> _floatingAds = [
    'Download our app for better experience',
    'Refer a friend and get discount',
    'Latest health tips and advice',
    'New treatment options available',
    'Book appointment through WhatsApp',
  ];

  static String getRandomBannerAd() {
    if (_bannerAds.isEmpty) return 'Ad space available';
    final random = UniqueKey().hashCode % _bannerAds.length;
    return _bannerAds[random.abs()];
  }

  static String getRandomFloatingAd() {
    if (_floatingAds.isEmpty) return 'Ad space available';
    final random = UniqueKey().hashCode % _floatingAds.length;
    return _floatingAds[random.abs()];
  }

  static Widget buildBannerAd() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.lightBlue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'AD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              getRandomBannerAd(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  static Widget buildFloatingAd() {
    return Container(
      width: 250,
      height: 100,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PROMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Special Offer!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              getRandomFloatingAd(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildInterstitialAd() {
    return Container(
      width: 300,
      height: 200,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Advertisement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            getRandomBannerAd(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Learn More',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}