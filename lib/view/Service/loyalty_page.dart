import 'package:flutter/material.dart';
import 'package:lelahanoi/model/voucher_model.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:lelahanoi/utils/auth_service.dart';
import 'package:provider/provider.dart';

import '../../model/user_model.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> {
  final Color _bgMint = const Color(0xFFB4D3B6);
  final Color _primaryTeal = const Color(0xFF719B75);
  final Color _darkTeal = const Color(0xFF2A635F);

  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    _user = await AuthService.getUserModel();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().strings;
    final user = _user;
    final tier = UserModel.tierFromSpend(user?.totalMoneySpend ?? 0);
    final tierName = UserModel.tierName(tier);
    final nextSpend = UserModel.tierNextSpend(tier);
    final progressValue = nextSpend == 0 ? 1.0 : ((user?.totalMoneySpend ?? 0) / nextSpend).clamp(0.0, 1.0);
    final vouchers = VoucherModel.forTier(tierName);

    return Scaffold(
      backgroundColor: _bgMint,
      appBar: AppBar(
        title: Text(t.loyaltyCard, style: const TextStyle(fontWeight: FontWeight.w400)),
        backgroundColor: _bgMint,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLoyaltyCard(user, tierName, t),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.memberStatus, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                        Text(tierName, style: TextStyle(color: _primaryTeal, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 10,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryTeal),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nextSpend <= 0
                          ? t.noData
                          : "${_formatCurrency(nextSpend - (user?.totalMoneySpend ?? 0))}đ",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      t.rewardsAvailable,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryTeal),
                    ),
                    const SizedBox(height: 15),
                    if (vouchers.isEmpty)
                      _buildEmptyReward(t)
                    else
                      ...vouchers.map((voucher) => _buildRewardItem(voucher)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoyaltyCard(UserModel? user, String tierName, dynamic t) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryTeal, _darkTeal],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _darkTeal.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Le La Hanoi", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text("Loyalty Card",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Icon(Icons.qr_code_2, color: Colors.white.withOpacity(0.8), size: 40),
              ],
            ),
            Center(
              child: Text(
                "${user?.point ?? 0}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            Center(child: Text(t.points, style: const TextStyle(color: Colors.white70))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(user?.name ?? "Customer", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(tierName, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(VoucherModel voucher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgMint.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.card_giftcard, color: _primaryTeal, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(voucher.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  voucher.description,
                  style: TextStyle(color: _primaryTeal, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(voucher.discountPercent > 0 ? "-${voucher.discountPercent}%" : "Gift",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyReward(dynamic t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(t.noData),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
