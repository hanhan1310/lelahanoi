class VoucherModel {
  final String title;
  final String description;
  final int requiredSpend;
  final String tier;
  final int discountPercent;

  const VoucherModel({
    required this.title,
    required this.description,
    required this.requiredSpend,
    required this.tier,
    required this.discountPercent,
  });

  static const List<VoucherModel> all = [
    VoucherModel(title: 'Free Espresso', description: 'Tặng 1 ly Espresso', requiredSpend: 500000, tier: 'Silver', discountPercent: 0),
    VoucherModel(title: '10% Off', description: 'Giảm 10% cho đơn tiếp theo', requiredSpend: 2000000, tier: 'Gold', discountPercent: 10),
    VoucherModel(title: '20% Off', description: 'Giảm 20% cho đơn tiếp theo', requiredSpend: 5000000, tier: 'Platinum', discountPercent: 20),
    VoucherModel(title: 'Free Cookie Box', description: 'Tặng hộp bánh cookies', requiredSpend: 2000000, tier: 'Gold', discountPercent: 0),
    VoucherModel(title: 'Free Delivery', description: 'Miễn phí ship 1 lần', requiredSpend: 500000, tier: 'Silver', discountPercent: 0),
  ];

  static List<VoucherModel> forTier(String tier) {
    const order = ['Bronze', 'Silver', 'Gold', 'Platinum'];
    final idx = order.indexOf(tier);
    return all.where((v) => order.indexOf(v.tier) <= idx).toList();
  }
}
