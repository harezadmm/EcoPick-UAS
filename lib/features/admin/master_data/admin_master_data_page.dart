import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../ecopick/providers/ecopick_provider.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../data/admin_service.dart';

class AdminMasterDataPage extends ConsumerStatefulWidget {
  const AdminMasterDataPage({super.key});

  @override
  ConsumerState<AdminMasterDataPage> createState() =>
      _AdminMasterDataPageState();
}

class _AdminMasterDataPageState extends ConsumerState<AdminMasterDataPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: const Text('Master Data'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Kategori Sampah'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _CategoriesTab(),
        ],
      ),
    );
  }
}

// ---------- CATEGORIES ----------

class _CategoriesTab extends ConsumerStatefulWidget {
  const _CategoriesTab();
  @override
  ConsumerState<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<_CategoriesTab> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = AdminService().fetchAllCategories();
    });
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategoryFormSheet(existing: existing),
    );
    if (saved == true) {
      _refresh();
      ref.invalidate(wasteCategoriesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Kategori',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cats = snap.data!;
          if (cats.isEmpty) {
            return const Center(
              child: Text('Belum ada kategori. Tambahkan satu.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              for (final c in cats)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (c['is_active'] as bool? ?? true)
                                ? AppColors.primaryLight
                                : AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.recycling_rounded,
                            color: (c['is_active'] as bool? ?? true)
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${c['green_coin_per_kg']} GC / kg'
                                '${(c['is_active'] as bool? ?? true) ? '' : ' • nonaktif'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openForm(existing: c),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                          ),
                          onPressed: () async {
                            await AdminService()
                                .deleteCategory(c['id'] as String);
                            _refresh();
                            ref.invalidate(wasteCategoriesProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _CategoryFormSheet({this.existing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _rate;
  bool _active = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.existing?['name'] as String? ?? '',
    );
    _rate = TextEditingController(
      text: (widget.existing?['green_coin_per_kg'] as int? ?? 100).toString(),
    );
    _active = widget.existing?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final rate = int.tryParse(_rate.text.trim());
    if (name.isEmpty) {
      _alert('Nama wajib diisi');
      return;
    }
    if (rate == null || rate <= 0) {
      _alert('GC per kg harus angka positif');
      return;
    }
    setState(() => _busy = true);
    try {
      await AdminService().upsertCategory(
        id: widget.existing?['id'] as String?,
        name: name,
        greenCoinPerKg: rate,
        isActive: _active,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _alert(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _alert(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Tambah Kategori' : 'Ubah Kategori',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            LabeledField(
              label: 'Nama Kategori',
              child: AppTextField(
                controller: _name,
                hint: 'Mis. Plastik PET',
              ),
            ),
            const SizedBox(height: AppSizes.md),
            LabeledField(
              label: 'GreenCoin per kg',
              child: AppTextField(
                controller: _rate,
                hint: '200',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Aktif'),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSizes.lg),
            PrimaryButton(
              label: 'Simpan',
              loading: _busy,
              onPressed: _save,
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- PRODUCTS ----------

class _ProductsTab extends ConsumerStatefulWidget {
  const _ProductsTab();
  @override
  ConsumerState<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<_ProductsTab> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = AdminService().fetchAllProducts();
    });
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProductFormSheet(existing: existing),
    );
    if (saved == true) {
      _refresh();
      ref.invalidate(marketplaceProductsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Produk',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snap.data!;
          if (products.isEmpty) {
            return const Center(
              child: Text('Belum ada produk. Tambahkan satu.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              for (final p in products)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${Formatters.greenCoin(p['price_gc'] as int? ?? 0)} • Stok ${p['stock']}'
                                '${(p['is_active'] as bool? ?? true) ? '' : ' • nonaktif'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openForm(existing: p),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                          ),
                          onPressed: () async {
                            await AdminService()
                                .deleteProduct(p['id'] as String);
                            _refresh();
                            ref.invalidate(marketplaceProductsProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _ProductFormSheet({this.existing});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _imageUrl;
  bool _active = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?['name'] as String? ?? '');
    _desc = TextEditingController(text: e?['description'] as String? ?? '');
    _price = TextEditingController(
      text: (e?['price_gc'] as int? ?? 100).toString(),
    );
    _stock = TextEditingController(
      text: (e?['stock'] as int? ?? 0).toString(),
    );
    _imageUrl = TextEditingController(text: e?['image_url'] as String? ?? '');
    _active = e?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    if (name.isEmpty) return _alert('Nama wajib diisi');
    if (price == null || price <= 0) return _alert('Harga harus > 0');
    if (stock == null || stock < 0) return _alert('Stok harus ≥ 0');

    setState(() => _busy = true);
    try {
      await AdminService().upsertProduct(
        id: widget.existing?['id'] as String?,
        name: name,
        description: _desc.text.trim(),
        priceGc: price,
        stock: stock,
        imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
        isActive: _active,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _alert(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _alert(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Tambah Produk' : 'Ubah Produk',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            LabeledField(
              label: 'Nama Produk',
              child: AppTextField(controller: _name, hint: 'Beras 5 kg'),
            ),
            const SizedBox(height: AppSizes.md),
            LabeledField(
              label: 'Deskripsi',
              child: AppTextField(
                controller: _desc,
                hint: 'Deskripsi singkat',
                maxLines: 2,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Harga (GC)',
                    child: AppTextField(
                      controller: _price,
                      hint: '2500',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: LabeledField(
                    label: 'Stok',
                    child: AppTextField(
                      controller: _stock,
                      hint: '10',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            LabeledField(
              label: 'URL Gambar (opsional)',
              child: AppTextField(
                controller: _imageUrl,
                hint: 'https://...',
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Aktif'),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSizes.lg),
            PrimaryButton(
              label: 'Simpan',
              loading: _busy,
              onPressed: _save,
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
