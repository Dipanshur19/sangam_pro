// lib/presentation/providers/providers.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction.dart' as entity;
import '../../domain/entities/customer.dart';
import '../../domain/entities/sms_entry.dart';
import '../../domain/entities/store_profile.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/product.dart';
import '../../services/auth_service.dart';
import '../../services/sms_service.dart';

// ── Auth / session ────────────────────────────────────
final authServiceProvider = Provider<AuthService>((_) => AuthService());

/// The currently logged-in user (null = logged out). Restores the saved session
/// on startup.
class SessionNotifier extends StateNotifier<AppUser?> {
  final AuthService _auth;
  bool _restored = false;
  SessionNotifier(this._auth) : super(null) {
    _restore();
  }

  Future<void> _restore() async {
    state = await _auth.getSessionUser();
    _restored = true;
  }

  bool get isRestored => _restored;

  Future<AppUser?> login({required String username, required String password, required UserRole role}) async {
    final user = await _auth.verify(username: username, password: password, role: role);
    if (user != null) {
      await _auth.setSession(user.id);
      state = user;
    }
    return user;
  }

  /// Used right after creating the admin during setup to start a session.
  Future<void> setUser(AppUser user) async {
    await _auth.setSession(user.id);
    state = user;
  }

  Future<void> logout() async {
    await _auth.clearSession();
    state = null;
  }
}

final currentUserProvider = StateNotifierProvider<SessionNotifier, AppUser?>(
  (ref) => SessionNotifier(ref.watch(authServiceProvider)),
);

final usersProvider = FutureProvider<List<AppUser>>((ref) => ref.watch(authServiceProvider).getUsers());
final hasAdminProvider = FutureProvider<bool>((ref) => ref.watch(authServiceProvider).hasAdmin());

// ── SMS auto-read ─────────────────────────────────────
final smsServiceProvider = Provider<SmsService>((_) => SmsService());

/// Whether automatic UPI SMS reading is enabled. Persists the choice, requests
/// permission, scans recent inbox messages, and listens for new ones while the
/// app is open — pushing parsed payments into [smsQueueProvider].
class SmsAutoReadNotifier extends StateNotifier<bool> {
  final Ref _ref;
  static const _key = 'sangam_sms_auto';
  SmsAutoReadNotifier(this._ref) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_key) ?? false) {
      state = true;
      await scanNow();
      _ref.read(smsServiceProvider).listenIncoming(_onEntry);
    }
  }

  void _onEntry(SmsEntry e) => _ref.read(smsQueueProvider.notifier).add(e);

  Future<bool> enable() async {
    final granted = await _ref.read(smsServiceProvider).requestPermission();
    if (!granted) return false;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
    state = true;
    await scanNow();
    _ref.read(smsServiceProvider).listenIncoming(_onEntry);
    return true;
  }

  Future<void> disable() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, false);
    state = false;
  }

  /// Scan the recent inbox now. Returns the number of payments found.
  Future<int> scanNow() async {
    final entries = await _ref.read(smsServiceProvider).readRecentUpiSms(days: 3);
    for (final e in entries) {
      _ref.read(smsQueueProvider.notifier).add(e);
    }
    return entries.length;
  }
}

final smsAutoReadProvider = StateNotifierProvider<SmsAutoReadNotifier, bool>(
  (ref) => SmsAutoReadNotifier(ref),
);

// ── Local source with demo data ───────────────────────
class LocalSource {
  static const _custsKey  = 'sangam_custs';
  static const _txnsKey   = 'sangam_txns';
  static const _seededKey = 'sangam_seeded_v2';
  static const _profileKey = 'sangam_store_profile';
  static const _productsKey = 'sangam_products';
  static const _uuid = Uuid();

  SharedPreferences? _p;
  Future<SharedPreferences> get _prefs async => _p ??= await SharedPreferences.getInstance();

  /// Ensures local storage is ready. Does NOT auto-seed demo data anymore —
  /// new shop owners choose between a fresh start and demo data during setup.
  Future<void> ensureSeeded() async {
    await _prefs;
  }

