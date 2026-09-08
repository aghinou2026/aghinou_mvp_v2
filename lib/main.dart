import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_image_uploader.dart';
import 'subscription_service.dart';
import 'iran_locations.dart';

const supabaseUrl = 'https://acfawprpdkzjpyblseay.supabase.co';
const supabasePublishableKey = 'sb_publishable_uHov32wG1uTxNIkbQbaQmQ_6W5mCwKf';
const adImagesBucket = 'ad-images';
final supabase = Supabase.instance.client;

const categoryNames = ['همه', 'خودرو', 'املاک', 'موبایل', 'لوازم خانه', 'کالای دیجیتال', 'پوشاک', 'خدمات'];
const categorySubs = <String, List<String>>{
  'خودرو': ['همه', 'سواری', 'وانت', 'کامیون و کامیونت', 'ماشین سنگین', 'کلاسیک', 'موتورسیکلت', 'قطعات و لوازم'],
  'املاک': ['همه', 'فروش آپارتمان', 'اجاره آپارتمان', 'خانه و ویلا', 'زمین', 'مغازه و تجاری', 'اداری'],
  'موبایل': ['همه', 'گوشی موبایل', 'تبلت', 'ساعت هوشمند', 'لوازم جانبی'],
  'لوازم خانه': ['همه', 'مبلمان', 'لوازم آشپزخانه', 'لوازم برقی', 'دکوراسیون'],
  'کالای دیجیتال': ['همه', 'لپ‌تاپ', 'کامپیوتر', 'کنسول بازی', 'دوربین', 'صوتی و تصویری'],
  'پوشاک': ['همه', 'مردانه', 'زنانه', 'بچگانه', 'کفش و کیف'],
  'خدمات': ['همه', 'فنی و تعمیرات', 'آموزشی', 'حمل و نقل', 'نظافت', 'سایر'],
};

