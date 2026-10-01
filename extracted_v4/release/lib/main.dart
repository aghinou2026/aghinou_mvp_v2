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
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(
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
      ))),
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
  final Future<void> Function() onPublished; const AddAdPage({super.key,required this.onPublished});
  @override State<AddAdPage> createState()=>_AddAdPageState();
}
class _AddAdPageState extends State<AddAdPage>{
  final title=TextEditingController(),desc=TextEditingController(),price=TextEditingController();
  String category='موبایل و تبلت',city='تهران'; bool publishing=false; final picker=ImagePicker(); final List<XFile> selectedImages=[];
  @override void dispose(){title.dispose();desc.dispose();price.dispose();super.dispose();}
  Future<void> pickImages()async{if(selectedImages.length>=10)return;final xs=await picker.pickMultiImage(imageQuality:85);if(mounted)setState(()=>selectedImages.addAll(xs.take(10-selectedImages.length)));}
  Future<void> publish()async{if(title.text.trim().isEmpty||desc.text.trim().isEmpty)return;final u=supabase.auth.currentUser;if(u==null)return;final p=int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'),''));if(p==null)return;setState(()=>publishing=true);try{final id=(await supabase.rpc('publish_ad',params:{'p_title':title.text.trim(),'p_description':desc.text.trim(),'p_price':p,'p_city':city,'p_category':category})).toString();for(var i=0;i<selectedImages.length;i++){final x=selectedImages[i];final bytes=await x.readAsBytes();final ext=x.name.contains('.')?x.name.split('.').last.toLowerCase():'jpg';final safe=<String>{'jpg','jpeg','png','webp'}.contains(ext)?ext:'jpg';final path='public/'+u.id+'/'+id+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+i.toString()+'.'+safe;await supabase.storage.from('ad-images').uploadBinary(path,bytes,fileOptions:FileOptions(contentType:safe=='png'?'image/png':safe=='webp'?'image/webp':'image/jpeg'));await supabase.from('ad_images').insert({'ad_id':id,'image_url':supabase.storage.from('ad-images').getPublicUrl(path)});}await widget.onPublished();if(mounted)Navigator.pop(context);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت آگهی: '+e.toString())));}finally{if(mounted)setState(()=>publishing=false);}}
  @override
  Widget build(BuildContext c) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('ثبت آگهی')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(value: category, items: _HomePageState.categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged:(v)=>setState(()=>category=v!), decoration: const InputDecoration(labelText:'دسته‌بندی', border:OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller:title, decoration:const InputDecoration(labelText:'عنوان',border:OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller:desc,maxLines:5,decoration:const InputDecoration(labelText:'توضیحات',border:OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'قیمت',border:OutlineInputBorder())),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed:publishing?null:pickImages,icon:const Icon(Icons.add_a_photo_outlined),label:Text('عکس '+selectedImages.length.toString()+'/۱۰')),
        const SizedBox(height: 20),
        FilledButton(onPressed:publishing?null:publish,child:publishing?const CircularProgressIndicator():const Text('ثبت و انتشار')),
      ]),
    );
  }
}class FavoritesPage extends StatelessWidget{const FavoritesPage({super.key});@override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,dynamic>>>(future:supabase.from('favorites').select('ad_id,ads(*)').eq('user_id',supabase.auth.currentUser!.id).then((r)=>List<Map<String,dynamic>>.from(r)),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(16),children:[const Text('ذخیره‌شده‌ها',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),...s.data!.map((r){final a=r['ads'] is Map?Map<String,dynamic>.from(r['ads']):<String,dynamic>{};return Card(child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>AdDetailPage(ad:a))),title:Text(a['title']?.toString()??'بدون عنوان'),subtitle:Text((a['price']?.toString()??'توافقی')+' تومان • '+(a['city']?.toString()??''))));})]));}}
class SubscriptionPage extends StatefulWidget{const SubscriptionPage({super.key});@override State<SubscriptionPage> createState()=>_SubscriptionPageState();}
class _SubscriptionPageState extends State<SubscriptionPage>{Map<String,dynamic>?s;final note=TextEditingController();bool loading=true,sending=false;@override void initState(){super.initState();load();}@override void dispose(){note.dispose();super.dispose();}Future<void>load()async{final r=await supabase.from('subscription_settings').select('price,duration_days,ad_limit,image_limit,destination_card,card_holder,bank_name,instructions,enabled').eq('id',true).maybeSingle();if(mounted)setState(() { s=r; loading=false; });}Future<void>submit()async{if(s==null||supabase.auth.currentUser==null||note.text.trim().isEmpty)return;setState(()=>sending=true);try{await supabase.from('payments').insert({'user_id':supabase.auth.currentUser!.id,'amount':s!['price'],'status':'checking','payment_note':note.text.trim(),'payment_code':supabase.auth.currentUser!.id.substring(0,8)+'-'+DateTime.now().millisecondsSinceEpoch.toString()});if(mounted)showDialog(context:context,builder:(_)=>const AlertDialog(title:Text('درخواست ثبت شد'),content:Text('اشتراک فقط پس از تأیید واقعی پرداخت فعال می‌شود.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('پرداخت: '+e.toString())));}finally{if(mounted)setState(()=>sending=false);}}@override Widget build(BuildContext c){if(loading)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:CircularProgressIndicator())));if(s==null||s!['enabled']!=true)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:Text('فروش اشتراک فعال نیست.'))));return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('خرید اشتراک')),body:ListView(padding:const EdgeInsets.all(16),children:[Card(child:ListTile(title:Text(s!['price'].toString()+' تومان'),subtitle:Text(s!['duration_days'].toString()+' روز • '+s!['ad_limit'].toString()+' آگهی • '+s!['image_limit'].toString()+' عکس'))),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SelectableText('شماره کارت: '+(s!['destination_card']?.toString()??'تنظیم نشده')),SelectableText('صاحب کارت: '+(s!['card_holder']?.toString()??'-')),SelectableText('بانک: '+(s!['bank_name']?.toString()??'-')),Text(s!['instructions']?.toString()??'')]))),TextField(controller:note,decoration:const InputDecoration(labelText:'کد پیگیری / توضیح انتقال',border:OutlineInputBorder())),FilledButton(onPressed:sending?null:submit,child:sending?const CircularProgressIndicator():const Text('ثبت برای بررسی'))]));}}
class AdDetailPage extends StatefulWidget{final Map<String,dynamic>ad;const AdDetailPage({super.key,required this.ad});@override State<AdDetailPage> createState()=>_AdDetailPageState();}
class _AdDetailPageState extends State<AdDetailPage>{bool saved=false;@override void initState(){super.initState();load();}Future<void>load()async{final u=supabase.auth.currentUser?.id,id=widget.ad['idd']?.toString();if(u==null||id==null)return;final r=await supabase.from('favorites').select('ad_id').eq('user_id',u).eq('ad_id',id).maybeSingle();if(mounted)setState(()=>saved=r!=null);}Future<void>toggle()async{final u=supabase.auth.currentUser?.id,id=widget.ad['idd']?.toString();if(u==null||id==null)return;if(saved)await supabase.from('favorites').delete().eq('user_id',u).eq('ad_id',id);else await supabase.from('favorites').insert({'user_id':u,'ad_id':id});if(mounted)setState(()=>saved=!saved);}@override Widget build(BuildContext c){return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('جزئیات آگهی'),actions:[IconButton(onPressed:toggle,icon:Icon(saved?Icons.favorite:Icons.favorite_border))]),body:ListView(padding:const EdgeInsets.all(16),children:[Text(widget.ad['title']?.toString()??'بدون عنوان',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text((widget.ad['price']?.toString()??'توافقی')+' تومان',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),Text((widget.ad['city']?.toString()??'')+' • '+(widget.ad['category']?.toString()??'')),const Divider(height:24),Text(widget.ad['edescription']?.toString()??'توضیحی ثبت نشده است.'),const SizedBox(height:24),FilledButton.icon(onPressed:(){},icon:const Icon(Icons.phone),label:const Text('تماس')),OutlinedButton.icon(onPressed:(){},icon:const Icon(Icons.chat),label:const Text('پیام'))]));}}