  // ── Store profile ──
  Future<StoreProfile> getStoreProfile() async {
    final p = await _prefs;
    final raw = p.getString(_profileKey);
    if (raw == null) return StoreProfile.empty;
    return StoreProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStoreProfile(StoreProfile profile) async {
    final p = await _prefs;
    await p.setString(_profileKey, jsonEncode(profile.toMap()));
  }

  /// Seed demo customers + transactions (used for "Try with demo data").
  Future<void> seedDemoData() async {
    final p = await _prefs;
    await _saveCustomers(_seedCustomers());
    await _saveTransactions(_seedTransactions());
    await p.setBool(_seededKey, true);
  }

  /// Start with an empty ledger (used for a real shop's first launch).
  Future<void> startFresh() async {
    final p = await _prefs;
    await _saveCustomers([]);
    await _saveTransactions([]);
    await p.setBool(_seededKey, true);
  }

  /// Erase all transactions and customers but keep the store profile.
  Future<void> clearAllData() async {
    await _saveCustomers([]);
    await _saveTransactions([]);
  }

  List<Customer> _seedCustomers() => [
    Customer(id:'c1',name:'Ramesh Gupta',   phone:'9876543210',createdAt:DateTime.now().subtract(const Duration(days:30))),
    Customer(id:'c2',name:'Kavita Devi',    phone:'9765432109',createdAt:DateTime.now().subtract(const Duration(days:25))),
    Customer(id:'c3',name:'Mohan Sharma',   phone:'9654321098',createdAt:DateTime.now().subtract(const Duration(days:20))),
    Customer(id:'c4',name:'Sunita Singh',   phone:'9543210987',createdAt:DateTime.now().subtract(const Duration(days:15))),
    Customer(id:'c5',name:'Raju Prasad',    phone:'9432109876',createdAt:DateTime.now().subtract(const Duration(days:10))),
    Customer(id:'c6',name:'Priya Kumari',   phone:'9321098765',createdAt:DateTime.now().subtract(const Duration(days:8))),
    Customer(id:'c7',name:'Vikram Yadav',   phone:'9210987654',createdAt:DateTime.now().subtract(const Duration(days:5))),
  ];

  List<entity.Transaction> _seedTransactions() {
    final now = DateTime.now();
    DateTime ago(int d) => now.subtract(Duration(days:d));
    return [
      entity.Transaction(id:_uuid.v4(),customerId:'c1',customerName:'Ramesh Gupta',  amount:350,type:entity.TransactionType.credit,    direction:entity.TransactionDirection.outgoing,note:'Atta 10kg, Dal 2kg',  date:ago(12)),
      entity.Transaction(id:_uuid.v4(),customerId:'c1',customerName:'Ramesh Gupta',  amount:200,type:entity.TransactionType.upiPaytm,  direction:entity.TransactionDirection.incoming,note:'Partial payment',     date:ago(8)),
      entity.Transaction(id:_uuid.v4(),customerId:'c2',customerName:'Kavita Devi',   amount:180,type:entity.TransactionType.credit,    direction:entity.TransactionDirection.outgoing,note:'Rice 5kg, Sugar 2kg', date:ago(5)),
      entity.Transaction(id:_uuid.v4(),customerId:'c3',customerName:'Mohan Sharma',  amount:500,type:entity.TransactionType.credit,    direction:entity.TransactionDirection.outgoing,note:'Monthly grocery',     date:ago(15)),
      entity.Transaction(id:_uuid.v4(),customerId:'c3',customerName:'Mohan Sharma',  amount:500,type:entity.TransactionType.upiGpay,   direction:entity.TransactionDirection.incoming,note:'Full payment',        date:ago(10)),
      entity.Transaction(id:_uuid.v4(),customerId:'c4',customerName:'Sunita Singh',  amount:600,type:entity.TransactionType.credit,    direction:entity.TransactionDirection.outgoing,note:'Cooking oil, biscuits',date:ago(12)),
      entity.Transaction(id:_uuid.v4(),customerId:'c4',customerName:'Sunita Singh',  amount:200,type:entity.TransactionType.cash,      direction:entity.TransactionDirection.incoming,note:'Part payment',        date:ago(7)),
      entity.Transaction(id:_uuid.v4(),customerId:'c5',customerName:'Raju Prasad',   amount:250,type:entity.TransactionType.credit,    direction:entity.TransactionDirection.outgoing,note:'Soap, shampoo, chips',date:ago(7)),
      entity.Transaction(id:_uuid.v4(),customerId:'c6',customerName:'Priya Kumari',  amount:420,type:entity.TransactionType.credit,    direction:entity.TransactionDirection.outgoing,note:'Monthly grocery',     date:ago(1)),
      entity.Transaction(id:_uuid.v4(),customerName:'Walk-in',amount:480,type:entity.TransactionType.upiPaytm,  direction:entity.TransactionDirection.incoming,date:now),
      entity.Transaction(id:_uuid.v4(),customerName:'Walk-in',amount:320,type:entity.TransactionType.upiGpay,   direction:entity.TransactionDirection.incoming,date:now),
      entity.Transaction(id:_uuid.v4(),customerName:'Walk-in',amount:150,type:entity.TransactionType.upiPhonePe,direction:entity.TransactionDirection.incoming,date:now),
      entity.Transaction(id:_uuid.v4(),customerName:'Walk-in',amount:750,type:entity.TransactionType.upiPaytm,  direction:entity.TransactionDirection.incoming,date:now),
      entity.Transaction(id:_uuid.v4(),customerName:'Walk-in',amount:200,type:entity.TransactionType.upiGpay,   direction:entity.TransactionDirection.incoming,date:now),
      entity.Transaction(id:_uuid.v4(),customerName:'Walk-in',amount:1200,type:entity.TransactionType.cash,     direction:entity.TransactionDirection.incoming,date:now),
      entity.Transaction(id:_uuid.v4(),customerName:'Walk-in',amount:350,type:entity.TransactionType.cash,      direction:entity.TransactionDirection.incoming,date:now),
      entity.Transaction(id:_uuid.v4(),customerId:'c7',customerName:'Vikram Yadav', amount:310,type:entity.TransactionType.upiGpay, direction:entity.TransactionDirection.incoming,note:'Cleared dues',date:now),
    ];
  }

  // Customers
  Future<List<Customer>> getCustomers() async {
    final p = await _prefs;
    final raw = p.getString(_custsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => _custFromMap(e)).toList();
  }

  Future<void> addCustomer(Customer c) async {
    final all = await getCustomers(); all.add(c); await _saveCustomers(all);
  }

  Future<void> _saveCustomers(List<Customer> list) async {
    final p = await _prefs;
    await p.setString(_custsKey, jsonEncode(list.map(_custToMap).toList()));
  }

  // Transactions
  Future<List<entity.Transaction>> getTransactions() async {
    final p = await _prefs;
    final raw = p.getString(_txnsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => _txnFromMap(e)).toList()
      ..sort((a,b) => b.date.compareTo(a.date));
  }

  Future<void> addTransaction(entity.Transaction t) async {
    final all = await getTransactions(); all.insert(0,t); await _saveTransactions(all);
  }

  Future<void> _saveTransactions(List<entity.Transaction> list) async {
    final p = await _prefs;
    await p.setString(_txnsKey, jsonEncode(list.map(_txnToMap).toList()));
  }

  // Products / Stock
  Future<List<Product>> getProducts() async {
    final p = await _prefs;
    final raw = p.getString(_productsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map))).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> addProduct(Product item) async {
    final all = await getProducts(); all.add(item); await _saveProducts(all);
  }

