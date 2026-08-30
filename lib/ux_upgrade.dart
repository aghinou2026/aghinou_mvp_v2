import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _db = Supabase.instance.client;

class EnhancedAdDetailsPage extends StatefulWidget {
  final Map<String, dynamic> ad;
  final List<String> images;
  final bool liked;
  final ValueChanged<bool> onLike;
  const EnhancedAdDetailsPage({super.key, required this.ad, required this.images, required this.liked, required this.onLike});
  @override State<EnhancedAdDetailsPage> createState() => _EnhancedAdDetailsPageState();
}

class _EnhancedAdDetailsPageState extends State<EnhancedAdDetailsPage> {
  late bool liked;
  int current = 0;
  @override void initState() { super.initState(); liked = widget.liked; }

  Future<void> navigateToLocation(double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('باز کردن مسیریاب ممکن نشد.')));
    }
  }
  void openGallery([int index = 0]) {
    if (widget.images.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FullScreenGallery(images: widget.images, initialIndex: index)));
  }

  @override Widget build(BuildContext context) {
    final a = widget.ad;
    final lat = (a['latitude'] as num?)?.toDouble();
    final lon = (a['longitude'] as num?)?.toDouble();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('جزئیات آگهی'), actions: [IconButton(onPressed: () { setState(() => liked = !liked); widget.onLike(liked); }, icon: Icon(liked ? Icons.favorite : Icons.favorite_border))]),
      body: ListView(padding: EdgeInsets.zero, children: [
        if (widget.images.isNotEmpty) SizedBox(height: 300, child: Stack(children: [
          PageView.builder(itemCount: widget.images.length, onPageChanged: (i) => setState(() => current = i), itemBuilder: (_, i) => GestureDetector(onTap: () => openGallery(i), child: Hero(tag: 'ad-${a['idd']}-img-$i', child: Image.network(widget.images[i], width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 50))))),),
          Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: Text('${current + 1}/${widget.images.length}', style: const TextStyle(color: Colors.white)))),
          Positioned(bottom: 12, right: 12, child: FilledButton.icon(onPressed: () => openGallery(current), icon: const Icon(Icons.fullscreen), label: const Text('تمام‌صفحه'))),
        ])) else const SizedBox(height: 120, child: Center(child: Icon(Icons.image_not_supported_outlined, size: 52))),
        Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${a['title'] ?? 'بدون عنوان'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [if ('${a['category'] ?? ''}'.isNotEmpty) Chip(label: Text('${a['category']}')), if ('${a['subcategory'] ?? ''}'.isNotEmpty && '${a['subcategory']}' != 'همه') Chip(label: Text('${a['subcategory']}')), if ('${a['city'] ?? ''}'.isNotEmpty) Chip(avatar: const Icon(Icons.location_on, size: 16), label: Text('${a['city']}'))]),
          const SizedBox(height: 18),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('${a['price'] ?? 'توافقی'} تومان', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)))),
          const SizedBox(height: 14),
          const Text('توضیحات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6), Text('${a['edescription'] ?? 'توضیحی ثبت نشده است.'}', style: const TextStyle(height: 1.8)),
          if ('${a['category'] ?? ''}' == 'خودرو') ...[
            const SizedBox(height: 20), const Text('مشخصات خودرو', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
            _specs(a, [('برند','vehicle_brand'),('مدل','vehicle_model'),('سال','vehicle_year'),('کارکرد','vehicle_mileage'),('رنگ','vehicle_color'),('گیربکس','vehicle_transmission'),('سوخت','vehicle_fuel'),('وضعیت بدنه','vehicle_body_condition')]),
          ],
          if (lat != null && lon != null) ...[
            const SizedBox(height: 22), const Text('موقعیت آگهی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 240, child: FlutterMap(options: MapOptions(initialCenter: LatLng(lat, lon), initialZoom: 14), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'ir.aghinou.app'), MarkerLayer(markers: [Marker(point: LatLng(lat, lon), width: 55, height: 55, child: const Icon(Icons.location_pin, color: Colors.red, size: 50))])]))),
            const SizedBox(height: 10), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => navigateToLocation(lat, lon), icon: const Icon(Icons.directions), label: const Text('مسیریابی تا محل آگهی'))),
          ],
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.share_outlined), label: const Text('اشتراک‌گذاری آگهی'))),
        ])),
      ]),
    ));
  }
  Widget _specs(Map<String, dynamic> a, List<(String,String)> fields) => Card(child: Column(children: [for (final f in fields) if (a[f.$2] != null && '${a[f.$2]}'.isNotEmpty) ListTile(dense: true, title: Text(f.$1), trailing: Text('${a[f.$2]}', style: const TextStyle(fontWeight: FontWeight.w600)))]));
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images; final int initialIndex;
  const _FullScreenGallery({required this.images, required this.initialIndex});
  @override State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}
class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController controller; late int index;
  @override void initState() { super.initState(); index = widget.initialIndex; controller = PageController(initialPage: index); }
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text('${index + 1}/${widget.images.length}')), body: PageView.builder(controller: controller, itemCount: widget.images.length, onPageChanged: (i) => setState(() => index = i), itemBuilder: (_, i) => Center(child: InteractiveViewer(child: Image.network(widget.images[i], fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 60)))));
}

