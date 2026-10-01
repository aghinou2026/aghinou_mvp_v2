import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const String supabaseUrl = 'https://acfawprpdkzjpyblseay.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_uHov32wG1uTxNIkbQbaQmQ_6W5mCwKf';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const AghinouApp());
}

final supabase = Supabase.instance.client;

class AghinouApp extends StatelessWidget {
  const AghinouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'آگهینو',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C3FE8),
        ),
      ),
      home: supabase.auth.currentSession == null ? const LoginPage() : const HomePage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  bool loading = false;
  bool codeSent = false;

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> sendCode() async {
    final value = phone.text.trim().replaceAll(' ', '');
    final normalized = value.startsWith('0') ? '+98${value.substring(1)}' : value;
    if (!RegExp(r'^\+98\d{10}$').hasMatch(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل را به‌صورت 09123456789 وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(
        phone: normalized,
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() => codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد تأیید به شماره موبایل شما ارسال شد.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال کد انجام نشد: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyCode() async {
    final raw = phone.text.trim().replaceAll(' ', '');
    final value = raw.startsWith('0') ? '+98${raw.substring(1)}' : raw;
    final token = otp.text.trim();

    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ارسال‌شده را کامل وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final result = await supabase.auth.verifyOTP(
        phone: value,
        token: token,
        type: OtpType.sms,
      );

      final user = result.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw Exception('ورود تأیید نشد.');
      }

      await supabase.from('profiles').upsert(
        {
          'iidd': user.id,
          'name': 'کاربر آگهینو',
        },
        onConflict: 'iidd',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کد صحیح نیست یا منقضی شده است: ${e.message}')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای پروفایل: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 70),
                const SizedBox(height: 12),
                const Text(
                  'آگهینو',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('خرید و فروش آسان و مطمئن'),
                const SizedBox(height: 35),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'شماره موبایل',
                    hintText: '0912 123 4567',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'کد ورود',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : (codeSent ? verifyCode : sendCode),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(codeSent ? 'تأیید و ورود' : 'ارسال کد ورود'),
                    ),
                  ),
                ),
                if (codeSent)
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              codeSent = false;
                              otp.clear();
                            }),
                    child: const Text('تغییر شماره موبایل'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'ورود با کد یک‌بارمصرف پیامکی',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override State<FavoritesPage> createState() => _FavoritesPageState();
}
class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String,dynamic>> items=[]; bool loading=true;
  @override void initState(){super.initState(); load();}
  Future<void> load() async {
    final uid=supabase.auth.currentUser?.id;
    if(uid==null){if(mounted)setState(()=>loading=false);return;}
    try {
      final rows=await supabase.from('favorites').select('ad_id, ads(*)').eq('user_id',uid).order('created_at',ascending:false);
      if(!mounted)return; setState(()=>items=List<Map<String,dynamic>>.from(rows));
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت علاقه‌مندی‌ها انجام نشد: $e')));}
    if(mounted)setState(()=>loading=false);
  }
  Future<void> remove(String id) async {
    final uid=supabase.auth.currentUser?.id; if(uid==null)return;
    try {await supabase.from('favorites').delete().eq('user_id',uid).eq('ad_id',id); await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حذف انجام نشد: $e')));}
  }
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('علاقه‌مندی‌ها')),
    body:loading?const Center(child:CircularProgressIndicator()):items.isEmpty?const Center(child:Text('هنوز آگهی ذخیره‌شده‌ای ندارید.')):ListView.builder(
      padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(context,i){
        final ad=items[i]['ads'] is Map ? Map<String,dynamic>.from(items[i]['ads']) : <String,dynamic>{};
        final id=items[i]['ad_id'].toString();
        return Card(child:ListTile(title:Text('${ad['title']??'بدون عنوان'}'),subtitle:Text('${ad['price']??'توافقی'} تومان • ${ad['city']??''}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>remove(id))));
      }),
  ));
}
String normalizePersian(String value) {
  return value
      .toLowerCase()
      .replaceAll('ي', 'ی')
      .replaceAll('ى', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('ة', 'ه')
      .replaceAll('ۀ', 'ه')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loadingAds = true;
  bool loadingSubscription = true;
  bool hasActiveSubscription = false;
  DateTime? subscriptionExpiresAt;
  int subscriptionAdLimit = 9;
  int subscriptionAdsUsed = 0;
  String searchQuery = '';
  String? selectedCategory;
  List<Map<String, dynamic>> ads = [];

  static const categories = <String>[
    'خودرو','املاک','موبایل و تبلت','لوازم دیجیتال','لوازم خانگی',
    'مبلمان و دکوراسیون','پوشاک و کیف و کفش','وسایل نقلیه','خدمات',
    'استخدام و کاریابی','لوازم شخصی','سرگرمی و ورزش','کشاورزی و دامداری',
    'ابزار و تجهیزات','حیوانات','سایر',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => loadingSubscription = false);
      return;
    }

    try {
      final row = await supabase
          .from('subscriptions')
          .select('expires_at,ad_limit,ads_used')
          .eq('user_id', uid)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final expiresRaw = row?['expires_at']?.toString();
      final expires = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

      if (!mounted) return;
      setState(() {
        subscriptionExpiresAt = expires;
        subscriptionAdLimit = (row?['ad_limit'] as num?)?.toInt() ?? 9;
        subscriptionAdsUsed = (row?['ads_used'] as num?)?.toInt() ?? 0;
        hasActiveSubscription = expires != null && expires.isAfter(DateTime.now());
        loadingSubscription = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingSubscription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بررسی اشتراک انجام نشد: $e')),
      );
    }
  }

  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url)')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        ads = List<Map<String, dynamic>>.from(rows);
        loadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
      );
    }
  }

  int get myAdsCount {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    return ads.where((ad) => ad['seller_id'] == uid).length;
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = normalizePersian(searchQuery);
    return ads.where((ad) {
      final categoryOk = selectedCategory == null ||
          '${ad['category'] ?? ''}' == selectedCategory;
      final text = normalizePersian('${ad['title'] ?? ''} ${ad['edescription'] ?? ''} '
          '${ad['city'] ?? ''} ${ad['category'] ?? ''}');
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'آگهینو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: loadAds,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const FavoritesPage()
                : tab == 2
                    ? const Center(
                        child: Text('پیام‌رسانی در نسخه بعدی فعال می‌شود.'),
                      )
                    : account(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    if (loadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('همه'),
                selected: selectedCategory == null,
                onSelected: (_) => setState(() => selectedCategory = null),
              ),
              ...categories.map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: selectedCategory == item,
                  onSelected: (_) => setState(() {
                    selectedCategory = selectedCategory == item ? null : item;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (filteredAds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            )
          else
            ...filteredAds.map((ad) => Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdDetailPage(ad: ad),
                        ),
                      );
                    },
                    leading: Builder(
                      builder: (context) {
                        final images = ad['ad_images'];
                        final firstUrl = images is List && images.isNotEmpty
                            ? images.first['image_url']?.toString()
                            : null;
                        if (firstUrl == null || firstUrl.isEmpty) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            firstUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      '${ad['title'] ?? 'بدون عنوان'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${ad['price'] ?? 'توافقی'} تومان\n'
                      '${ad['city'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                )),
        ],
      ),
    );
  }

  Widget account() {
    final count = myAdsCount;
    final remaining = (subscriptionAdLimit - subscriptionAdsUsed).clamp(0, subscriptionAdLimit);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            supabase.auth.currentUser?.phone ?? 'کاربر آگهینو',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('اشتراک پایه'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹,۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage()));
              },
              child: const Text('خرید'),
            )),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$count از ۹ آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('خروج'),
        ),
      ],
    );
  }

  void openAdd() {
    if (loadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال بررسی اشتراک هستیم...')),
      );
      return;
    }

    if (!hasActiveSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت آگهی ابتدا اشتراک پایه را فعال کنید.'),
        ),
      );
      setState(() => tab = 3);
      return;
    }

    if (myAdsCount >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه ۹ آگهی این ماه تکمیل شده است.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(
          onPublished: loadAds,
        ),
      ),
    );
  }
}


class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override State<SubscriptionPage> createState() => _SubscriptionPageState();
}
class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String, dynamic>? settings;
  bool loading = true, submitting = false;
  final paymentNote = TextEditingController();
  @override void initState() { super.initState(); loadSettings(); }
  @override void dispose() { paymentNote.dispose(); super.dispose(); }
  Future<void> loadSettings() async {
    try {
      final row = await supabase.from('subscription_settings').select('price,duration_days,ad_limit,image_limit,destination_card,card_holder,bank_name,instructions,enabled').eq('id', true).maybeSingle();
      if (!mounted) return;
      setState(() { settings = row; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('دریافت اطلاعات اشتراک انجام نشد: $e')));
    }
  }
  Future<void> submitPayment() async {
    final user = supabase.auth.currentUser; final s = settings;
    if (user == null || s == null) return;
    final note = paymentNote.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً کد پیگیری یا توضیح پرداخت را وارد کنید.')));
      return;
    }
    setState(() => submitting = true);
    try {
      await supabase.from('payments').insert({
        'user_id': user.id, 'amount': s['price'], 'status': 'checking',
        'payment_note': note,
        'payment_code': '${user.id.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch}',
      });
      if (!mounted) return;
      paymentNote.clear();
      await showDialog(context: context, builder: (_) => const AlertDialog(
        title: Text('درخواست ثبت شد'),
        content: Text('پرداخت شما در وضعیت «در حال بررسی» ثبت شد. اشتراک فقط پس از تأیید پرداخت فعال می‌شود.'),
      ));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت پرداخت انجام نشد: ${e.message}')));
    } finally { if (mounted) setState(() => submitting = false); }
  }
  @override Widget build(BuildContext context) {
    if (loading) return const Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: CircularProgressIndicator())));
    final s = settings;
    if (s == null || s['enabled'] != true) return const Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: Text('فروش اشتراک در حال حاضر فعال نیست.'))));
    final price = (s['price'] ?? 39000).toString(), days = (s['duration_days'] ?? 30).toString(), limit = (s['ad_limit'] ?? 9).toString(), imageLimit = (s['image_limit'] ?? 10).toString();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('خرید اشتراک آگهینو')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          const Icon(Icons.workspace_premium, size: 52),
          const SizedBox(height: 10), const Text('اشتراک آگهینو', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Text('$price تومان'), Text('$days روز • حداکثر $limit آگهی • $imageLimit عکس برای هر آگهی'),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('اطلاعات کارت مقصد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SelectableText('شماره کارت: ${s['destination_card'] ?? 'توسط مدیر تنظیم نشده'}'),
          SelectableText('صاحب کارت: ${s['card_holder'] ?? '-'}'), SelectableText('بانک: ${s['bank_name'] ?? '-'}'),
          if ((s['instructions'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 10), Text(s['instructions'].toString())],
        ]))),
        const SizedBox(height: 12),
        TextField(controller: paymentNote, decoration: const InputDecoration(labelText: 'کد پیگیری / توضیح پرداخت', hintText: 'مثلاً شماره پیگیری یا زمان انتقال', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: submitting ? null : submitPayment, icon: const Icon(Icons.check_circle_outline), label: Padding(padding: const EdgeInsets.all(14), child: submitting ? const CircularProgressIndicator(strokeWidth: 2) : const Text('ثبت درخواست پرداخت برای بررسی'))),
        const SizedBox(height: 10),
        const Text('توجه: صرفاً ثبت این درخواست اشتراک را فعال نمی‌کند. فعال‌سازی فقط پس از تأیید واقعی پرداخت توسط سیستم یا مدیر انجام می‌شود.', textAlign: TextAlign.center),
      ]),
    ));
  }
}

class AddAdPage extends StatefulWidget {
  final Future<void> Function() onPublished;

  const AddAdPage({
    super.key,
    required this.onPublished,
  });

  @override
  State<AddAdPage> createState() => _AddAdPageState();
}