  Future<void> updateProduct(Product item) async {
    final all = await getProducts();
    final idx = all.indexWhere((p) => p.id == item.id);
    if (idx >= 0) all[idx] = item; else all.add(item);
    await _saveProducts(all);
  }

  Future<void> deleteProduct(String id) async {
    final all = await getProducts();
    all.removeWhere((p) => p.id == id);
    await _saveProducts(all);
  }

  Future<void> _saveProducts(List<Product> list) async {
    final p = await _prefs;
    await p.setString(_productsKey, jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  // Computed
  Future<double> getBalance(String custId) async {
    final txns = await getTransactions();
    return txns.where((t) => t.customerId == custId).fold<double>(0.0, (s,t) =>
        t.direction == entity.TransactionDirection.outgoing ? s + t.amount : s - t.amount);
  }

  Future<DailyTotals> getDailyTotals(DateTime date) async {
    final txns = await getTransactions();
    final today = txns.where((t) => _sameDay(t.date, date)).toList();
    double paytm=0, gpay=0, phonePe=0, cash=0, creditOut=0, creditIn=0;
    for (final t in today) {
      if (t.direction == entity.TransactionDirection.incoming) {
        switch(t.type) {
          case entity.TransactionType.upiPaytm:   paytm += t.amount; break;
          case entity.TransactionType.upiGpay:    gpay += t.amount; break;
          case entity.TransactionType.upiPhonePe: phonePe += t.amount; break;
          case entity.TransactionType.cash:       cash += t.amount; break;
          case entity.TransactionType.credit:     creditIn += t.amount; break;
        }
      } else { if (t.type == entity.TransactionType.credit) creditOut += t.amount; }
    }
    return DailyTotals(paytm:paytm, gpay:gpay, phonePe:phonePe, cash:cash, creditOut:creditOut, creditIn:creditIn, txnCount:today.length);
  }

  Future<List<OverdueCustomer>> getOverdueCustomers({int dueDays = 7}) async {
    final custs = await getCustomers();
    final txns  = await getTransactions();
    final result = <OverdueCustomer>[];
    for (final c in custs) {
      final bal = txns.where((t) => t.customerId == c.id).fold<double>(0.0, (s,t) =>
          t.direction == entity.TransactionDirection.outgoing ? s + t.amount : s - t.amount);
      if (bal <= 0) continue;
      final lastCredit = txns.where((t) => t.customerId == c.id && t.type == entity.TransactionType.credit && t.direction == entity.TransactionDirection.outgoing).toList()
        ..sort((a,b) => b.date.compareTo(a.date));
      if (lastCredit.isEmpty) continue;
      final days = DateTime.now().difference(lastCredit.first.date).inDays;
      result.add(OverdueCustomer(customerId:c.id, customerName:c.name, phone:c.phone, balance:bal, daysOverdue:days-dueDays));
    }
    result.sort((a,b) => b.daysOverdue.compareTo(a.daysOverdue));
    return result;
  }

  Future<void> resetToDemo() async {
    await seedDemoData();
  }

  bool _sameDay(DateTime a, DateTime b) => a.year==b.year && a.month==b.month && a.day==b.day;

  // Serialization helpers
  Map<String,dynamic> _custToMap(Customer c) => {'id':c.id,'name':c.name,'phone':c.phone,'createdAt':c.createdAt.toIso8601String()};
  Customer _custFromMap(Map<String,dynamic> m) => Customer(id:m['id'],name:m['name'],phone:m['phone'],createdAt:DateTime.parse(m['createdAt']));
  Map<String,dynamic> _txnToMap(entity.Transaction t) => {'id':t.id,'customerId':t.customerId,'customerName':t.customerName,'amount':t.amount,'type':t.type.firestoreKey,'direction':t.direction==entity.TransactionDirection.incoming?'in':'out','note':t.note,'date':t.date.toIso8601String(),'source':t.source};
  entity.Transaction _txnFromMap(Map<String,dynamic> m) => entity.Transaction(id:m['id'],customerId:m['customerId'],customerName:m['customerName']??'Walk-in',amount:(m['amount'] as num).toDouble(),type:entity.TransactionTypeExt.fromKey(m['type']??'cash'),direction:m['direction']=='in'?entity.TransactionDirection.incoming:entity.TransactionDirection.outgoing,note:m['note'],date:DateTime.parse(m['date']),source:m['source']??'manual');
}

// ── Riverpod Providers ────────────────────────────────
final localSourceProvider = Provider<LocalSource>((_) => LocalSource());

final appInitProvider = FutureProvider<void>((ref) => ref.watch(localSourceProvider).ensureSeeded());

// ── Store profile ──
class StoreProfileNotifier extends StateNotifier<StoreProfile> {
  final LocalSource _source;
  StoreProfileNotifier(this._source) : super(StoreProfile.empty) {
    _load();
  }

  Future<void> _load() async {
    state = await _source.getStoreProfile();
  }

  Future<void> save(StoreProfile profile) async {
    await _source.saveStoreProfile(profile);
    state = profile;
  }

  Future<void> reload() => _load();
}

final storeProfileProvider = StateNotifierProvider<StoreProfileNotifier, StoreProfile>(
  (ref) => StoreProfileNotifier(ref.watch(localSourceProvider)),
);

final _txnStreamCtrl = StreamProvider<List<entity.Transaction>>((ref) async* {
  await ref.watch(appInitProvider.future);
  yield await ref.watch(localSourceProvider).getTransactions();
});

final transactionsStreamProvider = _txnStreamCtrl;

final addTransactionProvider = Provider<Future<void> Function(entity.Transaction)>((ref) {
  return (t) async {
    await ref.read(localSourceProvider).addTransaction(t);
    ref.invalidate(_txnStreamCtrl);
    ref.invalidate(todayTotalsProvider);
    ref.invalidate(overdueCustomersProvider);
  };
});

final todayTotalsProvider = FutureProvider<DailyTotals>((ref) async {
  ref.watch(_txnStreamCtrl);
  return ref.read(localSourceProvider).getDailyTotals(DateTime.now());
});

final customersStreamProvider = StreamProvider<List<Customer>>((ref) async* {
  await ref.watch(appInitProvider.future);
  yield await ref.read(localSourceProvider).getCustomers();
});

final addCustomerProvider = Provider<Future<void> Function(Customer)>((ref) {
  return (c) async {
    await ref.read(localSourceProvider).addCustomer(c);
    ref.invalidate(customersStreamProvider);
  };
});

final customerBalanceProvider = FutureProvider.family<double, String>((ref, custId) {
  ref.watch(_txnStreamCtrl);
  return ref.read(localSourceProvider).getBalance(custId);
});

final customerTransactionsProvider = FutureProvider.family<List<entity.Transaction>, String>((ref, custId) async {
  ref.watch(_txnStreamCtrl);
  final all = await ref.read(localSourceProvider).getTransactions();
  return all.where((t) => t.customerId == custId).toList();
});

final overdueCustomersProvider = FutureProvider<List<OverdueCustomer>>((ref) {
  ref.watch(_txnStreamCtrl);
  final dueDays = ref.watch(storeProfileProvider).creditDueDays;
  return ref.read(localSourceProvider).getOverdueCustomers(dueDays: dueDays);
});

// ── Products / Stock ──
final productsStreamProvider = StreamProvider<List<Product>>((ref) async* {
  await ref.watch(appInitProvider.future);
  yield await ref.read(localSourceProvider).getProducts();
});

final saveProductProvider = Provider<Future<void> Function(Product)>((ref) {
  return (item) async {
    await ref.read(localSourceProvider).updateProduct(item);
    ref.invalidate(productsStreamProvider);
  };
});

final deleteProductProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    await ref.read(localSourceProvider).deleteProduct(id);
    ref.invalidate(productsStreamProvider);
  };
});

final smsQueueProvider = StateNotifierProvider<_SmsQueueNotifier, List<SmsEntry>>((_) => _SmsQueueNotifier());

class _SmsQueueNotifier extends StateNotifier<List<SmsEntry>> {
  _SmsQueueNotifier() : super([]);
  void add(SmsEntry e) { if (!state.any((s) => s.id == e.id)) state = [...state, e]; }
  void dismiss(String id) { state = state.map((e) => e.id==id ? SmsEntry(id:e.id,rawSms:e.rawSms,parsedAmount:e.parsedAmount,parsedSource:e.parsedSource,receivedAt:e.receivedAt,status:'dismissed') : e).toList(); }
  void clear() => state = state.where((e) => e.status=='pending').toList();
  List<SmsEntry> get pending => state.where((e) => e.status=='pending').toList();
}

final onboardedProvider = FutureProvider<bool>((ref) async {
  final p = await SharedPreferences.getInstance();
  return p.getBool('sangam_onboarded') ?? false;
});
