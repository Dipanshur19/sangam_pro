import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/usecases/sms_parser.dart';
import '../domain/entities/transaction.dart';
import '../domain/entities/sms_entry.dart';

class SmsService {
  static const _lastSmsKey = 'last_sms_timestamp';

  /// Request SMS permissions (Android only)
  static Future<bool> requestPermissions() async {
    final status = await [
      Permission.sms,
      Permission.phone,
    ].request();
    return status[Permission.sms]?.isGranted ?? false;
  }

  static Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Read recent UPI SMS messages from device inbox
  /// Uses platform channel since telephony package needs integration
  static Future<List<SmsEntry>> readRecentUpiSms() async {
    final granted = await hasPermission();
    if (!granted) return [];

    // Note: In production, use telephony package:
    // final telephony = Telephony.instance;
    // final messages = await telephony.getInboxSms(
    //   columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    //   filter: SmsFilter.where(SmsColumn.DATE).greaterThan(lastTimestamp.toString()),
    // );

    // For POC, read last 24 hours of SMS and filter UPI ones
    final prefs = await SharedPreferences.getInstance();
    final lastTs = prefs.getInt(_lastSmsKey) ?? 0;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final cutoffMs = lastTs > 0 ? lastTs : cutoff.millisecondsSinceEpoch;

    // Store the timestamp for next poll
    await prefs.setInt(_lastSmsKey, DateTime.now().millisecondsSinceEpoch);

    // Return empty - actual SMS reading requires device + telephony package
    // This is the integration point
    return [];
  }

  /// Parse a single SMS text into a SmsEntry
  static SmsEntry? parseSmsToEntry(String smsText, DateTime receivedAt) {
    if (!SmsParser.isUpiSms(smsText)) return null;
    final parsed = SmsParser.parse(smsText);
    if (parsed.amount == null) return null;

    return SmsEntry(
      id: '${receivedAt.millisecondsSinceEpoch}',
      rawSms: smsText,
      parsedAmount: parsed.amount,
      parsedSource: parsed.source,
      receivedAt: receivedAt,
      status: 'pending',
    );
  }

  /// Get demo SMS list for testing
  static List<SmsEntry> getDemoSmsList() {
    final now = DateTime.now();
    return [
      SmsEntry(
        id: 'demo1',
        rawSms: 'Rs.480 received in Paytm Wallet from John Doe on ${now.toString().substring(0, 10)}',
        parsedAmount: 480,
        parsedSource: TransactionType.upiPaytm,
        receivedAt: now.subtract(const Duration(minutes: 5)),
        status: 'pending',
      ),
      SmsEntry(
        id: 'demo2',
        rawSms: 'You have received Rs.320 in your Google Pay account from Jane Smith',
        parsedAmount: 320,
        parsedSource: TransactionType.upiGpay,
        receivedAt: now.subtract(const Duration(minutes: 15)),
        status: 'pending',
      ),
      SmsEntry(
        id: 'demo3',
        rawSms: 'PhonePe: Rs.150 credited to your account from Bob Johnson',
        parsedAmount: 150,
        parsedSource: TransactionType.upiPhonePe,
        receivedAt: now.subtract(const Duration(minutes: 30)),
        status: 'pending',
      ),
    ];
  }
}

// ── SMS Provider for state ──────────────────────────
class SmsQueueNotifier {
  final List<SmsEntry> _queue = [];
  List<SmsEntry> get pending => _queue.where((e) => e.status == 'pending').toList();

  void addEntry(SmsEntry entry) {
    if (!_queue.any((e) => e.id == entry.id)) {
      _queue.add(entry);
    }
  }

  void dismissEntry(String id) {
    final idx = _queue.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _queue[idx] = SmsEntry(
        id: _queue[idx].id, rawSms: _queue[idx].rawSms,
        parsedAmount: _queue[idx].parsedAmount, parsedSource: _queue[idx].parsedSource,
        receivedAt: _queue[idx].receivedAt, status: 'dismissed',
      );
    }
  }

  void clearProcessed() {
    _queue.removeWhere((e) => e.status != 'pending');
  }
}