const categoryIcons = <String, IconData>{
  'همه': Icons.apps_rounded,
  'خودرو': Icons.directions_car_rounded,
  'املاک': Icons.home_work_rounded,
  'موبایل': Icons.phone_android_rounded,
  'لوازم خانه': Icons.chair_rounded,
  'کالای دیجیتال': Icons.laptop_mac_rounded,
  'پوشاک': Icons.checkroom_rounded,
  'خدمات': Icons.handyman_rounded,
};

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C4CF1)),
        scaffoldBackgroundColor: const Color(0xFFF7F5FC),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: Color(0xFFF7F5FC)),
        cardTheme: CardThemeData(elevation: 2, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(width: 2)),
        ),
      ),
      home: const EntryPage(),
    );
  }
}

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});
  @override State<EntryPage> createState() => _EntryPageState();
}
class _EntryPageState extends State<EntryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final session = supabase.auth.currentSession;
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => session != null ? const HomePage() : LoginPage(savedPhone: prefs.getString('aghinou_phone'))));
    });
  }
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.savedPhone});
  final String? savedPhone;
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  bool loading = false;
  bool changeNumber = false;
  @override void initState() { super.initState(); phone.text = widget.savedPhone ?? ''; changeNumber = widget.savedPhone == null; }
  @override void dispose() { phone.dispose(); super.dispose(); }

  Future<void> login() async {
    final value = phone.text.trim();
    if (value.length < 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شماره موبایل را کامل وارد کنید.'))); return; }
    setState(() => loading = true);
    try {
      if (supabase.auth.currentSession == null) await supabase.auth.signInAnonymously();
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('کاربر ساخته نشد');
      await supabase.from('profiles').upsert({'iidd': user.id, 'cphone': value, 'name': 'کاربر آگهینو'}, onConflict: 'iidd');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('aghinou_phone', value);
      await prefs.setBool('aghinou_first_run_intro_seen', true);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ورود: $e')));
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.savedPhone != null && widget.savedPhone!.isNotEmpty && !changeNumber;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Column(children: [
      Container(width: 88, height: 88, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(28)), child: Icon(Icons.storefront_rounded, size: 52, color: Theme.of(context).colorScheme.primary)),
      const SizedBox(height: 18), const Text('آگهینو', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)), const SizedBox(height: 6),
      const Text('خرید و فروش آسان و مطمئن', style: TextStyle(fontSize: 16)), const SizedBox(height: 32),
      if (saved) ...[
        const Text('خوش برگشتی 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        Text('ورود سریع با شماره ${widget.savedPhone}'), const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: loading ? null : login, icon: const Icon(Icons.flash_on_rounded), label: const Text('ورود سریع'))),
        const SizedBox(height: 8), TextButton(onPressed: loading ? null : () => setState(() => changeNumber = true), child: const Text('تغییر شماره موبایل')),
      ] else ...[
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل', prefixIcon: Icon(Icons.phone_rounded))), const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : login, child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ورود و ادامه'))),
      ],
    ]))))));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  String category = 'همه', subcategory = 'همه', city = 'همه شهرها', search = '', sortMode = 'جدیدترین';
  final searchController = TextEditingController();
  List<Map<String, dynamic>> ads = [];
  final favorites = <String>{};
  bool loading = true;

  @override void initState() { super.initState(); loadAds(); }
  @override void dispose() { searchController.dispose(); super.dispose(); }
  Future<void> loadAds() async {
    try {
      final result = await supabase.from('ads').select().order('created_at', ascending: false);
      if (mounted) setState(() => ads = List<Map<String, dynamic>>.from(result));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e'))); }
    finally { if (mounted) setState(() => loading = false); }
  }
  List<Map<String, dynamic>> get filtered {
    final list = ads.where((a) {
      final cat = '${a['category'] ?? ''}'; final sub = '${a['subcategory'] ?? ''}';
      final text = '${a['title'] ?? ''} ${a['edescription'] ?? ''} ${a['city'] ?? ''} ${a['vehicle_brand'] ?? ''} ${a['vehicle_model'] ?? ''}'.toLowerCase();
      return (category == 'همه' || cat == category) && (subcategory == 'همه' || sub == subcategory) && (city == 'همه شهرها' || '${a['city'] ?? ''}' == city) && (search.isEmpty || text.contains(search.toLowerCase()));
    }).toList();
    double price(Map<String, dynamic> a) => double.tryParse('${a['price'] ?? ''}') ?? double.infinity;
    if (sortMode == 'ارزان‌ترین') list.sort((a,b) => price(a).compareTo(price(b)));
    if (sortMode == 'گران‌ترین') list.sort((a,b) => price(b).compareTo(price(a)));
    return list;
  }
  Future<List<String>> imageUrls(String id) async { try { final r = await supabase.from('ad_images').select('image_url').eq('ad_id', id); return r.map<String>((x) => '${x['image_url'] ?? ''}').where((x) => x.isNotEmpty).toList(); } catch (_) { return []; } }
  Future<void> chooseCategory() async {
    final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => CategoryPage(initialCategory: category, initialSubcategory: subcategory)));
    if (result == null || !mounted) return; final p = result.split('|||'); setState(() { category = p[0]; subcategory = p.length > 1 ? p[1] : 'همه'; });
  }
  Future<void> chooseCity() async {
    final result = await showModalBottomSheet<String>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const CityPicker());
    if (result != null && mounted) setState(() => city = result);
  }
  Future<void> openAdd() async {
    final active = await SubscriptionService.hasActiveSubscription();
    if (!mounted) return;
    if (!active) { await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('اشتراک لازم است'), content: const Text('برای ثبت آگهی باید اشتراک ماهانه فعال داشته باشید.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بعداً')), FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage())); }, child: const Text('مشاهده اشتراک'))])); return; }
    final count = await supabase.from('ads').select('idd').eq('seller_id', supabase.auth.currentUser!.id);
    if (!mounted) return;
    if (count.length >= 9) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سهمیه ۹ آگهی تکمیل شده است.'))); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddAdPage(onPublished: loadAds)));
  }
  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeContent(),
      Center(child: Text('آگهی‌های محبوب', style: Theme.of(context).textTheme.headlineSmall)),
      Center(child: Text('پیام‌ها', style: Theme.of(context).textTheme.headlineSmall)),
      _accountPage(),
    ];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: SafeArea(child: pages[tab]),
      floatingActionButton: FloatingActionButton.extended(onPressed: openAdd, icon: const Icon(Icons.add_rounded), label: const Text('ثبت آگهی')),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'خانه'), NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'علاقه‌مندی'), NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'پیام‌ها'), NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'حساب')]),
    ));
  }

  Widget _homeContent() => RefreshIndicator(onRefresh: loadAds, child: CustomScrollView(slivers: [
    SliverAppBar(pinned: true, backgroundColor: const Color(0xFFF7F5FC), title: const Text('آگهینو', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: loadAds, icon: const Icon(Icons.refresh_rounded))]),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: TextField(controller: searchController, onChanged: (v) => setState(() => search = v.trim()), decoration: const InputDecoration(hintText: 'جستجو در آگهی‌ها', prefixIcon: Icon(Icons.search_rounded))))),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Expanded(child: OutlinedButton.icon(onPressed: chooseCategory, icon: Icon(categoryIcons[category] ?? Icons.category_rounded), label: Text(category == 'همه' ? 'دسته‌بندی' : '$category${subcategory != 'همه' ? ' • $subcategory' : ''}', overflow: TextOverflow.ellipsis))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: chooseCity, icon: const Icon(Icons.location_on_outlined), label: Text(city, overflow: TextOverflow.ellipsis)))]))),
    SliverToBoxAdapter(child: SizedBox(height: 126, child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 16, 16, 10), scrollDirection: Axis.horizontal, itemCount: categoryNames.length, separatorBuilder: (_,__) => const SizedBox(width: 10), itemBuilder: (_, i) { final c = categoryNames[i]; final selected = category == c; return GestureDetector(onTap: () => setState(() { category = c; subcategory = 'همه'; }), child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 92, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primaryContainer : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(categoryIcons[c], size: 30, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 7), Text(c, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]))); })),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: Row(children: [Text('${filtered.length} آگهی', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), PopupMenuButton<String>(initialValue: sortMode, onSelected: (v) => setState(() => sortMode = v), itemBuilder: (_) => const [PopupMenuItem(value: 'جدیدترین', child: Text('جدیدترین')), PopupMenuItem(value: 'ارزان‌ترین', child: Text('ارزان‌ترین')), PopupMenuItem(value: 'گران‌ترین', child: Text('گران‌ترین'))], child: const Chip(avatar: Icon(Icons.sort_rounded, size: 18), label: Text('مرتب‌سازی')))]))),
    if (loading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator())) else if (filtered.isEmpty) const SliverFillRemaining(child: Center(child: Text('آگهی‌ای پیدا نشد'))) else SliverPadding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 110), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((_, i) => AdCard(ad: filtered[i], imageLoader: imageUrls, favorite: favorites.contains('${filtered[i]['idd']}'), onFavorite: () => setState(() { final id = '${filtered[i]['idd']}'; favorites.contains(id) ? favorites.remove(id) : favorites.add(id); }), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdDetailsPage(ad: filtered[i], imageLoader: imageUrls)))), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 12, childAspectRatio: .68)))
  ]));

  Widget _accountPage() => ListView(padding: const EdgeInsets.all(20), children: [const SizedBox(height: 30), const CircleAvatar(radius: 42, child: Icon(Icons.person_rounded, size: 44)), const SizedBox(height: 12), const Center(child: Text('حساب کاربری', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), const SizedBox(height: 24), Card(child: Column(children: [ListTile(leading: const Icon(Icons.card_membership_rounded), title: const Text('اشتراک'), trailing: const Icon(Icons.chevron_left_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage()))), const Divider(height: 1), ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('خروج از حساب'), onTap: () async { await supabase.auth.signOut(); if (!mounted) return; final prefs = await SharedPreferences.getInstance(); await prefs.remove('aghinou_phone'); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false); })]))]);
}

