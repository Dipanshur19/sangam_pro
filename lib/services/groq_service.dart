import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/transaction.dart';
import '../domain/usecases/sms_parser.dart';

/// Parses UPI payment SMS using the Groq API (OpenAI-compatible).
///
/// The API key is injected at build time and is NEVER shown in the app UI or
/// committed to source. Provide it when building/running:
///
///   flutter run --dart-define=GROQ_API_KEY=gsk_xxx
///   flutter build apk --release --dart-define=GROQ_API_KEY=gsk_xxx
///
/// If no key is provided, callers fall back to the local regex [SmsParser].
class GroqService {
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static bool get isConfigured => _apiKey.isNotEmpty;

  static const String _systemPrompt =
      'You extract structured data from Indian UPI/bank payment SMS messages. '
      'Respond ONLY with a compact JSON object, no prose. Schema: '
      '{"is_payment": boolean, "amount": number|null, '
      '"app": "paytm"|"gpay"|"phonepe"|"other", "direction": "in"|"out"}. '
      '"is_payment" is true only if money was actually credited or debited. '
      '"direction" is "in" for money received/credited, "out" for money sent/debited. '
      'Detect the app from words like Paytm, Google Pay/GPay, PhonePe. '
      'If unsure about the app use "other".';

  /// Returns a [ParsedSms] if Groq successfully parses a real payment, else null.
  static Future<ParsedSms?> parseSms(String sms) async {
    if (_apiKey.isEmpty) return null;
    try {
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'temperature': 0,
              'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': sms},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final content = body['choices']?[0]?['message']?['content'] as String?;
      if (content == null) return null;

      final parsed = jsonDecode(content) as Map<String, dynamic>;
      if (parsed['is_payment'] != true) return null;

      final amount = (parsed['amount'] as num?)?.toDouble();
      if (amount == null || amount <= 0) return null;

      final app = (parsed['app'] as String?)?.toLowerCase() ?? 'other';
      TransactionType? source;
      if (app == 'paytm') {
        source = TransactionType.upiPaytm;
      } else if (app == 'gpay') {
        source = TransactionType.upiGpay;
      } else if (app == 'phonepe') {
        source = TransactionType.upiPhonePe;
      } else {
        source = TransactionType.upiPaytm; // generic UPI fallback
      }

      final isIncoming = (parsed['direction'] as String?)?.toLowerCase() != 'out';
      return ParsedSms(amount: amount, source: source, isIncoming: isIncoming);
    } catch (_) {
      return null;
    }
  }
}
