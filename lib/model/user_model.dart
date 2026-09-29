import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, manager }

enum MemberTier { bronze, silver, gold, platinum }

class UserModel {
  String id;
  String name;
  String email;
  String image;
  String phone;
  UserRole role;
  int point;
  int totalMoneySpend;
  MemberTier tier;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.image = '',
    this.phone = '',
    this.role = UserRole.customer,
    this.point = 0,
    this.totalMoneySpend = 0,
    this.tier = MemberTier.bronze,
  });

  static MemberTier tierFromSpend(int totalSpend) {
    if (totalSpend >= 5000000) return MemberTier.platinum;
    if (totalSpend >= 2000000) return MemberTier.gold;
    if (totalSpend >= 500000) return MemberTier.silver;
    return MemberTier.bronze;
  }

  static String tierName(MemberTier tier) {
    switch (tier) {
      case MemberTier.platinum: return 'Platinum';
      case MemberTier.gold:     return 'Gold';
      case MemberTier.silver:   return 'Silver';
      default:                  return 'Bronze';
    }
  }

  static int tierMinSpend(MemberTier tier) {
    switch (tier) {
      case MemberTier.platinum: return 5000000;
      case MemberTier.gold:     return 2000000;
      case MemberTier.silver:   return 500000;
      default:                  return 0;
    }
  }

  static int tierNextSpend(MemberTier tier) {
    switch (tier) {
      case MemberTier.bronze:  return 500000;
      case MemberTier.silver:  return 2000000;
      case MemberTier.gold:    return 5000000;
      default:                 return 5000000;
    }
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, _) {
    return UserModel.fromMap(snapshot.data() ?? {}, id: snapshot.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    final spend = data['total_money_spend'] ?? 0;
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      image: data['image'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] == 'manager' ? UserRole.manager : UserRole.customer,
      point: data['point'] ?? 0,
      totalMoneySpend: spend,
      tier: tierFromSpend(spend),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'image': image,
    'phone': phone,
    'role': role == UserRole.manager ? 'manager' : 'customer',
    'point': point,
    'total_money_spend': totalMoneySpend,
  };
}
