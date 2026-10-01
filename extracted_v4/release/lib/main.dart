import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        fontFamily: 'sans',
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF006D77),
          onPrimary: Colors.white,
          secondary: Color(0xFF0A9396),
          onSecondary: Colors.white,
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF17212B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F8FA),
          foregroundColor: Color(0xFF17212B),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFD7F0F1),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      home: supabase.auth.currentSession == null ? const LoginPage() : const HomePage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  String normalized() {
    final v = phone.text.trim().replaceAll(' ', '').replaceAll('-', '');
    return v.startsWith('0') ? '+98' + v.substring(1) : v;
  }

  Future<void> login() async {
    final v = normalized();
    final p = password.text;
    if (!RegExp(r'^\+98\d{10}$').hasMatch(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل را صحیح وارد کنید.')),
      );
      return;
    }
    if (p.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز ورود باید حداقل ۶ کاراکتر باشد.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final r = await supabase.auth.signInWithPassword(phone: v, password: p);
      final u = r.user;
      if (u == null) throw Exception('ورود انجام نشد.');
      await supabase.from('profiles').upsert({
        'iidd': u.id,
        'cphone': v,
        'name': 'کاربر آگهینو',
      }, onConflict: 'iidd');
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ورود: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ورود انجام نشد: ${e}')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> register() async {
    final v = normalized();
    final p = password.text;
    if (!RegExp(r'^\+98\d{10}$').hasMatch(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل را صحیح وارد کنید.')),
      );
      return;
    }
    if (p.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز ورود باید حداقل ۶ کاراکتر باشد.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final r = await supabase.auth.signUp(phone: v, password: p);
      final u = r.user;
      if (u == null) throw Exception('ساخت حساب انجام نشد.');
      if (r.session == null) {
        throw Exception('حساب ساخته شد، اما تأیید شماره تلفن فعال است. در تنظیمات Auth باید تأیید شماره تلفن خاموش باشد.');
      }
      await supabase.from('profiles').upsert({
        'iidd': u.id,
        'cphone': v,
        'name': 'کاربر آگهینو',
      }, onConflict: 'iidd');
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت‌نام: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت‌نام انجام نشد: ${e}')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF006D77), Color(0xFF0A9396)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 46, color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text('آگهینو', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF17212B))),
                const SizedBox(height: 6),
                const Text('بازار ساده، امن و حرفه‌ای', style: TextStyle(color: Color(0xFF60727A), fontSize: 14)),
                const SizedBox(height: 30),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'شماره موبایل', hintText: '09121234567', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'رمز ورود', hintText: 'حداقل ۶ کاراکتر', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : login, child: Text(loading ? 'در حال ورود...' : 'ورود'))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: loading ? null : register, child: const Text('ساخت حساب جدید'))),
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
  bool isAdmin = false;
  int adsUsed = 0;
  int adLimit = 9;
  DateTime? subscriptionExpiresAt;
  String searchQuery = '';
  String? selectedCategory;
  String? selectedCity;
  String sortMode = 'newest';
  int? minPrice;
  int? maxPrice;
  List<String> recentSearches = [];
  List<Map<String, dynamic>> ads = [];

  static const categories = <String>[
    'خودرو','املاک','موبایل و تبلت','لوازم دیجیتال','لوازم خانگی','مبلمان و دکوراسیون','پوشاک و کیف و کفش','وسایل نقلیه','خدمات','استخدام و کاریابی','لوازم شخصی','سرگرمی و ورزش','کشاورزی و دامداری','ابزار و تجهیزات','حیوانات','سایر',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadSubscription();
    loadAdmin();
  }

  Future<void> loadAdmin() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final row = await supabase.from('admin_users').select('user_id').eq('user_id', uid).maybeSingle();
      if (mounted) setState(() => isAdmin = row != null);
    } catch (_) {}
  }

  Future<void> loadSubscription() async {
    final uid=supabase.auth.currentUser?.id;
    if(uid==null){if(mounted)setState(()=>loadingSubscription=false);return;}
    try{
      final row=await supabase.from('subscriptions').select('expires_at,ads_used,ad_limit,status').eq('user_id',uid).eq('status','active').gt('expires_at',DateTime.now().toIso8601String()).order('expires_at',ascending:false).limit(1).maybeSingle();
      final expiresRaw=row?['expires_at']?.toString();
      final expires=expiresRaw==null?null:DateTime.tryParse(expiresRaw);
      if(!mounted)return;
      setState((){subscriptionExpiresAt=expires;hasActiveSubscription=expires!=null&&expires.isAfter(DateTime.now());adsUsed=(row?['ads_used'] as num?)?.toInt()??0;adLimit=(row?['ad_limit'] as num?)?.toInt()??9;loadingSubscription=false;});
    }catch(e){if(mounted){setState(()=>loadingSubscription=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('بررسی اشتراک انجام نشد: $e')));}}
  }
  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url,sort_order,is_primary)')
          .eq('publish_status', 'published')
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

  String normalizeFa(String value) {
    return value
        .toLowerCase()
        .replaceAll('ي','ی')
        .replaceAll('ى','ی')
        .replaceAll('ك','ک')
        .replaceAll('ة','ه')
        .replaceAll('ۀ','ه')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .replaceAll('‌',' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = normalizeFa(searchQuery);
    final result = ads.where((ad) {
      final categoryOk = selectedCategory == null || '${ad['category'] ?? ''}' == selectedCategory;
      final cityOk = selectedCity == null || '${ad['city'] ?? ''}' == selectedCity;
      final price = (ad['price'] as num?)?.toInt();
      final minOk = minPrice == null || (price != null && price >= minPrice!);
      final maxOk = maxPrice == null || (price != null && price <= maxPrice!);
      final text = normalizeFa('${ad['title'] ?? ''} ${ad['edescription'] ?? ''} ${ad['city'] ?? ''} ${ad['category'] ?? ''}');
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && cityOk && minOk && maxOk && searchOk;
    }).toList();
    if(sortMode=='cheapest') result.sort((a,b)=>((a['price'] as num?)??0).compareTo((b['price'] as num?)??0));
    if(sortMode=='expensive') result.sort((a,b)=>((b['price'] as num?)??0).compareTo((a['price'] as num?)??0));
    return result;
  }

  void openFilters() {
    final min=TextEditingController(text:minPrice?.toString()??'');
    final max=TextEditingController(text:maxPrice?.toString()??'');
    showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>StatefulBuilder(builder:(ctx,setSheet)=>Directionality(
      textDirection:TextDirection.rtl,
      child:Padding(padding:EdgeInsets.only(left:16,right:16,top:16,bottom:MediaQuery.of(ctx).viewInsets.bottom+16),child:ListView(shrinkWrap:true,children:[
        const Text('فیلتر آگهی‌ها',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(value:selectedCity,items:[null,...['تهران','آستارا','رشت','اردبیل','تبریز','مشهد','اصفهان','شیراز']].map((x)=>DropdownMenuItem<String>(value:x,child:Text(x??'همه شهرها'))).toList(),onChanged:(v)=>setSheet(() { selectedCity=v; }),decoration:const InputDecoration(labelText:'شهر',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:min,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'حداقل قیمت',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:max,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'حداکثر قیمت',border:OutlineInputBorder())),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:sortMode,items:const [
          DropdownMenuItem(value:'newest',child:Text('جدیدترین')),
          DropdownMenuItem(value:'cheapest',child:Text('ارزان‌ترین')),
          DropdownMenuItem(value:'expensive',child:Text('گران‌ترین')),
        ],onChanged:(v)=>setSheet(() { sortMode=v??'newest'; }),decoration:const InputDecoration(labelText:'مرتب‌سازی',border:OutlineInputBorder())),
        const SizedBox(height:14),
        FilledButton(onPressed:(){setState(() { minPrice=int.tryParse(min.text); maxPrice=int.tryParse(max.text); });Navigator.pop(ctx);},child:const Text('اعمال فیلتر')),
      ])))));
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const FavoritesPage()
                : tab == 2
                    ? const MessagesPage()
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
          Row(children:[
            Expanded(child:TextField(
            onSubmitted:(value){if(value.trim().isNotEmpty&&!recentSearches.contains(value.trim()))setState(()=>recentSearches=[value.trim(),...recentSearches].take(8).toList());},
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
            )),
            const SizedBox(width:8),
            IconButton.filledTonal(onPressed:saveCurrentSearch,icon:const Icon(Icons.bookmark_add_outlined),tooltip:'ذخیره جست‌وجو'),
            const SizedBox(width:2),
            IconButton.filledTonal(onPressed:openFilters,icon:const Icon(Icons.tune),tooltip:'فیلتر'),
          ]),
          if(recentSearches.isNotEmpty && searchQuery.isEmpty)
            SizedBox(height:40,child:ListView(scrollDirection:Axis.horizontal,children:recentSearches.map((x)=>Padding(padding:const EdgeInsets.only(left:6),child:ActionChip(label:Text(x),onPressed:()=>setState(()=>searchQuery=x)))).toList())),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006D77), Color(0xFF0A9396)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '“Indeed, with hardship comes ease.”',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  'Qur\'an 94:6',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
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

  Future<void> saveCurrentSearch() async {
    final uid=supabase.auth.currentUser?.id;if(uid==null)return;
    if(searchQuery.trim().isEmpty&&selectedCategory==null&&selectedCity==null&&minPrice==null&&maxPrice==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ابتدا یک عبارت یا فیلتر برای ذخیره انتخاب کنید.')));return;}
    try{await supabase.from('saved_searches').insert({'user_id':uid,'query':searchQuery.trim(),'filters':{'category':selectedCategory,'city':selectedCity,'min_price':minPrice,'max_price':maxPrice,'sort':sortMode}});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('جست‌وجو ذخیره شد.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره جست‌وجو: $e')));}
  }

  Future<void> buySubscription() async {
    if(!mounted)return;
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>const SubscriptionPage()));
    await loadSubscription();
  }

  Widget account() {
    final remaining = (adLimit - adsUsed).clamp(0, adLimit);

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
            title: const Text('اشتراک'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹٬۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionPage()),
              ),
              child: const Text('خرید اشتراک'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('آگهی‌های من'),
            subtitle: const Text('ویرایش و مدیریت آگهی‌های شما'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsPage())),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('اعلان‌ها'),
            subtitle: const Text('مشاهده و مدیریت اعلان‌های حساب'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark_outline),
            title: const Text('جست‌وجوهای ذخیره‌شده'),
            subtitle: const Text('مدیریت جست‌وجوهای ذخیره‌شده'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedSearchesPage())),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$adsUsed از $adLimit آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (isAdmin)
          Card(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('پنل مدیریت'),
              subtitle: const Text('بررسی و تأیید پرداخت‌ها'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())),
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

    if (adsUsed >= adLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه آگهی این دوره تکمیل شده است.'),
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

class MyAdsPage extends StatefulWidget {
  const MyAdsPage({super.key});
  @override State<MyAdsPage> createState()=>_MyAdsPageState();
}
class _MyAdsPageState extends State<MyAdsPage>{
  bool loading=true; List<Map<String,dynamic>> ads=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    try{
      final uid=supabase.auth.currentUser?.id;if(uid==null)return;
      final r=await supabase.from('ads').select('*, ad_images(image_url,sort_order,is_primary)').eq('seller_id',uid).order('created_at',ascending:false);
      if(mounted)setState((){ads=List<Map<String,dynamic>>.from(r);loading=false;});
    }catch(e){if(mounted)setState(()=>loading=false);}
  }
  Future<void> removeAd(String id)async{
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('حذف آگهی'),content:const Text('آیا از حذف آگهی مطمئن هستید؟'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حذف'))]));
    if(ok!=true)return;
    try{await supabase.from('ads').delete().eq('idd',id).eq('seller_id',supabase.auth.currentUser!.id);await load();}catch(e){}
  }
  @override Widget build(BuildContext c){
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('آگهی‌های من')),body:
      loading?const Center(child:CircularProgressIndicator()):ads.isEmpty?const Center(child:Text('هنوز آگهی‌ای ثبت نکرده‌اید.')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:ads.length,itemBuilder:(_,i){
        final a=ads[i];final ims=List<Map<String,dynamic>>.from(a['ad_images']??const[]);ims.sort((x,y)=>((x['sort_order'] as num?)??0).compareTo((y['sort_order'] as num?)??0));
        final img=ims.isEmpty?null:ims.first['image_url']?.toString();final s=a['publish_status']?.toString()??'pending';final st=s=='published'?'منتشر شده':s=='rejected'?'رد شده':s=='paused'?'متوقف شده':'در انتظار تأیید';
        return Card(child:ListTile(leading:img==null?const CircleAvatar(child:Icon(Icons.image)):Image.network(img,width:60,height:60,fit:BoxFit.cover),title:Text(a['title']?.toString()??''),subtitle:Text((a['price']??0).toString()+' تومان • '+st),trailing:PopupMenuButton<String>(itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('ویرایش')),PopupMenuItem(value:'delete',child:Text('حذف'))],onSelected:(v)async{if(v=='edit'){await Navigator.push(c,MaterialPageRoute(builder:(_)=>EditAdPage(ad:a)));await load();}else{await removeAd(a['idd'].toString());}})));
      })));
  }
}
class EditAdPage extends StatefulWidget{
  final Map<String,dynamic> ad;const EditAdPage({super.key,required this.ad});
  @override State<EditAdPage> createState()=>_EditAdPageState();
}
class _EditAdPageState extends State<EditAdPage>{
  late TextEditingController title,desc,price,neighborhood;late String category,city,condition,subcategory;bool saving=false;
  @override void initState(){super.initState();final a=widget.ad;title=TextEditingController(text:a['title']?.toString()??'');desc=TextEditingController(text:a['edescription']?.toString()??'');price=TextEditingController(text:(a['price'] as num?)?.toInt().toString()??'');neighborhood=TextEditingController(text:a['neighborhood']?.toString()??'');category=a['category']?.toString()??'سایر';city=a['city']?.toString()??'تهران';condition=a['item_condition']?.toString()??'در حد نو';subcategory=a['subcategory']?.toString()??'سایر';}
  @override void dispose(){title.dispose();desc.dispose();price.dispose();neighborhood.dispose();super.dispose();}
  List<String> get subs=>category=='موبایل و تبلت'?['موبایل','تبلت','لوازم جانبی موبایل']:category=='خودرو'?['سواری','وانت','موتورسیکلت','قطعات خودرو']:category=='املاک'?['آپارتمان','خانه','زمین','مغازه']:['سایر'];
  Future<void> save()async{
    final p=int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'),''));final uid=supabase.auth.currentUser?.id;if(p==null||uid==null)return;
    setState(()=>saving=true);try{
      await supabase.rpc('update_own_ad',params:{'p_ad_id':widget.ad['idd'],'p_title':title.text.trim(),'p_description':desc.text.trim(),'p_price':p,'p_city':city,'p_category':category,'p_subcategory':subcategory,'p_condition':condition,'p_neighborhood':neighborhood.text.trim().isEmpty?null:neighborhood.text.trim()});
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تغییرات ذخیره شد و آگهی برای بررسی دوباره ارسال شد.')));Navigator.pop(context);}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره تغییرات: '+e.toString())));}finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('ویرایش آگهی')),body:ListView(padding:const EdgeInsets.all(16),children:[
    DropdownButtonFormField<String>(value:category,items:_HomePageState.categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)setState(()=>category=v);},decoration:const InputDecoration(labelText:'دسته‌بندی',border:OutlineInputBorder())),
    const SizedBox(height:12),DropdownButtonFormField<String>(value:subs.contains(subcategory)?subcategory:subs.first,items:subs.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>subcategory=v??subs.first),decoration:const InputDecoration(labelText:'زیر‌دسته',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:desc,maxLines:5,decoration:const InputDecoration(labelText:'توضیحات',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'قیمت (تومان)',border:OutlineInputBorder())),
    const SizedBox(height:12),DropdownButtonFormField<String>(value:const['نو','در حد نو','کارکرده'].contains(condition)?condition:'در حد نو',items:const['نو','در حد نو','کارکرده'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>condition=v??condition),decoration:const InputDecoration(labelText:'وضعیت',border:OutlineInputBorder())),
    const SizedBox(height:12),DropdownButtonFormField<String>(value:const['تهران','آستارا','رشت','اردبیل','تبریز','مشهد','اصفهان','شیراز'].contains(city)?city:'تهران',items:const['تهران','آستارا','رشت','اردبیل','تبریز','مشهد','اصفهان','شیراز'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>city=v??city),decoration:const InputDecoration(labelText:'شهر',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:neighborhood,decoration:const InputDecoration(labelText:'محله',border:OutlineInputBorder())),
    const SizedBox(height:18),FilledButton(onPressed:saving?null:save,child:Text(saving?'در حال ذخیره...':'ذخیره تغییرات')),
  ])));
}
class AddAdPage extends StatefulWidget {
  final Future<void> Function() onPublished;
  const AddAdPage({super.key, required this.onPublished});
  @override State<AddAdPage> createState()=>_AddAdPageState();
}