class AdCard extends StatelessWidget {
  const AdCard({super.key, required this.ad, required this.imageLoader, required this.favorite, required this.onFavorite, required this.onTap});
  final Map<String, dynamic> ad; final Future<List<String>> Function(String) imageLoader; final bool favorite; final VoidCallback onFavorite, onTap;
  @override Widget build(BuildContext context) { final id = '${ad['idd'] ?? ''}'; final title = '${ad['title'] ?? 'بدون عنوان'}'; final price = '${ad['price'] ?? ''}'; final city = '${ad['city'] ?? ''}'; final sub = '${ad['subcategory'] ?? ''}'; return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Stack(fit: StackFit.expand, children: [FutureBuilder<List<String>>(future: imageLoader(id), builder: (_, snap) { final urls = snap.data ?? []; return urls.isEmpty ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.image_outlined, size: 44)) : Image.network(urls.first, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image_outlined))); }), Positioned(top: 6, right: 6, child: Material(color: Colors.white.withValues(alpha: .9), shape: const CircleBorder(), child: InkWell(onTap: onFavorite, customBorder: const CircleBorder(), child: Padding(padding: const EdgeInsets.all(7), child: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20)))))])), Padding(padding: const EdgeInsets.fromLTRB(10, 9, 10, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(price.isEmpty ? 'توافقی' : '$price تومان', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)), const SizedBox(height: 3), Text('$city${sub.isNotEmpty ? ' • $sub' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)), const SizedBox(height: 3), Text(_relativeTime(ad['created_at']), style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant))]))]))); }
}

String _relativeTime(dynamic value) { final d = DateTime.tryParse('$value')?.toLocal(); if (d == null) return 'زمان نامشخص'; final diff = DateTime.now().difference(d); if (diff.inMinutes < 1) return 'همین الان'; if (diff.inMinutes < 60) return '${diff.inMinutes} دقیقه پیش'; if (diff.inHours < 24) return '${diff.inHours} ساعت پیش'; if (diff.inDays < 7) return '${diff.inDays} روز پیش'; return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}'; }

class CategoryPage extends StatefulWidget { const CategoryPage({super.key, required this.initialCategory, required this.initialSubcategory}); final String initialCategory, initialSubcategory; @override State<CategoryPage> createState() => _CategoryPageState(); }
class _CategoryPageState extends State<CategoryPage> {
  late String selected; late String sub;
  @override void initState() { super.initState(); selected = widget.initialCategory; sub = widget.initialSubcategory; }
  void done() => Navigator.pop(context, '$selected|||$sub');
  @override Widget build(BuildContext context) { final subs = selected == 'همه' ? const <String>[] : (categorySubs[selected] ?? const <String>[]); return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('انتخاب دسته‌بندی'), actions: [TextButton(onPressed: done, child: const Text('تأیید'))]), body: ListView(padding: const EdgeInsets.all(16), children: [const Text('دسته اصلی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: categoryNames.map((c) => ChoiceChip(label: Text(c), selected: selected == c, avatar: Icon(categoryIcons[c], size: 18), onSelected: (_) => setState(() { selected = c; sub = 'همه'; }))).toList()), if (selected != 'همه') ...[const SizedBox(height: 24), Text('زیر‌دسته‌های $selected', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), ...subs.map((s) => Card(child: RadioListTile<String>(value: s, groupValue: sub, title: Text(s), onChanged: (v) => setState(() => sub = v ?? 'همه'))))]])); }
}

class CityPicker extends StatefulWidget { const CityPicker({super.key}); @override State<CityPicker> createState() => _CityPickerState(); }
class _CityPickerState extends State<CityPicker> {
  final controller = TextEditingController(); String q = '';
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final cities = allIranCities().where((c) => q.isEmpty || c.contains(q)).toList(); return Directionality(textDirection: TextDirection.rtl, child: SizedBox(height: MediaQuery.sizeOf(context).height * .86, child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 20), child: Column(children: [const Text('انتخاب شهر', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 12), TextField(controller: controller, autofocus: true, onChanged: (v) => setState(() => q = v.trim()), decoration: const InputDecoration(hintText: 'نام شهر را بنویسید؛ مثلاً اردبیل', prefixIcon: Icon(Icons.search_rounded))), const SizedBox(height: 10), Expanded(child: ListView.builder(itemCount: cities.length, itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.location_city_rounded), title: Text(cities[i]), onTap: () => Navigator.pop(context, cities[i]))))])))); }
}

