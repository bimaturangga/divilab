import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/catalog.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import 'product_detail_screen.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Text('Produk', style: AppText.h1.c(p.textPrimary)),
            const SizedBox(height: 16),
            const NoteBox(text: 'Jarum/lancet tipe 28G dapat dibeli di apotek terdekat'),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(aspectRatio: 750 / 376, child: Image.asset('assets/images/product_banner.png', fit: BoxFit.cover)),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Cari apotek terdekat',
              icon: Icons.location_on_outlined,
              variant: AppButtonVariant.outline,
              height: 44,
              onPressed: () => showSnack(context, 'Fitur peta apotek akan tersedia di versi berikutnya'),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Rekomendasi Produk'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < Product.all.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _ProductCard(product: Product.all[i])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    void open() => push(context, ProductDetailScreen(product: product));
    return Material(
      color: p.bgSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.borderDefault)),
      child: InkWell(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              color: const Color(0xFFEFF1F4),
              child: Image.asset(product.image, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppText.title.c(p.textPrimary)),
                  const SizedBox(height: 4),
                  Text(product.short, style: AppText.caption.c(p.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(product.price, style: AppText.title.c(p.primary)),
                  const SizedBox(height: 10),
                  AppButton(label: 'Lihat Detail', height: 34, onPressed: open),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
