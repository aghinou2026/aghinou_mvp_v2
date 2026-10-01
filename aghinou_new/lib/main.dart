import 'package:flutter/material.dart';

void main() => runApp(const AghinouApp());

class AghinouApp extends StatelessWidget {
  const AghinouApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'آگهینو',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6D45E8)), scaffoldBackgroundColor: const Color(0xFFF8F7FC)),
    home: const Directionality(textDirection: TextDirection.rtl, child: HomePage()),
  );
}

class Ad {
  final String title, price, place, time, category, image;
  const Ad(this.title, this.price, this.place, this.time, this.category, this.image);
}
const ads = <Ad>[
  Ad('آیفون ۱۳، ۱۲۸ گیگ، بسیار تمیز','۳۸,۵۰۰,۰۰۰ تومان','آستارا، مرکز شهر','۸ دقیقه پیش','موبایل','https://images.unsplash.com/photo-1592286927505-2fd7f7f2f4c7?auto=format&fit=crop&w=900&q=80'),
  Ad('مبل راحتی ۷ نفره، سالم و شیک','۲۴,۰۰۰,۰۰۰ تومان','آستارا، مرکز شهر','۲۵ دقیقه پیش','خانه','https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=900&q=80'),
  Ad('پژو ۲۰۶ تیپ ۵ مدل ۱۳۹۹','۶۹۰,۰۰۰,۰۰۰ تومان','اردبیل','۴۳ دقیقه پیش','خودرو','https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?auto=format&fit=crop&w=900&q=80'),
  Ad('لپ‌تاپ Lenovo IdeaPad، سالم','۳۲,۰۰۰,۰۰۰ تومان','رشت، منظریه','۱ ساعت پیش','دیجیتال','https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=900&q=80'),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int index = 0; String category = 'همه'; String query = '';
  @override Widget build(BuildContext context) {
    if (index == 1) return const SearchPage();
    if (index == 3) return const MessagesPage();
    if (index == 4) return const ProfilePage();
    final filtered = ads.where((ad) {
      final c = category == 'همه' || ad.category == category;
      final q = query.isEmpty || (ad.title + ' ' + ad.place + ' ' + ad.category).contains(query);
      return c && q;
    }).toList();
    return Scaffold(
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(18,16,18,110), children: [
        Row(children: [
          Container(width:50,height:50,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF7B52F0),Color(0xFF4D2CB5)]),borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.storefront_rounded,color:Colors.white)),
          const SizedBox(width:12),
          const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('سلام 👋',style:TextStyle(color:Colors.grey)),Text('آگهینو',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900))])),
          IconButton(onPressed:(){},icon:const Icon(Icons.notifications_none_rounded)),
        ]),
        const SizedBox(height:18),
        TextField(onChanged:(v)=>setState(()=>query=v),decoration:InputDecoration(hintText:'دنبال چه چیزی می‌گردی؟',prefixIcon:const Icon(Icons.search_rounded),suffixIcon:const Icon(Icons.tune_rounded),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(19),borderSide:BorderSide.none))),
        const SizedBox(height:14),
        Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFEFEAFF),borderRadius:BorderRadius.circular(17)),child:const Row(children:[Icon(Icons.location_on_rounded,color:Color(0xFF6D45E8)),SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('موقعیت شما',style:TextStyle(fontSize:11,color:Colors.grey)),Text('آستارا',style:TextStyle(fontWeight:FontWeight.bold))])),Text('تغییر شهر',style:TextStyle(color:Color(0xFF6D45E8),fontWeight:FontWeight.bold))])),
        const SizedBox(height:22),
        const Text('دسته‌بندی‌ها',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
        const SizedBox(height:10),
        SizedBox(height:55,child:ListView(scrollDirection:Axis.horizontal,children:['همه','خودرو','املاک','موبایل','دیجیتال','خانه','پوشاک','خدمات'].map((name)=>Padding(padding:const EdgeInsets.only(left:8),child:ChoiceChip(label:Text(name),selected:category==name,onSelected:(_)=>setState(()=>category=name),selectedColor:const Color(0xFF6D45E8),labelStyle:TextStyle(color:category==name?Colors.white:Colors.black87,fontWeight:FontWeight.bold)))).toList())),
        const SizedBox(height:18),
        Row(children:[const Text('آگهی‌های ویژه',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const Spacer(),Text('مشاهده همه',style:TextStyle(color:Color(0xFF6D45E8),fontWeight:FontWeight.bold))]),
        const SizedBox(height:10),
        SizedBox(height:205,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:2,separatorBuilder:(_,__)=>const SizedBox(width:12),itemBuilder:(_,i)=>FeaturedCard(ad:ads[i]))),
        const SizedBox(height:26),
        const Text('آگهی‌های جدید',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
        const SizedBox(height:10),
        ...filtered.map((ad)=>AdCard(ad:ad)),
      ])),
      floatingActionButton:FloatingActionButton.extended(backgroundColor:const Color(0xFF6D45E8),foregroundColor:Colors.white,onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CreateAdPage())),icon:const Icon(Icons.add_rounded),label:const Text('ثبت آگهی')),
      floatingActionButtonLocation:FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v){if(v==2){Navigator.push(context,MaterialPageRoute(builder:(_)=>const CreateAdPage()));}else{setState(()=>index=v);}},destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'خانه'),
        NavigationDestination(icon:Icon(Icons.search_rounded),label:'جست‌وجو'),
        NavigationDestination(icon:Icon(Icons.add_circle_outline_rounded),label:'ثبت آگهی'),
        NavigationDestination(icon:Icon(Icons.chat_bubble_outline_rounded),label:'پیام‌ها'),
        NavigationDestination(icon:Icon(Icons.person_outline_rounded),label:'پروفایل')]),
    );
  }
}

