import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/remote_user.dart';
import '../../../data/services/dummyjson_service.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import 'account_detail_screen.dart';
import 'remote_avatar.dart';

/// Ganti Akun — daftar akun dari API eksternal (GET dummyjson.com/users).
/// Mendukung pencarian (debounce), infinite scroll, pull-to-refresh,
/// skeleton loading, dan state error.
class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;

  final List<RemoteUser> _users = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  ApiException? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _load();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loadingMore || _loading || _users.length >= _total)) return;
    final id = ++_requestId;
    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final page = await context.read<DummyJsonService>().fetchUsers(
            skip: reset ? 0 : _users.length,
            query: _search.text,
          );
      if (!mounted || id != _requestId) return;
      setState(() {
        if (reset) _users.clear();
        _users.addAll(page.users);
        _total = page.total;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      if (reset) {
        setState(() => _error = e);
      } else {
        showSnack(context, e.message);
      }
    } finally {
      if (mounted && id == _requestId) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final activeRemote = context.watch<AppState>().activeProfile?.remoteId;
    return Scaffold(
      appBar: const AppTopBar(title: 'Ganti Akun'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari akun…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                fillColor: p.bgSubtle,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _search.clear();
                          _load(reset: true);
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: p.primary50, borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_rounded, size: 14, color: p.primary),
                    const SizedBox(width: 6),
                    Text(
                      _loading ? 'Memuat dari dummyjson.com/users…' : 'Akun dari dummyjson.com/users · $_total akun',
                      style: AppText.caption.c(p.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _body(activeRemote)),
        ],
      ),
    );
  }

  Widget _body(int? activeRemote) {
    final p = context.palette;
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const SkeletonBox(width: 44, height: 44, circle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140.0 - (i % 3) * 20, height: 12),
                    const SizedBox(height: 8),
                    SkeletonBox(width: 200.0 - (i % 2) * 30, height: 10),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 100, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: p.warning50, shape: BoxShape.circle),
                child: Icon(Icons.wifi_off_rounded, size: 44, color: p.warning),
              ),
              const SizedBox(height: 16),
              Text('Gagal memuat daftar akun', style: AppText.h2.c(p.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Periksa koneksi internet Anda lalu coba lagi. Daftar akun diambil dari server eksternal.',
                style: AppText.body.c(p.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: p.bgMuted, borderRadius: BorderRadius.circular(8)),
                child: Text(_error.toString(), style: AppText.caption.c(p.textTertiary), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              AppButton(label: 'Coba Lagi', icon: Icons.refresh_rounded, onPressed: () => _load(reset: true)),
            ],
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined, size: 48, color: p.textTertiary),
            const SizedBox(height: 10),
            Text('Akun "${_search.text}" tidak ditemukan', style: AppText.title.c(p.textPrimary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _users.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i >= _users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
            );
          }
          final u = _users[i];
          final active = u.id == activeRemote;
          return Material(
            color: active ? p.primary50 : p.bgSubtle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: active ? BorderSide(color: p.primary) : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => push(context, AccountDetailScreen(user: u)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    RemoteAvatar(user: u, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(u.fullName, style: AppText.title.c(p.textPrimary), overflow: TextOverflow.ellipsis)),
                              if (active) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(99)),
                                  child: Text('Aktif', style: AppText.labelSm.c(p.textOnPrimary)),
                                ),
                              ],
                            ],
                          ),
                          Text(u.email, style: AppText.caption.c(p.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            '${u.genderLabel} · ${u.age} th · ${u.city}',
                            style: AppText.caption.c(p.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
