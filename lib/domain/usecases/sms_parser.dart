import '../entities/transaction.dart';

class ParsedSms {
  final double? amount;
  final TransactionType? source;
  final bool isIncoming;

  const ParsedSms({this.amount, this.source, this.isIncoming = true});
}

/// Heuristic parser for Indian UPI / bank payment SMS.
///
/// Handles the common real-world formats from Paytm, Google Pay, PhonePe, BHIM
/// and bank account alerts (credited / debited / received / sent / spent), with
/// amounts written as `Rs`, `Rs.`, `INR` or `₹`, with commas and decimals.
class SmsParser {
  // Rs.1,234.56 / INR 1234 / ₹500
  static final RegExp _amountBefore =
      RegExp(r'(?:rs\.?|inr|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)', caseSensitive: false);
  // 1,234.56 Rs / 500INR
  static final RegExp _amountAfter =
      RegExp(r'([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(?:rs\.?|inr|₹)', caseSensitive: false);
  // "amount of 500" / "for 500"
  static final RegExp _amountLoose =
      RegExp(r'(?:amount|amt|for|of)\s*(?:rs\.?|inr|₹)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)', caseSensitive: false);

  static const List<String> _incomingKeywords = [
    'credited', 'received', 'recieved', 'deposited', 'refund', 'added', 'credited to',
  ];
  static const List<String> _outgoingKeywords = [
    'debited', 'spent', 'paid', 'sent', 'withdrawn', 'deducted', 'purchase', 'transferred',
  ];

  static double? _extractAmount(String sms) {
    for (final re in [_amountBefore, _amountAfter, _amountLoose]) {
      final m = re.firstMatch(sms);
      if (m != null) {
        final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (v != null && v > 0) return v;
      }
    }
    return null;
  }

  static TransactionType? _detectSource(String t) {
    if (t.contains('paytm')) return TransactionType.upiPaytm;
    if (t.contains('phonepe') || t.contains('phone pe')) return TransactionType.upiPhonePe;
    if (t.contains('google pay') || t.contains('gpay') || t.contains('g pay') || t.contains('tez')) {
      return TransactionType.upiGpay;
    }
    // BHIM / generic UPI / IMPS / bank — bucket under UPI (Paytm icon as default).
    if (t.contains('bhim') || t.contains('upi') || t.contains('imps') || t.contains('neft')) {
      return TransactionType.upiPaytm;
    }
    return null;
  }

  /// Earliest position of any keyword in [t], or -1 if none present.
  static int _earliest(String t, List<String> keywords) {
    int best = -1;
    for (final k in keywords) {
      final i = t.indexOf(k);
      if (i >= 0 && (best < 0 || i < best)) best = i;
    }
    return best;
  }

  static ParsedSms parse(String sms) {
    final t = sms.toLowerCase();
    final amount = _extractAmount(sms);
    final source = _detectSource(t);

    final inAt = _earliest(t, _incomingKeywords);
    final outAt = _earliest(t, _outgoingKeywords);

    // Whichever keyword appears first wins; default to incoming for shop payments.
    bool isIncoming = true;
    if (outAt >= 0 && (inAt < 0 || outAt < inAt)) {
      isIncoming = false;
    }

    return ParsedSms(amount: amount, source: source, isIncoming: isIncoming);
  }

  /// True if the message looks like a payment/transaction SMS worth queuing.
  static bool isUpiSms(String sms) {
    final t = sms.toLowerCase();
    final hasAmount = _extractAmount(sms) != null;
    if (!hasAmount) return false;

    final hasTxnWord = _incomingKeywords.any(t.contains) || _outgoingKeywords.any(t.contains);
    final hasChannel = ['upi', 'paytm', 'phonepe', 'phone pe', 'google pay', 'gpay', 'g pay',
            'bhim', 'imps', 'neft', 'a/c', 'acct', 'account', 'wallet']
        .any(t.contains);

    // Avoid OTP / promotional noise: need both an amount and either a
    // transaction verb or a payment channel mention.
    final looksPromo = t.contains('otp') || t.contains('one time password') || t.contains('cashback offer');
    return (hasTxnWord || hasChannel) && !looksPromo;
  }
}