class _AddAdPageState extends State<AddAdPage>{
  final title=TextEditingController(),desc=TextEditingController(),price=TextEditingController(),neighborhood=TextEditingController();
  String category='موبایل و تبلت',city='تهران',condition='در حد نو',subcategory='';
  bool publishing=false;
  final picker=ImagePicker();
  final List<XFile> selectedImages=[];

  List<String> get subcategories {
    if(category=='موبایل و تبلت') return ['موبایل','تبلت','لوازم جانبی موبایل'];
    if(category=='خودرو') return ['سواری','وانت','موتورسیکلت','قطعات خودرو'];
    if(category=='املاک') return ['آپارتمان','خانه','زمین','مغازه'];
    if(category=='لوازم دیجیتال') return ['لپ‌تاپ','کامپیوتر','دوربین','کنسول بازی'];
    return ['سایر'];
  }

  @override void initState(){super.initState(); subcategory=subcategories.first;}
  @override void dispose(){title.dispose();desc.dispose();price.dispose();neighborhood.dispose();super.dispose();}

  Future<void> pickImages() async {
    try{
      final settings=await supabase.from('subscription_settings').select('image_limit').eq('id',true).maybeSingle();
      final maxImages=(settings?['image_limit'] as num?)?.toInt()??10;
      if(selectedImages.length>=maxImages){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حداکثر $maxImages عکس مجاز است.')));
        return;
      }
      final xs=await picker.pickMultiImage(imageQuality:85,maxWidth:1800,maxHeight:1800);
      if(!mounted)return;
      final remaining=maxImages-selectedImages.length;
      setState(()=>selectedImages.addAll(xs.take(remaining)));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت تنظیمات عکس: $e')));
    }
  }
  void removeImage(int i)=>setState(()=>selectedImages.removeAt(i));

