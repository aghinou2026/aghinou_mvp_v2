import 'package:supabase_flutter/supabase_flutter.dart';

const int aghinouMonthlyPriceRial = 350000;

class SubscriptionService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<bool> hasActiveSubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from('payments')
        .select('subscription_expires_at')
        .eq('user_id', user.id)
        .eq('status', 'paid')
        .gt('subscription_expires_at', now)
        .order('subscription_expires_at', ascending: false)
        .limit(1);
    return rows.isNotEmpty;
  }

  static Future<Map<String, dynamic>> createPayment() async {
    final response = await _client.functions.invoke(
      'bitpay-payment',
      body: const {'action': 'create'},
    );
    final data = response.data;
    if (data is! Map) throw Exception('پاسخ درگاه پرداخت نامعتبر است.');
    final result = Map<String, dynamic>.from(data);
    final paymentUrl = '${result['payment_url'] ?? ''}';
    if (paymentUrl.isEmpty) {
      throw Exception('${result['message'] ?? 'لینک پرداخت ایجاد نشد.'}');
    }
    return result;
  }
}