class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();

  String category = 'کالای دیجیتال';
  String city = 'تهران';
  bool publishing = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> selectedImages = [];

  static const int maxImages = 10;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداکثر ۱۰ عکس می‌توانید انتخاب کنید.')),
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isEmpty || !mounted) return;

      final remaining = maxImages - selectedImages.length;
      setState(() {
        selectedImages.addAll(images.take(remaining));
      });

      if (images.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فقط ۱۰ عکس اول انتخاب می‌شوند.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتخاب عکس انجام نشد: $e')),
      );
    }
  }

  void removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages({
    required String adId,
    required String userId,
  }) async {
    final uploadedPaths = <String>[];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final Uint8List bytes = await image.readAsBytes();

        final originalExtension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';

        final extension =
            <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(originalExtension)
                ? originalExtension
                : 'jpg';

        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };

        final path =
            'public/$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

        await supabase.storage.from('ad-images').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );

        uploadedPaths.add(path);

        final imageUrl =
            supabase.storage.from('ad-images').getPublicUrl(path);

        await supabase.from('ad_images').insert({
          'ad_id': adId,
          'image_url': imageUrl,
        });
      }

      return uploadedPaths;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage
              .from('ad-images')
              .remove(uploadedPaths);
        } catch (_) {
          // Storage cleanup is best-effort.
        }
      }
      rethrow;
    }
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty ||
        desc.text.trim().isEmpty ||
        price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عنوان، توضیحات و قیمت را کامل کنید.'),
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا وارد حساب شوید.')),
      );
      return;
    }

    final parsedPrice =
        int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (parsedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      final subscription = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subscription == null) {
        throw Exception('SUBSCRIPTION_REQUIRED');
      }

      final ad = await supabase.rpc(
        'publish_ad',
        params: {
          'p_title': title.text.trim(),
          'p_description': desc.text.trim(),
          'p_price': parsedPrice,
          'p_city': city,
          'p_category': category,
        },
      );

      final adId = ad?.toString();
      if (adId == null || adId.isEmpty) {
        throw Exception('شناسه آگهی دریافت نشد.');
      }

      try {
        await _uploadImages(adId: adId, userId: user.id);
      } catch (e) {
        // Do not leave a half-published ad if image upload fails.
        try {
          await supabase.from('ad_images').delete().eq('ad_id', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        try {
          await supabase.from('ads').delete().eq('idd', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        rethrow;
      }

      await widget.onPublished();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آگهی ثبت شد ✅'),
          content: const Text(
            'آگهی با موفقیت در Supabase ذخیره شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطای آپلود عکس: ${e.message}\\n'
            'اگر این خطا ادامه داشت، Bucket و Storage Policies را در Supabase بررسی می‌کنیم.',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای Supabase: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SUBSCRIPTION_REQUIRED')
          ? 'برای ثبت آگهی اشتراک فعال لازم است.'
          : e.toString().contains('AD_LIMIT_REACHED')
              ? 'سهمیه ۹ آگهی فعال شما تکمیل شده است.'
              : 'خطا در ثبت آگهی: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('اشتراک پایه'),
                subtitle: const Text(
                  '۳۹,۰۰۰ تومان / ماه • سهمیه این ماه: حداکثر ۹ آگهی',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: const [
                'کالای دیجیتال',
                'خودرو',
                'املاک',
                'لوازم خانه',
                'پوشاک',
                'خدمات',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            _field(title, 'عنوان آگهی'),
            const SizedBox(height: 12),
            _field(desc, 'توضیحات', maxLines: 5),
            const SizedBox(height: 12),
            _field(price, 'قیمت'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: city,
              decoration: const InputDecoration(
                labelText: 'شهر',
                border: OutlineInputBorder(),
              ),
              items: const [
                'تهران',
                'کرج',
                'مشهد',
                'اصفهان',
                'شیراز',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => city = v!),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing ? null : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                selectedImages.isEmpty
                    ? 'افزودن عکس (حداکثر ۱۰ عکس)'
                    : 'افزودن عکس (${selectedImages.length}/۱۰)',
              ),
            ),
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  width: 105,
                                  height: 105,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: publishing ? null : () => removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: publishing ? null : publish,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: publishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ثبت و انتشار آگهی'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}).hasMatch(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل ایران را به‌صورت صحیح وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(
        email: value,
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() => codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ورود به ایمیل شما ارسال شد.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال کد انجام نشد: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyCode() async {
    final value = email.text.trim();
    final token = otp.text.trim();

    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ارسال‌شده را کامل وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final result = await supabase.auth.verifyOTP(
        email: value,
        token: token,
        type: OtpType.email,
      );

      final user = result.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw Exception('ورود تأیید نشد.');
      }

      await supabase.from('profiles').upsert(
        {
          'iidd': user.id,
          'name': 'کاربر آگهینو',
        },
        onConflict: 'iidd',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کد صحیح نیست یا منقضی شده است: ${e.message}')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای پروفایل: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 70),
                const SizedBox(height: 12),
                const Text(
                  'آگهینو',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('خرید و فروش آسان و مطمئن'),
                const SizedBox(height: 35),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'ایمیل',
                    hintText: 'example@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'کد ورود',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : (codeSent ? verifyCode : sendCode),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(codeSent ? 'تأیید و ورود' : 'ارسال کد ورود'),
                    ),
                  ),
                ),
                if (codeSent)
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              codeSent = false;
                              otp.clear();
                            }),
                    child: const Text('تغییر ایمیل'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'ورود با کد یک‌بارمصرف ایمیلی',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loadingAds = true;
  bool loadingSubscription = true;
  bool hasActiveSubscription = false;
  DateTime? subscriptionExpiresAt;
  String searchQuery = '';
  String? selectedCategory;
  List<Map<String, dynamic>> ads = [];

  static const categories = <String>[
    'کالای دیجیتال',
    'خودرو',
    'املاک',
    'لوازم خانه',
    'پوشاک',
    'خدمات',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => loadingSubscription = false);
      return;
    }

    try {
      final row = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', uid)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final expiresRaw = row?['expires_at']?.toString();
      final expires = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

      if (!mounted) return;
      setState(() {
        subscriptionExpiresAt = expires;
        hasActiveSubscription = expires != null && expires.isAfter(DateTime.now());
        loadingSubscription = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingSubscription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بررسی اشتراک انجام نشد: $e')),
      );
    }
  }

  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url)')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        ads = List<Map<String, dynamic>>.from(rows);
        loadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
      );
    }
  }

  int get myAdsCount {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    return ads.where((ad) => ad['seller_id'] == uid).length;
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = searchQuery.trim().toLowerCase();
    return ads.where((ad) {
      final categoryOk = selectedCategory == null ||
          '${ad['category'] ?? ''}' == selectedCategory;
      final text = '${ad['title'] ?? ''} ${ad['edescription'] ?? ''} '
          '${ad['city'] ?? ''} ${ad['category'] ?? ''}'.toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'آگهینو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: loadAds,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const Center(
                    child: Text('علاقه‌مندی‌ها در نسخه بعدی فعال می‌شود.'),
                  )
                : tab == 2
                    ? const Center(
                        child: Text('پیام‌رسانی در نسخه بعدی فعال می‌شود.'),
                      )
                    : account(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    if (loadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('همه'),
                selected: selectedCategory == null,
                onSelected: (_) => setState(() => selectedCategory = null),
              ),
              ...categories.map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: selectedCategory == item,
                  onSelected: (_) => setState(() {
                    selectedCategory = selectedCategory == item ? null : item;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (filteredAds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            )
          else
            ...filteredAds.map((ad) => Card(
                  child: ListTile(
                    leading: Builder(
                      builder: (context) {
                        final images = ad['ad_images'];
                        final firstUrl = images is List && images.isNotEmpty
                            ? images.first['image_url']?.toString()
                            : null;
                        if (firstUrl == null || firstUrl.isEmpty) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            firstUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      '${ad['title'] ?? 'بدون عنوان'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${ad['price'] ?? 'توافقی'} تومان\n'
                      '${ad['city'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                )),
        ],
      ),
    );
  }

  Widget account() {
    final count = myAdsCount;
    final remaining = (9 - count).clamp(0, 9);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            supabase.auth.currentUser?.phone ?? 'کاربر آگهینو',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('اشتراک پایه'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹,۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () async {
                try {
                  final response = await supabase.functions.invoke(
                    'zarinpal-payment',
                    body: const {'action': 'create'},
                  );
                  final data = Map<String, dynamic>.from(response.data as Map);
                  final paymentUrl = data['payment_url']?.toString();
                  if (paymentUrl == null || paymentUrl.isEmpty) {
                    throw Exception('لینک پرداخت از سرور دریافت نشد.');
                  }
                  final opened = await launchUrl(
                    Uri.parse(paymentUrl),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened) throw Exception('باز کردن صفحه پرداخت انجام نشد.');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('پس از تکمیل پرداخت، برنامه را بازخوانی کنید.'),
                      ),
                    );
                  }
                } on FunctionException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطای ایجاد پرداخت: ${e.details ?? e.reasonPhrase}')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطای پرداخت: $e')),
                  );
                }
              },
              child: const Text('خرید'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$count از ۹ آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('خروج'),
        ),
      ],
    );
  }

  void openAdd() {
    if (loadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال بررسی اشتراک هستیم...')),
      );
      return;
    }

    if (!hasActiveSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت آگهی ابتدا اشتراک پایه را فعال کنید.'),
        ),
      );
      setState(() => tab = 3);
      return;
    }

    if (myAdsCount >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه ۹ آگهی این ماه تکمیل شده است.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(
          onPublished: loadAds,
        ),
      ),
    );
  }
}