class AddAdPage extends StatefulWidget { const AddAdPage({super.key, required this.onPublished}); final Future<void> Function() onPublished; @override State<AddAdPage> createState() => _AddAdPageState(); }
class _AddAdPageState extends State<AddAdPage> {
  final title = TextEditingController(); final desc = TextEditingController(); final price = TextEditingController(); final city = TextEditingController();
  String category = 'همه', subcategory = 'همه'; List<XFile> images = []; bool saving = false;
  @override void dispose() { title.dispose(); desc.dispose(); price.dispose(); city.dispose(); super.dispose(); }
  Future<void> pickImages() async { final picked = await ImagePicker().pickMultiImage(imageQuality: 88); if (!mounted) return; setState(() => images = picked.take(10).toList()); }
  Future<void> pickCity() async { final v = await showModalBottomSheet<String>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const CityPicker()); if (v != null) setState(() => city.text = v); }
  Future<void> pickCategory() async { final v = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => CategoryPage(initialCategory: category, initialSubcategory: subcategory))); if (v == null) return; final p = v.split('|||'); setState(() { category = p[0]; subcategory = p.length > 1 ? p[1] : 'همه'; }); }
  Future<void> save() async {
    if (title.text.trim().isEmpty || category == 'همه' || city.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عنوان، دسته‌بندی و شهر را کامل کنید.'))); return; }
    final user = supabase.auth.currentUser; if (user == null) return;
    setState(() => saving = true);
    try {
      final row = await supabase.from('ads').insert({'seller_id': user.id, 'title': title.text.trim(), 'edescription': desc.text.trim(), 'category': category, 'subcategory': subcategory, 'city': city.text.trim(), 'price': price.text.trim().isEmpty ? null : price.text.trim()}).select('idd').single();
      final id = '${row['idd']}';
      if (images.isNotEmpty) await const AdImageUploader(client: supabase, bucket: adImagesBucket).uploadXFiles(adId: id, userId: user.id, images: images);
      await widget.onPublished();
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت آگهی انجام نشد: $e'))); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('ثبت آگهی')), body: ListView(padding: const EdgeInsets.all(16), children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان آگهی *', prefixIcon: Icon(Icons.title_rounded))), const SizedBox(height: 12), OutlinedButton.icon(onPressed: pickCategory, icon: Icon(categoryIcons[category]), label: Align(alignment: Alignment.centerRight, child: Text(category == 'همه' ? 'دسته‌بندی را انتخاب کنید *' : '$category${subcategory != 'همه' ? ' • $subcategory' : ''}'))), const SizedBox(height: 12), TextField(controller: city, readOnly: true, onTap: pickCity, decoration: const InputDecoration(labelText: 'شهر *', hintText: 'برای جستجوی سریع لمس کنید', prefixIcon: Icon(Icons.location_on_rounded), suffixIcon: Icon(Icons.keyboard_arrow_down_rounded))), const SizedBox(height: 12), TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت', prefixIcon: Icon(Icons.payments_outlined))), const SizedBox(height: 12), TextField(controller: desc, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'توضیحات')), const SizedBox(height: 14), OutlinedButton.icon(onPressed: pickImages, icon: const Icon(Icons.photo_library_outlined), label: Text('انتخاب عکس‌ها (${images.length}/10)')), if (images.isNotEmpty) SizedBox(height: 90, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: images.length, separatorBuilder: (_,__) => const SizedBox(width: 8), itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(images[i].readAsBytes() as dynamic, width: 90, height: 90, fit: BoxFit.cover))), const SizedBox(height: 20), SizedBox(height: 52, child: FilledButton(onPressed: saving ? null : save, child: saving ? const CircularProgressIndicator() : const Text('ثبت آگهی')))]));
}

