import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/api_service.dart';

void main() {
  group('ApiService - Online Mode Tests', () {
    late MockRepository mockRepo;

    setUp(() {
      mockRepo = MockRepository();
    });

    test(
      'checkHealth returns true when backend responds with HTTP 200',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/health/') {
            return http.Response(
              jsonEncode({'status': 'ok', 'road_nodes': 900, 'vehicles': 5}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiService = ApiService(
          baseUrl: 'http://test-server:8000',
          client: mockClient,
        );

        final isHealthy = await apiService.checkHealth();
        expect(isHealthy, isTrue);
        expect(apiService.isBackendReachable, isTrue);
      },
    );

    test(
      'login authenticates with Django REST backend and stores auth token',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/health/') {
            return http.Response(jsonEncode({'status': 'ok'}), 200);
          }
          if (request.url.path == '/api/auth/login/') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['email'], 'citizen@resq.com');
            return http.Response(
              jsonEncode({
                'token': 'auth-token-test-12345',
                'role': 'citizen',
                'user': {
                  'id': 1,
                  'name': 'Demo Citizen',
                  'email': 'citizen@resq.com',
                  'role': 'citizen',
                  'phone': '+92 300 1234567',
                  'is_active': true,
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiService = ApiService(
          baseUrl: 'http://test-server:8000',
          client: mockClient,
        );

        final response = await apiService.login(
          'citizen@resq.com',
          'Citizen123',
          mockRepo: mockRepo,
        );

        expect(response.isSuccess, isTrue);
        expect(response.isFromFallback, isFalse);
        expect(response.statusCode, 200);
        expect(response.data?.email, 'citizen@resq.com');
        expect(response.data?.name, 'Demo Citizen');
        expect(apiService.authToken, 'auth-token-test-12345');
      },
    );

    test('getVehicles returns vehicles list from live backend', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health/') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (request.url.path == '/api/vehicles/') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'call_sign': 'KHI-1122-AMB',
                'license_plate': 'KHI-1122-AMB',
                'vehicle_type': 'Ambulance',
                'status': 'Available',
                'latitude': 24.8720,
                'longitude': 67.0104,
                'driver_name': 'Captain Tariq',
              },
              {
                'id': 2,
                'call_sign': 'KHI-FIRE-077',
                'license_plate': 'KHI-FIRE-077',
                'vehicle_type': 'Fire Brigade',
                'status': 'Available',
                'latitude': 24.8550,
                'longitude': 66.9987,
                'driver_name': 'Sgt. Farooq',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://test-server:8000',
        client: mockClient,
      );

      final response = await apiService.getVehicles(mockRepo: mockRepo);
      expect(response.isSuccess, isTrue);
      expect(response.isFromFallback, isFalse);
      expect(response.data?.length, 2);
      expect(response.data?.first.licensePlate, 'KHI-1122-AMB');
      expect(response.data?.first.driverName, 'Captain Tariq');
    });

    test(
      'reportEmergency posts emergency and parses created response',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/health/') {
            return http.Response(jsonEncode({'status': 'ok'}), 200);
          }
          if (request.url.path == '/api/emergencies/') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['category'], 'ACCIDENT');
            return http.Response(
              jsonEncode({
                'id': 42,
                'code': 'EM-2026-0042',
                'category': 'ACCIDENT',
                'description': 'Crash at Nursery',
                'severity': 4,
                'urgency': 5,
                'people_affected': 2,
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiService = ApiService(
          baseUrl: 'http://test-server:8000',
          client: mockClient,
        );

        final response = await apiService.reportEmergency(
          category: 'Accident',
          severity: 4,
          urgency: 5,
          peopleAffected: 2,
          description: 'Crash at Nursery',
          location: const LatLng(24.8640, 67.0650),
          locationLabel: 'Nursery Flyover',
          userId: 'USR-1',
          mockRepo: mockRepo,
        );

        expect(response.isSuccess, isTrue);
        expect(response.isFromFallback, isFalse);
        expect(response.statusCode, 201);
        expect(response.data?.id, 'EM-2026-0042');
        expect(response.data?.category, 'Accident');
      },
    );

    test(
      'triggerAllocation runs Knapsack optimization and returns assignments',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/health/') {
            return http.Response(jsonEncode({'status': 'ok'}), 200);
          }
          if (request.url.path == '/api/allocate/') {
            return http.Response(
              jsonEncode({
                'id': 10,
                'assignments': [
                  {'vehicle_id': 1, 'emergency_id': 42, 'score': 95.5},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiService = ApiService(
          baseUrl: 'http://test-server:8000',
          client: mockClient,
        );

        final response = await apiService.triggerAllocation();
        expect(response.isSuccess, isTrue);
        expect(response.isFromFallback, isFalse);
        expect(response.data?['assignments'], isNotEmpty);
      },
    );
  });

  group('ApiService - Offline Fallback Tests', () {
    late MockRepository mockRepo;

    setUp(() {
      mockRepo = MockRepository();
    });

    test('checkHealth returns false when network throws exception', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Connection refused');
      });

      final apiService = ApiService(
        baseUrl: 'http://offline-server:8000',
        client: mockClient,
      );

      final isHealthy = await apiService.checkHealth(
        timeout: const Duration(milliseconds: 50),
      );
      expect(isHealthy, isFalse);
      expect(apiService.isBackendReachable, isFalse);
    });

    test(
      'login falls back to MockRepository when backend is unreachable',
      () async {
        final mockClient = MockClient((request) async {
          throw Exception('Network unreachable');
        });

        final apiService = ApiService(
          baseUrl: 'http://offline-server:8000',
          client: mockClient,
        );

        final response = await apiService.login(
          'citizen@resq.com',
          'Citizen123',
          mockRepo: mockRepo,
        );

        expect(response.isSuccess, isTrue);
        expect(response.isFromFallback, isTrue);
        expect(response.data?.email, 'citizen@resq.com');
        expect(response.data?.role, 'citizen');
      },
    );

    test(
      'login with invalid credentials in offline mode returns error',
      () async {
        final mockClient = MockClient((request) async {
          throw Exception('Network unreachable');
        });

        final apiService = ApiService(
          baseUrl: 'http://offline-server:8000',
          client: mockClient,
        );

        final response = await apiService.login(
          'wrong@resq.com',
          'WrongPassword',
          mockRepo: mockRepo,
        );

        expect(response.isSuccess, isFalse);
        expect(response.isFromFallback, isTrue);
        expect(response.error, isNotNull);
      },
    );

    test(
      'getVehicles returns mockRepo vehicles when backend is unreachable',
      () async {
        final mockClient = MockClient((request) async {
          throw Exception('Network unreachable');
        });

        final apiService = ApiService(
          baseUrl: 'http://offline-server:8000',
          client: mockClient,
        );

        final response = await apiService.getVehicles(mockRepo: mockRepo);
        expect(response.isSuccess, isTrue);
        expect(response.isFromFallback, isTrue);
        expect(response.data?.length, mockRepo.vehicles.length);
      },
    );

    test('reportEmergency saves to mockRepo when backend is offline', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network unreachable');
      });

      final apiService = ApiService(
        baseUrl: 'http://offline-server:8000',
        client: mockClient,
      );

      final initialCount = mockRepo.emergencies.length;

      final response = await apiService.reportEmergency(
        category: 'Fire',
        severity: 5,
        urgency: 4,
        peopleAffected: 6,
        description: 'Building fire in Saddar',
        location: const LatLng(24.8607, 67.0011),
        locationLabel: 'Saddar Bazaar',
        userId: 'USR-CITIZEN-01',
        mockRepo: mockRepo,
      );

      expect(response.isSuccess, isTrue);
      expect(response.isFromFallback, isTrue);
      expect(mockRepo.emergencies.length, initialCount + 1);
      expect(response.data?.description, 'Building fire in Saddar');
    });

    test('triggerAllocation returns fallback error when offline', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network unreachable');
      });

      final apiService = ApiService(
        baseUrl: 'http://offline-server:8000',
        client: mockClient,
      );

      final response = await apiService.triggerAllocation();
      expect(response.isSuccess, isFalse);
      expect(response.isFromFallback, isTrue);
      expect(response.error, contains('offline'));
    });
  });
}