class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();

  String category = 'کالای دیجیتال';
  String city = 'تهران';
  bool publishing = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> selectedImages = [];

  static const int maxImages = 10;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداکثر ۱۰ عکس می‌توانید انتخاب کنید.')),
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isEmpty || !mounted) return;

      final remaining = maxImages - selectedImages.length;
      setState(() {
        selectedImages.addAll(images.take(remaining));
      });

      if (images.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فقط ۱۰ عکس اول انتخاب می‌شوند.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتخاب عکس انجام نشد: $e')),
      );
    }
  }

  void removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages({
    required String adId,
    required String userId,
  }) async {
    final uploadedPaths = <String>[];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final Uint8List bytes = await image.readAsBytes();

        final originalExtension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';

        final extension =
            <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(originalExtension)
                ? originalExtension
                : 'jpg';

        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };

        final path =
            '$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

        await supabase.storage.from('ad-images').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );

        uploadedPaths.add(path);

        final imageUrl =
            supabase.storage.from('ad-images').getPublicUrl(path);

        await supabase.from('ad_images').insert({
          'ad_id': adId,
          'image_url': imageUrl,
        });
      }

      return uploadedPaths;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage
              .from('ad-images')
              .remove(uploadedPaths);
        } catch (_) {
          // Storage cleanup is best-effort.
        }
      }
      rethrow;
    }
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty ||
        desc.text.trim().isEmpty ||
        price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عنوان، توضیحات و قیمت را کامل کنید.'),
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا وارد حساب شوید.')),
      );
      return;
    }

    final parsedPrice =
        int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (parsedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      final subscription = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subscription == null) {
        throw Exception('SUBSCRIPTION_REQUIRED');
      }

      final ad = await supabase.rpc(
        'publish_ad',
        params: {
          'p_title': title.text.trim(),
          'p_description': desc.text.trim(),
          'p_price': parsedPrice,
          'p_city': city,
          'p_category': category,
        },
      );

      final adId = ad?.toString();
      if (adId == null || adId.isEmpty) {
        throw Exception('شناسه آگهی دریافت نشد.');
      }

      try {
        await _uploadImages(adId: adId, userId: user.id);
      } catch (e) {
        // Do not leave a half-published ad if image upload fails.
        try {
          await supabase.from('ad_images').delete().eq('ad_id', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        try {
          await supabase.from('ads').delete().eq('idd', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        rethrow;
      }

      await widget.onPublished();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آگهی ثبت شد ✅'),
          content: const Text(
            'آگهی با موفقیت در Supabase ذخیره شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطای آپلود عکس: ${e.message}\\n'
            'اگر این خطا ادامه داشت، Bucket و Storage Policies را در Supabase بررسی می‌کنیم.',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای Supabase: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SUBSCRIPTION_REQUIRED')
          ? 'برای ثبت آگهی اشتراک فعال لازم است.'
          : e.toString().contains('AD_LIMIT_REACHED')
              ? 'سهمیه ۹ آگهی فعال شما تکمیل شده است.'
              : 'خطا در ثبت آگهی: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('اشتراک پایه'),
                subtitle: const Text(
                  '۳۹,۰۰۰ تومان / ماه • سهمیه این ماه: حداکثر ۹ آگهی',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: const [
                'کالای دیجیتال',
                'خودرو',
                'املاک',
                'لوازم خانه',
                'پوشاک',
                'خدمات',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            _field(title, 'عنوان آگهی'),
            const SizedBox(height: 12),
            _field(desc, 'توضیحات', maxLines: 5),
            const SizedBox(height: 12),
            _field(price, 'قیمت'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: city,
              decoration: const InputDecoration(
                labelText: 'شهر',
                border: OutlineInputBorder(),
              ),
              items: const [
                'تهران',
                'کرج',
                'مشهد',
                'اصفهان',
                'شیراز',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => city = v!),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing ? null : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                selectedImages.isEmpty
                    ? 'افزودن عکس (حداکثر ۱۰ عکس)'
                    : 'افزودن عکس (${selectedImages.length}/۱۰)',
              ),
            ),
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  width: 105,
                                  height: 105,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: publishing ? null : () => removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: publishing ? null : publish,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: publishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ثبت و انتشار آگهی'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}).hasMatch(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل ایران را به‌صورت صحیح وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(
        phone: normalized,
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() => codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد تأیید به شماره موبایل شما ارسال شد.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال کد انجام نشد: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyCode() async {
    final raw = phone.text.trim().replaceAll(' ', '');
    final value = raw.startsWith('0') ? '+98${raw.substring(1)}' : raw;
    final token = otp.text.trim();

    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ارسال‌شده را کامل وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final result = await supabase.auth.verifyOTP(
        phone: value,
        token: token,
        type: OtpType.sms,
      );

      final user = result.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw Exception('ورود تأیید نشد.');
      }

      await supabase.from('profiles').upsert(
        {
          'iidd': user.id,
          'name': 'کاربر آگهینو',
        },
        onConflict: 'iidd',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کد صحیح نیست یا منقضی شده است: ${e.message}')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای پروفایل: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 70),
                const SizedBox(height: 12),
                const Text(
                  'آگهینو',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('خرید و فروش آسان و مطمئن'),
                const SizedBox(height: 35),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'شماره موبایل',
                    hintText: '0912 123 4567',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'کد ورود',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : (codeSent ? verifyCode : sendCode),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(codeSent ? 'تأیید و ورود' : 'ارسال کد ورود'),
                    ),
                  ),
                ),
                if (codeSent)
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              codeSent = false;
                              otp.clear();
                            }),
                    child: const Text('تغییر شماره موبایل'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'ورود با کد یک‌بارمصرف پیامکی',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loadingAds = true;
  bool loadingSubscription = true;
  bool hasActiveSubscription = false;
  DateTime? subscriptionExpiresAt;
  String searchQuery = '';
  String? selectedCategory;
  List<Map<String, dynamic>> ads = [];

  static const categories = <String>[
    'کالای دیجیتال',
    'خودرو',
    'املاک',
    'لوازم خانه',
    'پوشاک',
    'خدمات',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => loadingSubscription = false);
      return;
    }

    try {
      final row = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', uid)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final expiresRaw = row?['expires_at']?.toString();
      final expires = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

      if (!mounted) return;
      setState(() {
        subscriptionExpiresAt = expires;
        hasActiveSubscription = expires != null && expires.isAfter(DateTime.now());
        loadingSubscription = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingSubscription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بررسی اشتراک انجام نشد: $e')),
      );
    }
  }

  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url)')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        ads = List<Map<String, dynamic>>.from(rows);
        loadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
      );
    }
  }

  int get myAdsCount {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    return ads.where((ad) => ad['seller_id'] == uid).length;
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = searchQuery.trim().toLowerCase();
    return ads.where((ad) {
      final categoryOk = selectedCategory == null ||
          '${ad['category'] ?? ''}' == selectedCategory;
      final text = '${ad['title'] ?? ''} ${ad['edescription'] ?? ''} '
          '${ad['city'] ?? ''} ${ad['category'] ?? ''}'.toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'آگهینو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: loadAds,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const Center(
                    child: Text('علاقه‌مندی‌ها در نسخه بعدی فعال می‌شود.'),
                  )
                : tab == 2
                    ? const Center(
                        child: Text('پیام‌رسانی در نسخه بعدی فعال می‌شود.'),
                      )
                    : account(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    if (loadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('همه'),
                selected: selectedCategory == null,
                onSelected: (_) => setState(() => selectedCategory = null),
              ),
              ...categories.map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: selectedCategory == item,
                  onSelected: (_) => setState(() {
                    selectedCategory = selectedCategory == item ? null : item;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (filteredAds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            )
          else
            ...filteredAds.map((ad) => Card(
                  child: ListTile(
                    leading: Builder(
                      builder: (context) {
                        final images = ad['ad_images'];
                        final firstUrl = images is List && images.isNotEmpty
                            ? images.first['image_url']?.toString()
                            : null;
                        if (firstUrl == null || firstUrl.isEmpty) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            firstUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      '${ad['title'] ?? 'بدون عنوان'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${ad['price'] ?? 'توافقی'} تومان\n'
                      '${ad['city'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                )),
        ],
      ),
    );
  }

  Widget account() {
    final count = myAdsCount;
    final remaining = (9 - count).clamp(0, 9);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            supabase.auth.currentUser?.phone ?? 'کاربر آگهینو',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('اشتراک پایه'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹,۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage()));
              },
              child: const Text('خرید'),
            )),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$count از ۹ آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('خروج'),
        ),
      ],
    );
  }

  void openAdd() {
    if (loadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال بررسی اشتراک هستیم...')),
      );
      return;
    }

    if (!hasActiveSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت آگهی ابتدا اشتراک پایه را فعال کنید.'),
        ),
      );
      setState(() => tab = 3);
      return;
    }

    if (myAdsCount >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه ۹ آگهی این ماه تکمیل شده است.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(
          onPublished: loadAds,
        ),
      ),
    );
  }
}



class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String, dynamic>? settings;
  bool loading = true, submitting = false;
  final paymentNote = TextEditingController();
  @override void initState() { super.initState(); loadSettings(); }
  @override void dispose() { paymentNote.dispose(); super.dispose(); }
  Future<void> loadSettings() async {
    try {
      final row = await supabase.from('subscription_settings').select('price,duration_days,ad_limit,image_limit,destination_card,card_holder,bank_name,instructions,enabled').eq('id', true).maybeSingle();
      if (!mounted) return;
      setState(() { settings = row; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('دریافت اطلاعات اشتراک انجام نشد: $e')));
    }
  }
  Future<void> submitPayment() async {
    final user = supabase.auth.currentUser; final s = settings;
    if (user == null || s == null) return;
    final note = paymentNote.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً کد پیگیری یا توضیح پرداخت را وارد کنید.')));
      return;
    }
    setState(() => submitting = true);
    try {
      await supabase.from('payments').insert({
        'user_id': user.id, 'amount': s['price'], 'status': 'checking',
        'payment_note': note,
        'payment_code': '${user.id.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch}',
      });
      if (!mounted) return;
      paymentNote.clear();
      await showDialog(context: context, builder: (_) => const AlertDialog(
        title: Text('درخواست ثبت شد'),
        content: Text('پرداخت شما در وضعیت «در حال بررسی» ثبت شد. اشتراک فقط پس از تأیید پرداخت فعال می‌شود.'),
      ));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت پرداخت انجام نشد: ${e.message}')));
    } finally { if (mounted) setState(() => submitting = false); }
  }
  @override Widget build(BuildContext context) {
    if (loading) return const Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: CircularProgressIndicator())));
    final s = settings;
    if (s == null || s['enabled'] != true) return const Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: Text('فروش اشتراک در حال حاضر فعال نیست.'))));
    final price = (s['price'] ?? 39000).toString(), days = (s['duration_days'] ?? 30).toString(), limit = (s['ad_limit'] ?? 9).toString(), imageLimit = (s['image_limit'] ?? 10).toString();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('خرید اشتراک آگهینو')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          const Icon(Icons.workspace_premium, size: 52),
          const SizedBox(height: 10), const Text('اشتراک آگهینو', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Text('\$price تومان'), Text('\$days روز • حداکثر \$limit آگهی • \$imageLimit عکس برای هر آگهی'),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('اطلاعات کارت مقصد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SelectableText('شماره کارت: ${s['destination_card'] ?? 'توسط مدیر تنظیم نشده'}'),
          SelectableText('صاحب کارت: ${s['card_holder'] ?? '-'}'), SelectableText('بانک: ${s['bank_name'] ?? '-'}'),
          if ((s['instructions'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 10), Text(s['instructions'].toString())],
        ]))),
        const SizedBox(height: 12),
        TextField(controller: paymentNote, decoration: const InputDecoration(labelText: 'کد پیگیری / توضیح پرداخت', hintText: 'مثلاً شماره پیگیری یا زمان انتقال', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: submitting ? null : submitPayment, icon: const Icon(Icons.check_circle_outline), label: Padding(padding: const EdgeInsets.all(14), child: submitting ? const CircularProgressIndicator(strokeWidth: 2) : const Text('ثبت درخواست پرداخت برای بررسی'))),
        const SizedBox(height: 10),
        const Text('توجه: صرفاً ثبت این درخواست اشتراک را فعال نمی‌کند. فعال‌سازی فقط پس از تأیید واقعی پرداخت توسط سیستم یا مدیر انجام می‌شود.', textAlign: TextAlign.center),
      ]),
    ));
  }
}