class FeaturedCard extends StatelessWidget {
  final Ad ad; const FeaturedCard({super.key,required this.ad});
  @override Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(22),child:SizedBox(width:300,child:Stack(fit:StackFit.expand,children:[
    Image.network(ad.image,fit:BoxFit.cover),
    Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Colors.black.withValues(alpha:.82)]))),
    const Positioned(top:12,right:12,child:Chip(label:Text('ویژه',style:TextStyle(color:Colors.white)),backgroundColor:Color(0xFF6D45E8))),
    Positioned(right:14,left:14,bottom:14,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(ad.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:16)),Text(ad.price,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),Text(ad.place,style:const TextStyle(color:Colors.white70,fontSize:12))])),
  ])));
}

class AdCard extends StatefulWidget {
  final Ad ad; const AdCard({super.key,required this.ad});
  @override State<AdCard> createState()=>_AdCardState();
}
class _AdCardState extends State<AdCard> {
  bool saved=false;
  @override Widget build(BuildContext context)=>GestureDetector(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdDetailPage(ad:widget.ad))),child:Container(margin:const EdgeInsets.only(bottom:11),padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFECE9F2))),child:Row(children:[
    ClipRRect(borderRadius:BorderRadius.circular(15),child:Image.network(widget.ad.image,width:108,height:108,fit:BoxFit.cover)),
    const SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.ad.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15)),const SizedBox(height:8),Text(widget.ad.price,style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:7),Text(widget.ad.place+' • '+widget.ad.time,style:const TextStyle(fontSize:11,color:Colors.grey))])),
    IconButton(onPressed:()=>setState(()=>saved=!saved),icon:Icon(saved?Icons.favorite:Icons.favorite_border,color:saved?Colors.pink:Colors.grey)),
  ])));
}

class AdDetailPage extends StatelessWidget {
  final Ad ad; const AdDetailPage({super.key,required this.ad});
  @override Widget build(BuildContext context)=>Scaffold(body:CustomScrollView(slivers:[
    SliverAppBar(expandedHeight:310,pinned:true,flexibleSpace:FlexibleSpaceBar(background:Image.network(ad.image,fit:BoxFit.cover))),
    SliverPadding(padding:const EdgeInsets.all(20),sliver:SliverToBoxAdapter(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(ad.category,style:const TextStyle(color:Color(0xFF6D45E8),fontWeight:FontWeight.bold)),
      const SizedBox(height:12),Text(ad.title,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),
      const SizedBox(height:10),Text(ad.price,style:const TextStyle(fontSize:21,color:Color(0xFF6D45E8),fontWeight:FontWeight.w900)),
      const SizedBox(height:22),const Text('توضیحات آگهی',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),const Text('این آگهی نمونه نسخه جدید آگهینو است. در نسخه نهایی مشخصات کامل، فروشنده، بازدید، ذخیره، گزارش، پیام و آگهی‌های مشابه از Backend واقعی نمایش داده می‌شود.',style:TextStyle(height:1.8,color:Colors.grey)),
      const SizedBox(height:20),const Card(child:ListTile(leading:CircleAvatar(child:Icon(Icons.person)),title:Text('فروشنده آگهینو'),subtitle:Text('عضو فعال • مشاهده پروفایل'),trailing:Icon(Icons.chevron_left))),
    ]))),
  ]),bottomNavigationBar:SafeArea(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:FilledButton.icon(onPressed:(){},icon:const Icon(Icons.chat),label:const Text('پیام'))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:(){},icon:const Icon(Icons.phone),label:const Text('تماس')))]))));
}

class CreateAdPage extends StatelessWidget {
  const CreateAdPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('ثبت آگهی جدید')),body:ListView(padding:const EdgeInsets.all(18),children:[
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF6D45E8),Color(0xFF8E6AF2)]),borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('آگهی خودت را بساز ✨',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('اشتراک فعال: تا ۹ آگهی در یک ماه',style:TextStyle(color:Colors.white70))])),
    const SizedBox(height:15),
    ...[['۱','دسته‌بندی','دسته و زیر‌دسته آگهی'],['۲','اطلاعات آگهی','عنوان، توضیحات، قیمت و وضعیت'],['۳','موقعیت','شهر، محله و موقعیت تقریبی'],['۴','تصاویر','حداکثر ۱۰ عکس و عکس اصلی'],['۵','پیش‌نمایش','بررسی نهایی و انتشار']].map((s)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:const Color(0xFFEFEAFF),child:Text(s[0])),title:Text(s[1],style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(s[2]),trailing:const Icon(Icons.chevron_left)))),
    const SizedBox(height:8),FilledButton(onPressed:(){},child:const Padding(padding:EdgeInsets.all(13),child:Text('شروع ثبت آگهی'))),
  ]));
}

class SearchPage extends StatelessWidget { const SearchPage({super.key}); @override Widget build(BuildContext context)=>const Scaffold(body:Center(child:Text('جست‌وجوی پیشرفته آگهینو'))); }
class MessagesPage extends StatelessWidget { const MessagesPage({super.key}); @override Widget build(BuildContext context)=>const Scaffold(body:Center(child:Text('پیام‌های آگهینو'))); }
class ProfilePage extends StatelessWidget { const ProfilePage({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('پروفایل')),body:ListView(padding:const EdgeInsets.all(18),children:[const CircleAvatar(radius:45,child:Icon(Icons.person,size:48)),const SizedBox(height:12),const Center(child:Text('کاربر آگهینو',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900))),const SizedBox(height:20),for(final item in ['آگهی‌های من','ذخیره‌شده‌ها','اشتراک من','پرداخت‌ها','تنظیمات'])Card(child:ListTile(title:Text(item),trailing:const Icon(Icons.chevron_left))) ])); }
