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
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  runApp(const AghinouApp());
}

class AghinouApp extends StatelessWidget {
  const AghinouApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'آگهینو',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C3FE8))),
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
  void dispose() { phone.dispose(); super.dispose(); }

  Future<void> login() async {
    final value = phone.text.trim();
    if (value.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شماره موبایل را کامل وارد کنید.')));
      return;
    }
    setState(() => loading = true);
    try {
      if (supabase.auth.currentUser == null) await supabase.auth.signInAnonymously();
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('کاربر ساخته نشد.');
      await supabase.from('profiles').upsert({'iidd': user.id, 'cphone': value, 'name': 'کاربر آگهینو'}, onConflict: 'iidd');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
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
                const Text('آگهینو', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('خرید و فروش آسان و مطمئن'),
                const SizedBox(height: 35),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ادامه'),
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
  String category = 'همه';
  String search = '';
  final searchController = TextEditingController();
  List<Map<String, dynamic>> ads = [];
  final favorites = <String>{};
  final categories = const ['همه', 'خودرو', 'املاک', 'موبایل', 'لوازم خانه', 'کالای دیجیتال', 'پوشاک', 'خدمات'];

  @override
  void initState() { super.initState(); loadAds(); }
  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  Future<void> loadAds() async {
    try {
      final r = await supabase.from('ads').select().order('created_at', ascending: false);
      if (mounted) setState(() => ads = List<Map<String, dynamic>>.from(r));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get filtered => ads.where((a) {
    final c = '${a['category'] ?? ''}';
    final t = '${a['title'] ?? ''} ${a['edescription'] ?? ''} ${a['city'] ?? ''}'.toLowerCase();
    return (category == 'همه' || c == category) && (search.isEmpty || t.contains(search.toLowerCase()));
  }).toList();

  int get myAds => ads.where((a) => a['seller_id'] == supabase.auth.currentUser?.id).length;

  Future<List<String>> imageUrls(String id) async {
    try {
      final r = await supabase.from('ad_images').select('image_url').eq('ad_id', id);
      return r.map<String>((x) => '${x['image_url'] ?? ''}').where((x) => x.isNotEmpty).toList();
    } catch (_) { return []; }
  }

  void openAdd() {
    if (myAds >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سهمیه ۹ آگهی تکمیل شده است.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddAdPage(onPublished: loadAds)));
  }

  void openDetails(Map<String, dynamic> ad, List<String> images) {
    final id = '${ad['idd'] ?? ''}';
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdDetailsPage(
      ad: ad,
      images: images,
      liked: favorites.contains(id),
      onLike: (value) => setState(() {
        if (value) { favorites.add(id); } else { favorites.remove(id); }
      }),
    )));
  }

  Widget adCard(Map<String, dynamic> ad) {
    final id = '${ad['idd'] ?? ''}';
    return FutureBuilder<List<String>>(
      future: imageUrls(id),
      builder: (context, snap) {
        final images = snap.data ?? const <String>[];
        final liked = favorites.contains(id);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openDetails(ad, images),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: images.isEmpty
                      ? const ColoredBox(color: Color(0xFFEDEDED), child: Icon(Icons.image_outlined, size: 40))
                      : Image.network(images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 40)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${ad['title'] ?? 'بدون عنوان'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 7),
                        Text('${ad['price'] ?? 'توافقی'} تومان'),
                        const SizedBox(height: 4),
                        Text('${ad['city'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    if (liked) { favorites.remove(id); } else { favorites.add(id); }
                  }),
                  icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget home() {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          TextField(
            controller: searchController,
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.isEmpty ? null : IconButton(onPressed: () { searchController.clear(); setState(() => search = ''); }, icon: const Icon(Icons.clear)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height: 18),
          const Text('دسته‌بندی‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: categories.map((x) => ChoiceChip(label: Text(x), selected: category == x, onSelected: (_) => setState(() => category = x))).toList()),
          const SizedBox(height: 22),
          const Text('جدیدترین آگهی‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (filtered.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('آگهی‌ای برای نمایش پیدا نشد.'))),
          for (final ad in filtered) adCard(ad),
        ],
      ),
    );
  }

  Widget favoritesView() {
    final list = ads.where((a) => favorites.contains('${a['idd'] ?? ''}')).toList();
    if (list.isEmpty) return const Center(child: Text('هنوز آگهی‌ای به علاقه‌مندی‌ها اضافه نشده است.'));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
      const Text('علاقه‌مندی‌ها', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      for (final ad in list) adCard(ad),
    ]);
  }

  Widget account() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const CircleAvatar(radius: 38, child: Icon(Icons.person, size: 42)),
        const SizedBox(height: 10),
        const Center(child: Text('کاربر آگهینو', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 18),
        Card(child: ListTile(leading: const Icon(Icons.campaign_outlined), title: const Text('آگهی‌های من'), subtitle: Text('$myAds از ۹ آگهی استفاده شده'), onTap: () => setState(() => tab = 0))),
        Card(child: ListTile(leading: const Icon(Icons.phone), title: const Text('شماره موبایل'), subtitle: const Text('شماره ثبت‌شده در حساب'))),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
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
            IconButton(onPressed: loadAds, icon: const Icon(Icons.refresh)),
            IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اعلان جدیدی ندارید.'))), icon: const Icon(Icons.notifications_none)),
          ],
        ),
        body: IndexedStack(index: tab, children: [home(), favoritesView(), const Center(child: Text('پیام‌های شما اینجا نمایش داده می‌شود.')), account()]),
        floatingActionButton: tab == 0 ? FloatingActionButton.extended(onPressed: openAdd, icon: const Icon(Icons.add), label: const Text('ثبت آگهی')) : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
            NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'علاقه‌مندی'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat), label: 'پیام‌ها'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حساب'),
          ],
        ),
      ),
    );
  }
}

