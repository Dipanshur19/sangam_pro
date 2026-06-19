import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/entities/transaction.dart';
import '../domain/entities/sms_entry.dart';
import '../domain/usecases/sms_parser.dart';
import 'groq_service.dart';

/// Reads UPI payment SMS from the device and turns them into [SmsEntry]s.
///
/// Parsing uses the local regex [SmsParser] first; if that can't find an amount
/// and a Groq key is configured at build time, it falls back to [GroqService].
class SmsService {
  final Telephony _telephony = Telephony.instance;

  /// Ask the user for SMS read permission. Returns true if granted.
  /// Uses permission_handler so we request exactly the SMS group (READ/RECEIVE),
  /// matching the manifest, instead of also asking for phone permissions.
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async => Permission.sms.isGranted;

  Future<SmsEntry?> _toEntry(String body, DateTime receivedAt) async {
    if (body.isEmpty || !SmsParser.isUpiSms(body)) return null;
    ParsedSms parsed = SmsParser.parse(body);
    // Use Groq to recover the amount/details when the regex misses.
    if (parsed.amount == null && GroqService.isConfigured) {
      final g = await GroqService.parseSms(body);
      if (g != null) parsed = g;
    }
    if (parsed.amount == null) return null;
    return SmsEntry(
      id: '${receivedAt.millisecondsSinceEpoch}_${body.hashCode}',
      rawSms: body,
      parsedAmount: parsed.amount,
      parsedSource: parsed.source,
      receivedAt: receivedAt,
      status: 'pending',
    );
  }

  /// Scan the inbox for UPI payment SMS from the last [days] days.
  Future<List<SmsEntry>> readRecentUpiSms({int days = 3}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      );
      final entries = <SmsEntry>[];
      for (final m in messages) {
        final received = DateTime.fromMillisecondsSinceEpoch(m.date ?? 0);
        if (received.isBefore(cutoff)) continue;
        final e = await _toEntry(m.body ?? '', received);
        if (e != null) entries.add(e);
      }
      return entries;
    } catch (_) {
      return [];
    }
  }

  /// Listen for incoming SMS while the app is in the foreground.
  void listenIncoming(void Function(SmsEntry entry) onEntry) {
    try {
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage msg) async {
          final e = await _toEntry(msg.body ?? '', DateTime.now());
          if (e != null) onEntry(e);
        },
        listenInBackground: false,
      );
    } catch (_) {/* listening unavailable (e.g. iOS / no permission) */}
  }

  /// Sample messages used when demo data is loaded.
  static List<SmsEntry> getDemoSmsList() {
    final now = DateTime.now();
    return [
      SmsEntry(
        id: 'demo1',
        rawSms: 'Rs.480 received in your Paytm wallet. UPI Ref 4821.',
        parsedAmount: 480,
        parsedSource: TransactionType.upiPaytm,
        receivedAt: now.subtract(const Duration(minutes: 5)),
      ),
      SmsEntry(
        id: 'demo2',
        rawSms: 'You received Rs.320 via Google Pay (UPI).',
        parsedAmount: 320,
        parsedSource: TransactionType.upiGpay,
        receivedAt: now.subtract(const Duration(minutes: 15)),
      ),
      SmsEntry(
        id: 'demo3',
        rawSms: 'PhonePe: Rs.150 credited to your account.',
        parsedAmount: 150,
        parsedSource: TransactionType.upiPhonePe,
        receivedAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }
}
