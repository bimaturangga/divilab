import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/catalog.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  void _buy(BuildContext context) {
    const stores = [
      ('Shopee', 'Platform belanja online terpopuler', Color(0xFFEE4D2D)),
      ('Tokopedia', 'Marketplace terpercaya di Indonesia', Color(0xFF03AC0E)),
      ('Apotek Hiro', 'Apotek terpercaya di Indonesia', Color(0xFF2E90FA)),
    ];
    showAppSheet<void>(
      context,
      builder: (ctx) {
        final p = ctx.palette;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHeader(title: 'Beli di mana?'),
                Image.asset('assets/images/shopping_bag.png',
                    width: 72, height: 72),
                const SizedBox(height: 12),
                for (final s in stores)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: p.bgSubtle,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.pop(ctx);
                          Clipboard.setData(
                              ClipboardData(text: '${product.name} ${s.$1}'));
                          showSnack(context,
                              'Kata kunci "${product.name}" disalin, buka aplikasi ${s.$1} untuk membeli');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: s.$3,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(s.$1[0],
                                    style: AppText.h3.c(Colors.white)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.$1,
                                        style: AppText.title.c(p.textPrimary)),
                                    Text(s.$2,
                                        style:
                                            AppText.caption.c(p.textSecondary)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: p.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: 300 + top,
                  color: const Color(0xFFE9EAEC),
                  padding: EdgeInsets.only(top: top + 20),
                  child: Image.asset(product.image, fit: BoxFit.contain),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.bgCanvas,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: AppText.h1.c(p.textPrimary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 16, color: p.warning),
                            const SizedBox(width: 4),
                            Text('4,8 · 1,2rb terjual',
                                style: AppText.caption.c(p.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(product.price, style: AppText.h2.c(p.primary)),
                        const SizedBox(height: 14),
                        Text(product.short,
                            style: AppText.body.c(p.textSecondary)),
                        const SizedBox(height: 20),
                        Text('Spesifikasi', style: AppText.h3.c(p.textPrimary)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: p.bgSubtle,
                              borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            children: [
                              for (final s in product.specs)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                          width: 100,
                                          child: Text(s.$1,
                                              style: AppText.bodySm
                                                  .c(p.textSecondary))),
                                      Expanded(
                                          child: Text(s.$2,
                                              style: AppText.label
                                                  .c(p.textPrimary))),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Deskripsi', style: AppText.h3.c(p.textPrimary)),
                        const SizedBox(height: 8),
                        Text(product.description,
                            style: AppText.body.c(p.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: top + 8,
            left: 12,
            child: _roundButton(
                Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
          ),
          Positioned(
            top: top + 8,
            right: 12,
            child: _roundButton(Icons.share_outlined, () {
              Clipboard.setData(
                  ClipboardData(text: '${product.name} – ${product.price}'));
              showSnack(context, 'Info produk disalin');
            }),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: p.bgCanvas,
            border: Border(top: BorderSide(color: p.borderDefault))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                    child: AppButton(
                        label: 'Beli Sekarang',
                        onPressed: () => _buy(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20, color: const Color(0xFF16191F))),
        ),
      );
}