class AdDetailsPage extends StatefulWidget {
  final Map<String, dynamic> ad;
  final List<String> images;
  final bool liked;
  final ValueChanged<bool> onLike;
  const AdDetailsPage({super.key, required this.ad, required this.images, required this.liked, required this.onLike});
  @override
  State<AdDetailsPage> createState() => _AdDetailsPageState();
}

class _AdDetailsPageState extends State<AdDetailsPage> {
  late bool liked;
  @override
  void initState() { super.initState(); liked = widget.liked; }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جزئیات آگهی'),
          actions: [
            IconButton(onPressed: () { setState(() => liked = !liked); widget.onLike(liked); }, icon: Icon(liked ? Icons.favorite : Icons.favorite_border)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            if (widget.images.isEmpty)
              const SizedBox(height: 240, child: Center(child: Icon(Icons.image_outlined, size: 90)))
            else
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: widget.images.length,
                  itemBuilder: (_, i) => Image.network(widget.images[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 60))),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.ad['title'] ?? 'بدون عنوان'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('${widget.ad['price'] ?? 'توافقی'} تومان', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('${widget.ad['city'] ?? ''} • ${widget.ad['category'] ?? ''}'),
                  const Divider(height: 30),
                  const Text('توضیحات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${widget.ad['edescription'] ?? 'توضیحی ثبت نشده است.'}', style: const TextStyle(fontSize: 16, height: 1.7)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('گفتگو به‌زودی فعال می‌شود.'))),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('پیام به فروشنده'),
                    ),
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
  void dispose() { title.dispose(); desc.dispose(); price.dispose(); super.dispose(); }

  Future<void> pickImages() async {
    try {
      final picked = await picker.pickMultiImage(imageQuality: 90);
      if (!mounted || picked.isEmpty) return;
      setState(() => images.addAll(picked.take(10 - images.length)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('انتخاب عکس انجام نشد: $e')));
    }
  }

  Future<void> uploadImages(String adId, String userId) async {
    final paths = <String>[];
    try {
      for (var i = 0; i < images.length; i++) {
        final im = images[i];
        final bytes = await im.readAsBytes();
        final name = im.name.toLowerCase();
        final ext = name.endsWith('.png') ? 'png' : name.endsWith('.webp') ? 'webp' : 'jpg';
        final type = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
        final path = 'public/$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$ext';
        await supabase.storage.from(adImagesBucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type, upsert: false));
        paths.add(path);
        final url = supabase.storage.from(adImagesBucket).getPublicUrl(path);
        await supabase.from('ad_images').insert({'ad_id': adId, 'image_url': url});
      }
    } catch (e) {
      if (paths.isNotEmpty) { try { await supabase.storage.from(adImagesBucket).remove(paths); } catch (_) {} }
      rethrow;
    }
  }

  Future<void> cleanup(String? id) async {
    if (id == null) return;
    try { await supabase.from('ad_images').delete().eq('ad_id', id); } catch (_) {}
    try { await supabase.from('ads').delete().eq('idd', id); } catch (_) {}
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty || desc.text.trim().isEmpty || price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عنوان، توضیحات و قیمت را کامل کنید.')));
      return;
    }
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا وارد حساب شوید.')));
      return;
    }
    final p = int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قیمت را به صورت عدد وارد کنید.')));
      return;
    }
    setState(() => publishing = true);
    String? id;
    try {
      final row = await supabase.from('ads').insert({'seller_id': user.id, 'title': title.text.trim(), 'edescription': desc.text.trim(), 'price': p, 'city': city, 'category': category}).select('idd').single();
      id = row['idd']?.toString();
      if (id == null || id!.isEmpty) throw Exception('شناسه آگهی دریافت نشد.');
      await uploadImages(id!, user.id);
      await widget.onPublished();
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('آگهی ثبت شد ✅'), content: const Text('آگهی با موفقیت ثبت شد.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('باشه'))]));
      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      await cleanup(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطای آپلود عکس: ${e.message}')));
    } on PostgrestException catch (e) {
      await cleanup(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطای Supabase: ${e.message}')));
    } catch (e) {
      await cleanup(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ثبت آگهی: $e')));
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  Widget field(TextEditingController c, String label, {int lines = 1}) {
    return TextField(controller: c, maxLines: lines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));
  }

  @override
  Widget build(BuildContext context) {
    const cats = ['کالای دیجیتال', 'خودرو', 'املاک', 'لوازم خانه', 'پوشاک', 'خدمات'];
    const cities = ['تهران', 'کرج', 'مشهد', 'اصفهان', 'شیراز'];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت آگهی جدید')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'دسته‌بندی', border: OutlineInputBorder()),
              items: cats.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: publishing ? null : (v) { if (v != null) setState(() => category = v); },
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
              decoration: const InputDecoration(labelText: 'شهر', border: OutlineInputBorder()),
              items: cities.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: publishing ? null : (v) { if (v != null) setState(() => city = v); },
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: publishing || images.length >= 10 ? null : pickImages,
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
                  itemBuilder: (context, i) {
                    return FutureBuilder<Uint8List>(
                      future: images[i].readAsBytes(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox(width: 105, child: Center(child: CircularProgressIndicator()));
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(snap.data!, width: 105, height: 105, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                onPressed: publishing ? null : () => setState(() => images.removeAt(i)),
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
                icon: publishing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.publish),
                label: Text(publishing ? 'در حال ثبت...' : 'ثبت آگهی'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
