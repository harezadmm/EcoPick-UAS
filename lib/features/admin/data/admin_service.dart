import '../../../core/config/supabase_config.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int totalTransactions;
  final double recycledKg;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalTransactions,
    required this.recycledKg,
  });
}

class AdminUserRecord {
  final String id;
  final String name;
  final String email;
  final String role;
  final int greenCoinBalance;

  const AdminUserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.greenCoinBalance,
  });

  factory AdminUserRecord.fromMap(Map<String, dynamic> map) {
    final email = map['email'] as String? ?? '';
    final name = map['full_name'] as String? ?? '';
    return AdminUserRecord(
      id: map['id'] as String? ?? '',
      name: name.trim().isEmpty ? _nameFromEmail(email) : name,
      email: email,
      role: map['role'] as String? ?? 'user',
      greenCoinBalance: _toInt(map['green_coin_balance']),
    );
  }
}

class AdminWasteRequestRecord {
  final String id;
  final String type;
  final String userId;
  final String userName;
  final String userEmail;
  final String categoryName;
  final double weightKg;
  final int estimatedGc;
  final String status;
  final String notes;
  final DateTime createdAt;

  const AdminWasteRequestRecord({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.categoryName,
    required this.weightKg,
    required this.estimatedGc,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  factory AdminWasteRequestRecord.fromMap(
    Map<String, dynamic> map, {
    required String type,
  }) {
    final profile = _nestedMap(map['profiles']);
    final category = _nestedMap(map['waste_categories']);
    final email = profile['email'] as String? ?? '';
    final name = profile['full_name'] as String? ?? '';
    return AdminWasteRequestRecord(
      id: map['id'] as String? ?? '',
      type: type,
      userId: map['user_id'] as String? ?? '',
      userName: name.trim().isEmpty ? _nameFromEmail(email) : name,
      userEmail: email,
      categoryName: category['name'] as String? ?? 'Sampah',
      weightKg: _toDouble(map['estimated_weight_kg']),
      estimatedGc: _toInt(map['estimated_green_coin']),
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String? ?? 'Tidak ada aksi',
      createdAt: _toDate(map['created_at']),
    );
  }
}

class AdminCoinTransactionRecord {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String sourceType;
  final String status;
  final String description;
  final int amountGc;
  final DateTime createdAt;

  const AdminCoinTransactionRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.sourceType,
    required this.status,
    required this.description,
    required this.amountGc,
    required this.createdAt,
  });

  factory AdminCoinTransactionRecord.fromMap(Map<String, dynamic> map) {
    final profile = _nestedMap(map['profiles']);
    final email = profile['email'] as String? ?? '';
    final name = profile['full_name'] as String? ?? '';
    return AdminCoinTransactionRecord(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      userName: name.trim().isEmpty ? _nameFromEmail(email) : name,
      userEmail: email,
      sourceType: map['source_type'] as String? ?? 'adjustment',
      status: map['status'] as String? ?? 'completed',
      description: map['description'] as String? ?? 'Tidak ada aksi',
      amountGc: _toInt(map['amount_gc']),
      createdAt: _toDate(map['created_at']),
    );
  }
}

class AdminMarketplaceProductRecord {
  final String id;
  final String name;
  final String description;
  final int priceGc;
  final int stock;
  final String? imageUrl;
  final String? emoji;
  final bool isActive;

  const AdminMarketplaceProductRecord({
    required this.id,
    required this.name,
    required this.description,
    required this.priceGc,
    required this.stock,
    required this.imageUrl,
    required this.isActive,
    this.emoji,
  });