class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();

  String category = 'کالای دیجیتال';
  String city = 'تهران';
  bool publishing = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> selectedImages = [];

  static const int maxImages = 10;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداکثر ۱۰ عکس می‌توانید انتخاب کنید.')),
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isEmpty || !mounted) return;

      final remaining = maxImages - selectedImages.length;
      setState(() {
        selectedImages.addAll(images.take(remaining));
      });

      if (images.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فقط ۱۰ عکس اول انتخاب می‌شوند.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتخاب عکس انجام نشد: $e')),
      );
    }
  }

  void removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages({
    required String adId,
    required String userId,
  }) async {
    final uploadedPaths = <String>[];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final Uint8List bytes = await image.readAsBytes();

        final originalExtension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';

        final extension =
            <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(originalExtension)
                ? originalExtension
                : 'jpg';

        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };

        final path =
            '$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

        await supabase.storage.from('ad-images').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );

        uploadedPaths.add(path);

        final imageUrl =
            supabase.storage.from('ad-images').getPublicUrl(path);

        await supabase.from('ad_images').insert({
          'ad_id': adId,
          'image_url': imageUrl,
        });
      }

      return uploadedPaths;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage
              .from('ad-images')
              .remove(uploadedPaths);
        } catch (_) {
          // Storage cleanup is best-effort.
        }
      }
      rethrow;
    }
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty ||
        desc.text.trim().isEmpty ||
        price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عنوان، توضیحات و قیمت را کامل کنید.'),
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا وارد حساب شوید.')),
      );
      return;
    }

    final parsedPrice =
        int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (parsedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      final subscription = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subscription == null) {
        throw Exception('SUBSCRIPTION_REQUIRED');
      }

      final ad = await supabase.rpc(
        'publish_ad',
        params: {
          'p_title': title.text.trim(),
          'p_description': desc.text.trim(),
          'p_price': parsedPrice,
          'p_city': city,
          'p_category': category,
        },
      );

      final adId = ad?.toString();
      if (adId == null || adId.isEmpty) {
        throw Exception('شناسه آگهی دریافت نشد.');
      }

      try {
        await _uploadImages(adId: adId, userId: user.id);
      } catch (e) {
        // Do not leave a half-published ad if image upload fails.
        try {
          await supabase.from('ad_images').delete().eq('ad_id', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        try {
          await supabase.from('ads').delete().eq('idd', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        rethrow;
      }

      await widget.onPublished();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آگهی ثبت شد ✅'),
          content: const Text(
            'آگهی با موفقیت در Supabase ذخیره شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطای آپلود عکس: ${e.message}\\n'
            'اگر این خطا ادامه داشت، Bucket و Storage Policies را در Supabase بررسی می‌کنیم.',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای Supabase: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SUBSCRIPTION_REQUIRED')
          ? 'برای ثبت آگهی اشتراک فعال لازم است.'
          : e.toString().contains('AD_LIMIT_REACHED')
              ? 'سهمیه ۹ آگهی فعال شما تکمیل شده است.'
              : 'خطا در ثبت آگهی: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('اشتراک پایه'),
                subtitle: const Text(
                  '۳۹,۰۰۰ تومان / ماه • سهمیه این ماه: حداکثر ۹ آگهی',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: const [
                'کالای دیجیتال',
                'خودرو',
                'املاک',
                'لوازم خانه',
                'پوشاک',
                'خدمات',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            _field(title, 'عنوان آگهی'),
            const SizedBox(height: 12),
            _field(desc, 'توضیحات', maxLines: 5),
            const SizedBox(height: 12),
            _field(price, 'قیمت'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: city,
              decoration: const InputDecoration(
                labelText: 'شهر',
                border: OutlineInputBorder(),
              ),
              items: const [
                'تهران',
                'کرج',
                'مشهد',
                'اصفهان',
                'شیراز',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => city = v!),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing ? null : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                selectedImages.isEmpty
                    ? 'افزودن عکس (حداکثر ۱۰ عکس)'
                    : 'افزودن عکس (${selectedImages.length}/۱۰)',
              ),
            ),
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  width: 105,
                                  height: 105,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: publishing ? null : () => removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: publishing ? null : publish,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: publishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ثبت و انتشار آگهی'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}).hasMatch(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل ایران را به‌صورت صحیح وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(
        email: value,
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() => codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ورود به ایمیل شما ارسال شد.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال کد انجام نشد: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyCode() async {
    final value = email.text.trim();
    final token = otp.text.trim();

    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ارسال‌شده را کامل وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final result = await supabase.auth.verifyOTP(
        email: value,
        token: token,
        type: OtpType.email,
      );

      final user = result.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw Exception('ورود تأیید نشد.');
      }

      await supabase.from('profiles').upsert(
        {
          'iidd': user.id,
          'name': 'کاربر آگهینو',
        },
        onConflict: 'iidd',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کد صحیح نیست یا منقضی شده است: ${e.message}')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای پروفایل: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 70),
                const SizedBox(height: 12),
                const Text(
                  'آگهینو',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('خرید و فروش آسان و مطمئن'),
                const SizedBox(height: 35),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'ایمیل',
                    hintText: 'example@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'کد ورود',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : (codeSent ? verifyCode : sendCode),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(codeSent ? 'تأیید و ورود' : 'ارسال کد ورود'),
                    ),
                  ),
                ),
                if (codeSent)
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              codeSent = false;
                              otp.clear();
                            }),
                    child: const Text('تغییر ایمیل'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'ورود با کد یک‌بارمصرف ایمیلی',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loadingAds = true;
  bool loadingSubscription = true;
  bool hasActiveSubscription = false;
  DateTime? subscriptionExpiresAt;
  String searchQuery = '';
  String? selectedCategory;
  List<Map<String, dynamic>> ads = [];

  static const categories = <String>[
    'کالای دیجیتال',
    'خودرو',
    'املاک',
    'لوازم خانه',
    'پوشاک',
    'خدمات',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => loadingSubscription = false);
      return;
    }

    try {
      final row = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', uid)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final expiresRaw = row?['expires_at']?.toString();
      final expires = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

      if (!mounted) return;
      setState(() {
        subscriptionExpiresAt = expires;
        hasActiveSubscription = expires != null && expires.isAfter(DateTime.now());
        loadingSubscription = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingSubscription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بررسی اشتراک انجام نشد: $e')),
      );
    }
  }

  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url)')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        ads = List<Map<String, dynamic>>.from(rows);
        loadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
      );
    }
  }

  int get myAdsCount {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    return ads.where((ad) => ad['seller_id'] == uid).length;
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = searchQuery.trim().toLowerCase();
    return ads.where((ad) {
      final categoryOk = selectedCategory == null ||
          '${ad['category'] ?? ''}' == selectedCategory;
      final text = '${ad['title'] ?? ''} ${ad['edescription'] ?? ''} '
          '${ad['city'] ?? ''} ${ad['category'] ?? ''}'.toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'آگهینو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: loadAds,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const Center(
                    child: Text('علاقه‌مندی‌ها در نسخه بعدی فعال می‌شود.'),
                  )
                : tab == 2
                    ? const Center(
                        child: Text('پیام‌رسانی در نسخه بعدی فعال می‌شود.'),
                      )
                    : account(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    if (loadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('همه'),
                selected: selectedCategory == null,
                onSelected: (_) => setState(() => selectedCategory = null),
              ),
              ...categories.map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: selectedCategory == item,
                  onSelected: (_) => setState(() {
                    selectedCategory = selectedCategory == item ? null : item;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (filteredAds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            )
          else
            ...filteredAds.map((ad) => Card(
                  child: ListTile(
                    leading: Builder(
                      builder: (context) {
                        final images = ad['ad_images'];
                        final firstUrl = images is List && images.isNotEmpty
                            ? images.first['image_url']?.toString()
                            : null;
                        if (firstUrl == null || firstUrl.isEmpty) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            firstUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      '${ad['title'] ?? 'بدون عنوان'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${ad['price'] ?? 'توافقی'} تومان\n'
                      '${ad['city'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                )),
        ],
      ),
    );
  }

  Widget account() {
    final count = myAdsCount;
    final remaining = (9 - count).clamp(0, 9);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            supabase.auth.currentUser?.phone ?? 'کاربر آگهینو',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('اشتراک پایه'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹,۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () async {
                try {
                  final response = await supabase.functions.invoke(
                    'zarinpal-payment',
                    body: const {'action': 'create'},
                  );
                  final data = Map<String, dynamic>.from(response.data as Map);
                  final paymentUrl = data['payment_url']?.toString();
                  if (paymentUrl == null || paymentUrl.isEmpty) {
                    throw Exception('لینک پرداخت از سرور دریافت نشد.');
                  }
                  final opened = await launchUrl(
                    Uri.parse(paymentUrl),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened) throw Exception('باز کردن صفحه پرداخت انجام نشد.');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('پس از تکمیل پرداخت، برنامه را بازخوانی کنید.'),
                      ),
                    );
                  }
                } on FunctionException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطای ایجاد پرداخت: ${e.details ?? e.reasonPhrase}')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطای پرداخت: $e')),
                  );
                }
              },
              child: const Text('خرید'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$count از ۹ آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('خروج'),
        ),
      ],
    );
  }

  void openAdd() {
    if (loadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال بررسی اشتراک هستیم...')),
      );
      return;
    }

    if (!hasActiveSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت آگهی ابتدا اشتراک پایه را فعال کنید.'),
        ),
      );
      setState(() => tab = 3);
      return;
    }

    if (myAdsCount >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه ۹ آگهی این ماه تکمیل شده است.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(
          onPublished: loadAds,
        ),
      ),
    );
  }
}



