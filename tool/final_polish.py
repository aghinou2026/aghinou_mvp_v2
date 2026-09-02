from pathlib import Path
import re

p = Path('lib/main.dart')
s = p.read_text(encoding='utf-8')

# Required imports.
imports = [
    "import 'package:shared_preferences/shared_preferences.dart';",
    "import 'package:flutter_map/flutter_map.dart';",
    "import 'package:latlong2/latlong.dart';",
    "import 'package:url_launcher/url_launcher.dart';",
]
anchor = "import 'package:geolocator/geolocator.dart';"
for imp in imports:
    if imp not in s:
        s = s.replace(anchor, anchor + '\n' + imp, 1)
        anchor = imp

# Shared color helper.
if 'Color _categoryColor(String name)' not in s:
    marker = "const categoryNames = ['همه', 'خودرو', 'املاک', 'موبایل', 'لوازم خانه', 'کالای دیجیتال', 'پوشاک', 'خدمات'];"
    helper = """Color _categoryColor(String name) {
  const colors = <String, Color>{'خودرو': Color(0xFFEF5350), 'املاک': Color(0xFF42A5F5), 'موبایل': Color(0xFFAB47BC), 'لوازم خانه': Color(0xFF26A69A), 'کالای دیجیتال': Color(0xFF5C6BC0), 'پوشاک': Color(0xFFEC407A), 'خدمات': Color(0xFFFFA726)};
  return colors[name] ?? const Color(0xFF6C4CF1);
}

"""
    s = s.replace(marker, helper + marker, 1)

# Persistent theme.
if 'final ValueNotifier<ThemeMode> aghinouThemeMode' not in s:
    marker = 'final supabase = Supabase.instance.client;'
    helper = """final ValueNotifier<ThemeMode> aghinouThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
Future<void> loadAghinouTheme() async {
  final p = await SharedPreferences.getInstance();
  final v = p.getString('aghinou_theme_mode') ?? 'system';
  aghinouThemeMode.value = v == 'dark' ? ThemeMode.dark : v == 'light' ? ThemeMode.light : ThemeMode.system;
}
Future<void> setAghinouTheme(ThemeMode mode) async {
  aghinouThemeMode.value = mode;
  final p = await SharedPreferences.getInstance();
  await p.setString('aghinou_theme_mode', mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.light ? 'light' : 'system');
}

"""
    s = s.replace(marker, marker + '\n' + helper, 1)
    s = s.replace("  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);\n  runApp(const AghinouApp());", "  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);\n  await loadAghinouTheme();\n  runApp(const AghinouApp());", 1)

# Session persistence: valid existing session skips login page.
if 'Future<void> _resumeSession() async' not in s:
    marker = "  @override void dispose() { phone.dispose(); super.dispose(); }"
    resume = """
  @override void initState() { super.initState(); _resumeSession(); }
  Future<void> _resumeSession() async {
    if (!mounted || supabase.auth.currentSession == null) return;
    try { await supabase.auth.refreshSession(); if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())); }
    catch (_) { await supabase.auth.signOut(); }
  }
"""
    s = s.replace(marker, resume + '\n' + marker, 1)

# Category page: selected category only, then visual subcategory tiles.
start = s.find('class CategoryPage extends StatefulWidget {')
if start < 0: start = s.find('class CategoryPage extends StatelessWidget {')
end = s.find('class CityPicker extends StatefulWidget {', start)
if start >= 0 and end > start:
    cat = """class CategoryPage extends StatelessWidget {
  final String initialCategory, initialSubcategory;
  const CategoryPage({super.key, required this.initialCategory, required this.initialSubcategory});
  @override Widget build(BuildContext context) {
    final category = initialCategory;
    final subs = categorySubs[category] ?? const <String>[];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: Text(category)), body: GridView.builder(
      padding: const EdgeInsets.all(16), itemCount: subs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.12),
      itemBuilder: (_, i) { final sub = subs[i]; final c = _categoryColor(category); return InkWell(borderRadius: BorderRadius.circular(18), onTap: () => Navigator.pop(context, '$category|||$sub'), child: Container(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.withValues(alpha: .30))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: c.withValues(alpha: .13), shape: BoxShape.circle), child: Icon(aghinouCategoryIcons[category] ?? Icons.category_rounded, color: c, size: 31)), const SizedBox(height: 10), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(sub, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: c, fontSize: 14)))]))); },
    )));
  }
}

"""
    s = s[:start] + cat + s[end:]

# Searchable city picker. Replace the existing picker through the next class.
start = s.find('class CityPicker extends StatefulWidget {')
if start >= 0:
    m = re.search(r'\nclass (?!CityPicker\b)[A-Za-z_][A-Za-z0-9_]*', s[start+10:])
    if m:
        end = start + 10 + m.start()
        picker = """class CityPicker extends StatefulWidget {
  const CityPicker({super.key});
  @override State<CityPicker> createState() => _CityPickerState();
}
class _CityPickerState extends State<CityPicker> {
  final controller = TextEditingController(); String q = '';
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final query = q.trim().toLowerCase();
    final cities = allIranCities().where((x) => query.isEmpty || x.toLowerCase().contains(query)).toList();
    return Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), child: Column(children: [
      TextField(controller: controller, autofocus: true, onChanged: (v) => setState(() => q = v), decoration: InputDecoration(hintText: 'جستجوی شهر...', prefixIcon: const Icon(Icons.search), suffixIcon: q.isEmpty ? null : IconButton(onPressed: () { controller.clear(); setState(() => q = ''); }, icon: const Icon(Icons.close)))),
      const SizedBox(height: 10), Expanded(child: ListView.separated(itemCount: cities.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.location_city_outlined), title: Text(cities[i]), onTap: () => Navigator.pop(context, cities[i])))),
    ]))));
  }
}

"""
        s = s[:start] + picker + s[end:]

