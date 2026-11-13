/// Perangkat DiViLab yang bisa dipasangkan.
class DeviceInfo {
  const DeviceInfo({required this.name, required this.code, required this.asset, required this.supportsBloodPressure});

  final String name;
  final String code;
  final String asset;
  final bool supportsBloodPressure;

  static const optima = DeviceInfo(
    name: 'DiViLab Optima',
    code: 'DVIBGCU25121800X3',
    asset: 'assets/images/device_optima.png',
    supportsBloodPressure: true,
  );
  static const core = DeviceInfo(
    name: 'DiViLab Core',
    code: 'DVIGCUC25120800DX',
    asset: 'assets/images/device_core.png',
    supportsBloodPressure: false,
  );
}

/// Produk di halaman Produk.
class Product {
  const Product({
    required this.name,
    required this.short,
    required this.description,
    required this.price,
    required this.image,
    required this.specs,
  });

  final String name;
  final String short;
  final String description;
  final String price;
  final String image;
  final List<(String, String)> specs;

  static const all = [
    Product(
      name: 'DiViLab Optima 4in1',
      short: 'Starter pack perangkat Optima, mesin tes, strip 3 jenis, lancet.',
      description:
          'Perangkat Optima adalah alat ukur kesehatan all-in-one untuk memantau tekanan darah, glukosa, kolesterol, '
          'dan asam urat secara cepat serta akurat. Ideal untuk penggunaan mandiri di rumah maupun klinis, dengan layar '
          'intuitif, manset nyaman, dan konektivitas nirkabel ke aplikasi DiViLab.',
      price: 'Rp1.250.000',
      image: 'assets/images/product_optima.png',
      specs: [
        ('Parameter', 'Tekanan darah, gula darah, kolesterol, asam urat'),
        ('Konektivitas', 'Bluetooth 5.0 · Aplikasi DiViLab'),
        ('Hasil', '± 10 detik per strip'),
        ('Garansi', '1 tahun resmi'),
      ],
    ),
    Product(
      name: 'DiViLab Core 3in1',
      short: 'Starter pack perangkat Core, strip 3 jenis, lancet.',
      description:
          'DiViLab Core adalah alat ukur ringkas untuk gula darah, kolesterol, dan asam urat. Praktis dibawa bepergian '
          'dan otomatis menyinkronkan hasil ke aplikasi melalui Bluetooth.',
      price: 'Rp850.000',
      image: 'assets/images/device_optima.png',
      specs: [
        ('Parameter', 'Gula darah, kolesterol, asam urat'),
        ('Konektivitas', 'Bluetooth 5.0 · Aplikasi DiViLab'),
        ('Hasil', '± 10 detik per strip'),
        ('Garansi', '1 tahun resmi'),
      ],
    ),
  ];
}
