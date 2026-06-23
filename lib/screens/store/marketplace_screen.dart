import 'package:flutter/material.dart';

import '../../data/dto.dart';
import '../../data/repositories.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';

/// The XP marketplace — spend earned XP on avatars, map styles, themes, profile
/// effects, boosts and premium time. Non-physical, all in-app perks.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  MarketplaceData? _data;
  bool _loading = true;
  String _cat = 'All';

  static const _cats = [
    ['All', '🛍'],
    ['Avatar', '🧑‍🚀'],
    ['MapStyle', '🗺'],
    ['Theme', '🎨'],
    ['Effect', '✨'],
    ['Boost', '🚀'],
    ['Premium', '👑'],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await Repos.marketplace.list();
      if (mounted) setState(() => _data = d);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy(StoreProduct p) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuySheet(product: p),
    );
    if (ok != true) return;
    final res = await AppState.instance.buyProduct(p.id);
    if (!mounted) return;
    if (res != null && res.success) {
      showSnack(context, '🎉 ${res.message}', type: SnackType.success);
      _load();
    } else {
      showSnack(context, res?.message ?? 'Purchase failed',
          type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final balance = _data?.xpBalance ?? AppState.instance.xpBalance;
    final products = (_data?.products ?? [])
        .where((p) => _cat == 'All' || p.category == _cat)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.sBg,
      body: Column(
        children: [
          // Header with balance
          Container(
            padding: EdgeInsets.fromLTRB(Insets.x5, topPad + 12, Insets.x5, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A1F5E), Color(0xFF14131F)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SquareIconButton(Icons.arrow_back,
                        bg: const Color(0x33000000),
                        onTap: () => Navigator.of(context).pop()),
                    const Spacer(),
                    Text('Marketplace', style: AppText.h2),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 16),
                _BalanceCard(balance: balance),
              ],
            ),
          ),
          // Category chips
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(Insets.x5, 8, Insets.x5, 4),
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _cats[i];
                final on = _cat == c[0];
                return GestureDetector(
                  onTap: () => setState(() => _cat = c[0]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: on ? AppColors.grad : null,
                      color: on ? null : AppColors.sFill(0.06),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: on
                              ? Colors.transparent
                              : AppColors.borderSubtle),
                    ),
                    child: Text('${c[1]}  ${_label(c[0])}',
                        style: AppText.caption.copyWith(
                            color: on ? Colors.white : AppColors.sText2,
                            fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          Insets.x5, 12, Insets.x5, 120),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) =>
                          _ProductCard(product: products[i], onBuy: () => _buy(products[i])),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _label(String cat) => switch (cat) {
        'MapStyle' => 'Map',
        _ => cat,
      };
}

class _BalanceCard extends StatelessWidget {
  final int balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.gold.withValues(alpha: 0.22),
          AppColors.brand500.withValues(alpha: 0.18),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                gradient: AppColors.gradGold, shape: BoxShape.circle),
            child: const Text('⚡', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR XP BALANCE',
                  style: AppText.caption
                      .copyWith(fontSize: 10, letterSpacing: 1.2)),
              const SizedBox(height: 2),
              Text('$balance XP',
                  style: AppText.h2.copyWith(color: AppColors.gold)),
            ],
          ),
          const Spacer(),
          const Text('Earn more by\nspeaking 🗣',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  final VoidCallback onBuy;
  const _ProductCard({required this.product, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: p.owned && !p.isConsumable ? null : onBuy,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: p.featured
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brand500.withValues(alpha: 0.22),
                    AppColors.gold.withValues(alpha: 0.10),
                  ])
              : null,
          color: p.featured ? null : AppColors.sFill(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: p.featured
                  ? AppColors.gold.withValues(alpha: 0.4)
                  : AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (p.featured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        gradient: AppColors.gradGold,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('★ HOT',
                        style: AppText.caption.copyWith(
                            fontSize: 8.5,
                            color: const Color(0xFF3A2600),
                            fontWeight: FontWeight.w900)),
                  ),
                const Spacer(),
                if (p.owned && !p.isConsumable)
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
              ],
            ),
            const Spacer(),
            Center(child: Text(p.emoji, style: const TextStyle(fontSize: 44))),
            const Spacer(),
            Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label),
            const SizedBox(height: 2),
            Text(p.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption
                    .copyWith(fontSize: 10.5, color: AppColors.sText3)),
            const SizedBox(height: 10),
            _priceButton(p),
          ],
        ),
      ),
    );
  }

  Widget _priceButton(StoreProduct p) {
    if (p.owned && !p.isConsumable) {
      return Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Owned',
            style: AppText.caption.copyWith(
                color: AppColors.success, fontWeight: FontWeight.w700)),
      );
    }
    final affordable = p.affordable;
    return Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: affordable ? AppColors.grad : null,
        color: affordable ? null : AppColors.sFill(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('⚡ ${p.priceXp} XP',
          style: AppText.caption.copyWith(
              color: affordable ? Colors.white : AppColors.sText3,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _BuySheet extends StatelessWidget {
  final StoreProduct product;
  const _BuySheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final affordable = p.affordable;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n800,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
            top: BorderSide(color: AppColors.brand500.withValues(alpha: 0.4))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Insets.x6, 18, Insets.x6, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 18),
              Text(p.emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(p.name, style: AppText.h2, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(p.description,
                  style: AppText.smMuted, textAlign: TextAlign.center),
              if (p.grantsPremiumDays > 0) ...[
                const SizedBox(height: 8),
                Text('Adds ${p.grantsPremiumDays} days of Premium',
                    style: AppText.caption.copyWith(color: AppColors.gold)),
              ],
              const SizedBox(height: 20),
              if (!affordable)
                Text('Not enough XP — keep speaking to earn more!',
                    style: AppText.caption.copyWith(color: AppColors.warning),
                    textAlign: TextAlign.center),
              const SizedBox(height: 12),
              PrimaryButton(
                affordable ? 'Buy for ⚡ ${p.priceXp} XP' : 'Need ⚡ ${p.priceXp} XP',
                gradient: affordable ? AppColors.grad : AppColors.gradGold,
                onTap: affordable
                    ? () => Navigator.of(context).pop(true)
                    : null,
              ),
              const SizedBox(height: 8),
              GhostButton('Cancel', onTap: () => Navigator.of(context).pop(false)),
            ],
          ),
        ),
      ),
    );
  }
}