# Two-column vehicle form.
start = s.find('  Widget vehicleFields() {')
end = s.find('  @override\n  Widget build(BuildContext context) {', start)
if start >= 0 and end > start:
    vf = """  Widget vehicleFields() {
    final fields = [textField(brand, 'برند خودرو'), textField(model, 'مدل'), textField(year, 'سال ساخت', keyboard: TextInputType.number), textField(mileage, 'کارکرد (کیلومتر)', keyboard: TextInputType.number), textField(color, 'رنگ')];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('مشخصات خودرو'), GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.6, children: fields), const SizedBox(height: 10),
      Row(children: [Expanded(child: DropdownButtonFormField<String>(value: transmission, decoration: const InputDecoration(labelText: 'گیربکس'), items: ['دستی','اتومات','نیمه‌اتومات'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged: publishing?null:(v){if(v!=null)setState(()=>transmission=v);})), const SizedBox(width:10), Expanded(child: DropdownButtonFormField<String>(value:fuel, decoration: const InputDecoration(labelText:'نوع سوخت'), items:['بنزین','گاز','دوگانه‌سوز','دیزل','برقی','هیبریدی'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged:publishing?null:(v){if(v!=null)setState(()=>fuel=v);})),]), const SizedBox(height:10),
      Row(children: [Expanded(child: DropdownButtonFormField<String>(value:body, decoration:const InputDecoration(labelText:'وضعیت بدنه'), items:['سالم','یک لکه','چند لکه','رنگ‌شده','تصادفی'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged:publishing?null:(v){if(v!=null)setState(()=>body=v);})), const SizedBox(width:10), Expanded(child: SwitchListTile(contentPadding:EdgeInsets.zero,value:exchange,onChanged:publishing?null:(v)=>setState(()=>exchange=v),title:const Text('معاوضه')))]),
    ]);
  }

"""
    s = s[:start] + vf + s[end:]

# Searchable city control in AddAdPage.
s = s.replace("""Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: city, decoration: const InputDecoration(labelText: 'شهر'), items: allIranCities().map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: publishing ? null : (v) { if (v != null) setState(() => city = v); })),
              IconButton(onPressed: publishing ? null : getLocation, icon: Icon(lat == null ? Icons.my_location : Icons.location_on)),
            ]),""", """Row(children: [Expanded(child: InkWell(onTap: publishing ? null : chooseCity, borderRadius: BorderRadius.circular(16), child: InputDecorator(decoration: const InputDecoration(labelText:'شهر', prefixIcon:Icon(Icons.location_city_outlined)), child: Row(children:[Expanded(child:Text(city)),const Icon(Icons.keyboard_arrow_down)])))), const SizedBox(width:8), IconButton.filledTonal(onPressed: publishing?null:getLocation, icon:Icon(lat==null?Icons.my_location:Icons.location_on))]),""", 1)

# Reduce upload size for more reliable mobile uploads.
s = s.replace('picker.pickMultiImage(imageQuality: 85)', 'picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)')

# Add map preview/navigation to ad details when coordinates are available.
marker = """                const Divider(height: 30),
                const Text('توضیحات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),"""
block = """                if (a['latitude'] != null && a['longitude'] != null) ...[
                  const Divider(height: 30), const Text('موقعیت آگهی', style: TextStyle(fontSize:22,fontWeight:FontWeight.bold)), const SizedBox(height:10),
                  ClipRRect(borderRadius:BorderRadius.circular(18), child:SizedBox(height:230, child:FlutterMap(options:MapOptions(initialCenter:LatLng(double.parse('${a['latitude']}'),double.parse('${a['longitude']}')),initialZoom:14),children:[TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.aghinou.app'),MarkerLayer(markers:[Marker(point:LatLng(double.parse('${a['latitude']}'),double.parse('${a['longitude']}')),width:44,height:44,child:const Icon(Icons.location_pin,color:Colors.red,size:42))])]))),
                  const SizedBox(height:8), OutlinedButton.icon(onPressed:()=>launchUrl(Uri.parse('https://www.openstreetmap.org/?mlat=${a['latitude']}&mlon=${a['longitude']}#map=16/${a['latitude']}/${a['longitude']}')),icon:const Icon(Icons.navigation_outlined),label:const Text('مشاهده و مسیریابی روی نقشه')),
                ],
                const Divider(height: 30),
                const Text('توضیحات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),"""
s = s.replace(marker, block, 1)

# Posting gate remains 9 ads; subscription check is handled here.
old_open = """  void openAdd() {
    if (myAds >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سهمیه ۹ آگهی تکمیل شده است.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddAdPage(onPublished: loadAds)));
  }"""
new_open = """  Future<void> openAdd() async {
    if (myAds >= 9) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سهمیه ۹ آگهی تکمیل شده است.'))); return; }
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool('aghinou_subscription_active') ?? false;
    if (!active && mounted) { await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('اشتراک لازم است'),content:const Text('مشاهده و جستجوی آگهی‌ها رایگان است؛ برای ثبت آگهی اشتراک ماهانه ۳۵٬۰۰۰ تومان لازم است.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('فعلاً نه')),FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('خرید اشتراک ۳۵٬۰۰۰ تومان'))])); return; }
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => AddAdPage(onPublished: loadAds)));
  }"""
s = s.replace(old_open, new_open, 1)

p.write_text(s, encoding='utf-8')
print('Final Aghinou polish applied.')
