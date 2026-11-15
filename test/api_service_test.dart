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

    test('registerCitizen registers online and falls back offline', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health/') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (request.url.path == '/api/auth/register/') {
          return http.Response(
            jsonEncode({
              'token': 'reg-token-xyz',
              'user': {
                'id': 99,
                'name': 'Live Citizen',
                'email': 'live@citizen.pk',
                'phone': '03001234567',
                'role': 'citizen',
                'is_active': true,
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final onlineService = ApiService(
        baseUrl: 'http://test-server:8000',
        client: mockClient,
      );
      final onlineRes = await onlineService.registerCitizen(
        name: 'Live Citizen',
        email: 'live@citizen.pk',
        password: 'Password123',
        phone: '03001234567',
        mockRepo: mockRepo,
      );
      expect(onlineRes.isSuccess, isTrue);
      expect(onlineRes.isFromFallback, isFalse);
      expect(onlineRes.data?.email, 'live@citizen.pk');

      // Offline fallback
      final offlineClient = MockClient((request) async {
        throw Exception('Network unreachable');
      });
      final offlineService = ApiService(
        baseUrl: 'http://offline-server:8000',
        client: offlineClient,
      );
      final offlineRes = await offlineService.registerCitizen(
        name: 'Offline Citizen',
        email: 'offline@citizen.pk',
        password: 'Password123',
        phone: '03009999999',
        mockRepo: mockRepo,
      );
      expect(offlineRes.isSuccess, isTrue);
      expect(offlineRes.isFromFallback, isTrue);
      expect(offlineRes.data?.email, 'offline@citizen.pk');
    });

    test('getMe and updateProfile manage user profile', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health/') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (request.url.path == '/api/auth/me/') {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'id': 10,
                'name': 'Original User',
                'email': 'user@resq.pk',
                'phone': '03001112223',
                'role': 'citizen',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else if (request.method == 'PATCH') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'id': 10,
                'name': body['name'],
                'email': 'user@resq.pk',
                'phone': body['phone'],
                'role': 'citizen',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://test-server:8000',
        client: mockClient,
      );

      final meRes = await apiService.getMe(mockRepo: mockRepo);
      expect(meRes.isSuccess, isTrue);
      expect(meRes.data?.name, 'Original User');

      final updateRes = await apiService.updateProfile(
        name: 'Updated User',
        phone: '03112223334',
        mockRepo: mockRepo,
      );
      expect(updateRes.isSuccess, isTrue);
      expect(updateRes.data?.name, 'Updated User');
      expect(updateRes.data?.phone, '03112223334');
    });

    test('getUsers and createStaffAccount manage operational staff', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health/') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (request.url.path == '/api/users/') {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                {
                  'id': 1,
                  'name': 'Dispatcher One',
                  'email': 'd1@resq.pk',
                  'phone': '03001234567',
                  'role': 'dispatcher',
                  'is_active': true,
                },
                {
                  'id': 2,
                  'name': 'Demo Citizen',
                  'email': 'citizen@resq.com',
                  'phone': '03001234567',
                  'role': 'citizen',
                  'is_active': true,
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else if (request.method == 'POST') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'id': 88,
                'name': body['name'],
                'email': body['email'],
                'phone': body['phone'],
                'role': body['role'],
                'is_active': true,
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://test-server:8000',
        client: mockClient,
      );

      // Verify getUsers filters out Demo Citizen
      final usersRes = await apiService.getUsers(mockRepo: mockRepo);
      expect(usersRes.isSuccess, isTrue);
      expect(usersRes.data?.length, 1);
      expect(usersRes.data?.first.name, 'Dispatcher One');

      // Verify createStaffAccount
      final staffRes = await apiService.createStaffAccount(
        name: 'Driver New',
        email: 'driver.new@resq.pk',
        password: 'Password123',
        role: 'driver',
        phone: '03331112233',
        mockRepo: mockRepo,
      );
      expect(staffRes.isSuccess, isTrue);
      expect(staffRes.data?.role, 'driver');
      expect(staffRes.data?.name, 'Driver New');
    });

    test('getResources and getRoute fetch operational logistics', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health/') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (request.url.path == '/api/resources/') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'name': 'Trauma Kit',
                'category': 'Medical',
                'quantity': 5,
                'unit': 'kits',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/route/') {
          return http.Response(
            jsonEncode({
              'total_time': 6.2,
              'distance_km': 3.1,
              'route_coords': [
                [24.8607, 67.0011],
                [24.8720, 67.0104],
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

      final resRes = await apiService.getResources(mockRepo: mockRepo);
      expect(resRes.isSuccess, isTrue);
      expect(resRes.data?.first.name, 'Trauma Kit');

      final routeRes = await apiService.getRoute(
        from: const LatLng(24.8607, 67.0011),
        to: const LatLng(24.8720, 67.0104),
        mockRepo: mockRepo,
      );
      expect(routeRes.isSuccess, isTrue);
      expect(routeRes.data?['total_time'], 6.2);
    });

    test('updateEmergencyStatus, getDriverMission, and getNotifications', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health/') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (request.url.path == '/api/emergencies/1/status/') {
          return http.Response(jsonEncode({'status': 'EN_ROUTE'}), 200);
        }
        if (request.url.path == '/api/driver/mission/') {
          return http.Response(
            jsonEncode({
              'mission': {'id': 101, 'status': 'ACTIVE'},
            }),
            200,
          );
        }
        if (request.url.path == '/api/notifications/') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'title': 'Emergency Alert',
                'message': 'New report nearby',
                'is_read': false,
                'target_role': 'citizen',
              },
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://test-server:8000',
        client: mockClient,
      );

      final statusRes = await apiService.updateEmergencyStatus(
        emergencyId: 'EM-1',
        status: 'EN_ROUTE',
        mockRepo: mockRepo,
      );
      expect(statusRes.isSuccess, isTrue);

      final missionRes = await apiService.getDriverMission(mockRepo: mockRepo);
      expect(missionRes.isSuccess, isTrue);
      expect(missionRes.data?['mission']['id'], 101);

      final notifRes = await apiService.getNotifications(mockRepo: mockRepo);
      expect(notifRes.isSuccess, isTrue);
      expect(notifRes.data?.first.title, 'Emergency Alert');
    });
  });
}