class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();

  String category = 'کالای دیجیتال';
  String city = 'تهران';
  bool publishing = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> selectedImages = [];

  static const int maxImages = 10;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداکثر ۱۰ عکس می‌توانید انتخاب کنید.')),
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isEmpty || !mounted) return;

      final remaining = maxImages - selectedImages.length;
      setState(() {
        selectedImages.addAll(images.take(remaining));
      });

      if (images.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فقط ۱۰ عکس اول انتخاب می‌شوند.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتخاب عکس انجام نشد: $e')),
      );
    }
  }

  void removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages({
    required String adId,
    required String userId,
  }) async {
    final uploadedPaths = <String>[];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final Uint8List bytes = await image.readAsBytes();

        final originalExtension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';

        final extension =
            <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(originalExtension)
                ? originalExtension
                : 'jpg';

        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };

        final path =
            '$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

        await supabase.storage.from('ad-images').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );

        uploadedPaths.add(path);

        final imageUrl =
            supabase.storage.from('ad-images').getPublicUrl(path);

        await supabase.from('ad_images').insert({
          'ad_id': adId,
          'image_url': imageUrl,
        });
      }

      return uploadedPaths;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage
              .from('ad-images')
              .remove(uploadedPaths);
        } catch (_) {
          // Storage cleanup is best-effort.
        }
      }
      rethrow;
    }
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty ||
        desc.text.trim().isEmpty ||
        price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عنوان، توضیحات و قیمت را کامل کنید.'),
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا وارد حساب شوید.')),
      );
      return;
    }

    final parsedPrice =
        int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (parsedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      final subscription = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subscription == null) {
        throw Exception('SUBSCRIPTION_REQUIRED');
      }

      final ad = await supabase.rpc(
        'publish_ad',
        params: {
          'p_title': title.text.trim(),
          'p_description': desc.text.trim(),
          'p_price': parsedPrice,
          'p_city': city,
          'p_category': category,
        },
      );

      final adId = ad?.toString();
      if (adId == null || adId.isEmpty) {
        throw Exception('شناسه آگهی دریافت نشد.');
      }

      try {
        await _uploadImages(adId: adId, userId: user.id);
      } catch (e) {
        // Do not leave a half-published ad if image upload fails.
        try {
          await supabase.from('ad_images').delete().eq('ad_id', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        try {
          await supabase.from('ads').delete().eq('idd', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        rethrow;
      }

      await widget.onPublished();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آگهی ثبت شد ✅'),
          content: const Text(
            'آگهی با موفقیت در Supabase ذخیره شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطای آپلود عکس: ${e.message}\\n'
            'اگر این خطا ادامه داشت، Bucket و Storage Policies را در Supabase بررسی می‌کنیم.',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای Supabase: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SUBSCRIPTION_REQUIRED')
          ? 'برای ثبت آگهی اشتراک فعال لازم است.'
          : e.toString().contains('AD_LIMIT_REACHED')
              ? 'سهمیه ۹ آگهی فعال شما تکمیل شده است.'
              : 'خطا در ثبت آگهی: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('اشتراک پایه'),
                subtitle: const Text(
                  '۳۹,۰۰۰ تومان / ماه • سهمیه این ماه: حداکثر ۹ آگهی',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: const [
                'کالای دیجیتال',
                'خودرو',
                'املاک',
                'لوازم خانه',
                'پوشاک',
                'خدمات',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            _field(title, 'عنوان آگهی'),
            const SizedBox(height: 12),
            _field(desc, 'توضیحات', maxLines: 5),
            const SizedBox(height: 12),
            _field(price, 'قیمت'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: city,
              decoration: const InputDecoration(
                labelText: 'شهر',
                border: OutlineInputBorder(),
              ),
              items: const [
                'تهران',
                'کرج',
                'مشهد',
                'اصفهان',
                'شیراز',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => city = v!),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing ? null : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                selectedImages.isEmpty
                    ? 'افزودن عکس (حداکثر ۱۰ عکس)'
                    : 'افزودن عکس (${selectedImages.length}/۱۰)',
              ),
            ),
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  width: 105,
                                  height: 105,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: publishing ? null : () => removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: publishing ? null : publish,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: publishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ثبت و انتشار آگهی'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}).hasMatch(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل را به‌صورت صحیح وارد کنید.')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(
        phone: normalized,
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() => codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد تأیید به شماره موبایل شما ارسال شد.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال کد انجام نشد: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyCode() async {
    final raw = phone.text.trim().replaceAll(' ', '');
    final value = raw.startsWith('0') ? '+98${raw.substring(1)}' : raw;
    final token = otp.text.trim();

    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ارسال‌شده را کامل وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final result = await supabase.auth.verifyOTP(
        phone: value,
        token: token,
        type: OtpType.sms,
      );

      final user = result.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw Exception('ورود تأیید نشد.');
      }

      await supabase.from('profiles').upsert(
        {
          'iidd': user.id,
          'name': 'کاربر آگهینو',
        },
        onConflict: 'iidd',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کد صحیح نیست یا منقضی شده است: ${e.message}')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای پروفایل: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 70),
                const SizedBox(height: 12),
                const Text(
                  'آگهینو',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('خرید و فروش آسان و مطمئن'),
                const SizedBox(height: 35),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'شماره موبایل',
                    hintText: '0912 123 4567',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'کد ورود',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : (codeSent ? verifyCode : sendCode),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(codeSent ? 'تأیید و ورود' : 'ارسال کد ورود'),
                    ),
                  ),
                ),
                if (codeSent)
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              codeSent = false;
                              otp.clear();
                            }),
                    child: const Text('تغییر شماره موبایل'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'ورود با کد یک‌بارمصرف پیامکی',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override State<FavoritesPage> createState() => _FavoritesPageState();
}
class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String,dynamic>> items=[]; bool loading=true;
  @override void initState(){super.initState(); load();}
  Future<void> load() async {
    final uid=supabase.auth.currentUser?.id;
    if(uid==null){if(mounted)setState(()=>loading=false);return;}
    try {
      final rows=await supabase.from('favorites').select('ad_id, ads(*)').eq('user_id',uid).order('created_at',ascending:false);
      if(!mounted)return; setState(()=>items=List<Map<String,dynamic>>.from(rows));
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت علاقه‌مندی‌ها انجام نشد: $e')));}
    if(mounted)setState(()=>loading=false);
  }
  Future<void> remove(String id) async {
    final uid=supabase.auth.currentUser?.id; if(uid==null)return;
    try {await supabase.from('favorites').delete().eq('user_id',uid).eq('ad_id',id); await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حذف انجام نشد: $e')));}
  }
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('علاقه‌مندی‌ها')),
    body:loading?const Center(child:CircularProgressIndicator()):items.isEmpty?const Center(child:Text('هنوز آگهی ذخیره‌شده‌ای ندارید.')):ListView.builder(
      padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(context,i){
        final ad=items[i]['ads'] is Map ? Map<String,dynamic>.from(items[i]['ads']) : <String,dynamic>{};
        final id=items[i]['ad_id'].toString();
        return Card(child:ListTile(title:Text('${ad['title']??'بدون عنوان'}'),subtitle:Text('${ad['price']??'توافقی'} تومان • ${ad['city']??''}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>remove(id))));
      }),
  ));
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loadingAds = true;
  bool loadingSubscription = true;
  bool hasActiveSubscription = false;
  DateTime? subscriptionExpiresAt;
  String searchQuery = '';
  String? selectedCategory;
  List<Map<String, dynamic>> ads = [];

  static const categories = <String>[
    'کالای دیجیتال',
    'خودرو',
    'املاک',
    'لوازم خانه',
    'پوشاک',
    'خدمات',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => loadingSubscription = false);
      return;
    }

    try {
      final row = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', uid)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final expiresRaw = row?['expires_at']?.toString();
      final expires = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

      if (!mounted) return;
      setState(() {
        subscriptionExpiresAt = expires;
        hasActiveSubscription = expires != null && expires.isAfter(DateTime.now());
        loadingSubscription = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingSubscription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بررسی اشتراک انجام نشد: $e')),
      );
    }
  }

  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url)')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        ads = List<Map<String, dynamic>>.from(rows);
        loadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
      );
    }
  }

  int get myAdsCount {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    return ads.where((ad) => ad['seller_id'] == uid).length;
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = searchQuery.trim().toLowerCase();
    return ads.where((ad) {
      final categoryOk = selectedCategory == null ||
          '${ad['category'] ?? ''}' == selectedCategory;
      final text = '${ad['title'] ?? ''} ${ad['edescription'] ?? ''} '
          '${ad['city'] ?? ''} ${ad['category'] ?? ''}'.toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'آگهینو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: loadAds,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const Center(
                    child: Text('علاقه‌مندی‌ها در نسخه بعدی فعال می‌شود.'),
                  )
                : tab == 2
                    ? const Center(
                        child: Text('پیام‌رسانی در نسخه بعدی فعال می‌شود.'),
                      )
                    : account(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    if (loadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('همه'),
                selected: selectedCategory == null,
                onSelected: (_) => setState(() => selectedCategory = null),
              ),
              ...categories.map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: selectedCategory == item,
                  onSelected: (_) => setState(() {
                    selectedCategory = selectedCategory == item ? null : item;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (filteredAds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            )
          else
            ...filteredAds.map((ad) => Card(
                  child: ListTile(
                    leading: Builder(
                      builder: (context) {
                        final images = ad['ad_images'];
                        final firstUrl = images is List && images.isNotEmpty
                            ? images.first['image_url']?.toString()
                            : null;
                        if (firstUrl == null || firstUrl.isEmpty) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            firstUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      '${ad['title'] ?? 'بدون عنوان'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${ad['price'] ?? 'توافقی'} تومان\n'
                      '${ad['city'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                )),
        ],
      ),
    );
  }

  Widget account() {
    final count = myAdsCount;
    final remaining = (9 - count).clamp(0, 9);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            supabase.auth.currentUser?.phone ?? 'کاربر آگهینو',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('اشتراک پایه'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹,۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage()));
              },
              child: const Text('خرید'),
            )),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$count از ۹ آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('خروج'),
        ),
      ],
    );
  }

  void openAdd() {
    if (loadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال بررسی اشتراک هستیم...')),
      );
      return;
    }

    if (!hasActiveSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت آگهی ابتدا اشتراک پایه را فعال کنید.'),
        ),
      );
      setState(() => tab = 3);
      return;
    }

    if (myAdsCount >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه ۹ آگهی این ماه تکمیل شده است.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(
          onPublished: loadAds,
        ),
      ),
    );
  }
}


class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override State<SubscriptionPage> createState() => _SubscriptionPageState();
}
class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String, dynamic>? settings;
  bool loading = true, submitting = false;
  final paymentNote = TextEditingController();
  @override void initState() { super.initState(); loadSettings(); }
  @override void dispose() { paymentNote.dispose(); super.dispose(); }
  Future<void> loadSettings() async {
    try {
      final row = await supabase.from('subscription_settings').select('price,duration_days,ad_limit,image_limit,destination_card,card_holder,bank_name,instructions,enabled').eq('id', true).maybeSingle();
      if (!mounted) return;
      setState(() { settings = row; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('دریافت اطلاعات اشتراک انجام نشد: $e')));
    }
  }
  Future<void> submitPayment() async {
    final user = supabase.auth.currentUser; final s = settings;
    if (user == null || s == null) return;
    final note = paymentNote.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً کد پیگیری یا توضیح پرداخت را وارد کنید.')));
      return;
    }
    setState(() => submitting = true);
    try {
      await supabase.from('payments').insert({
        'user_id': user.id, 'amount': s['price'], 'status': 'checking',
        'payment_note': note,
        'payment_code': '${user.id.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch}',
      });
      if (!mounted) return;
      paymentNote.clear();
      await showDialog(context: context, builder: (_) => const AlertDialog(
        title: Text('درخواست ثبت شد'),
        content: Text('پرداخت شما در وضعیت «در حال بررسی» ثبت شد. اشتراک فقط پس از تأیید پرداخت فعال می‌شود.'),
      ));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت پرداخت انجام نشد: ${e.message}')));
    } finally { if (mounted) setState(() => submitting = false); }
  }
  @override Widget build(BuildContext context) {
    if (loading) return const Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: CircularProgressIndicator())));
    final s = settings;
    if (s == null || s['enabled'] != true) return const Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: Text('فروش اشتراک در حال حاضر فعال نیست.'))));
    final price = (s['price'] ?? 39000).toString(), days = (s['duration_days'] ?? 30).toString(), limit = (s['ad_limit'] ?? 9).toString(), imageLimit = (s['image_limit'] ?? 10).toString();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('خرید اشتراک آگهینو')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          const Icon(Icons.workspace_premium, size: 52),
          const SizedBox(height: 10), const Text('اشتراک آگهینو', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Text('$price تومان'), Text('$days روز • حداکثر $limit آگهی • $imageLimit عکس برای هر آگهی'),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('اطلاعات کارت مقصد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SelectableText('شماره کارت: ${s['destination_card'] ?? 'توسط مدیر تنظیم نشده'}'),
          SelectableText('صاحب کارت: ${s['card_holder'] ?? '-'}'), SelectableText('بانک: ${s['bank_name'] ?? '-'}'),
          if ((s['instructions'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 10), Text(s['instructions'].toString())],
        ]))),
        const SizedBox(height: 12),
        TextField(controller: paymentNote, decoration: const InputDecoration(labelText: 'کد پیگیری / توضیح پرداخت', hintText: 'مثلاً شماره پیگیری یا زمان انتقال', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: submitting ? null : submitPayment, icon: const Icon(Icons.check_circle_outline), label: Padding(padding: const EdgeInsets.all(14), child: submitting ? const CircularProgressIndicator(strokeWidth: 2) : const Text('ثبت درخواست پرداخت برای بررسی'))),
        const SizedBox(height: 10),
        const Text('توجه: صرفاً ثبت این درخواست اشتراک را فعال نمی‌کند. فعال‌سازی فقط پس از تأیید واقعی پرداخت توسط سیستم یا مدیر انجام می‌شود.', textAlign: TextAlign.center),
      ]),
    ));
  }
}

class AddAdPage extends StatefulWidget {
  final Future<void> Function() onPublished;

  const AddAdPage({
    super.key,
    required this.onPublished,
  });

  @override
  State<AddAdPage> createState() => _AddAdPageState();
}

