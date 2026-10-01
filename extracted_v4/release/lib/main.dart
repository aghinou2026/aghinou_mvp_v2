import 'dart:typed_data';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6FEB),
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
  final phone = TextEditingController(); final otp = TextEditingController(); bool loading=false, codeSent=false;
  @override void dispose(){phone.dispose();otp.dispose();super.dispose();}
  String normalized(){final v=phone.text.trim().replaceAll(' ','').replaceAll('-','');return v.startsWith('0')?'+98'+v.substring(1):v;}
  Future<void> sendCode() async { final v=normalized(); if(!RegExp(r'^\+98\d{10}$').hasMatch(v)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره موبایل را صحیح وارد کنید.')));return;} setState(()=>loading=true); try{await supabase.auth.signInWithOtp(phone:v,shouldCreateUser:true);if(mounted)setState(()=>codeSent=true);}on AuthException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ارسال کد: '+e.message)));}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> verifyCode() async { final v=normalized(); final token=otp.text.trim(); if(token.length<4)return; setState(()=>loading=true); try{final r=await supabase.auth.verifyOTP(phone:v,token:token,type:OtpType.sms);final u=r.user??supabase.auth.currentUser;if(u==null)throw Exception('ورود تأیید نشد');await supabase.from('profiles').upsert({'iidd':u.id,'cphone':v,'name':'کاربر آگهینو'},onConflict:'iidd');if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomePage()));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ورود: '+e.toString())));}finally{if(mounted)setState(()=>loading=false);}}
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
                const Icon(Icons.storefront, size: 70),
                const SizedBox(height: 12),
                const Text('آگهینو', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل', hintText: '09121234567', border: OutlineInputBorder())),
                if (codeSent) TextField(controller: otp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کد تأیید', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : (codeSent ? verifyCode : sendCode), child: Text(codeSent ? 'تأیید و ورود' : 'ارسال کد'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}class HomePage extends StatefulWidget {
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
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim();
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = normalizeFa(searchQuery);
    return ads.where((ad) {
      final categoryOk = selectedCategory == null || '${ad['category'] ?? ''}' == selectedCategory;
      final text = normalizeFa('${ad['title'] ?? ''} ${ad['edescription'] ?? ''} ${ad['city'] ?? ''} ${ad['category'] ?? ''}');
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
    if(selectedImages.length>=10){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('حداکثر ۱۰ عکس مجاز است.')));
      return;
    }
    final xs=await picker.pickMultiImage(imageQuality:85,maxWidth:1800,maxHeight:1800);
    if(!mounted)return;
    setState(()=>selectedImages.addAll(xs.take(10-selectedImages.length)));
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
    try{
      final id=(await supabase.rpc('publish_ad',params:{
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
        final path='public/'+u.id+'/'+id+'/'+i.toString()+'_'+DateTime.now().microsecondsSinceEpoch.toString()+'.'+safe;
        await supabase.storage.from('ad-images').uploadBinary(path,bytes,fileOptions:FileOptions(
          contentType:safe=='png'?'image/png':safe=='webp'?'image/webp':'image/jpeg'));
        await supabase.from('ad_images').insert({'ad_id':id,'image_url':supabase.storage.from('ad-images').getPublicUrl(path)});
      }
      await widget.onPublished();
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('آگهی با موفقیت ثبت شد.')));
        Navigator.pop(context);
      }
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت آگهی: '+e.toString())));
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
        Text('تعداد عکس: '+selectedImages.length.toString()+' از ۱۰'),
        const SizedBox(height:12),
        FilledButton(onPressed:publishing?null:(){Navigator.pop(context);publish();},child:const Text('تأیید و انتشار')),
      ]))));
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
          OutlinedButton.icon(onPressed:publishing?null:pickImages,icon:const Icon(Icons.add_a_photo_outlined),label:Text('افزودن عکس '+selectedImages.length.toString()+'/۱۰')),
          if(selectedImages.isNotEmpty)SizedBox(height:120,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:selectedImages.length,itemBuilder:(_,i)=>Stack(children:[
            ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.memory(Uint8List.fromList(selectedImages[i].readAsBytesSync()),width:110,height:110,fit:BoxFit.cover)),
            Positioned(top:3,right:3,child:CircleAvatar(radius:14,child:IconButton(padding:EdgeInsets.zero,onPressed:()=>removeImage(i),icon:const Icon(Icons.close,size:16))))
          ]),separatorBuilder:(_,__)=>const SizedBox(width:8))),
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
  @override State<AdminPage> createState() => _AdminPageState();
}
class _AdminPageState extends State<AdminPage> {
  bool loading = true;
  bool working = false;
  List<Map<String,dynamic>> payments = [];
  @override void initState() { super.initState(); loadPayments(); }
  Future<void> loadPayments() async {
    try {
      final r = await supabase.from('payments').select('id,user_id,amount,status,payment_note,payment_code,created_at').inFilter('status',['pending','checking']).order('created_at',ascending:false);
      if (mounted) setState(() { payments=List<Map<String,dynamic>>.from(r); loading=false; });
    } catch(e) { if(mounted){ setState(()=>loading=false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت پرداخت‌ها: $e'))); } }
  }
  Future<void> decide(String id,bool approve) async {
    if(working)return;
    setState(()=>working=true);
    try {
      await supabase.rpc('confirm_payment',params:{'p_payment_id':id,'p_approve':approve,'p_reason':approve?null:'تأیید نشد توسط مدیر'});
      if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(approve?'پرداخت تأیید و اشتراک فعال شد.':'پرداخت رد شد.'))); await loadPayments(); }
    } catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('عملیات: $e'))); }
    finally { if(mounted)setState(()=>working=false); }
  }
  @override Widget build(BuildContext context) {
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('پنل مدیریت'),actions:[IconButton(onPressed:loadPayments,icon:const Icon(Icons.refresh))]),
      body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
        onRefresh:loadPayments,
        child:ListView(padding:const EdgeInsets.all(16),children:[
          Card(child:ListTile(leading:const Icon(Icons.payments_outlined),title:const Text('پرداخت‌های در انتظار'),subtitle:Text('${payments.length} پرداخت برای بررسی'))),
          if(payments.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('پرداخت در انتظار بررسی وجود ندارد.')),
          ...payments.map((p)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('مبلغ: ${p['amount']??'-'} تومان',style:const TextStyle(fontWeight:FontWeight.bold)),
            Text('کد پرداخت: ${p['payment_code']??'-'}'),
            Text('توضیح: ${p['payment_note']??'-'}'),
            const SizedBox(height:8),
            Row(children:[
              Expanded(child:FilledButton.icon(onPressed:working?null:()=>decide(p['id'].toString(),true),icon:const Icon(Icons.check),label:const Text('تأیید'))),
              const SizedBox(width:8),
              Expanded(child:OutlinedButton.icon(onPressed:working?null:()=>decide(p['id'].toString(),false),icon:const Icon(Icons.close),label:const Text('رد'))),
            ])
          ]))))
        ])
      )
    ));
  }
}
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
  Map<String,dynamic>? settings; final note=TextEditingController(); bool loading=true,sending=false;
  @override void initState(){super.initState();load();}
  @override void dispose(){note.dispose();super.dispose();}
  Future<void> load() async { try{final r=await supabase.from('subscription_settings').select('price,duration_days,ad_limit,image_limit,destination_card,card_holder,bank_name,instructions,enabled').eq('id',true).maybeSingle();if(mounted)setState((){settings=r;loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}
  Future<void> submit() async {final u=supabase.auth.currentUser;if(u==null||settings==null||note.text.trim().isEmpty)return;setState(()=>sending=true);try{await supabase.from('payments').insert({'user_id':u.id,'amount':settings!['price'],'status':'checking','payment_note':note.text.trim(),'payment_code':u.id.substring(0,8)+'-'+DateTime.now().millisecondsSinceEpoch.toString()});if(mounted)showDialog(context:context,builder:(_)=>const AlertDialog(title:Text('درخواست ثبت شد'),content:Text('اشتراک فقط پس از تأیید واقعی پرداخت فعال می‌شود.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت پرداخت: '+e.toString())));}finally{if(mounted)setState(()=>sending=false);}}
  @override Widget build(BuildContext c){
    if(loading)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:CircularProgressIndicator())));
    final s=settings;
    if(s==null||s['enabled']!=true)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:Text('فروش اشتراک فعال نیست.'))));
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('خرید اشتراک')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:ListTile(title:Text(s['price'].toString()+' تومان'),subtitle:Text(s['duration_days'].toString()+' روز • '+s['ad_limit'].toString()+' آگهی • '+s['image_limit'].toString()+' عکس'))),
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          SelectableText('شماره کارت: '+(s['destination_card']?.toString()??'تنظیم نشده')),
          SelectableText('صاحب کارت: '+(s['card_holder']?.toString()??'-')),
          SelectableText('بانک: '+(s['bank_name']?.toString()??'-')),
          Text(s['instructions']?.toString()??''),
        ]))),
        TextField(controller:note,decoration:const InputDecoration(labelText:'کد پیگیری / توضیح انتقال',border:OutlineInputBorder())),
        FilledButton(onPressed:sending?null:submit,child:sending?const CircularProgressIndicator():const Text('ثبت برای بررسی')),
      ]),
    ));
  }
}

