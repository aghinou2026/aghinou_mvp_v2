import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://acfawprpdkzjpyblseay.supabase.co';
const supabasePublishableKey = 'sb_publishable_uHov32wG1uTxNIkbQbaQmQ_6W5mCwKf';
const adImagesBucket = 'ad-images';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  runApp(const AghinouApp());
}

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
  final phone = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final value = phone.text.trim();
    if (value.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل را کامل وارد کنید.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      if (supabase.auth.currentUser == null) {
        await supabase.auth.signInAnonymously();
      }

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('کاربر ساخته نشد.');
      }

      await supabase.from('profiles').upsert(
        {
          'iidd': user.id,
          'cphone': value,
          'name': 'کاربر آگهینو',
        },
        onConflict: 'iidd',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
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
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('ادامه'),
                  ),
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
  bool loading = true;
  List<Map<String, dynamic>> ads = [];

  @override
  void initState() {
    super.initState();
    loadAds();
  }

  Future<void> loadAds() async {
    try {
      final result = await supabase
          .from('ads')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          ads = List<Map<String, dynamic>>.from(result);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int get myAds {
    final userId = supabase.auth.currentUser?.id;
    return ads.where((ad) => ad['seller_id'] == userId).length;
  }

  void openAdd() {
    if (myAds >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سهمیه ۹ آگهی تکمیل شده است.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(onPublished: loadAds),
      ),
    );
  }

  Widget home() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('🚗 خودرو')),
              Chip(label: Text('🏠 املاک')),
              Chip(label: Text('📱 موبایل')),
              Chip(label: Text('🪑 لوازم خانه')),
              Chip(label: Text('💻 کالای دیجیتال')),
              Chip(label: Text('👕 پوشاک')),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (ads.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            ),
          for (final ad in ads)
            Card(
              child: ListTile(
                onTap: () {},
                leading: const CircleAvatar(
                  child: Icon(Icons.image_outlined),
                ),
                title: Text('${ad['title'] ?? 'بدون عنوان'}'),
                subtitle: Text(
                  '${ad['price'] ?? 'توافقی'} تومان\n${ad['city'] ?? ''}',
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget account() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'کاربر آگهینو',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text('$myAds از ۹ آگهی استفاده شده'),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('آگهینو'),
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
        body: IndexedStack(
          index: tab,
          children: [
            home(),
            const Center(child: Text('علاقه‌مندی‌ها')),
            const Center(child: Text('پیام‌ها')),
            account(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) {
            setState(() => tab = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }
}

class AddAdPage extends StatefulWidget {
  final Future<void> Function() onPublished;

  const AddAdPage({super.key, required this.onPublished});

  @override
  State<AddAdPage> createState() => _AddAdPageState();
}

class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();
  final picker = ImagePicker();
  final images = <XFile>[];

  String category = 'کالای دیجیتال';
  String city = 'تهران';
  bool publishing = false;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    try {
      final picked = await picker.pickMultiImage(imageQuality: 90);
      if (!mounted || picked.isEmpty) return;

      final remaining = 10 - images.length;
      setState(() {
        images.addAll(picked.take(remaining));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('انتخاب عکس انجام نشد: $e')),
        );
      }
    }
  }

  Future<void> uploadImages(String adId, String userId) async {
    final paths = <String>[];

    try {
      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        final bytes = await image.readAsBytes();
        final name = image.name.toLowerCase();
        final ext = name.endsWith('.png')
            ? 'png'
            : name.endsWith('.webp')
                ? 'webp'
                : 'jpg';
        final type = ext == 'png'
            ? 'image/png'
            : ext == 'webp'
                ? 'image/webp'
                : 'image/jpeg';
        final path =
            'public/$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$ext';

        await supabase.storage.from(adImagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: type,
            upsert: false,
          ),
        );
        paths.add(path);

        final url = supabase.storage.from(adImagesBucket).getPublicUrl(path);
        await supabase.from('ad_images').insert({
          'ad_id': adId,
          'image_url': url,
        });
      }
    } catch (e) {
      if (paths.isNotEmpty) {
        try {
          await supabase.storage.from(adImagesBucket).remove(paths);
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> cleanup(String? id) async {
    if (id == null) return;

    try {
      await supabase.from('ad_images').delete().eq('ad_id', id);
    } catch (_) {}

    try {
      await supabase.from('ads').delete().eq('idd', id);
    } catch (_) {}
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty ||
        desc.text.trim().isEmpty ||
        price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان، توضیحات و قیمت را کامل کنید.')),
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

    final parsed = int.tryParse(
      price.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')),
      );
      return;
    }

    setState(() => publishing = true);
    String? adId;

    try {
      final row = await supabase
          .from('ads')
          .insert({
            'seller_id': user.id,
            'title': title.text.trim(),
            'edescription': desc.text.trim(),
            'price': parsed,
            'city': city,
            'category': category,
          })
          .select('idd')
          .single();

      adId = row['idd']?.toString();
      if (adId == null || adId!.isEmpty) {
        throw Exception('شناسه آگهی دریافت نشد.');
      }

      await uploadImages(adId!, user.id);
      await widget.onPublished();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('آگهی ثبت شد ✅'),
            content: const Text('آگهی با موفقیت ثبت شد.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('باشه'),
              ),
            ],
          );
        },
      );

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      await cleanup(adId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطای آپلود عکس: ${e.message}')),
        );
      }
    } on PostgrestException catch (e) {
      await cleanup(adId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطای Supabase: ${e.message}')),
        );
      }
    } catch (e) {
      await cleanup(adId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت آگهی: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'کالای دیجیتال',
      'خودرو',
      'املاک',
      'لوازم خانه',
      'پوشاک',
      'خدمات',
    ];
    final cities = ['تهران', 'کرج', 'مشهد', 'اصفهان', 'شیراز'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: publishing
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => category = value);
                      }
                    },
            ),
            const SizedBox(height: 12),
            field(title, 'عنوان آگهی'),
            const SizedBox(height: 12),
            field(desc, 'توضیحات', lines: 5),
            const SizedBox(height: 12),
            field(price, 'قیمت'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: city,
              decoration: const InputDecoration(
                labelText: 'شهر',
                border: OutlineInputBorder(),
              ),
              items: cities
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: publishing
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => city = value);
                      }
                    },
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing || images.length >= 10
                  ? null
                  : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text('افزودن عکس (${images.length}/۱۰)'),
            ),
            if (images.isNotEmpty)
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return FutureBuilder<Uint8List>(
                      future: images[index].readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            width: 105,
                            height: 105,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                snapshot.data!,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                onPressed: publishing
                                    ? null
                                    : () => setState(
                                          () => images.removeAt(index),
                                        ),
                                icon: const Icon(Icons.cancel),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: publishing ? null : publish,
                icon: publishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish),
                label: Text(
                  publishing ? 'در حال ثبت...' : 'ثبت آگهی',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
