// lib/presentation/providers/providers.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction.dart' as entity;
import '../../domain/entities/customer.dart';
import '../../domain/entities/sms_entry.dart';
import '../../core/constants.dart';

// ── Auth Service ──────────────────────────────────────
class AuthService {
  final _auth = FirebaseAuth.instance;
  String? _verificationId;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendOtp(String phone) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (cred) async => await _auth.signInWithCredential(cred),
      verificationFailed: (e) => throw e,
      codeSent: (vId, _) => _verificationId = vId,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<bool> verifyOtp(String otp) async {
    if (_verificationId == null) return false;
    try {
      final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: otp);
      await _auth.signInWithCredential(cred);
      return true;
    } catch (_) { return false; }
  }

  Future<void> signOut() => _auth.signOut();
  User? get currentUser => _auth.currentUser;
}

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authServiceProvider).authStateChanges);

// ── Local source with demo data ───────────────────────
class LocalSource {
  static const _custsKey  = 'sangam_custs';
  static const _txnsKey   = 'sangam_txns';
  static const _seededKey = 'sangam_seeded_v2';
  static const _uuid = Uuid();

  SharedPreferences? _p;
  Future<SharedPreferences> get _prefs async => _p ??= await SharedPreferences.getInstance();

  Future<void> ensureSeeded() async {
    final p = await _prefs;
    if (p.getBool(_seededKey) == true) return;
    await _saveCustomers(_seedCustomers());
    await _saveTransactions(_seedTransactions());
    await p.setBool(_seededKey, true);
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

  Future<List<OverdueCustomer>> getOverdueCustomers() async {
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
      result.add(OverdueCustomer(customerId:c.id, customerName:c.name, phone:c.phone, balance:bal, daysOverdue:days-7));
    }
    result.sort((a,b) => b.daysOverdue.compareTo(a.daysOverdue));
    return result;
  }

  Future<void> resetToDemo() async {
    final p = await _prefs;
    await p.remove(_seededKey);
    await ensureSeeded();
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
  return ref.read(localSourceProvider).getOverdueCustomers();
});

final smsQueueProvider = StateNotifierProvider<_SmsQueueNotifier, List<SmsEntry>>((_) => _SmsQueueNotifier());

class _SmsQueueNotifier extends StateNotifier<List<SmsEntry>> {
  _SmsQueueNotifier() : super([]);
  void add(SmsEntry e) { if (!state.any((s) => s.id == e.id)) state = [...state, e]; }
  void dismiss(String id) { state = state.map((e) => e.id==id ? SmsEntry(id:e.id,rawSms:e.rawSms,parsedAmount:e.parsedAmount,parsedSource:e.parsedSource,receivedAt:e.receivedAt,status:'dismissed') : e).toList(); }
  void clear() => state = state.where((e) => e.status=='pending').toList();
  List<SmsEntry> get pending => state.where((e) => e.status=='pending').toList();
}

final apiKeyProvider = FutureProvider<String?>((ref) async {
  final p = await SharedPreferences.getInstance();
  return p.getString('sangam_api_key');
});

final setApiKeyProvider = Provider<Future<void> Function(String)>((ref) {
  return (key) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sangam_api_key', key);
    ref.invalidate(apiKeyProvider);
  };
});

final onboardedProvider = FutureProvider<bool>((ref) async {
  final p = await SharedPreferences.getInstance();
  return p.getBool('sangam_onboarded') ?? false;
});