  Future<void> publish() async {
    if(title.text.trim().isEmpty||desc.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('عنوان و توضیحات را کامل کنید.')));return;
    }
    final u=supabase.auth.currentUser;
    if(u==null)return;
    final p=int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'),''));
    if(p==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('قیمت را صحیح وارد کنید.')));return;}
    setState(()=>publishing=true);
    String? createdAdId;
    final uploadedPaths=<String>[];
    try{
      createdAdId=(await supabase.rpc('publish_ad',params:{
        'p_title':title.text.trim(),
        'p_description':desc.text.trim(),
        'p_price':p,
        'p_city':city,
        'p_category':category,
        'p_subcategory':subcategory,
        'p_condition':condition,
        'p_neighborhood':neighborhood.text.trim().isEmpty?null:neighborhood.text.trim(),
      })).toString();

      for(var i=0;i<selectedImages.length;i++){
        final x=selectedImages[i];
        final bytes=await x.readAsBytes();
        final ext=x.name.contains('.')?x.name.split('.').last.toLowerCase():'jpg';
        final safe=<String>{'jpg','jpeg','png','webp'}.contains(ext)?ext:'jpg';
        final path='public/'+u.id+'/'+createdAdId+'/'+i.toString()+'_'+DateTime.now().microsecondsSinceEpoch.toString()+'.'+safe;
        await supabase.storage.from('ad-images').uploadBinary(path,bytes,fileOptions:FileOptions(
          contentType:safe=='png'?'image/png':safe=='webp'?'image/webp':'image/jpeg'));
        uploadedPaths.add(path);
        await supabase.from('ad_images').insert({'ad_id':createdAdId,'image_url':supabase.storage.from('ad-images').getPublicUrl(path),'sort_order':i,'is_primary':i==0});
      }
      await widget.onPublished();
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('آگهی ثبت شد و برای تأیید مدیر ارسال شد.')));
        Navigator.pop(context);
      }
    }catch(e){
      if(createdAdId!=null){
        try{if(uploadedPaths.isNotEmpty)await supabase.storage.from('ad-images').remove(uploadedPaths);}catch(_){ }
        try{await supabase.from('ad_images').delete().eq('ad_id',createdAdId!);}catch(_){ }
        try{await supabase.from('ads').delete().eq('idd',createdAdId!);}catch(_){ }
      }
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت آگهی انجام نشد و تغییرات ناقص پاک شد: '+e.toString())));
    }finally{if(mounted)setState(()=>publishing=false);}
  }
  Future<void> preview() async {
    if(title.text.trim().isEmpty||desc.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ابتدا عنوان و توضیحات را کامل کنید.')));return;
    }
    await showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Directionality(
      textDirection:TextDirection.rtl,
      child:SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('پیش‌نمایش آگهی',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        Text(title.text,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        Text(price.text+' تومان'),
        Text(city+' • '+subcategory+' • '+condition),
        if(neighborhood.text.trim().isNotEmpty)Text('محله: '+neighborhood.text.trim()),
        const SizedBox(height:10),
        Text(desc.text,maxLines:5,overflow:TextOverflow.ellipsis),
        const SizedBox(height:16),
        Text('تعداد عکس انتخاب‌شده: '+selectedImages.length.toString()),
        const SizedBox(height:12),
        FilledButton(onPressed:publishing?null:(){Navigator.pop(context);publish();},child:const Text('تأیید و انتشار')),
      ])))));
  }

  @override Widget build(BuildContext c) {
    return Directionality(
      textDirection:TextDirection.rtl,
      child:Scaffold(
        appBar:AppBar(title:const Text('ثبت آگهی')),
        body:ListView(padding:const EdgeInsets.all(16),children:[
          DropdownButtonFormField<String>(value:category,items:_HomePageState.categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(v){if(v==null)return;setState(()=>category=v);subcategory=subcategories.first;},decoration:const InputDecoration(labelText:'دسته‌بندی',border:OutlineInputBorder())),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(value:subcategory,items:subcategories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(v)=>setState(()=>subcategory=v??subcategories.first),decoration:const InputDecoration(labelText:'زیر‌دسته',border:OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان آگهی',border:OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(controller:desc,maxLines:5,decoration:const InputDecoration(labelText:'توضیحات',border:OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'قیمت (تومان)',border:OutlineInputBorder())),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(value:condition,items:const ['نو','در حد نو','کارکرده'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(v)=>setState(()=>condition=v??condition),decoration:const InputDecoration(labelText:'وضعیت کالا',border:OutlineInputBorder())),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(value:city,items:const ['تهران','آستارا','رشت','اردبیل','تبریز','مشهد','اصفهان','شیراز'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(v)=>setState(()=>city=v??city),decoration:const InputDecoration(labelText:'شهر',border:OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(controller:neighborhood,decoration:const InputDecoration(labelText:'محله (اختیاری)',border:OutlineInputBorder())),
          const SizedBox(height:14),
          OutlinedButton.icon(onPressed:publishing?null:pickImages,icon:const Icon(Icons.add_a_photo_outlined),label:Text('افزودن عکس '+selectedImages.length.toString()+'/حداکثر')),
          if(selectedImages.isNotEmpty)SizedBox(height:132,child:ReorderableListView.builder(
            scrollDirection:Axis.horizontal,
            buildDefaultDragHandles:false,
            itemCount:selectedImages.length,
            onReorder:(oldIndex,newIndex){setState((){if(newIndex>oldIndex)newIndex--;final x=selectedImages.removeAt(oldIndex);selectedImages.insert(newIndex,x);});},
            itemBuilder:(_,i){final img=selectedImages[i];return Padding(
              key:ValueKey(img.path),
              padding:const EdgeInsets.only(right:8),
              child:Stack(children:[
                ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(File(img.path),width:110,height:110,fit:BoxFit.cover)),
                Positioned(top:3,right:3,child:CircleAvatar(radius:14,child:IconButton(padding:EdgeInsets.zero,onPressed:()=>removeImage(i),icon:const Icon(Icons.close,size:16)))),
                Positioned(bottom:3,left:3,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(8)),child:Text(i==0?'عکس اصلی':'${i+1}',style:const TextStyle(color:Colors.white,fontSize:11))))
              ]));}
          )),
          if(selectedImages.length>1)const Padding(padding:EdgeInsets.only(top:6),child:Text('برای تغییر عکس اصلی، عکس اول را جابه‌جا کنید.')),
          const SizedBox(height:16),
          OutlinedButton(onPressed:publishing?null:preview,child:const Text('پیش‌نمایش')),
          const SizedBox(height:8),
          FilledButton(onPressed:publishing?null:publish,child:publishing?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2)):const Text('ثبت و انتشار')),
        ]),
      ),
    );
  }
}
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override State<AdminPage> createState()=>_AdminPageState();
}
class _AdminPageState extends State<AdminPage>{
  bool loading=true,working=false;
  List<Map<String,dynamic>> payments=[],ads=[],users=[],reports=[];
  Map<String,dynamic>? stats;
  final price=TextEditingController(),days=TextEditingController(),limit=TextEditingController(),images=TextEditingController(),card=TextEditingController(),holder=TextEditingController(),bank=TextEditingController(),instructions=TextEditingController(),userSearch=TextEditingController(),adSearch=TextEditingController();
  bool enabled=true;
  @override void initState(){super.initState();load();}
  @override void dispose(){for(final c in [price,days,limit,images,card,holder,bank,instructions,userSearch,adSearch])c.dispose();super.dispose();}
  Future<void> load() async {
    try{
      final r=await supabase.from('subscription_settings').select('*').eq('id',true).maybeSingle();
      final p=await supabase.from('payments').select('id,user_id,amount,status,payment_note,payment_code,metadata,provider,created_at,paid_at,confirmed_at').inFilter('status',['pending','checking']).order('created_at',ascending:false);
      final st=await supabase.rpc('admin_dashboard_stats');
      final rr=await supabase.from('reports').select('id,reporter_id,ad_id,reason,details,status,created_at,ads(title,city)').order('created_at',ascending:false).limit(100);
      final aa=await supabase.from('ads').select('idd,title,price,city,category,seller_id,publish_status,created_at').order('created_at',ascending:false).limit(100);
      final uu=await supabase.from('profiles').select('iidd,name,cphone,created_at').order('created_at',ascending:false).limit(100);
      if(r!=null){price.text=r['price'].toString();days.text=r['duration_days'].toString();limit.text=r['ad_limit'].toString();images.text=r['image_limit'].toString();card.text=r['destination_card']?.toString()??'';holder.text=r['card_holder']?.toString()??'';bank.text=r['bank_name']?.toString()??'';instructions.text=r['instructions']?.toString()??'';enabled=r['enabled']==true;}
      if(mounted)setState(() { stats=Map<String,dynamic>.from(st); payments=List<Map<String,dynamic>>.from(p); ads=List<Map<String,dynamic>>.from(aa); users=List<Map<String,dynamic>>.from(uu); reports=List<Map<String,dynamic>>.from(rr); loading=false; });
    }catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('پنل مدیریت: $e')));}}
  }
  Future<void> saveSettings() async {setState(()=>working=true);try{await supabase.rpc('update_subscription_settings',params:{'p_price':int.parse(price.text),'p_duration_days':int.parse(days.text),'p_ad_limit':int.parse(limit.text),'p_image_limit':int.parse(images.text),'p_destination_card':card.text.trim(),'p_card_holder':holder.text.trim(),'p_bank_name':bank.text.trim(),'p_instructions':instructions.text.trim(),'p_enabled':enabled});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تنظیمات ذخیره شد.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره تنظیمات: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Future<void> decide(String id,bool approve) async {if(working)return;setState(()=>working=true);try{await supabase.rpc('confirm_payment',params:{'p_payment_id':id,'p_approve':approve,'p_reason':approve?null:'تأیید نشد توسط مدیر'});if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(approve?'پرداخت تأیید و اشتراک فعال شد.':'پرداخت رد شد.')));await load();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('عملیات: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Future<void> moderateAd(String id,String status) async {if(working)return;setState(()=>working=true);try{await supabase.rpc('moderate_ad',params:{'p_ad_id':id,'p_status':status,'p_reason':status=='rejected'?'آگهی مطابق قوانین تأیید نشد.':null});if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(status=='published'?'آگهی تأیید شد.':status=='paused'?'آگهی متوقف شد.':'آگهی رد شد.')));await load();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تغییر وضعیت آگهی: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Future<void> setReportStatus(String id,String status) async {if(working)return;setState(()=>working=true);try{await supabase.rpc('admin_set_report_status',params:{'p_report_id':id,'p_status':status});if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('وضعیت گزارش به‌روزرسانی شد.')));await load();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('گزارش: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Future<void> deleteAd(String id) async {if(working)return;setState(()=>working=true);try{await supabase.from('ads').delete().eq('idd',id);if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('آگهی حذف شد.')));await load();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حذف آگهی: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Widget field(TextEditingController c,String label,{TextInputType type=TextInputType.text})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,keyboardType:type,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
  Widget stat(String label,dynamic value,IconData icon)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(children:[Icon(icon,size:24),Text(value?.toString()??'0',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),Text(label)]))));
  @override Widget build(BuildContext context){
    if(loading)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:CircularProgressIndicator())));
    final uq=userSearch.text.trim().toLowerCase(),aq=adSearch.text.trim().toLowerCase();
    final fu=users.where((x)=>uq.isEmpty||x['name'].toString().toLowerCase().contains(uq)||x['cphone'].toString().contains(uq)).toList();
    final fa=ads.where((x)=>aq.isEmpty||x['title'].toString().toLowerCase().contains(aq)||x['city'].toString().toLowerCase().contains(aq)).toList();
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('پنل مدیریت'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),body:ListView(padding:const EdgeInsets.all(12),children:[
      const Text('داشبورد',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Row(children:[stat('کاربران',stats?['users'],Icons.people),stat('آگهی‌ها',stats?['ads'],Icons.list_alt)]),Row(children:[stat('پرداخت موفق',stats?['paid_payments'],Icons.payments),stat('درآمد',stats?['revenue'],Icons.account_balance_wallet)]),
      ExpansionTile(title:const Text('تنظیمات اشتراک و کارت‌به‌کارت'),children:[Padding(padding:const EdgeInsets.all(12),child:Column(children:[field(price,'قیمت اشتراک',type:TextInputType.number),field(days,'مدت (روز)',type:TextInputType.number),field(limit,'سهمیه آگهی',type:TextInputType.number),field(images,'حداکثر عکس',type:TextInputType.number),field(card,'شماره کارت مقصد'),field(holder,'صاحب کارت'),field(bank,'بانک'),field(instructions,'توضیحات'),SwitchListTile(value:enabled,onChanged:(v)=>setState(()=>enabled=v),title:const Text('فروش اشتراک فعال باشد')),FilledButton(onPressed:working?null:saveSettings,child:const Text('ذخیره'))]))]),
      ExpansionTile(title:Text('مدیریت کاربران (${fu.length})'),children:[Padding(padding:const EdgeInsets.all(12),child:TextField(controller:userSearch,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'نام یا شماره',prefixIcon:Icon(Icons.search),border:OutlineInputBorder()))),...fu.take(50).map((u)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(u['name']?.toString()??'کاربر'),subtitle:Text(u['cphone']?.toString()??'-')))]),
      ExpansionTile(title:Text('مدیریت آگهی‌ها (${fa.length})'),children:[Padding(padding:const EdgeInsets.all(12),child:TextField(controller:adSearch,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'عنوان یا شهر',prefixIcon:Icon(Icons.search),border:OutlineInputBorder()))),...fa.take(50).map((ad)=>ListTile(title:Text(ad['title']?.toString()??'بدون عنوان'),subtitle:Text('${ad['city']??''} • ${ad['category']??''} • ${ad['price']??'توافقی'} تومان'),trailing:Wrap(children:[IconButton(tooltip:'تأیید',onPressed:working?null:()=>moderateAd(ad['idd'].toString(),'published'),icon:const Icon(Icons.check_circle_outline)),IconButton(tooltip:'رد',onPressed:working?null:()=>moderateAd(ad['idd'].toString(),'rejected'),icon:const Icon(Icons.cancel_outlined)),IconButton(tooltip:'توقف',onPressed:working?null:()=>moderateAd(ad['idd'].toString(),'paused'),icon:const Icon(Icons.pause_circle_outline)),IconButton(icon:const Icon(Icons.delete_outline),onPressed:working?null:()=>deleteAd(ad['idd'].toString()))])))]),
      ExpansionTile(title:Text('پرداخت‌های در انتظار (${payments.length})'),children:[
        ...payments.map((p){
          final meta=p['metadata'] is Map?Map<String,dynamic>.from(p['metadata']):<String,dynamic>{};
          final refCode=p['payment_code']?.toString()??'-';
          final last4=meta['payer_card_last4']?.toString()??'-';
          final transferAt=meta['transfer_at']?.toString()??'-';
          return Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(
            isThreeLine:true,
            leading:const CircleAvatar(child:Icon(Icons.payments_outlined)),
            title:Text('${p['amount']??'-'} تومان',style:const TextStyle(fontWeight:FontWeight.bold)),
            subtitle:Text('شماره پیگیری: $refCode\\n۴ رقم آخر کارت: $last4\\nزمان انتقال: $transferAt'),
            onTap:()=>showDialog(context:context,builder:(_)=>AlertDialog(
              title:const Text('جزئیات پرداخت'),
              content:SingleChildScrollView(child:Text('مبلغ: ${p['amount']??'-'} تومان\\nشماره پیگیری: $refCode\\n۴ رقم آخر کارت: $last4\\nزمان انتقال: $transferAt\\nیادداشت: ${p['payment_note']??'-'}')),
              actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('بستن'))],
            )),
            trailing:Wrap(children:[
              IconButton(tooltip:'تأیید پرداخت',onPressed:working?null:()=>decide(p['id'].toString(),true),icon:const Icon(Icons.check_circle_outline)),
              IconButton(tooltip:'رد پرداخت',onPressed:working?null:()=>decide(p['id'].toString(),false),icon:const Icon(Icons.cancel_outlined)),
            ]),
          );
        }),
      ]),
      ExpansionTile(title:Text('گزارش‌های آگهی (${reports.length})'),children:[...reports.map((r)=>Card(child:ListTile(title:Text((r['ads'] is Map? r['ads']['title']?.toString():null)??'آگهی گزارش‌شده'),subtitle:Text('${r['reason']??''} • وضعیت: ${r['status']??'pending'}\n${r['details']??''}'),trailing:Wrap(children:[IconButton(tooltip:'در حال بررسی',onPressed:working?null:()=>setReportStatus(r['id'].toString(),'reviewing'),icon:const Icon(Icons.search)),IconButton(tooltip:'حل شد',onPressed:working?null:()=>setReportStatus(r['id'].toString(),'resolved'),icon:const Icon(Icons.check_circle_outline)),IconButton(tooltip:'رد گزارش',onPressed:working?null:()=>setReportStatus(r['id'].toString(),'rejected'),icon:const Icon(Icons.close))]))))]),
    ])));
  }
}class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override State<NotificationsPage> createState() => _NotificationsPageState();
}
class _NotificationsPageState extends State<NotificationsPage> {
  bool loading=true; List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final uid=supabase.auth.currentUser?.id;if(uid==null){if(mounted)setState(()=>loading=false);return;}
    try{final r=await supabase.from('notifications').select('id,title,body,type,read_at,created_at').eq('user_id',uid).order('created_at',ascending:false).limit(100);if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});}
    catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت اعلان‌ها انجام نشد: $e')));}}
  }
  Future<void> markRead(String id) async {try{await supabase.from('notifications').update({'read_at':DateTime.now().toIso8601String()}).eq('id',id).eq('user_id',supabase.auth.currentUser!.id);if(mounted)setState((){final i=rows.indexWhere((x)=>x['id'].toString()==id);if(i>=0)rows[i]['read_at']=DateTime.now().toIso8601String();});}catch(_){ }}
  Future<void> markAllRead() async {final uid=supabase.auth.currentUser?.id;if(uid==null)return;try{await supabase.from('notifications').update({'read_at':DateTime.now().toIso8601String()}).eq('user_id',uid).isFilter('read_at',null);await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('علامت‌گذاری اعلان‌ها: $e')));}}
  @override Widget build(BuildContext context){
    final unread=rows.where((x)=>x['read_at']==null).length;
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:Text('اعلان‌ها${unread>0?' ($unread)':''}'),actions:[if(unread>0)TextButton(onPressed:markAllRead,child:const Text('همه خوانده شد'))]),
      body:loading?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('اعلانی ندارید.')):ListView.builder(
        padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(_,i){final n=rows[i];final unreadItem=n['read_at']==null;return Card(child:ListTile(
          leading:Icon(unreadItem?Icons.notifications_active:Icons.notifications_none),
          title:Text(n['title']?.toString()??'اعلان آگهینو',style:TextStyle(fontWeight:unreadItem?FontWeight.bold:FontWeight.normal)),
          subtitle:Text('${n['body']??''}\\n${n['created_at']??''}'),
          onTap:()=>markRead(n['id'].toString()),
        ));},
      ),
    ));
  }
}
class SavedSearchesPage extends StatefulWidget {
  const SavedSearchesPage({super.key});
  @override State<SavedSearchesPage> createState()=>_SavedSearchesPageState();
}
class _SavedSearchesPageState extends State<SavedSearchesPage>{
  bool loading=true;List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {final uid=supabase.auth.currentUser?.id;if(uid==null){if(mounted)setState(()=>loading=false);return;}try{final r=await supabase.from('saved_searches').select('id,query,filters,created_at').eq('user_id',uid).order('created_at',ascending:false);if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});}catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت جست‌وجوهای ذخیره‌شده: $e')));}}}
  Future<void> deleteSearch(String id) async {final uid=supabase.auth.currentUser?.id;if(uid==null)return;try{await supabase.from('saved_searches').delete().eq('id',id).eq('user_id',uid);await load();}catch(_){ }}
  @override Widget build(BuildContext context){return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('جست‌وجوهای ذخیره‌شده')),body:loading?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('جست‌وجوی ذخیره‌شده‌ای ندارید.')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(_,i){final r=rows[i];final f=r['filters'] is Map?Map<String,dynamic>.from(r['filters']):<String,dynamic>{};final d=<String>[if(f['city']!=null&&f['city'].toString().isNotEmpty)'شهر: ${f['city']}',if(f['category']!=null&&f['category'].toString().isNotEmpty)'دسته: ${f['category']}'].join(' • ');return Card(child:ListTile(title:Text(r['query']?.toString().isNotEmpty==true?r['query'].toString():'جست‌وجوی بدون کلمه'),subtitle:Text(d.isEmpty?'بدون فیلتر':d),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>deleteSearch(r['id'].toString()))));},)));}}
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override State<FavoritesPage> createState() => _FavoritesPageState();
}
class _FavoritesPageState extends State<FavoritesPage> {
  bool loading=true; List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async { final u=supabase.auth.currentUser; if(u==null){if(mounted)setState(()=>loading=false);return;} try{final r=await supabase.from('favorites').select('ad_id,ads(*)').eq('user_id',u.id);if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}
  @override Widget build(BuildContext c){if(loading)return const Center(child:CircularProgressIndicator());return Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(16),children:[const Text('آگهی‌های ذخیره‌شده',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),if(rows.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('آگهی ذخیره‌شده‌ای ندارید.')), ...rows.map((r){final ad=r['ads'] is Map?Map<String,dynamic>.from(r['ads']):<String,dynamic>{};return Card(child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>AdDetailPage(ad:ad))),title:Text(ad['title']?.toString()??'بدون عنوان'),subtitle:Text((ad['price']?.toString()??'توافقی')+' تومان • '+(ad['city']?.toString()??''))));})]));}
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override State<SubscriptionPage> createState()=>_SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String,dynamic>? settings;
  final reference=TextEditingController();
  final payerLast4=TextEditingController();
  final note=TextEditingController();
  DateTime? transferAt;
  bool loading=true,sending=false;

  @override void initState(){super.initState();load();}
  @override void dispose(){reference.dispose();payerLast4.dispose();note.dispose();super.dispose();}

  Future<void> load() async {
    try{
      final r=await supabase.from('subscription_settings').select('price,duration_days,ad_limit,image_limit,destination_card,card_holder,bank_name,instructions,enabled').eq('id',true).maybeSingle();
      if(mounted)setState((){settings=r;loading=false;});
    }catch(e){
      if(mounted){
        setState(()=>loading=false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت اطلاعات اشتراک: $e')));
      }
    }
  }

  String two(int n)=>n.toString().padLeft(2,'0');
  String formatDateTime(DateTime d)=>'${d.year}/${two(d.month)}/${two(d.day)} - ${two(d.hour)}:${two(d.minute)}';

  Future<void> pickTransferTime() async {
    final now=DateTime.now();
    final date=await showDatePicker(
      context:context,
      initialDate:transferAt??now,
      firstDate:DateTime(now.year-1),
      lastDate:DateTime(now.year,now.month,now.day),
      helpText:'تاریخ انتقال را انتخاب کنید',
      confirmText:'تأیید',
      cancelText:'لغو',
    );
    if(date==null||!mounted)return;
    final time=await showTimePicker(
      context:context,
      initialTime:TimeOfDay.fromDateTime(transferAt??now),
      helpText:'ساعت انتقال را انتخاب کنید',
      confirmText:'تأیید',
      cancelText:'لغو',
    );
    if(time==null||!mounted)return;
    setState(()=>transferAt=DateTime(date.year,date.month,date.day,time.hour,time.minute));
  }

  Future<void> submit() async {
    final u=supabase.auth.currentUser;
    final s=settings;
    final ref=reference.text.trim();
    final last4=payerLast4.text.trim();

    if(u==null||s==null||s['enabled']!=true)return;
    if(ref.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره پیگیری/مرجع انتقال را وارد کنید.')));
      return;
    }
    if(last4.isNotEmpty&&!RegExp(r'^\d{4}$').hasMatch(last4)){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('۴ رقم آخر کارت باید دقیقاً ۴ رقم باشد.')));
      return;
    }
    if(transferAt==null){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تاریخ و ساعت انتقال را انتخاب کنید.')));
      return;
    }

    setState(()=>sending=true);
    try{
      final amount=(s['price'] as num).toInt();
      await supabase.from('payments').insert({
        'user_id':u.id,
        'amount':amount,
        'plan':'base_monthly',
        'status':'checking',
        'provider':'manual_card_to_card',
        'payment_note':note.text.trim().isEmpty?null:note.text.trim(),
        'payment_code':ref,
        'metadata':{
          'method':'card_to_card',
          'payer_card_last4':last4.isEmpty?null:last4,
          'transfer_at':transferAt!.toIso8601String(),
          'submitted_at':DateTime.now().toIso8601String(),
        },
      });

      if(!mounted)return;
      await showDialog(
        context:context,
        builder:(_)=>AlertDialog(
          title:const Text('درخواست ثبت شد'),
          content:const Text('اطلاعات پرداخت برای بررسی مدیر ارسال شد. اشتراک فقط بعد از تطبیق انتقال با حساب مقصد و تأیید مدیر فعال می‌شود.'),
          actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('متوجه شدم'))],
        ),
      );
      if(mounted)Navigator.pop(context);
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت پرداخت: $e')));
    }finally{
      if(mounted)setState(()=>sending=false);
    }
  }

  @override Widget build(BuildContext c){
    if(loading)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:CircularProgressIndicator())));
    final s=settings;
    if(s==null||s['enabled']!=true)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:Text('فروش اشتراک فعال نیست.'))));

    final card=s['destination_card']?.toString()??'';
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('خرید اشتراک')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Container(
          padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(
            gradient:const LinearGradient(colors:[Color(0xFF006D77),Color(0xFF0A9396)],begin:Alignment.topRight,end:Alignment.bottomLeft),
            borderRadius:BorderRadius.circular(20),
          ),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('اشتراک آگهینو',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w800)),
            const SizedBox(height:8),
            Text('${s['price']} تومان',style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)),
            const SizedBox(height:6),
            Text('${s['duration_days']} روز • ${s['ad_limit']} آگهی • ${s['image_limit']} عکس برای هر آگهی',style:const TextStyle(color:Colors.white70)),
          ]),
        ),
        const SizedBox(height:12),
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('۱) انتقال کارت‌به‌کارت',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          Row(children:[
            Expanded(child:SelectableText(card.isEmpty?'شماره کارت تنظیم نشده':card,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),
            if(card.isNotEmpty)IconButton(tooltip:'کپی شماره کارت',onPressed:()async{await Clipboard.setData(ClipboardData(text:card));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره کارت کپی شد.')));},icon:const Icon(Icons.copy_all_outlined)),
          ]),
          const SizedBox(height:8),
          Text('صاحب کارت: ${s['card_holder']?.toString()??'-'}'),
          Text('بانک: ${s['bank_name']?.toString()??'-'}'),
          const SizedBox(height:10),
          Text(s['instructions']?.toString()??'مبلغ دقیق اشتراک را به کارت مقصد انتقال دهید.'),
        ]))),
        const SizedBox(height:6),
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('۲) مشخصات انتقال',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          TextField(controller:reference,keyboardType:TextInputType.text,decoration:const InputDecoration(labelText:'شماره پیگیری / شماره مرجع انتقال *',hintText:'مثلاً 123456789',border:OutlineInputBorder())),
          const SizedBox(height:10),
          TextField(controller:payerLast4,keyboardType:TextInputType.number,maxLength:4,inputFormatters:[FilteringTextInputFormatter.digitsOnly],decoration:const InputDecoration(labelText:'۴ رقم آخر کارت پرداخت‌کننده (اختیاری)',counterText:'',border:OutlineInputBorder())),
          const SizedBox(height:10),
          InkWell(
            onTap:pickTransferTime,
            borderRadius:BorderRadius.circular(14),
            child:InputDecorator(
              decoration:const InputDecoration(labelText:'تاریخ و ساعت انتقال *',border:OutlineInputBorder()),
              child:Text(transferAt==null?'انتخاب کنید':formatDateTime(transferAt!)),
            ),
          ),
          const SizedBox(height:10),
          TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'توضیح اضافی (اختیاری)',hintText:'مثلاً انتقال از کارت شخص دیگر انجام شده است.',border:OutlineInputBorder())),
        ]))),
        const SizedBox(height:8),
        Card(child:ListTile(
          leading:const Icon(Icons.verified_user_outlined),
          title:const Text('فعال‌سازی امن'),
          subtitle:const Text('ثبت درخواست به‌تنهایی اشتراک را فعال نمی‌کند. مدیر باید انتقال واقعی را با حساب مقصد تطبیق و تأیید کند.'),
        )),
        const SizedBox(height:10),
        SizedBox(height:52,child:FilledButton.icon(
          onPressed:sending?null:submit,
          icon:sending?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded),
          label:Text(sending?'در حال ثبت...':'ثبت اطلاعات برای بررسی'),
        )),
      ]),
    ));
  }
}