class AdDetailPage extends StatefulWidget {
  final Map<String,dynamic> ad;
  const AdDetailPage({super.key,required this.ad});
  @override State<AdDetailPage> createState()=>_AdDetailPageState();
}
class _AdDetailPageState extends State<AdDetailPage>{
  bool saved=false,loading=true;
  List<Map<String,dynamic>> images=[],similar=[];
  Map<String,dynamic>? seller;

  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final u=supabase.auth.currentUser?.id;
    final id=widget.ad['idd']?.toString();
    if(id==null){if(mounted)setState(()=>loading=false);return;}
    try{
      await supabase.rpc('increment_ad_view',params:{'p_ad_id':id});
      if(u!=null){
        final fav=await supabase.from('favorites').select('ad_id').eq('user_id',u).eq('ad_id',id).maybeSingle();
        if(mounted)setState(()=>saved=fav!=null);
      }
      final imgs=await supabase.from('ad_images').select('image_url').eq('ad_id',id);
      final sellerId=widget.ad['seller_id']?.toString();
      Map<String,dynamic>? sp;
      if(sellerId!=null) sp=Map<String,dynamic>.from((await supabase.from('profiles').select('iidd,name,cphone,created_at').eq('iidd',sellerId).maybeSingle())??{});
      final sims=await supabase.from('ads').select('idd,title,price,city,category').eq('category',widget.ad['category']?.toString()??'').neq('idd',id).limit(6);
      if(mounted)setState((){images=List<Map<String,dynamic>>.from(imgs);seller=sp;similar=List<Map<String,dynamic>>.from(sims);loading=false;});
    }catch(e){if(mounted)setState(()=>loading=false);}
  }

  Future<void> toggle() async {
    final u=supabase.auth.currentUser?.id,id=widget.ad['idd']?.toString();
    if(u==null||id==null)return;
    try{
      if(saved) await supabase.from('favorites').delete().eq('user_id',u).eq('ad_id',id);
      else await supabase.from('favorites').insert({'user_id':u,'ad_id':id});
      if(mounted)setState(()=>saved=!saved);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره آگهی: '+e.toString())));}
  }

  Future<void> report() async {
    final id=widget.ad['idd']?.toString(),u=supabase.auth.currentUser?.id;
    if(id==null||u==null)return;
    final reason=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(
      title:const Text('گزارش آگهی'),
      children:['کلاهبرداری','کالای غیرقانونی','اطلاعات نادرست','قیمت نادرست','محتوای نامناسب','آگهی تکراری','سایر']
        .map((x)=>SimpleDialogOption(onPressed:()=>Navigator.pop(context,x),child:Text(x))).toList()));
    if(reason==null)return;
    try{
      await supabase.from('reports').insert({'reporter_id':u,'ad_id':id,'reason':reason});
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('گزارش شما ثبت شد.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('گزارش: '+e.toString())));}
  }

  Future<void> shareAd() async {
    final text='آگهی آگهینو: ${widget.ad['title']??''} • ${widget.ad['city']??''}';
    await Clipboard.setData(ClipboardData(text:text));
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('متن آگهی کپی شد.')));
  }

  Future<void> startChat() async {
    final u=supabase.auth.currentUser?.id,sellerId=widget.ad['seller_id']?.toString(),adId=widget.ad['idd']?.toString();
    if(u==null||sellerId==null||adId==null||sellerId==u){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('امکان شروع گفت‌وگو وجود ندارد.')));return;}
    try{
      final ex=await supabase.from('conversations').select('id').eq('ad_id',adId).eq('buyer_id',u).eq('seller_id',sellerId).maybeSingle();
      final cid=ex?['id']?.toString()??(await supabase.from('conversations').insert({'buyer_id':u,'seller_id':sellerId,'ad_id':adId,'title':widget.ad['title']?.toString()??'گفت‌وگو'}).select('id').single())['id'].toString();
      if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>ConversationPage(conversationId:cid,title:widget.ad['title']?.toString()??'گفت‌وگو')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('شروع گفت‌وگو: '+e.toString())));}
  }

  Future<void> callSeller() async {
    final sellerId=widget.ad['seller_id']?.toString();
    final phone=seller?['cphone']?.toString();
    if(sellerId==null||phone==null||phone.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره تماس فروشنده در دسترس نیست.')));return;}
    await launchUrl(Uri.parse('tel:$phone'));
  }

  @override Widget build(BuildContext c){
    final title=widget.ad['title']?.toString()??'بدون عنوان';
    final price=widget.ad['price']?.toString()??'توافقی';
    final city=widget.ad['city']?.toString()??'';
    final cat=widget.ad['category']?.toString()??'';
    final desc=widget.ad['edescription']?.toString()??'توضیحی ثبت نشده است.';
    final condition=widget.ad['item_condition']?.toString()??'';
    final neighborhood=widget.ad['neighborhood']?.toString()??'';
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('جزئیات آگهی'),actions:[
        IconButton(onPressed:shareAd,icon:const Icon(Icons.share_outlined)),
        IconButton(onPressed:toggle,icon:Icon(saved?Icons.favorite:Icons.favorite_border)),
      ]),
      body:loading?const Center(child:CircularProgressIndicator()):ListView(
        children:[
          if(images.isNotEmpty)SizedBox(height:270,child:PageView.builder(itemCount:images.length,itemBuilder:(_,i)=>Image.network(images[i]['image_url'].toString(),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Center(child:Icon(Icons.broken_image_outlined,size:60))))),
          Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),
            const SizedBox(height:8),
            Text(price+' تومان',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
            Text([city,neighborhood,cat,condition].where((x)=>x.isNotEmpty).join(' • ')),
            const SizedBox(height:10),
            Text('بازدید: ${widget.ad['view_count']??0}'),
            const Divider(height:28),
            const Text('توضیحات',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
            const SizedBox(height:6),Text(desc),
            const SizedBox(height:20),
            if(seller!=null)Card(child:ListTile(
              leading:const CircleAvatar(child:Icon(Icons.person)),
              title:Text(seller!['name']?.toString()??'فروشنده'),
              subtitle:Text('عضویت: ${seller!['created_at']?.toString().split('T').first??'-'}'),
              trailing:const Icon(Icons.person_outline),
            )),
            const SizedBox(height:8),
            Row(children:[
              Expanded(child:FilledButton.icon(onPressed:callSeller,icon:const Icon(Icons.phone),label:const Text('تماس'))),
              const SizedBox(width:8),
              Expanded(child:OutlinedButton.icon(onPressed:startChat,icon:const Icon(Icons.chat),label:const Text('پیام'))),
            ]),
            const SizedBox(height:8),
            OutlinedButton.icon(onPressed:report,icon:const Icon(Icons.flag_outlined),label:const Text('گزارش آگهی')),
            if(similar.isNotEmpty)...[
              const SizedBox(height:18),
              const Text('آگهی‌های مشابه',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
              const SizedBox(height:8),
              SizedBox(height:145,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:similar.length,itemBuilder:(_,i){
                final x=similar[i];
                return SizedBox(width:190,child:Card(child:ListTile(
                  title:Text(x['title']?.toString()??'',maxLines:2,overflow:TextOverflow.ellipsis),
                  subtitle:Text((x['price']?.toString()??'توافقی')+' تومان\n'+(x['city']?.toString()??'')),
                  onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdDetailPage(ad:x))),
                )));
              },separatorBuilder:(_,__)=>const SizedBox(width:8))),
            ],
          ])),
        ],
      ),
    ));
  }
}
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override State<MessagesPage> createState()=>_MessagesPageState();
}
class _MessagesPageState extends State<MessagesPage>{
  bool loading=true; List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final u=supabase.auth.currentUser;
    if(u==null){if(mounted)setState(()=>loading=false);return;}
    try{
      final r=await supabase.from('conversations').select('*').or('buyer_id.eq.${u.id},seller_id.eq.${u.id}').order('created_at',ascending:false);
      if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});
    }catch(_){if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext c){
    if(loading)return const Center(child:CircularProgressIndicator());
    return Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('پیام‌ها',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      if(rows.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('هنوز گفت‌وگویی ندارید.')),
      ...rows.map((r)=>Card(child:ListTile(
        title:Text(r['title']?.toString()??'گفت‌وگو'),
        subtitle:Text(r['updated_at']?.toString()??r['created_at']?.toString()??''),
        leading:const Icon(Icons.chat_bubble_outline),
        onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ConversationPage(conversationId:r['id'].toString(),title:r['title']?.toString()??'گفت‌وگو'))),
      ))),
    ]));
  }
}
class ConversationPage extends StatefulWidget {
  final String conversationId, title;
  const ConversationPage({super.key, required this.conversationId, required this.title});
  @override State<ConversationPage> createState() => _ConversationPageState();
}
class _ConversationPageState extends State<ConversationPage> {
  final input=TextEditingController();
  bool loading=true, sending=false;
  List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  @override void dispose(){input.dispose();super.dispose();}
  Future<void> load() async {
    try {
      final r=await supabase.from('messages').select('*').eq('conversation_id',widget.conversationId).order('created_at');
      if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});
    } catch(e) { if(mounted)setState(()=>loading=false); }
  }
  Future<void> send() async {
    final body=input.text.trim(); final u=supabase.auth.currentUser?.id;
    if(body.isEmpty||u==null)return;
    setState(()=>sending=true);
    try {
      await supabase.from('messages').insert({'conversation_id':widget.conversationId,'sender_id':u,'body':body});
      input.clear(); await load();
    } catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ارسال پیام: '+e.toString()))); }
    finally { if(mounted)setState(()=>sending=false); }
  }
  @override Widget build(BuildContext c) {
    final u=supabase.auth.currentUser?.id;
    return Directionality(
      textDirection:TextDirection.rtl,
      child:Scaffold(
        appBar:AppBar(title:Text(widget.title)),
        body:Column(
          children:[
            Expanded(
              child:loading
                ? const Center(child:CircularProgressIndicator())
                : ListView(
                    padding:const EdgeInsets.all(12),
                    children:rows.map((r){
                      final mine=r['sender_id']==u;
                      return Align(
                        alignment:mine?Alignment.centerLeft:Alignment.centerRight,
                        child:Card(child:Padding(padding:const EdgeInsets.all(10),child:Text(r['body']?.toString()??''))),
                      );
                    }).toList(),
                  ),
            ),
            SafeArea(
              child:Row(
                children:[
                  Expanded(child:TextField(controller:input,decoration:const InputDecoration(hintText:'پیام خود را بنویسید'))),
                  IconButton(onPressed:sending?null:send,icon:const Icon(Icons.send)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