class ProfileHubPage extends StatefulWidget {
  final String city; final int myAds; final VoidCallback onMyAds; final VoidCallback onFavorites; final VoidCallback onCity;
  const ProfileHubPage({super.key, required this.city, required this.myAds, required this.onMyAds, required this.onFavorites, required this.onCity});
  @override State<ProfileHubPage> createState() => _ProfileHubPageState();
}
class _ProfileHubPageState extends State<ProfileHubPage> {
  final name = TextEditingController();
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final u = _db.auth.currentUser; if (u != null) { final r = await _db.from('profiles').select('name').eq('iidd', u.id).maybeSingle(); if (mounted) name.text = '${r?['name'] ?? 'کاربر آگهینو'}'; } }
  @override void dispose() { name.dispose(); super.dispose(); }
  Future<void> save() async { final u = _db.auth.currentUser; if (u == null) return; await _db.from('profiles').upsert({'iidd':u.id,'name':name.text.trim().isEmpty?'کاربر آگهینو':name.text.trim()}, onConflict:'iidd'); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پروفایل ذخیره شد.'))); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 110), children: [
    Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 48)), const SizedBox(height: 12), const Text('حساب کاربری آگهینو', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 16), TextField(controller: name, decoration: const InputDecoration(labelText: 'نام شما', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 10), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_outlined), label: const Text('ذخیره اطلاعات')))]))),
    const SizedBox(height: 10),
    Card(child: ListTile(leading: const Icon(Icons.campaign_outlined), title: const Text('آگهی‌های من'), subtitle: Text('${widget.myAds} آگهی'), trailing: const Icon(Icons.chevron_left), onTap: widget.onMyAds)),
    Card(child: ListTile(leading: const Icon(Icons.favorite_border), title: const Text('علاقه‌مندی‌ها'), trailing: const Icon(Icons.chevron_left), onTap: widget.onFavorites)),
    Card(child: ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('شهر من'), subtitle: Text(widget.city), trailing: const Icon(Icons.chevron_left), onTap: widget.onCity)),
    Card(child: ListTile(leading: const Icon(Icons.security_outlined), title: const Text('امنیت و حریم خصوصی'), subtitle: const Text('مدیریت اطلاعات حساب'))),
    Card(child: ListTile(leading: const Icon(Icons.help_outline), title: const Text('راهنما و پشتیبانی'), subtitle: const Text('پرسش‌های متداول و ارتباط با ما'))),
    Card(child: ListTile(leading: const Icon(Icons.info_outline), title: const Text('درباره آگهینو'), subtitle: const Text('نسخه فعلی برنامه'))),
  ]);

class HomeSections extends StatelessWidget {
  final void Function(String) onCategory;
  const HomeSections({super.key, required this.onCategory});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('دسته‌بندی‌های محبوب', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
    GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, childAspectRatio: .82, children: [('خودرو',Icons.directions_car_outlined),('املاک',Icons.home_work_outlined),('موبایل',Icons.phone_android),('کالای دیجیتال',Icons.devices_outlined),('لوازم خانه',Icons.chair_outlined),('پوشاک',Icons.checkroom_outlined),('خدمات',Icons.handyman_outlined),('همه',Icons.grid_view_outlined)].map((x)=>InkWell(onTap:()=>onCategory(x.$1),borderRadius:BorderRadius.circular(16),child:Column(children:[Container(width:58,height:58,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:BorderRadius.circular(18)),child:Icon(x.$2)),const SizedBox(height:6),Text(x.$1,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600))]))).toList()),
    const SizedBox(height: 14),
    Card(child: ListTile(leading: const Icon(Icons.near_me_outlined), title: const Text('آگهی‌های نزدیک من'), subtitle: const Text('آگهی‌های دارای موقعیت روی نقشه'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyMapPage())))),
    const SizedBox(height: 18),
  ]);
}

class NearbyMapPage extends StatefulWidget { const NearbyMapPage({super.key}); @override State<NearbyMapPage> createState()=>_NearbyMapPageState(); }
class _NearbyMapPageState extends State<NearbyMapPage> {
  List<Map<String,dynamic>> ads=[];
  @override void initState(){super.initState();_load();}
  Future<void> _load() async { final r=await _db.from('ads').select('idd,title,latitude,longitude,city').not('latitude','is',null).not('longitude','is',null); if(mounted)setState(()=>ads=List<Map<String,dynamic>>.from(r)); }
  @override Widget build(BuildContext context){ final c=ads.isNotEmpty?LatLng((ads.first['latitude'] as num).toDouble(),(ads.first['longitude'] as num).toDouble()):const LatLng(35.6892,51.3890); return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('آگهی‌های نزدیک من')),body:FlutterMap(options:MapOptions(initialCenter:c,initialZoom:11),children:[TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'ir.aghinou.app'),MarkerLayer(markers:[for(final a in ads) Marker(point:LatLng((a['latitude'] as num).toDouble(),(a['longitude'] as num).toDouble()),width:52,height:60,child:GestureDetector(onTap:()=>showModalBottomSheet(context:context,builder:(_)=>Padding(padding:const EdgeInsets.all(20),child:ListTile(title:Text('${a['title']??'آگهی'}'),subtitle:Text('${a['city']??''}')))),child:const Icon(Icons.location_pin,color:Colors.red,size:48)))])]))); }
}
