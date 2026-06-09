import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../data/admin_service.dart';
import '../models/admin_section.dart';
import '../widgets/admin_drawer.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  final _search = TextEditingController();
  final _expandedEcoPickUsers = <String>{};
  final _expandedEcoDropUsers = <String>{};
  final _expandedTransactionUsers = <String>{};
  late Future<AdminDashboardSnapshot> _future;
  AdminSection _section = AdminSection.overview;

  @override
  void initState() {
    super.initState();
    _future = AdminService().fetchDashboardSnapshot();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = AdminService().fetchDashboardSnapshot();
    });
  }

  void _selectSection(AdminSection section) {
    setState(() {
      _section = section;
      _search.clear();
    });
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _updateWasteStatus(
    AdminWasteRequestRecord request,
    String status,
  ) async {
    try {
      if (request.type == 'EcoPick') {
        await AdminService().updateEcoPickStatus(
          request: request,
          status: status,
        );
      } else {
        await AdminService().updateEcoDropStatus(
          request: request,
          status: status,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${requestCode(request)} diperbarui')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _approveWithdraw(AdminCoinTransactionRecord record) async {
    try {
      await AdminService().approveWithdraw(record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penarikan disetujui — saldo telah dipotong'),
          backgroundColor: AppColors.primary,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _rejectWithdraw(AdminCoinTransactionRecord record) async {
    try {
      await AdminService().rejectWithdraw(record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penarikan ditolak — saldo dikembalikan ke pengguna'),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: AdminDrawer(
        selectedSection: _section,
        onSectionSelected: _selectSection,
        onLogout: () {
          _logout();
        },
      ),
      appBar: AppBar(
        toolbarHeight: 78,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'EcoPoin Admin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          Consumer(
            builder: (context, innerRef, _) {
              innerRef.watch(themeModeProvider);
              final isDark =
                  Theme.of(context).brightness == Brightness.dark;
              return Padding(
                padding: const EdgeInsets.only(right: AppSizes.md),
                child: IconButton(
                  tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
                  onPressed: () =>
                      innerRef.read(themeModeProvider.notifier).toggle(),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween<double>(begin: 0.6, end: 1).animate(anim),
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      key: ValueKey(isDark),
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<AdminDashboardSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                  message: snapshot.error.toString(), onTap: _refresh);
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _bodyFor(data),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _bodyFor(AdminDashboardSnapshot data) {
    final query = _search.text.trim().toLowerCase();
    switch (_section) {
      case AdminSection.overview:
        return _OverviewView(
          key: const ValueKey('overview'),
          data: data,
          onOpenUsers: () => _selectSection(AdminSection.users),
        );
      case AdminSection.users:
        return _UsersView(
          key: const ValueKey('users'),
          search: _search,
          users: _filterUsers(data.users, query),
          onChanged: () => setState(() {}),
        );
      case AdminSection.ecopick:
        return _WasteManagementView(
          key: const ValueKey('ecopick'),
          title: 'EcoPick Management',
          subtitle: 'Manage and track waste pickup requests efficiently.',
          search: _search,
          requests: _filterWaste(data.ecopicks, query),
          expandedUsers: _expandedEcoPickUsers,
          onChanged: () => setState(() {}),
          onToggle: _toggleExpanded,
          onStatusChanged: _updateWasteStatus,
        );
      case AdminSection.ecodrop:
        return _WasteManagementView(
          key: const ValueKey('ecodrop'),
          title: 'EcoDrop Management',
          subtitle:
              'Manage, review, and verify user waste drop-off submissions.',
          search: _search,
          requests: _filterWaste(data.ecodrops, query),
          expandedUsers: _expandedEcoDropUsers,
          onChanged: () => setState(() {}),
          onToggle: _toggleExpanded,
          onStatusChanged: _updateWasteStatus,
        );
      case AdminSection.transactions:
        return _TransactionsView(
          key: const ValueKey('transactions'),
          search: _search,
          transactions: _filterTransactions(data.transactions, query),
          expandedUsers: _expandedTransactionUsers,
          onChanged: () => setState(() {}),
          onToggle: _toggleExpanded,
          onApprove: _approveWithdraw,
          onReject: _rejectWithdraw,
        );
      case AdminSection.marketplace:
        return _MarketplaceView(
          key: const ValueKey('marketplace'),
          search: _search,
          products: _filterProducts(data.products, query),
          onChanged: () => setState(() {}),
          onSaved: () {
            ref.invalidate(marketplaceProductsProvider);
            _refresh();
          },
        );
      case AdminSection.settings:
        return _SettingsView(
          key: const ValueKey('settings'),
          onRefresh: _refresh,
          onLogout: _logout,
        );
    }
  }

  void _toggleExpanded(Set<String> expanded, String userId) {
    setState(() {
      if (!expanded.remove(userId)) expanded.add(userId);
    });
  }
}

List<AdminUserRecord> _filterUsers(List<AdminUserRecord> users, String query) {
  if (query.isEmpty) return users;
  return users.where((user) {
    return user.name.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query) ||
        user.id.toLowerCase().contains(query);
  }).toList();
}

List<AdminWasteRequestRecord> _filterWaste(
  List<AdminWasteRequestRecord> requests,
  String query,
) {
  if (query.isEmpty) return requests;
  return requests.where((request) {
    return request.userName.toLowerCase().contains(query) ||
        request.userEmail.toLowerCase().contains(query) ||
        request.id.toLowerCase().contains(query) ||
        request.categoryName.toLowerCase().contains(query);
  }).toList();
}

List<AdminCoinTransactionRecord> _filterTransactions(
  List<AdminCoinTransactionRecord> transactions,
  String query,
) {
  if (query.isEmpty) return transactions;
  return transactions.where((transaction) {
    return transaction.userName.toLowerCase().contains(query) ||
        transaction.userEmail.toLowerCase().contains(query) ||
        transaction.id.toLowerCase().contains(query) ||
        transaction.sourceType.toLowerCase().contains(query);
  }).toList();
}

List<AdminMarketplaceProductRecord> _filterProducts(
  List<AdminMarketplaceProductRecord> products,
  String query,
) {
  if (query.isEmpty) return products;
  return products.where((product) {
    return product.name.toLowerCase().contains(query) ||
        product.description.toLowerCase().contains(query) ||
        product.id.toLowerCase().contains(query);
  }).toList();
}

class _OverviewView extends StatelessWidget {
  final AdminDashboardSnapshot data;
  final VoidCallback onOpenUsers;

  const _OverviewView({
    super.key,
    required this.data,
    required this.onOpenUsers,
  });

  @override
  Widget build(BuildContext context) {
    final logs = [...data.ecopicks, ...data.ecodrops]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final hPad = AppSizes.screenHorizontal(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppSizes.lg,
        hPad,
        AppSizes.xl,
      ),
      children: [
        MotionFadeSlide(
          delayMs: 20,
          child: _Panel(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              AppSizes.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Growth',
                  style: _sectionTitleStyle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  'Activity across all segments',
                  style: TextStyle(
                    color: AppColors.textS(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MetricValue(
                        value: '${data.stats.totalUsers}',
                        label: 'Total Users',
                        color: const Color(0xFF1D8CF8),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _MetricValue(
                        value: '${data.stats.totalTransactions}',
                        label: 'Total Tx',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _MetricValue(
                        value: '${_compactDouble(data.stats.recycledKg)} kg',
                        label: 'Recycled',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        MotionFadeSlide(
          delayMs: 90,
          child: _ActivityTrendCard(
            requests: logs,
            transactions: data.transactions,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        MotionFadeSlide(
          delayMs: 160,
          child: _AnalyticsSplitCard(
            data: data,
            requests: logs,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        MotionFadeSlide(
          delayMs: 230,
          child: _MarketplaceSnapshotCard(products: data.products),
        ),
        const SizedBox(height: AppSizes.md),
        MotionFadeSlide(
          delayMs: 300,
          child: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Recent Platform Logs',
                          style: _sectionTitleStyle(context)),
                    ),
                    TextButton(
                      onPressed: onOpenUsers,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Lihat semua'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                if (logs.isEmpty)
                  const _EmptyLine('Belum ada aktivitas platform')
                else
                  for (final item in logs.take(3))
                    _PlatformLogTile(request: item),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricValue extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricValue({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = AppSizes.isNarrow(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: narrow ? 18 : 23,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textS(context),
            fontSize: narrow ? 11 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActivityTrendCard extends StatelessWidget {
  final List<AdminWasteRequestRecord> requests;
  final List<AdminCoinTransactionRecord> transactions;

  const _ActivityTrendCard({
    required this.requests,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final values = _weeklyActivityValues(requests, transactions);
    final maxValue =
        values.fold<int>(0, (max, value) => value > max ? value : max);
    final hasData = maxValue > 0;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Trend', style: _sectionTitleStyle(context)),
          const SizedBox(height: 2),
          Text(
            'Request & transaksi 7 hari terakhir',
            style: TextStyle(
              color: AppColors.textS(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: (hasData ? maxValue + 1 : 4).toDouble(),
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.div(context),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final labels = _lastSevenDayLabels();
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSizes.sm),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              color: AppColors.textT(context),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 0,
                      barRods: [
                        BarChartRodData(
                          toY: values[i].toDouble(),
                          width: 18,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                          color: values[i] == 0
                              ? AppColors.surfaceMuted
                              : AppColors.primary,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (hasData ? maxValue + 1 : 4).toDouble(),
                            color: AppColors.surfMuted(context),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (!hasData) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              'Belum ada aktivitas minggu ini',
              style: TextStyle(
                color: AppColors.textS(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalyticsSplitCard extends StatelessWidget {
  final AdminDashboardSnapshot data;
  final List<AdminWasteRequestRecord> requests;

  const _AnalyticsSplitCard({
    required this.data,
    required this.requests,
  });

  @override
  Widget build(BuildContext context) {
    final mix = _requestMix(data);
    final statuses = _statusCounts(requests, data.transactions);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final children = [
          Expanded(child: _RequestMixChart(mix: mix)),
          if (wide) const SizedBox(width: AppSizes.md),
          Expanded(child: _StatusBreakdown(statuses: statuses)),
        ];
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children)
            : Column(
                children: [
                  _RequestMixChart(mix: mix),
                  const SizedBox(height: AppSizes.xl),
                  _StatusBreakdown(statuses: statuses),
                ],
              );
      },
    );
  }
}

class _RequestMixChart extends StatelessWidget {
  final List<_ChartSlice> mix;

  const _RequestMixChart({required this.mix});

  @override
  Widget build(BuildContext context) {
    final total = mix.fold<int>(0, (sum, item) => sum + item.value);
    final chartMix = total == 0
        ? const [
            _ChartSlice(label: 'EcoPick', value: 1, color: Color(0x3322C55E)),
            _ChartSlice(label: 'EcoDrop', value: 1, color: Color(0x333B82F6)),
            _ChartSlice(label: 'GreenCoin', value: 1, color: Color(0x33F59E0B)),
          ]
        : mix;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Segment Mix', style: _sectionTitleStyle(context)),
          const SizedBox(height: 2),
          Text(
            total == 0
                ? 'Belum ada aktivitas segmen'
                : '$total aktivitas tercatat',
            style: TextStyle(
              color: AppColors.textS(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 130,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 32,
                sectionsSpace: 3,
                startDegreeOffset: -90,
                sections: [
                  for (final item in chartMix)
                    PieChartSectionData(
                      value: item.value.toDouble(),
                      title: total == 0 ? '' : '${item.value}',
                      radius: 22,
                      color: item.color,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.sm,
            children: [
              for (final item in mix)
                _LegendDot(label: item.label, color: item.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> statuses;

  const _StatusBreakdown({required this.statuses});

  @override
  Widget build(BuildContext context) {
    final total = statuses.values.fold<int>(0, (sum, value) => sum + value);
    final rows = [
      _StatusRowData('completed', statuses['completed'] ?? 0),
      _StatusRowData('pending', statuses['pending'] ?? 0),
      _StatusRowData(
          'process', (statuses['process'] ?? 0) + (statuses['verified'] ?? 0)),
      _StatusRowData('rejected', statuses['rejected'] ?? 0),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Breakdown', style: _sectionTitleStyle(context)),
          const SizedBox(height: 2),
          Text(
            total == 0 ? 'Belum ada status request' : '$total item dipantau',
            style: TextStyle(
              color: AppColors.textS(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: _ProgressRow(
                label: statusLabel(row.status),
                value: row.value,
                total: total,
                color: _statusPalette(row.status).$2,
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketplaceSnapshotCard extends StatelessWidget {
  final List<AdminMarketplaceProductRecord> products;

  const _MarketplaceSnapshotCard({required this.products});

  @override
  Widget build(BuildContext context) {
    final active = products.where((product) => product.isActive).length;
    final stock = products.fold<int>(0, (sum, product) => sum + product.stock);
    final inventoryValue = products.fold<int>(
      0,
      (sum, product) => sum + (product.priceGc * product.stock),
    );

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Marketplace Snapshot', style: _sectionTitleStyle(context)),
          const SizedBox(height: 2),
          Text(
            'Stok & nilai katalog produk',
            style: TextStyle(
              color: AppColors.textS(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: _CompactAnalyticTile(
                  icon: Icons.storefront_outlined,
                  label: 'Produk Aktif',
                  value: '$active/${products.length}',
                  color: const Color(0xFF1D8CF8),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: _CompactAnalyticTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Total Stok',
                  value: '$stock',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _CompactAnalyticTile(
            icon: Icons.savings_outlined,
            label: 'Nilai Inventori',
            value: Formatters.greenCoin(inventoryValue),
            color: const Color(0xFFF59E0B),
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _CompactAnalyticTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool expanded;

  const _CompactAnalyticTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSizes.md),
          Expanded(
            flex: expanded ? 2 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textS(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textP(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            backgroundColor: AppColors.surfMuted(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.xs),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textS(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChartSlice {
  final String label;
  final int value;
  final Color color;

  const _ChartSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatusRowData {
  final String status;
  final int value;

  const _StatusRowData(this.status, this.value);
}

class _PlatformLogTile extends StatelessWidget {
  final AdminWasteRequestRecord request;

  const _PlatformLogTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.div(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.type} - ${request.categoryName}',
                  style: TextStyle(
                    color: AppColors.textP(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  request.userName,
                  style: TextStyle(
                    color: AppColors.textS(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _StatusChip(status: request.status),
        ],
      ),
    );
  }
}

class _UsersView extends StatelessWidget {
  final TextEditingController search;
  final List<AdminUserRecord> users;
  final VoidCallback onChanged;

  const _UsersView({
    super.key,
    required this.search,
    required this.users,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = AppSizes.screenHorizontal(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppSizes.lg,
        hPad,
        AppSizes.xl,
      ),
      children: [
        const _PageHeading(
          title: 'Users Management',
          subtitle: 'Manage and monitor all registered platform users.',
        ),
        _SearchBox(
          controller: search,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSizes.xl),
        _Panel(
          padding: EdgeInsets.zero,
          child: users.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSizes.lg),
                  child: _EmptyLine('Pengguna tidak ditemukan'),
                )
              : Column(
                  children: [
                    for (var i = 0; i < users.length; i++)
                      _UserTile(
                        user: users[i],
                        showDivider: i != users.length - 1,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminUserRecord user;
  final bool showDivider;

  const _UserTile({
    required this.user,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.lg,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: AppColors.div(context)))
            : null,
      ),
      child: Row(
        children: [
          const _AvatarIcon(),
          const SizedBox(width: AppSizes.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textP(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textP(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ID: ${userCode(user.id)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteManagementView extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController search;
  final List<AdminWasteRequestRecord> requests;
  final Set<String> expandedUsers;
  final VoidCallback onChanged;
  final void Function(Set<String>, String) onToggle;
  final Future<void> Function(AdminWasteRequestRecord, String) onStatusChanged;

  const _WasteManagementView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.search,
    required this.requests,
    required this.expandedUsers,
    required this.onChanged,
    required this.onToggle,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _groupWaste(requests);
    if (expandedUsers.isEmpty && groups.isNotEmpty) {
      expandedUsers.add(groups.first.userId);
    }

    final hPad = AppSizes.screenHorizontal(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppSizes.lg,
        hPad,
        AppSizes.xl,
      ),
      children: [
        _PageHeading(title: title, subtitle: subtitle),
        _SearchBox(controller: search, onChanged: onChanged),
        const SizedBox(height: AppSizes.xl),
        _Panel(
          padding: EdgeInsets.zero,
          child: groups.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSizes.lg),
                  child: _EmptyLine('Data tidak ditemukan'),
                )
              : Column(
                  children: [
                    for (var i = 0; i < groups.length; i++)
                      _WasteGroupTile(
                        group: groups[i],
                        expanded: expandedUsers.contains(groups[i].userId),
                        showDivider: i != groups.length - 1,
                        onTap: () => onToggle(expandedUsers, groups[i].userId),
                        onStatusChanged: onStatusChanged,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _WasteGroup {
  final String userId;
  final String userName;
  final List<AdminWasteRequestRecord> requests;

  const _WasteGroup({
    required this.userId,
    required this.userName,
    required this.requests,
  });
}

List<_WasteGroup> _groupWaste(List<AdminWasteRequestRecord> requests) {
  final grouped = <String, List<AdminWasteRequestRecord>>{};
  for (final request in requests) {
    grouped.putIfAbsent(request.userId, () => []).add(request);
  }
  return grouped.entries
      .map(
        (entry) => _WasteGroup(
          userId: entry.key,
          userName: entry.value.first.userName,
          requests: entry.value,
        ),
      )
      .toList();
}

class _WasteGroupTile extends StatelessWidget {
  final _WasteGroup group;
  final bool expanded;
  final bool showDivider;
  final VoidCallback onTap;
  final Future<void> Function(AdminWasteRequestRecord, String) onStatusChanged;

  const _WasteGroupTile({
    required this.group,
    required this.expanded,
    required this.showDivider,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: AppColors.div(context)))
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  const _AvatarIcon(size: 38),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textP(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${group.requests.length} Data',
                          style: TextStyle(
                            color: AppColors.textS(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color:
                        expanded ? AppColors.primary : AppColors.textT(context),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                0,
                AppSizes.lg,
                AppSizes.lg,
              ),
              child: Column(
                children: [
                  for (final request in group.requests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      child: _WasteRequestCard(
                        request: request,
                        onStatusChanged: onStatusChanged,
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _WasteRequestCard extends StatelessWidget {
  final AdminWasteRequestRecord request;
  final Future<void> Function(AdminWasteRequestRecord, String) onStatusChanged;

  const _WasteRequestCard({
    required this.request,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _statusActions(request);
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfMuted(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  requestCode(request),
                  style: TextStyle(
                    color: AppColors.textS(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _CategoryChip(label: request.categoryName),
              Text(
                '${_compactDouble(request.weightKg)} kg',
                style: TextStyle(
                  color: AppColors.textS(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          if (actions.isEmpty)
            Text(
              request.notes.trim().isEmpty ? 'Tidak ada aksi' : request.notes,
              style: TextStyle(
                color: AppColors.textS(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                for (final action in actions)
                  _ActionButton(
                    label: action.label,
                    color: action.color,
                    onTap: () => onStatusChanged(request, action.status),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AdminAction {
  final String label;
  final String status;
  final Color color;

  const _AdminAction({
    required this.label,
    required this.status,
    required this.color,
  });
}

List<_AdminAction> _statusActions(AdminWasteRequestRecord request) {
  if (request.status == 'completed' || request.status == 'rejected') {
    return const [];
  }
  if (request.type == 'EcoPick') {
    if (request.status == 'pending') {
      return const [
        _AdminAction(
          label: 'Proses',
          status: 'process',
          color: Color(0xFF1D8CF8),
        ),
        _AdminAction(
          label: 'Selesai',
          status: 'completed',
          color: AppColors.primary,
        ),
      ];
    }
    return const [
      _AdminAction(
        label: 'Selesai',
        status: 'completed',
        color: AppColors.primary,
      ),
      _AdminAction(
        label: 'Tolak',
        status: 'rejected',
        color: AppColors.danger,
      ),
    ];
  }

  if (request.status == 'pending') {
    return const [
      _AdminAction(
        label: 'Verifikasi',
        status: 'verified',
        color: Color(0xFF1D8CF8),
      ),
      _AdminAction(
        label: 'Selesai',
        status: 'completed',
        color: AppColors.primary,
      ),
    ];
  }
  return const [
    _AdminAction(
      label: 'Selesai',
      status: 'completed',
      color: AppColors.primary,
    ),
    _AdminAction(
      label: 'Tolak',
      status: 'rejected',
      color: AppColors.danger,
    ),
  ];
}

class _TransactionsView extends StatelessWidget {
  final TextEditingController search;
  final List<AdminCoinTransactionRecord> transactions;
  final Set<String> expandedUsers;
  final VoidCallback onChanged;
  final void Function(Set<String>, String) onToggle;
  final Future<void> Function(AdminCoinTransactionRecord) onApprove;
  final Future<void> Function(AdminCoinTransactionRecord) onReject;

  const _TransactionsView({
    super.key,
    required this.search,
    required this.transactions,
    required this.expandedUsers,
    required this.onChanged,
    required this.onToggle,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _groupTransactions(transactions);
    if (expandedUsers.isEmpty && groups.isNotEmpty) {
      expandedUsers.add(groups.first.userId);
    }

    final hPad = AppSizes.screenHorizontal(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppSizes.lg,
        hPad,
        AppSizes.xl,
      ),
      children: [
        const _PageHeading(
          title: 'GreenCoin Transaction Management',
          subtitle: 'Manage requests and monitor point movements.',
        ),
        _SearchBox(controller: search, onChanged: onChanged),
        const SizedBox(height: AppSizes.xl),
        _Panel(
          padding: EdgeInsets.zero,
          child: groups.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSizes.lg),
                  child: _EmptyLine('Transaksi tidak ditemukan'),
                )
              : Column(
                  children: [
                    for (var i = 0; i < groups.length; i++)
                      _TransactionGroupTile(
                        group: groups[i],
                        expanded: expandedUsers.contains(groups[i].userId),
                        showDivider: i != groups.length - 1,
                        onTap: () => onToggle(expandedUsers, groups[i].userId),
                        onApprove: onApprove,
                        onReject: onReject,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MarketplaceView extends StatefulWidget {
  final TextEditingController search;
  final List<AdminMarketplaceProductRecord> products;
  final VoidCallback onChanged;
  final VoidCallback onSaved;

  const _MarketplaceView({
    super.key,
    required this.search,
    required this.products,
    required this.onChanged,
    required this.onSaved,
  });

  @override
  State<_MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<_MarketplaceView> {
  Future<void> _openForm({AdminMarketplaceProductRecord? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MarketplaceProductForm(existing: existing),
    );
    if (saved == true) widget.onSaved();
  }

  Future<void> _delete(AdminMarketplaceProductRecord product) async {
    try {
      await AdminService().deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} dinonaktifkan')),
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppSizes.screenHorizontal(context);
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            hPad,
            AppSizes.lg,
            hPad,
            112,
          ),
          children: [
            const _PageHeading(
              title: 'Marketplace Management',
              subtitle: 'Manage products shown in the user marketplace.',
            ),
            _SearchBox(
              controller: widget.search,
              onChanged: widget.onChanged,
            ),
            const SizedBox(height: AppSizes.xl),
            if (widget.products.isEmpty)
              const _Panel(
                child: _EmptyLine('Produk tidak ditemukan'),
              )
            else
              for (final product in widget.products)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: _MarketplaceProductTile(
                    product: product,
                    onEdit: () => _openForm(existing: product),
                    onDelete: () => _delete(product),
                  ),
                ),
          ],
        ),
        Positioned(
          right: AppSizes.xl,
          bottom: AppSizes.xl,
          child: FloatingActionButton.extended(
            onPressed: () => _openForm(),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Tambah Produk',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MarketplaceProductTile extends StatelessWidget {
  final AdminMarketplaceProductRecord product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MarketplaceProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = AppSizes.isNarrow(context);
    final avatarSize = narrow ? 44.0 : 54.0;
    return _Panel(
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: AppColors.primarySubtleColor(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primary,
              size: narrow ? 22 : 28,
            ),
          ),
          SizedBox(width: narrow ? AppSizes.md : AppSizes.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textP(context),
                    fontSize: narrow ? 15 : 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.greenCoin(product.priceGc)} • Stok ${product.stock}'
                  '${product.isActive ? '' : ' • nonaktif'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textS(context),
                    fontSize: narrow ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (narrow)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18),
                      SizedBox(width: AppSizes.sm),
                      Text('Edit produk'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: AppColors.danger, size: 18),
                      SizedBox(width: AppSizes.sm),
                      Text('Hapus produk',
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              color: AppColors.textP(context),
              tooltip: 'Edit produk',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.danger,
              tooltip: 'Hapus produk',
            ),
          ],
        ],
      ),
    );
  }
}

class _MarketplaceProductForm extends StatefulWidget {
  final AdminMarketplaceProductRecord? existing;

  const _MarketplaceProductForm({this.existing});

  @override
  State<_MarketplaceProductForm> createState() =>
      _MarketplaceProductFormState();
}

class _MarketplaceProductFormState extends State<_MarketplaceProductForm> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _imageUrl;
  late final TextEditingController _emoji;
  bool _active = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _desc = TextEditingController(text: existing?.description ?? '');
    _price = TextEditingController(
      text: (existing?.priceGc ?? 100).toString(),
    );
    _stock = TextEditingController(
      text: (existing?.stock ?? 0).toString(),
    );
    _imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    _emoji = TextEditingController(text: existing?.emoji ?? '');
    _active = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    _emoji.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim());
    final stock = int.tryParse(_stock.text.trim());

    if (name.isEmpty) return _alert('Nama wajib diisi');
    if (price == null || price <= 0) return _alert('Harga harus > 0');
    if (stock == null || stock < 0) return _alert('Stok harus minimal 0');

    setState(() => _busy = true);
    try {
      await AdminService().upsertProduct(
        id: widget.existing?.id,
        name: name,
        description: _desc.text.trim(),
        priceGc: price,
        stock: stock,
        imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
        emoji: _emoji.text.trim().isEmpty ? null : _emoji.text.trim(),
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
    final hPad = AppSizes.screenHorizontal(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, AppSizes.xl, hPad, AppSizes.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Tambah Produk' : 'Ubah Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textP(context),
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
              label: 'Emoji (opsional)',
              child: AppTextField(
                controller: _emoji,
                hint: 'Mis. 🍚 (kosongkan untuk otomatis dari nama)',
              ),
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
              onChanged: (value) => setState(() => _active = value),
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

class _SettingsView extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _SettingsView({
    super.key,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = AppSizes.screenHorizontal(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppSizes.lg,
        hPad,
        AppSizes.xl,
      ),
      children: [
        const _PageHeading(
          title: 'Settings',
          subtitle: 'Manage admin session and refresh platform data.',
        ),
        _Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Refresh Data',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Load the latest platform records.'),
                onTap: onRefresh,
              ),
              Divider(height: 1, color: AppColors.div(context)),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text('Exit from admin dashboard.'),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionGroup {
  final String userId;
  final String userName;
  final List<AdminCoinTransactionRecord> transactions;

  const _TransactionGroup({
    required this.userId,
    required this.userName,
    required this.transactions,
  });
}

List<_TransactionGroup> _groupTransactions(
  List<AdminCoinTransactionRecord> transactions,
) {
  final grouped = <String, List<AdminCoinTransactionRecord>>{};
  for (final transaction in transactions) {
    grouped.putIfAbsent(transaction.userId, () => []).add(transaction);
  }
  return grouped.entries
      .map(
        (entry) => _TransactionGroup(
          userId: entry.key,
          userName: entry.value.first.userName,
          transactions: entry.value,
        ),
      )
      .toList();
}

class _TransactionGroupTile extends StatelessWidget {
  final _TransactionGroup group;
  final bool expanded;
  final bool showDivider;
  final VoidCallback onTap;
  final Future<void> Function(AdminCoinTransactionRecord) onApprove;
  final Future<void> Function(AdminCoinTransactionRecord) onReject;

  const _TransactionGroupTile({
    required this.group,
    required this.expanded,
    required this.showDivider,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: AppColors.div(context)))
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  const _AvatarIcon(size: 38),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textP(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${group.transactions.length} Data',
                          style: TextStyle(
                            color: AppColors.textS(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color:
                        expanded ? AppColors.primary : AppColors.textT(context),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                0,
                AppSizes.lg,
                AppSizes.lg,
              ),
              child: Column(
                children: [
                  for (final transaction in group.transactions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      child: _TransactionCard(
                        transaction: transaction,
                        onApprove: onApprove,
                        onReject: onReject,
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final AdminCoinTransactionRecord transaction;
  final Future<void> Function(AdminCoinTransactionRecord) onApprove;
  final Future<void> Function(AdminCoinTransactionRecord) onReject;

  const _TransactionCard({
    required this.transaction,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _busy = false;

  Future<void> _handleAction(Future<void> Function(AdminCoinTransactionRecord) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(widget.transaction);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isPending = tx.status == 'pending';
    final amountAbs = tx.amountGc.abs();
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfMuted(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transactionCode(tx.id),
                  style: TextStyle(
                    color: AppColors.textS(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(status: tx.status),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // Wallet / account info from description
          if (tx.description.trim().isNotEmpty)
            Text(
              tx.description,
              style: TextStyle(
                color: AppColors.textS(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$amountAbs GC',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: AppSizes.md),
            _busy
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Wrap(
                    spacing: AppSizes.sm,
                    children: [
                      _ActionButton(
                        label: 'Terima',
                        color: AppColors.primary,
                        onTap: () => _handleAction(widget.onApprove),
                      ),
                      _ActionButton(
                        label: 'Tolak',
                        color: AppColors.danger,
                        onTap: () => _handleAction(widget.onReject),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PageHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = AppSizes.isNarrow(context);
    return Padding(
      padding: EdgeInsets.only(bottom: narrow ? AppSizes.lg : AppSizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textP(context),
              fontSize: narrow ? 18 : 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textS(context),
              fontSize: narrow ? 13 : 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: 'Search by name, email, or ID...',
        prefixIcon: const Icon(Icons.search_rounded),
        fillColor: AppColors.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.lg,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.brd(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Panel({
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final inner = padding ?? EdgeInsets.all(AppSizes.panelPadding(context));
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.curve,
      width: double.infinity,
      padding: inner,
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.brd(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  final double size;

  const _AvatarIcon({this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: size * 0.48,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FF),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.recycling_rounded,
            size: 14,
            color: Color(0xFF1685E8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1685E8),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final palette = _statusPalette(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: palette.$1,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: palette.$2,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Text(label),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String message;

  const _EmptyLine(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textS(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _ErrorState({
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 36,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textS(context)),
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: onTap,
              child: const Text('Muat ulang'),
            ),
          ],
        ),
      ),
    );
  }
}

// Theme-aware section title so it stays readable in dark mode.
TextStyle _sectionTitleStyle(BuildContext context) => TextStyle(
      color: AppColors.textP(context),
      fontSize: 16,
      fontWeight: FontWeight.w800,
    );

(Color, Color) _statusPalette(String status) {
  switch (status) {
    case 'completed':
      return (AppColors.statusCompleted, AppColors.statusCompletedText);
    case 'pending':
      return (AppColors.statusPending, AppColors.statusPendingText);
    case 'process':
    case 'verified':
      return (AppColors.statusProcess, AppColors.statusProcessText);
    case 'rejected':
    case 'cancelled':
      return (AppColors.statusRejected, AppColors.statusRejectedText);
    default:
      return (AppColors.surfaceMuted, AppColors.textSecondary);
  }
}

String statusLabel(String status) {
  switch (status) {
    case 'completed':
      return 'SELESAI';
    case 'pending':
      return 'PENDING';
    case 'process':
      return 'PROSES';
    case 'verified':
      return 'VERIFIED';
    case 'rejected':
      return 'DITOLAK';
    case 'cancelled':
      return 'BATAL';
    default:
      return status.toUpperCase();
  }
}

String userCode(String id) => '#USR-${_cleanId(id, first: true)}';

String requestCode(AdminWasteRequestRecord request) {
  return request.type == 'EcoPick'
      ? 'PCK-${_cleanId(request.id)}'
      : 'DRP-${_cleanId(request.id)}';
}

String transactionCode(String id) => 'TX-${_cleanId(id)}';

List<int> _weeklyActivityValues(
  List<AdminWasteRequestRecord> requests,
  List<AdminCoinTransactionRecord> transactions,
) {
  final now = DateTime.now();
  final days = [
    for (var i = 6; i >= 0; i--)
      DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
  ];

  return [
    for (final day in days)
      requests.where((item) => _isSameDay(item.createdAt, day)).length +
          transactions.where((item) => _isSameDay(item.createdAt, day)).length,
  ];
}

List<String> _lastSevenDayLabels() {
  const labels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  final now = DateTime.now();
  return [
    for (var i = 6; i >= 0; i--)
      labels[DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: i))
              .weekday %
          7],
  ];
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

List<_ChartSlice> _requestMix(AdminDashboardSnapshot data) {
  return [
    _ChartSlice(
      label: 'EcoPick',
      value: data.ecopicks.length,
      color: AppColors.primary,
    ),
    _ChartSlice(
      label: 'EcoDrop',
      value: data.ecodrops.length,
      color: const Color(0xFF3B82F6),
    ),
    _ChartSlice(
      label: 'GreenCoin',
      value: data.transactions.length,
      color: const Color(0xFFF59E0B),
    ),
  ];
}

Map<String, int> _statusCounts(
  List<AdminWasteRequestRecord> requests,
  List<AdminCoinTransactionRecord> transactions,
) {
  final counts = <String, int>{};
  for (final item in requests) {
    counts[item.status] = (counts[item.status] ?? 0) + 1;
  }
  for (final item in transactions) {
    counts[item.status] = (counts[item.status] ?? 0) + 1;
  }
  return counts;
}

String _cleanId(String id, {bool first = false}) {
  final clean = id.replaceAll('-', '').toUpperCase();
  if (clean.isEmpty) return '0000';
  if (first) return clean.substring(0, clean.length < 8 ? clean.length : 8);
  final start = clean.length > 4 ? clean.length - 4 : 0;
  return clean.substring(start);
}

String _compactDouble(double value) {
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