class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();

  String category = 'کالای دیجیتال';
  String city = 'تهران';
  bool publishing = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> selectedImages = [];

  static const int maxImages = 10;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداکثر ۱۰ عکس می‌توانید انتخاب کنید.')),
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isEmpty || !mounted) return;

      final remaining = maxImages - selectedImages.length;
      setState(() {
        selectedImages.addAll(images.take(remaining));
      });

      if (images.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فقط ۱۰ عکس اول انتخاب می‌شوند.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتخاب عکس انجام نشد: $e')),
      );
    }
  }

  void removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages({
    required String adId,
    required String userId,
  }) async {
    final uploadedPaths = <String>[];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final Uint8List bytes = await image.readAsBytes();

        final originalExtension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';

        final extension =
            <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(originalExtension)
                ? originalExtension
                : 'jpg';

        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };

        final path =
            '$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

        await supabase.storage.from('ad-images').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );

        uploadedPaths.add(path);

        final imageUrl =
            supabase.storage.from('ad-images').getPublicUrl(path);

        await supabase.from('ad_images').insert({
          'ad_id': adId,
          'image_url': imageUrl,
        });
      }

      return uploadedPaths;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage
              .from('ad-images')
              .remove(uploadedPaths);
        } catch (_) {
          // Storage cleanup is best-effort.
        }
      }
      rethrow;
    }
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty ||
        desc.text.trim().isEmpty ||
        price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عنوان، توضیحات و قیمت را کامل کنید.'),
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا وارد حساب شوید.')),
      );
      return;
    }

    final parsedPrice =
        int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (parsedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      final subscription = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subscription == null) {
        throw Exception('SUBSCRIPTION_REQUIRED');
      }

      final ad = await supabase.rpc(
        'publish_ad',
        params: {
          'p_title': title.text.trim(),
          'p_description': desc.text.trim(),
          'p_price': parsedPrice,
          'p_city': city,
          'p_category': category,
        },
      );

      final adId = ad?.toString();
      if (adId == null || adId.isEmpty) {
        throw Exception('شناسه آگهی دریافت نشد.');
      }

      try {
        await _uploadImages(adId: adId, userId: user.id);
      } catch (e) {
        // Do not leave a half-published ad if image upload fails.
        try {
          await supabase.from('ad_images').delete().eq('ad_id', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        try {
          await supabase.from('ads').delete().eq('idd', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        rethrow;
      }

      await widget.onPublished();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آگهی ثبت شد ✅'),
          content: const Text(
            'آگهی با موفقیت در Supabase ذخیره شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطای آپلود عکس: ${e.message}\\n'
            'اگر این خطا ادامه داشت، Bucket و Storage Policies را در Supabase بررسی می‌کنیم.',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای Supabase: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SUBSCRIPTION_REQUIRED')
          ? 'برای ثبت آگهی اشتراک فعال لازم است.'
          : e.toString().contains('AD_LIMIT_REACHED')
              ? 'سهمیه ۹ آگهی فعال شما تکمیل شده است.'
              : 'خطا در ثبت آگهی: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('اشتراک پایه'),
                subtitle: const Text(
                  '۳۹,۰۰۰ تومان / ماه • سهمیه این ماه: حداکثر ۹ آگهی',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: const [
                'کالای دیجیتال',
                'خودرو',
                'املاک',
                'لوازم خانه',
                'پوشاک',
                'خدمات',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            _field(title, 'عنوان آگهی'),
            const SizedBox(height: 12),
            _field(desc, 'توضیحات', maxLines: 5),
            const SizedBox(height: 12),
            _field(price, 'قیمت'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: city,
              decoration: const InputDecoration(
                labelText: 'شهر',
                border: OutlineInputBorder(),
              ),
              items: const [
                'تهران',
                'کرج',
                'مشهد',
                'اصفهان',
                'شیراز',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => city = v!),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing ? null : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                selectedImages.isEmpty
                    ? 'افزودن عکس (حداکثر ۱۰ عکس)'
                    : 'افزودن عکس (${selectedImages.length}/۱۰)',
              ),
            ),
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  width: 105,
                                  height: 105,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: publishing ? null : () => removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: publishing ? null : publish,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: publishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ثبت و انتشار آگهی'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}).hasMatch(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل ایران را به‌صورت صحیح وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(
        email: value,
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() => codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ورود به ایمیل شما ارسال شد.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال کد انجام نشد: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyCode() async {
    final value = email.text.trim();
    final token = otp.text.trim();

    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ارسال‌شده را کامل وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final result = await supabase.auth.verifyOTP(
        email: value,
        token: token,
        type: OtpType.email,
      );

      final user = result.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw Exception('ورود تأیید نشد.');
      }

      await supabase.from('profiles').upsert(
        {
          'iidd': user.id,
          'name': 'کاربر آگهینو',
        },
        onConflict: 'iidd',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کد صحیح نیست یا منقضی شده است: ${e.message}')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای پروفایل: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 70),
                const SizedBox(height: 12),
                const Text(
                  'آگهینو',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('خرید و فروش آسان و مطمئن'),
                const SizedBox(height: 35),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'ایمیل',
                    hintText: 'example@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'کد ورود',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : (codeSent ? verifyCode : sendCode),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(codeSent ? 'تأیید و ورود' : 'ارسال کد ورود'),
                    ),
                  ),
                ),
                if (codeSent)
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              codeSent = false;
                              otp.clear();
                            }),
                    child: const Text('تغییر ایمیل'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'ورود با کد یک‌بارمصرف ایمیلی',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loadingAds = true;
  bool loadingSubscription = true;
  bool hasActiveSubscription = false;
  DateTime? subscriptionExpiresAt;
  String searchQuery = '';
  String? selectedCategory;
  List<Map<String, dynamic>> ads = [];

  static const categories = <String>[
    'کالای دیجیتال',
    'خودرو',
    'املاک',
    'لوازم خانه',
    'پوشاک',
    'خدمات',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => loadingSubscription = false);
      return;
    }

    try {
      final row = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', uid)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final expiresRaw = row?['expires_at']?.toString();
      final expires = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

      if (!mounted) return;
      setState(() {
        subscriptionExpiresAt = expires;
        hasActiveSubscription = expires != null && expires.isAfter(DateTime.now());
        loadingSubscription = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingSubscription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بررسی اشتراک انجام نشد: $e')),
      );
    }
  }

  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url)')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        ads = List<Map<String, dynamic>>.from(rows);
        loadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
      );
    }
  }

  int get myAdsCount {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    return ads.where((ad) => ad['seller_id'] == uid).length;
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = searchQuery.trim().toLowerCase();
    return ads.where((ad) {
      final categoryOk = selectedCategory == null ||
          '${ad['category'] ?? ''}' == selectedCategory;
      final text = '${ad['title'] ?? ''} ${ad['edescription'] ?? ''} '
          '${ad['city'] ?? ''} ${ad['category'] ?? ''}'.toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'آگهینو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: loadAds,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const Center(
                    child: Text('علاقه‌مندی‌ها در نسخه بعدی فعال می‌شود.'),
                  )
                : tab == 2
                    ? const Center(
                        child: Text('پیام‌رسانی در نسخه بعدی فعال می‌شود.'),
                      )
                    : account(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    if (loadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('همه'),
                selected: selectedCategory == null,
                onSelected: (_) => setState(() => selectedCategory = null),
              ),
              ...categories.map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: selectedCategory == item,
                  onSelected: (_) => setState(() {
                    selectedCategory = selectedCategory == item ? null : item;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (filteredAds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            )
          else
            ...filteredAds.map((ad) => Card(
                  child: ListTile(
                    leading: Builder(
                      builder: (context) {
                        final images = ad['ad_images'];
                        final firstUrl = images is List && images.isNotEmpty
                            ? images.first['image_url']?.toString()
                            : null;
                        if (firstUrl == null || firstUrl.isEmpty) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            firstUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      '${ad['title'] ?? 'بدون عنوان'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${ad['price'] ?? 'توافقی'} تومان\n'
                      '${ad['city'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                )),
        ],
      ),
    );
  }

  Widget account() {
    final count = myAdsCount;
    final remaining = (9 - count).clamp(0, 9);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            supabase.auth.currentUser?.phone ?? 'کاربر آگهینو',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('اشتراک پایه'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹,۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () async {
                try {
                  final response = await supabase.functions.invoke(
                    'zarinpal-payment',
                    body: const {'action': 'create'},
                  );
                  final data = Map<String, dynamic>.from(response.data as Map);
                  final paymentUrl = data['payment_url']?.toString();
                  if (paymentUrl == null || paymentUrl.isEmpty) {
                    throw Exception('لینک پرداخت از سرور دریافت نشد.');
                  }
                  final opened = await launchUrl(
                    Uri.parse(paymentUrl),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened) throw Exception('باز کردن صفحه پرداخت انجام نشد.');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('پس از تکمیل پرداخت، برنامه را بازخوانی کنید.'),
                      ),
                    );
                  }
                } on FunctionException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطای ایجاد پرداخت: ${e.details ?? e.reasonPhrase}')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطای پرداخت: $e')),
                  );
                }
              },
              child: const Text('خرید'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$count از ۹ آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('خروج'),
        ),
      ],
    );
  }

  void openAdd() {
    if (loadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال بررسی اشتراک هستیم...')),
      );
      return;
    }

    if (!hasActiveSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت آگهی ابتدا اشتراک پایه را فعال کنید.'),
        ),
      );
      setState(() => tab = 3);
      return;
    }

    if (myAdsCount >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه ۹ آگهی این ماه تکمیل شده است.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(
          onPublished: loadAds,
        ),
      ),
    );
  }
}



class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();

  String category = 'کالای دیجیتال';
  String city = 'تهران';
  bool publishing = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> selectedImages = [];

  static const int maxImages = 10;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداکثر ۱۰ عکس می‌توانید انتخاب کنید.')),
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isEmpty || !mounted) return;

      final remaining = maxImages - selectedImages.length;
      setState(() {
        selectedImages.addAll(images.take(remaining));
      });

      if (images.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فقط ۱۰ عکس اول انتخاب می‌شوند.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتخاب عکس انجام نشد: $e')),
      );
    }
  }

  void removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages({
    required String adId,
    required String userId,
  }) async {
    final uploadedPaths = <String>[];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final Uint8List bytes = await image.readAsBytes();

        final originalExtension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';

        final extension =
            <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(originalExtension)
                ? originalExtension
                : 'jpg';

        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };

        final path =
            '$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

        await supabase.storage.from('ad-images').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );

        uploadedPaths.add(path);

        final imageUrl =
            supabase.storage.from('ad-images').getPublicUrl(path);

        await supabase.from('ad_images').insert({
          'ad_id': adId,
          'image_url': imageUrl,
        });
      }

      return uploadedPaths;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage
              .from('ad-images')
              .remove(uploadedPaths);
        } catch (_) {
          // Storage cleanup is best-effort.
        }
      }
      rethrow;
    }
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty ||
        desc.text.trim().isEmpty ||
        price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عنوان، توضیحات و قیمت را کامل کنید.'),
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا وارد حساب شوید.')),
      );
      return;
    }

    final parsedPrice =
        int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (parsedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      final subscription = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subscription == null) {
        throw Exception('SUBSCRIPTION_REQUIRED');
      }

      final ad = await supabase.rpc(
        'publish_ad',
        params: {
          'p_title': title.text.trim(),
          'p_description': desc.text.trim(),
          'p_price': parsedPrice,
          'p_city': city,
          'p_category': category,
        },
      );

      final adId = ad?.toString();
      if (adId == null || adId.isEmpty) {
        throw Exception('شناسه آگهی دریافت نشد.');
      }

      try {
        await _uploadImages(adId: adId, userId: user.id);
      } catch (e) {
        // Do not leave a half-published ad if image upload fails.
        try {
          await supabase.from('ad_images').delete().eq('ad_id', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        try {
          await supabase.from('ads').delete().eq('idd', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        rethrow;
      }

      await widget.onPublished();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آگهی ثبت شد ✅'),
          content: const Text(
            'آگهی با موفقیت در Supabase ذخیره شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطای آپلود عکس: ${e.message}\\n'
            'اگر این خطا ادامه داشت، Bucket و Storage Policies را در Supabase بررسی می‌کنیم.',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای Supabase: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SUBSCRIPTION_REQUIRED')
          ? 'برای ثبت آگهی اشتراک فعال لازم است.'
          : e.toString().contains('AD_LIMIT_REACHED')
              ? 'سهمیه ۹ آگهی فعال شما تکمیل شده است.'
              : 'خطا در ثبت آگهی: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('اشتراک پایه'),
                subtitle: const Text(
                  '۳۹,۰۰۰ تومان / ماه • سهمیه این ماه: حداکثر ۹ آگهی',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: const [
                'کالای دیجیتال',
                'خودرو',
                'املاک',
                'لوازم خانه',
                'پوشاک',
                'خدمات',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            _field(title, 'عنوان آگهی'),
            const SizedBox(height: 12),
            _field(desc, 'توضیحات', maxLines: 5),
            const SizedBox(height: 12),
            _field(price, 'قیمت'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: city,
              decoration: const InputDecoration(
                labelText: 'شهر',
                border: OutlineInputBorder(),
              ),
              items: const [
                'تهران',
                'کرج',
                'مشهد',
                'اصفهان',
                'شیراز',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => city = v!),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing ? null : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                selectedImages.isEmpty
                    ? 'افزودن عکس (حداکثر ۱۰ عکس)'
                    : 'افزودن عکس (${selectedImages.length}/۱۰)',
              ),
            ),
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  width: 105,
                                  height: 105,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: publishing ? null : () => removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: publishing ? null : publish,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: publishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ثبت و انتشار آگهی'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}).hasMatch(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل ایران را به‌صورت صحیح وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(
        phone: normalized,
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() => codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد تأیید به شماره موبایل شما ارسال شد.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال کد انجام نشد: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyCode() async {
    final raw = phone.text.trim().replaceAll(' ', '');
    final value = raw.startsWith('0') ? '+98${raw.substring(1)}' : raw;
    final token = otp.text.trim();

    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ارسال‌شده را کامل وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final result = await supabase.auth.verifyOTP(
        phone: value,
        token: token,
        type: OtpType.sms,
      );

      final user = result.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw Exception('ورود تأیید نشد.');
      }

      await supabase.from('profiles').upsert(
        {
          'iidd': user.id,
          'name': 'کاربر آگهینو',
        },
        onConflict: 'iidd',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کد صحیح نیست یا منقضی شده است: ${e.message}')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای پروفایل: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 70),
                const SizedBox(height: 12),
                const Text(
                  'آگهینو',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('خرید و فروش آسان و مطمئن'),
                const SizedBox(height: 35),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'شماره موبایل',
                    hintText: '0912 123 4567',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'کد ورود',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : (codeSent ? verifyCode : sendCode),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(codeSent ? 'تأیید و ورود' : 'ارسال کد ورود'),
                    ),
                  ),
                ),
                if (codeSent)
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              codeSent = false;
                              otp.clear();
                            }),
                    child: const Text('تغییر شماره موبایل'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'ورود با کد یک‌بارمصرف پیامکی',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loadingAds = true;
  bool loadingSubscription = true;
  bool hasActiveSubscription = false;
  DateTime? subscriptionExpiresAt;
  String searchQuery = '';
  String? selectedCategory;
  List<Map<String, dynamic>> ads = [];

  static const categories = <String>[
    'کالای دیجیتال',
    'خودرو',
    'املاک',
    'لوازم خانه',
    'پوشاک',
    'خدمات',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => loadingSubscription = false);
      return;
    }

    try {
      final row = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', uid)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final expiresRaw = row?['expires_at']?.toString();
      final expires = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

      if (!mounted) return;
      setState(() {
        subscriptionExpiresAt = expires;
        hasActiveSubscription = expires != null && expires.isAfter(DateTime.now());
        loadingSubscription = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingSubscription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بررسی اشتراک انجام نشد: $e')),
      );
    }
  }

  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url)')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        ads = List<Map<String, dynamic>>.from(rows);
        loadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
      );
    }
  }

  int get myAdsCount {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    return ads.where((ad) => ad['seller_id'] == uid).length;
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = searchQuery.trim().toLowerCase();
    return ads.where((ad) {
      final categoryOk = selectedCategory == null ||
          '${ad['category'] ?? ''}' == selectedCategory;
      final text = '${ad['title'] ?? ''} ${ad['edescription'] ?? ''} '
          '${ad['city'] ?? ''} ${ad['category'] ?? ''}'.toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'آگهینو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: loadAds,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const Center(
                    child: Text('علاقه‌مندی‌ها در نسخه بعدی فعال می‌شود.'),
                  )
                : tab == 2
                    ? const Center(
                        child: Text('پیام‌رسانی در نسخه بعدی فعال می‌شود.'),
                      )
                    : account(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    if (loadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('همه'),
                selected: selectedCategory == null,
                onSelected: (_) => setState(() => selectedCategory = null),
              ),
              ...categories.map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: selectedCategory == item,
                  onSelected: (_) => setState(() {
                    selectedCategory = selectedCategory == item ? null : item;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (filteredAds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            )
          else
            ...filteredAds.map((ad) => Card(
                  child: ListTile(
                    leading: Builder(
                      builder: (context) {
                        final images = ad['ad_images'];
                        final firstUrl = images is List && images.isNotEmpty
                            ? images.first['image_url']?.toString()
                            : null;
                        if (firstUrl == null || firstUrl.isEmpty) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            firstUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      '${ad['title'] ?? 'بدون عنوان'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${ad['price'] ?? 'توافقی'} تومان\n'
                      '${ad['city'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                )),
        ],
      ),
    );
  }

  Widget account() {
    final count = myAdsCount;
    final remaining = (9 - count).clamp(0, 9);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            supabase.auth.currentUser?.phone ?? 'کاربر آگهینو',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('اشتراک پایه'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹,۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage()));
              },
              child: const Text('خرید'),
            )),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$count از ۹ آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('خروج'),
        ),
      ],
    );
  }

  void openAdd() {
    if (loadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال بررسی اشتراک هستیم...')),
      );
      return;
    }

    if (!hasActiveSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت آگهی ابتدا اشتراک پایه را فعال کنید.'),
        ),
      );
      setState(() => tab = 3);
      return;
    }

    if (myAdsCount >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه ۹ آگهی این ماه تکمیل شده است.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(
          onPublished: loadAds,
        ),
      ),
    );
  }
}



