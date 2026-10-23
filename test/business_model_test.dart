import 'package:flutter_test/flutter_test.dart';
import 'package:popup_deals_app/features/business/data/models/business.dart';

Map<String, dynamic> _baseJson({Object? status, Object? isVerified}) => {
      'id': 'biz_1',
      'name': 'Pizza Place',
      'email': 'biz@example.com',
      'phoneNumber': '+995500000000',
      'description': 'Best pizza in town',
      'address': '12 Rustaveli Ave',
      'latitude': 41.7,
      'longitude': 44.8,
      'category': 'food',
      'createdAt': DateTime(2026).toIso8601String(),
      if (status != null) 'status': status,
      if (isVerified != null) 'isVerified': isVerified,
    };

void main() {
  group('BusinessModel status state machine', () {
    test('defaults to pending when no status or isVerified present', () {
      final biz = BusinessModel.fromJson(_baseJson());
      expect(biz.status, 'pending');
      expect(biz.isPending, isTrue);
      expect(biz.isApproved, isFalse);
      expect(biz.isVerified, isFalse);
    });

    test('reads status directly when present', () {
      final biz = BusinessModel.fromJson(_baseJson(status: 'suspended'));
      expect(biz.isSuspended, isTrue);
      expect(biz.isVerified, isFalse);
    });

    test('isVerified getter is true only when status is approved', () {
      for (final status in ['pending', 'rejected', 'suspended']) {
        final biz = BusinessModel.fromJson(_baseJson(status: status));
        expect(biz.isVerified, isFalse, reason: 'status=$status');
      }
      final approved = BusinessModel.fromJson(_baseJson(status: 'approved'));
      expect(approved.isVerified, isTrue);
    });

    test('backward compat: old isVerified:true documents map to approved', () {
      final biz = BusinessModel.fromJson(_baseJson(isVerified: true));
      expect(biz.status, 'approved');
      expect(biz.isApproved, isTrue);
    });

    test('backward compat: old isVerified:false documents map to pending', () {
      final biz = BusinessModel.fromJson(_baseJson(isVerified: false));
      expect(biz.status, 'pending');
    });

    test('explicit status takes precedence over legacy isVerified', () {
      final biz = BusinessModel.fromJson(
          _baseJson(status: 'rejected', isVerified: true));
      expect(biz.status, 'rejected');
    });
  });

  group('BusinessModel JSON round-trip', () {
    test('toJson/fromJson preserves status', () {
      final original = BusinessModel.fromJson(_baseJson(status: 'approved'));
      final restored = BusinessModel.fromJson(original.toJson());
      expect(restored.status, 'approved');
      expect(restored, original);
    });

    test('copyWith updates status independently of other fields', () {
      final original = BusinessModel.fromJson(_baseJson(status: 'pending'));
      final approved = original.copyWith(status: 'approved');
      expect(approved.status, 'approved');
      expect(approved.name, original.name);
    });
  });
}