class AdDetailsPage extends StatelessWidget { const AdDetailsPage({super.key, required this.ad, required this.imageLoader}); final Map<String,dynamic> ad; final Future<List<String>> Function(String) imageLoader; @override Widget build(BuildContext context) { final id='${ad['idd'] ?? ''}'; return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('جزئیات آگهی')), body: FutureBuilder<List<String>>(future: imageLoader(id), builder: (_, snap) { final urls=snap.data ?? []; return ListView(padding: const EdgeInsets.all(16), children: [if(urls.isNotEmpty) SizedBox(height: 280, child: PageView(children: urls.map((u)=>ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(u, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.broken_image)))).toList())), const SizedBox(height: 18), Text('${ad['title'] ?? 'بدون عنوان'}', style: const TextStyle(fontSize: 25,fontWeight: FontWeight.w900)), const SizedBox(height: 10), Text('${ad['price'] ?? 'توافقی'}${ad['price'] == null || '${ad['price']}' == '' ? '' : ' تومان'}', style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary)), const SizedBox(height: 12), Text('${ad['city'] ?? ''} • ${ad['category'] ?? ''} • ${ad['subcategory'] ?? ''}'), const Divider(height: 30), Text('${ad['edescription'] ?? 'توضیحی ثبت نشده است'}', style: const TextStyle(fontSize: 16,height: 1.7))]; }))); } }

class SubscriptionPage extends StatelessWidget { const SubscriptionPage({super.key}); @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('اشتراک آگهینو')), body: Padding(padding: const EdgeInsets.all(20), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.workspace_premium_rounded, size: 60), const SizedBox(height: 12), const Text('اشتراک ماهانه', style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('۳۵٬۰۰۰ تومان', style: TextStyle(fontSize: 28,fontWeight: FontWeight.w900)), const SizedBox(height: 10), const Text('امکان ثبت حداکثر ۹ آگهی'), const SizedBox(height: 24), FilledButton.icon(onPressed: () async { try { final result=await SubscriptionService.createPayment(); final url=Uri.tryParse('${result['payment_url'] ?? ''}'); if(url != null) { /* پرداخت توسط سرویس موجود */ } } catch (_) {} }, icon: const Icon(Icons.credit_card_rounded), label: const Text('خرید اشتراک'))]))))); }
}