class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String, dynamic>? settings;
  bool loading = true, submitting = false;
  final paymentNote = TextEditingController();
  @override void initState() { super.initState(); loadSettings(); }
  @override void dispose() { paymentNote.dispose(); super.dispose(); }
  Future<void> loadSettings() async {
    try {
      final row = await supabase.from('subscription_settings').select('price,duration_days,ad_limit,image_limit,destination_card,card_holder,bank_name,instructions,enabled').eq('id', true).maybeSingle();
      if (!mounted) return;
      setState(() { settings = row; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('دریافت اطلاعات اشتراک انجام نشد: $e')));
    }
  }
  Future<void> submitPayment() async {
    final user = supabase.auth.currentUser; final s = settings;
    if (user == null || s == null) return;
    final note = paymentNote.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً کد پیگیری یا توضیح پرداخت را وارد کنید.')));
      return;
    }
    setState(() => submitting = true);
    try {
      await supabase.from('payments').insert({
        'user_id': user.id, 'amount': s['price'], 'status': 'checking',
        'payment_note': note,
        'payment_code': '${user.id.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch}',
      });
      if (!mounted) return;
      paymentNote.clear();
      await showDialog(context: context, builder: (_) => const AlertDialog(
        title: Text('درخواست ثبت شد'),
        content: Text('پرداخت شما در وضعیت «در حال بررسی» ثبت شد. اشتراک فقط پس از تأیید پرداخت فعال می‌شود.'),
      ));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت پرداخت انجام نشد: ${e.message}')));
    } finally { if (mounted) setState(() => submitting = false); }
  }
  @override Widget build(BuildContext context) {
    if (loading) return const Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: CircularProgressIndicator())));
    final s = settings;
    if (s == null || s['enabled'] != true) return const Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: Text('فروش اشتراک در حال حاضر فعال نیست.'))));
    final price = (s['price'] ?? 39000).toString(), days = (s['duration_days'] ?? 30).toString(), limit = (s['ad_limit'] ?? 9).toString(), imageLimit = (s['image_limit'] ?? 10).toString();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('خرید اشتراک آگهینو')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          const Icon(Icons.workspace_premium, size: 52),
          const SizedBox(height: 10), const Text('اشتراک آگهینو', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Text('\$price تومان'), Text('\$days روز • حداکثر \$limit آگهی • \$imageLimit عکس برای هر آگهی'),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('اطلاعات کارت مقصد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SelectableText('شماره کارت: ${s['destination_card'] ?? 'توسط مدیر تنظیم نشده'}'),
          SelectableText('صاحب کارت: ${s['card_holder'] ?? '-'}'), SelectableText('بانک: ${s['bank_name'] ?? '-'}'),
          if ((s['instructions'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 10), Text(s['instructions'].toString())],
        ]))),
        const SizedBox(height: 12),
        TextField(controller: paymentNote, decoration: const InputDecoration(labelText: 'کد پیگیری / توضیح پرداخت', hintText: 'مثلاً شماره پیگیری یا زمان انتقال', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: submitting ? null : submitPayment, icon: const Icon(Icons.check_circle_outline), label: Padding(padding: const EdgeInsets.all(14), child: submitting ? const CircularProgressIndicator(strokeWidth: 2) : const Text('ثبت درخواست پرداخت برای بررسی'))),
        const SizedBox(height: 10),
        const Text('توجه: صرفاً ثبت این درخواست اشتراک را فعال نمی‌کند. فعال‌سازی فقط پس از تأیید واقعی پرداخت توسط سیستم یا مدیر انجام می‌شود.', textAlign: TextAlign.center),
      ]),
    ));
  }
}



