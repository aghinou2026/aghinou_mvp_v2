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
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final otp = TextEditingController();
  bool loading = false;
  bool codeSent = false;

  @override
  void dispose() {
    email.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> sendCode() async {
    final value = email.text.trim();
    if (!value.contains('@') || !value.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('یک ایمیل معتبر وارد کنید.')),
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
          .from('payments')
          .select('subscription_expires_at')
          .eq('user_id', uid)
          .eq('status', 'paid')
          .gt('subscription_expires_at', DateTime.now().toIso8601String())
          .order('subscription_expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final expiresRaw = row?['subscription_expires_at']?.toString();
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
      final text = '${ad['title'] ?? ''} ${ad['edescriptions'] ?? ''} '
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
            supabase.auth.currentUser?.email ?? 'کاربر آگهینو',
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
                  : 'غیرفعال • ۳۵,۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
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
          .from('payments')
          .select('subscription_expires_at')
          .eq('user_id', user.id)
          .eq('status', 'paid')
          .gt('subscription_expires_at', DateTime.now().toIso8601String())
          .order('subscription_expires_at', ascending: false)
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
                  '۳۵,۰۰۰ تومان / ماه • سهمیه این ماه: حداکثر ۹ آگهی',
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