  factory AdminMarketplaceProductRecord.fromMap(Map<String, dynamic> map) {
    return AdminMarketplaceProductRecord(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Produk',
      description: map['description'] as String? ?? '',
      priceGc: _toInt(map['price_gc']),
      stock: _toInt(map['stock']),
      imageUrl: map['image_url'] as String?,
      emoji: map['emoji'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

class AdminDashboardSnapshot {
  final AdminDashboardStats stats;
  final List<AdminUserRecord> users;
  final List<AdminWasteRequestRecord> ecopicks;
  final List<AdminWasteRequestRecord> ecodrops;
  final List<AdminCoinTransactionRecord> transactions;
  final List<AdminMarketplaceProductRecord> products;

  const AdminDashboardSnapshot({
    required this.stats,
    required this.users,
    required this.ecopicks,
    required this.ecodrops,
    required this.transactions,
    required this.products,
  });
}

class AdminService {
  Future<AdminDashboardSnapshot> fetchDashboardSnapshot() async {
    if (!SupabaseConfig.isConfigured) return _demoSnapshot();

    final results = await Future.wait([
      _fetchUsers(),
      _fetchEcoPickRequests(),
      _fetchEcoDropRequests(),
      _fetchGreenCoinTransactions(),
      _fetchProducts(),
    ]);

    final users = results[0] as List<AdminUserRecord>;
    final ecopicks = results[1] as List<AdminWasteRequestRecord>;
    final ecodrops = results[2] as List<AdminWasteRequestRecord>;
    final transactions = results[3] as List<AdminCoinTransactionRecord>;
    final products = results[4] as List<AdminMarketplaceProductRecord>;
    final recycledKg = [
      ...ecopicks.where((item) => item.status == 'completed'),
      ...ecodrops.where((item) => item.status == 'completed'),
    ].fold<double>(0, (sum, item) => sum + item.weightKg);

    return AdminDashboardSnapshot(
      stats: AdminDashboardStats(
        totalUsers: users.length,
        totalTransactions: transactions.length,
        recycledKg: recycledKg,
      ),
      users: users,
      ecopicks: ecopicks,
      ecodrops: ecodrops,
      transactions: transactions,
      products: products,
    );
  }

  Future<List<AdminUserRecord>> _fetchUsers() async {
    final rows = await SupabaseConfig.client
        .from('profiles')
        .select()
        .order('created_at', ascending: true);
    return [for (final row in rows) AdminUserRecord.fromMap(row)];
  }

  Future<List<AdminWasteRequestRecord>> _fetchEcoPickRequests() async {
    final rows = await SupabaseConfig.client
        .from('ecopick_requests')
        .select('*, profiles:user_id(*), waste_categories:category_id(*)')
        .order('created_at', ascending: false);
    return [
      for (final row in rows)
        AdminWasteRequestRecord.fromMap(row, type: 'EcoPick'),
    ];
  }

  Future<List<AdminWasteRequestRecord>> _fetchEcoDropRequests() async {
    final rows = await SupabaseConfig.client
        .from('ecodrop_requests')
        .select('*, profiles:user_id(*), waste_categories:category_id(*)')
        .order('created_at', ascending: false);
    return [
      for (final row in rows)
        AdminWasteRequestRecord.fromMap(row, type: 'EcoDrop'),
    ];
  }

  Future<List<AdminCoinTransactionRecord>> _fetchGreenCoinTransactions() async {
    // Only fetch withdraw requests — ecopick/ecodrop are managed in their own sections
    final rows = await SupabaseConfig.client
        .from('greencoin_transactions')
        .select('*, profiles:user_id(*)')
        .eq('source_type', 'withdraw')
        .order('created_at', ascending: false);
    return [for (final row in rows) AdminCoinTransactionRecord.fromMap(row)];
  }

  /// Menyetujui permintaan penarikan: memotong saldo user dan menandai transaksi selesai.
  Future<void> approveWithdraw(AdminCoinTransactionRecord record) async {
    if (!SupabaseConfig.isConfigured) return;

    // Deduct balance from user profile
    final profileRow = await SupabaseConfig.client
        .from('profiles')
        .select('green_coin_balance')
        .eq('id', record.userId)
        .single();
    final currentBalance = _toInt(profileRow['green_coin_balance']);
    // amountGc is stored as negative for withdrawals
    final newBalance = currentBalance + record.amountGc;
    if (newBalance < 0) throw Exception('Saldo tidak mencukupi untuk disetujui');

    await SupabaseConfig.client
        .from('profiles')
        .update({'green_coin_balance': newBalance})
        .eq('id', record.userId);

    await SupabaseConfig.client
        .from('greencoin_transactions')
        .update({'status': 'completed'})
        .eq('id', record.id);
  }

  /// Menolak permintaan penarikan: saldo tidak berubah (belum pernah dipotong).
  Future<void> rejectWithdraw(AdminCoinTransactionRecord record) async {
    if (!SupabaseConfig.isConfigured) return;
    await SupabaseConfig.client
        .from('greencoin_transactions')
        .update({'status': 'rejected'})
        .eq('id', record.id);
  }

  Future<List<AdminMarketplaceProductRecord>> _fetchProducts() async {
    final rows = await SupabaseConfig.client
        .from('marketplace_products')
        .select()
        .order('created_at', ascending: false);
    return [
      for (final row in rows) AdminMarketplaceProductRecord.fromMap(row),
    ];
  }

  Future<void> updateEcoPickStatus({
    required AdminWasteRequestRecord request,
    required String status,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    if (status == 'completed') {
      await _creditIfMissing(request, sourceType: 'ecopick');
    }
    await SupabaseConfig.client
        .from('ecopick_requests')
        .update({'status': status}).eq('id', request.id);
  }

  Future<void> updateEcoDropStatus({
    required AdminWasteRequestRecord request,
    required String status,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    if (status == 'completed') {
      await _creditIfMissing(request, sourceType: 'ecodrop');
    }
    await SupabaseConfig.client
        .from('ecodrop_requests')
        .update({'status': status}).eq('id', request.id);
  }

  Future<void> _creditIfMissing(
    AdminWasteRequestRecord request, {
    required String sourceType,
  }) async {
    final existing = await SupabaseConfig.client
        .from('greencoin_transactions')
        .select('id')
        .eq('source_id', request.id)
        .eq('source_type', sourceType)
        .maybeSingle();
    if (existing != null) return;

    await SupabaseConfig.client.rpc('adjust_balance', params: {
      'p_user_id': request.userId,
      'p_amount': request.estimatedGc,
      'p_source_type': sourceType,
      'p_source_id': request.id,
      'p_transaction_type': 'earn',
      'p_description': '${request.type} - ${request.weightKg} kg',
    });
  }

  // Waste categories
  Future<void> upsertCategory({
    String? id,
    required String name,
    required int greenCoinPerKg,
    bool isActive = true,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    final payload = {
      'name': name,
      'green_coin_per_kg': greenCoinPerKg,
      'is_active': isActive,
    };
    if (id == null) {
      await SupabaseConfig.client.from('waste_categories').insert(payload);
    } else {
      await SupabaseConfig.client
          .from('waste_categories')
          .update(payload)
          .eq('id', id);
    }
  }

  Future<void> deleteCategory(String id) async {
    if (!SupabaseConfig.isConfigured) return;
    // soft-disable to preserve referential integrity with existing transactions
    await SupabaseConfig.client
        .from('waste_categories')
        .update({'is_active': false}).eq('id', id);
  }

  // Marketplace products
  Future<void> upsertProduct({
    String? id,
    required String name,
    required String description,
    required int priceGc,
    required int stock,
    String? imageUrl,
    String? emoji,
    bool isActive = true,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    final payload = {
      'name': name,
      'description': description,
      'price_gc': priceGc,
      'stock': stock,
      'image_url': imageUrl,
      'emoji': emoji,
      'is_active': isActive,
    };
    if (id == null) {
      await SupabaseConfig.client.from('marketplace_products').insert(payload);
    } else {
      await SupabaseConfig.client
          .from('marketplace_products')
          .update(payload)
          .eq('id', id);
    }
  }

  Future<void> deleteProduct(String id) async {
    if (!SupabaseConfig.isConfigured) return;
    await SupabaseConfig.client
        .from('marketplace_products')
        .update({'is_active': false}).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchAllCategories() async {
    if (!SupabaseConfig.isConfigured) return [];
    final rows = await SupabaseConfig.client
        .from('waste_categories')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    if (!SupabaseConfig.isConfigured) return [];
    final rows = await SupabaseConfig.client
        .from('marketplace_products')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}

Map<String, dynamic> _nestedMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

String _nameFromEmail(String email) {
  final name = email.split('@').first.trim();
  return name.isEmpty ? 'Pengguna' : name;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime _toDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

AdminDashboardSnapshot _demoSnapshot() {
  const users = [
    AdminUserRecord(
      id: '50d0486e-0000-0000-0000-000000000000',
      name: 'test',
      email: 'test@gmail.com',
      role: 'user',
      greenCoinBalance: 19600,
    ),
    AdminUserRecord(
      id: 'e4c21ced-0000-0000-0000-000000000000',
      name: 'Administrator',
      email: 'admin@gmail.com',
      role: 'admin',
      greenCoinBalance: 0,
    ),
    AdminUserRecord(
      id: 'f19805dc-0000-0000-0000-000000000000',
      name: 'harizzss',
      email: 'harizaa@gmail.com',
      role: 'user',
      greenCoinBalance: 0,
    ),
    AdminUserRecord(
      id: 'af3ffea2-0000-0000-0000-000000000000',
      name: 'harus',
      email: 'hariz@gmail.com',
      role: 'user',
      greenCoinBalance: 0,
    ),
  ];

  final now = DateTime.now();
  final ecopicks = [
    AdminWasteRequestRecord(
      id: '00000000-0000-0000-0000-00000000d8ef',
      type: 'EcoPick',
      userId: users[0].id,
      userName: users[0].name,
      userEmail: users[0].email,
      categoryName: 'Plastik',
      weightKg: 98,
      estimatedGc: 19600,
      status: 'completed',
      notes: 'Tidak ada aksi',
      createdAt: now,
    ),
    AdminWasteRequestRecord(
      id: '00000000-0000-0000-0000-000000007784',
      type: 'EcoPick',
      userId: users[0].id,
      userName: users[0].name,
      userEmail: users[0].email,
      categoryName: 'Kaca',
      weightKg: 600,
      estimatedGc: 0,
      status: 'completed',
      notes: 'Tidak ada aksi',
      createdAt: now.subtract(const Duration(minutes: 4)),
    ),
    AdminWasteRequestRecord(
      id: '00000000-0000-0000-0000-000000001111',
      type: 'EcoPick',
      userId: users[2].id,
      userName: users[2].name,
      userEmail: users[2].email,
      categoryName: 'Plastik',
      weightKg: 12,
      estimatedGc: 2400,
      status: 'pending',
      notes: 'Menunggu verifikasi',
      createdAt: now.subtract(const Duration(minutes: 10)),
    ),
  ];

  final ecodrops = [
    AdminWasteRequestRecord(
      id: '00000000-0000-0000-0000-00000000d622',
      type: 'EcoDrop',
      userId: users[3].id,
      userName: users[3].name,
      userEmail: users[3].email,
      categoryName: 'Plastik',
      weightKg: 90,
      estimatedGc: 18000,
      status: 'completed',
      notes: 'Tidak ada aksi',
      createdAt: now.subtract(const Duration(minutes: 7)),
    ),
    AdminWasteRequestRecord(
      id: '00000000-0000-0000-0000-00000000d94e',
      type: 'EcoDrop',
      userId: users[3].id,
      userName: users[3].name,
      userEmail: users[3].email,
      categoryName: 'Plastik',
      weightKg: 90,
      estimatedGc: 18000,
      status: 'completed',
      notes: 'Tidak ada aksi',
      createdAt: now.subtract(const Duration(minutes: 12)),
    ),
  ];

  // Demo: only withdraw requests appear in Transaction Management
  final transactions = [
    AdminCoinTransactionRecord(
      id: '00000000-0000-0000-0000-00000000w001',
      userId: users[0].id,
      userName: users[0].name,
      userEmail: users[0].email,
      sourceType: 'withdraw',
      status: 'pending',
      description: 'DANA \u2022 DANA \u2022\u2022\u2022\u2022 1234 \u2022 test',
      amountGc: -2000,
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
    AdminCoinTransactionRecord(
      id: '00000000-0000-0000-0000-00000000w002',
      userId: users[2].id,
      userName: users[2].name,
      userEmail: users[2].email,
      sourceType: 'withdraw',
      status: 'pending',
      description: 'GoPay \u2022 GoPay \u2022\u2022\u2022\u2022 5678 \u2022 harizzss',
      amountGc: -500,
      createdAt: now.subtract(const Duration(minutes: 15)),
    ),
    AdminCoinTransactionRecord(
      id: '00000000-0000-0000-0000-00000000w003',
      userId: users[3].id,
      userName: users[3].name,
      userEmail: users[3].email,
      sourceType: 'withdraw',
      status: 'completed',
      description: 'OVO \u2022 OVO \u2022\u2022\u2022\u2022 9012 \u2022 harus',
      amountGc: -1000,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
  ];

  const products = [
    AdminMarketplaceProductRecord(
      id: '00000000-0000-0000-0000-00000000b001',
      name: 'Beras 5 kg',
      description: 'Beras premium siap masak',
      priceGc: 2500,
      stock: 12,
      imageUrl: null,
      isActive: true,
    ),
    AdminMarketplaceProductRecord(
      id: '00000000-0000-0000-0000-00000000b002',
      name: 'Minyak Goreng 2L',
      description: 'Minyak goreng bermerk',
      priceGc: 1800,
      stock: 8,
      imageUrl: null,
      isActive: true,
    ),
    AdminMarketplaceProductRecord(
      id: '00000000-0000-0000-0000-00000000b003',
      name: 'Detergen 1 kg',
      description: 'Detergen pembersih pakaian',
      priceGc: 900,
      stock: 24,
      imageUrl: null,
      isActive: true,
    ),
    AdminMarketplaceProductRecord(
      id: '00000000-0000-0000-0000-00000000b004',
      name: 'Sabun Cuci Piring',
      description: 'Sabun cuci anti-bakteri',
      priceGc: 600,
      stock: 30,
      imageUrl: null,
      isActive: true,
    ),
  ];

  return AdminDashboardSnapshot(
    stats: AdminDashboardStats(
      totalUsers: users.length,
      totalTransactions: transactions.length,
      recycledKg: [
        ...ecopicks.where((item) => item.status == 'completed'),
        ...ecodrops.where((item) => item.status == 'completed'),
      ].fold<double>(0, (sum, item) => sum + item.weightKg),
    ),
    users: users,
    ecopicks: ecopicks,
    ecodrops: ecodrops,
    transactions: transactions,
    products: products,
  );
}