class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();

  String category = 'کالای دیجیتال';
  String city = 'تهران';
  bool publishing = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> selectedImages = [];

  static const int maxImages = 10;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداکثر ۱۰ عکس می‌توانید انتخاب کنید.')),
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isEmpty || !mounted) return;

      final remaining = maxImages - selectedImages.length;
      setState(() {
        selectedImages.addAll(images.take(remaining));
      });

      if (images.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فقط ۱۰ عکس اول انتخاب می‌شوند.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتخاب عکس انجام نشد: $e')),
      );
    }
  }

  void removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages({
    required String adId,
    required String userId,
  }) async {
    final uploadedPaths = <String>[];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final Uint8List bytes = await image.readAsBytes();

        final originalExtension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';

        final extension =
            <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(originalExtension)
                ? originalExtension
                : 'jpg';

        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };

        final path =
            '$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

        await supabase.storage.from('ad-images').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );

        uploadedPaths.add(path);

        final imageUrl =
            supabase.storage.from('ad-images').getPublicUrl(path);

        await supabase.from('ad_images').insert({
          'ad_id': adId,
          'image_url': imageUrl,
        });
      }

      return uploadedPaths;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage
              .from('ad-images')
              .remove(uploadedPaths);
        } catch (_) {
          // Storage cleanup is best-effort.
        }
      }
      rethrow;
    }
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty ||
        desc.text.trim().isEmpty ||
        price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عنوان، توضیحات و قیمت را کامل کنید.'),
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا وارد حساب شوید.')),
      );
      return;
    }

    final parsedPrice =
        int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (parsedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      final subscription = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subscription == null) {
        throw Exception('SUBSCRIPTION_REQUIRED');
      }

      final ad = await supabase.rpc(
        'publish_ad',
        params: {
          'p_title': title.text.trim(),
          'p_description': desc.text.trim(),
          'p_price': parsedPrice,
          'p_city': city,
          'p_category': category,
        },
      );

      final adId = ad?.toString();
      if (adId == null || adId.isEmpty) {
        throw Exception('شناسه آگهی دریافت نشد.');
      }

      try {
        await _uploadImages(adId: adId, userId: user.id);
      } catch (e) {
        // Do not leave a half-published ad if image upload fails.
        try {
          await supabase.from('ad_images').delete().eq('ad_id', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        try {
          await supabase.from('ads').delete().eq('idd', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        rethrow;
      }

      await widget.onPublished();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آگهی ثبت شد ✅'),
          content: const Text(
            'آگهی با موفقیت در Supabase ذخیره شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطای آپلود عکس: ${e.message}\\n'
            'اگر این خطا ادامه داشت، Bucket و Storage Policies را در Supabase بررسی می‌کنیم.',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای Supabase: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SUBSCRIPTION_REQUIRED')
          ? 'برای ثبت آگهی اشتراک فعال لازم است.'
          : e.toString().contains('AD_LIMIT_REACHED')
              ? 'سهمیه ۹ آگهی فعال شما تکمیل شده است.'
              : 'خطا در ثبت آگهی: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('اشتراک پایه'),
                subtitle: const Text(
                  '۳۹,۰۰۰ تومان / ماه • سهمیه این ماه: حداکثر ۹ آگهی',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: const [
                'کالای دیجیتال',
                'خودرو',
                'املاک',
                'لوازم خانه',
                'پوشاک',
                'خدمات',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            _field(title, 'عنوان آگهی'),
            const SizedBox(height: 12),
            _field(desc, 'توضیحات', maxLines: 5),
            const SizedBox(height: 12),
            _field(price, 'قیمت'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: city,
              decoration: const InputDecoration(
                labelText: 'شهر',
                border: OutlineInputBorder(),
              ),
              items: const [
                'تهران',
                'کرج',
                'مشهد',
                'اصفهان',
                'شیراز',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => city = v!),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing ? null : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                selectedImages.isEmpty
                    ? 'افزودن عکس (حداکثر ۱۰ عکس)'
                    : 'افزودن عکس (${selectedImages.length}/۱۰)',
              ),
            ),
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  width: 105,
                                  height: 105,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: publishing ? null : () => removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: publishing ? null : publish,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: publishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ثبت و انتشار آگهی'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}).hasMatch(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل ایران را به‌صورت صحیح وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(
        email: value,
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() => codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ورود به ایمیل شما ارسال شد.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال کد انجام نشد: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyCode() async {
    final value = email.text.trim();
    final token = otp.text.trim();

    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد ارسال‌شده را کامل وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final result = await supabase.auth.verifyOTP(
        email: value,
        token: token,
        type: OtpType.email,
      );

      final user = result.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw Exception('ورود تأیید نشد.');
      }

      await supabase.from('profiles').upsert(
        {
          'iidd': user.id,
          'name': 'کاربر آگهینو',
        },
        onConflict: 'iidd',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کد صحیح نیست یا منقضی شده است: ${e.message}')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای پروفایل: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 70),
                const SizedBox(height: 12),
                const Text(
                  'آگهینو',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('خرید و فروش آسان و مطمئن'),
                const SizedBox(height: 35),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'ایمیل',
                    hintText: 'example@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'کد ورود',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : (codeSent ? verifyCode : sendCode),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(codeSent ? 'تأیید و ورود' : 'ارسال کد ورود'),
                    ),
                  ),
                ),
                if (codeSent)
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              codeSent = false;
                              otp.clear();
                            }),
                    child: const Text('تغییر ایمیل'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'ورود با کد یک‌بارمصرف ایمیلی',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loadingAds = true;
  bool loadingSubscription = true;
  bool hasActiveSubscription = false;
  DateTime? subscriptionExpiresAt;
  String searchQuery = '';
  String? selectedCategory;
  List<Map<String, dynamic>> ads = [];

  static const categories = <String>[
    'کالای دیجیتال',
    'خودرو',
    'املاک',
    'لوازم خانه',
    'پوشاک',
    'خدمات',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => loadingSubscription = false);
      return;
    }

    try {
      final row = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', uid)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final expiresRaw = row?['expires_at']?.toString();
      final expires = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

      if (!mounted) return;
      setState(() {
        subscriptionExpiresAt = expires;
        hasActiveSubscription = expires != null && expires.isAfter(DateTime.now());
        loadingSubscription = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingSubscription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بررسی اشتراک انجام نشد: $e')),
      );
    }
  }

  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url)')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        ads = List<Map<String, dynamic>>.from(rows);
        loadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
      );
    }
  }

  int get myAdsCount {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    return ads.where((ad) => ad['seller_id'] == uid).length;
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = searchQuery.trim().toLowerCase();
    return ads.where((ad) {
      final categoryOk = selectedCategory == null ||
          '${ad['category'] ?? ''}' == selectedCategory;
      final text = '${ad['title'] ?? ''} ${ad['edescription'] ?? ''} '
          '${ad['city'] ?? ''} ${ad['category'] ?? ''}'.toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'آگهینو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: loadAds,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const Center(
                    child: Text('علاقه‌مندی‌ها در نسخه بعدی فعال می‌شود.'),
                  )
                : tab == 2
                    ? const Center(
                        child: Text('پیام‌رسانی در نسخه بعدی فعال می‌شود.'),
                      )
                    : account(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    if (loadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('همه'),
                selected: selectedCategory == null,
                onSelected: (_) => setState(() => selectedCategory = null),
              ),
              ...categories.map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: selectedCategory == item,
                  onSelected: (_) => setState(() {
                    selectedCategory = selectedCategory == item ? null : item;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (filteredAds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            )
          else
            ...filteredAds.map((ad) => Card(
                  child: ListTile(
                    leading: Builder(
                      builder: (context) {
                        final images = ad['ad_images'];
                        final firstUrl = images is List && images.isNotEmpty
                            ? images.first['image_url']?.toString()
                            : null;
                        if (firstUrl == null || firstUrl.isEmpty) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            firstUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      '${ad['title'] ?? 'بدون عنوان'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${ad['price'] ?? 'توافقی'} تومان\n'
                      '${ad['city'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                )),
        ],
      ),
    );
  }

  Widget account() {
    final count = myAdsCount;
    final remaining = (9 - count).clamp(0, 9);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            supabase.auth.currentUser?.phone ?? 'کاربر آگهینو',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('اشتراک پایه'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹,۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () async {
                try {
                  final response = await supabase.functions.invoke(
                    'zarinpal-payment',
                    body: const {'action': 'create'},
                  );
                  final data = Map<String, dynamic>.from(response.data as Map);
                  final paymentUrl = data['payment_url']?.toString();
                  if (paymentUrl == null || paymentUrl.isEmpty) {
                    throw Exception('لینک پرداخت از سرور دریافت نشد.');
                  }
                  final opened = await launchUrl(
                    Uri.parse(paymentUrl),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened) throw Exception('باز کردن صفحه پرداخت انجام نشد.');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('پس از تکمیل پرداخت، برنامه را بازخوانی کنید.'),
                      ),
                    );
                  }
                } on FunctionException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطای ایجاد پرداخت: ${e.details ?? e.reasonPhrase}')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطای پرداخت: $e')),
                  );
                }
              },
              child: const Text('خرید'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$count از ۹ آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('خروج'),
        ),
      ],
    );
  }

  void openAdd() {
    if (loadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال بررسی اشتراک هستیم...')),
      );
      return;
    }

    if (!hasActiveSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت آگهی ابتدا اشتراک پایه را فعال کنید.'),
        ),
      );
      setState(() => tab = 3);
      return;
    }

    if (myAdsCount >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه ۹ آگهی این ماه تکمیل شده است.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(
          onPublished: loadAds,
        ),
      ),
    );
  }
}



class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();

  String category = 'کالای دیجیتال';
  String city = 'تهران';
  bool publishing = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> selectedImages = [];

  static const int maxImages = 10;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداکثر ۱۰ عکس می‌توانید انتخاب کنید.')),
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isEmpty || !mounted) return;

      final remaining = maxImages - selectedImages.length;
      setState(() {
        selectedImages.addAll(images.take(remaining));
      });

      if (images.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فقط ۱۰ عکس اول انتخاب می‌شوند.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتخاب عکس انجام نشد: $e')),
      );
    }
  }

  void removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages({
    required String adId,
    required String userId,
  }) async {
    final uploadedPaths = <String>[];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final Uint8List bytes = await image.readAsBytes();

        final originalExtension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';

        final extension =
            <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(originalExtension)
                ? originalExtension
                : 'jpg';

        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };

        final path =
            '$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

        await supabase.storage.from('ad-images').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );

        uploadedPaths.add(path);

        final imageUrl =
            supabase.storage.from('ad-images').getPublicUrl(path);

        await supabase.from('ad_images').insert({
          'ad_id': adId,
          'image_url': imageUrl,
        });
      }

      return uploadedPaths;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage
              .from('ad-images')
              .remove(uploadedPaths);
        } catch (_) {
          // Storage cleanup is best-effort.
        }
      }
      rethrow;
    }
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty ||
        desc.text.trim().isEmpty ||
        price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عنوان، توضیحات و قیمت را کامل کنید.'),
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا وارد حساب شوید.')),
      );
      return;
    }

    final parsedPrice =
        int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (parsedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      final subscription = await supabase
          .from('subscriptions')
          .select('expires_at')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subscription == null) {
        throw Exception('SUBSCRIPTION_REQUIRED');
      }

      final ad = await supabase.rpc(
        'publish_ad',
        params: {
          'p_title': title.text.trim(),
          'p_description': desc.text.trim(),
          'p_price': parsedPrice,
          'p_city': city,
          'p_category': category,
        },
      );

      final adId = ad?.toString();
      if (adId == null || adId.isEmpty) {
        throw Exception('شناسه آگهی دریافت نشد.');
      }

      try {
        await _uploadImages(adId: adId, userId: user.id);
      } catch (e) {
        // Do not leave a half-published ad if image upload fails.
        try {
          await supabase.from('ad_images').delete().eq('ad_id', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        try {
          await supabase.from('ads').delete().eq('idd', adId);
        } catch (_) {
          // Best-effort cleanup.
        }
        rethrow;
      }

      await widget.onPublished();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آگهی ثبت شد ✅'),
          content: const Text(
            'آگهی با موفقیت در Supabase ذخیره شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطای آپلود عکس: ${e.message}\\n'
            'اگر این خطا ادامه داشت، Bucket و Storage Policies را در Supabase بررسی می‌کنیم.',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای Supabase: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SUBSCRIPTION_REQUIRED')
          ? 'برای ثبت آگهی اشتراک فعال لازم است.'
          : e.toString().contains('AD_LIMIT_REACHED')
              ? 'سهمیه ۹ آگهی فعال شما تکمیل شده است.'
              : 'خطا در ثبت آگهی: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('اشتراک پایه'),
                subtitle: const Text(
                  '۳۹,۰۰۰ تومان / ماه • سهمیه این ماه: حداکثر ۹ آگهی',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: const [
                'کالای دیجیتال',
                'خودرو',
                'املاک',
                'لوازم خانه',
                'پوشاک',
                'خدمات',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            _field(title, 'عنوان آگهی'),
            const SizedBox(height: 12),
            _field(desc, 'توضیحات', maxLines: 5),
            const SizedBox(height: 12),
            _field(price, 'قیمت'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: city,
              decoration: const InputDecoration(
                labelText: 'شهر',
                border: OutlineInputBorder(),
              ),
              items: const [
                'تهران',
                'کرج',
                'مشهد',
                'اصفهان',
                'شیراز',
              ]
                  .map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => city = v!),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing ? null : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                selectedImages.isEmpty
                    ? 'افزودن عکس (حداکثر ۱۰ عکس)'
                    : 'افزودن عکس (${selectedImages.length}/۱۰)',
              ),
            ),
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  width: 105,
                                  height: 105,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: publishing ? null : () => removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: publishing ? null : publish,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: publishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ثبت و انتشار آگهی'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class AdDetailPage extends StatefulWidget {
  final Map<String, dynamic> ad;
  const AdDetailPage({super.key, required this.ad});

  @override
  State<AdDetailPage> createState() => _AdDetailPageState();
}

class _AdDetailPageState extends State<AdDetailPage> {
  bool saved = false;
  bool saving = false;

  Future<void> loadSaved() async {
    final uid = supabase.auth.currentUser?.id;
    final adId = widget.ad['idd']?.toString();
    if (uid == null || adId == null) return;
    try {
      final row = await supabase
          .from('favorites')
          .select('ad_id')
          .eq('user_id', uid)
          .eq('ad_id', adId)
          .maybeSingle();
      if (mounted) setState(() => saved = row != null);
    } catch (_) {}
  }

  Future<void> toggleSaved() async {
    final uid = supabase.auth.currentUser?.id;
    final adId = widget.ad['idd']?.toString();
    if (uid == null || adId == null || saving) return;
    setState(() => saving = true);
    try {
      if (saved) {
        await supabase.from('favorites').delete().eq('user_id', uid).eq('ad_id', adId);
      } else {
        await supabase.from('favorites').insert({'user_id': uid, 'ad_id': adId});
      }
      if (mounted) setState(() => saved = !saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ذخیره آگهی انجام نشد: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.ad['title']?.toString() ?? 'بدون عنوان';
    final price = widget.ad['price']?.toString() ?? 'توافقی';
    final city = widget.ad['city']?.toString() ?? '';
    final category = widget.ad['category']?.toString() ?? '';
    final description = widget.ad['edescription']?.toString() ?? 'توضیحی ثبت نشده است.';
    final images = widget.ad['ad_images'] is List
        ? List<Map<String, dynamic>>.from(
            (widget.ad['ad_images'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
          )
        : <Map<String, dynamic>>[];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جزئیات آگهی'),
          actions: [
            IconButton(
              onPressed: saving ? null : toggleSaved,
              icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (images.isNotEmpty)
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final url = images[index]['image_url']?.toString() ?? '';
                    return InteractiveViewer(
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined, size: 48),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 220,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_outlined, size: 60),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('$price تومان', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('$city  •  $category'),
                  const Divider(height: 28),
                  const Text('توضیحات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone_outlined),
                          label: const Text('تماس'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('پیام'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
