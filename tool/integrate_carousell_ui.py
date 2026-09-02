from pathlib import Path
import re

path=Path('lib/main.dart')
text=path.read_text(encoding='utf-8')

# Imports needed by the integrated UI.
if "package:shared_preferences/shared_preferences.dart" not in text:
    text=text.replace("import 'package:geolocator/geolocator.dart';", "import 'package:geolocator/geolocator.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\nimport 'package:flutter_map/flutter_map.dart';\nimport 'package:latlong2/latlong.dart';")

# Persistent theme controller.
if 'final ValueNotifier<ThemeMode> aghinouThemeMode' not in text:
    marker="final supabase = Supabase.instance.client;"
    helper="""
final ValueNotifier<ThemeMode> aghinouThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

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
    text=text.replace(marker, marker+'\n'+helper,1)
    text=text.replace("  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);\n  runApp(const AghinouApp());", "  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);\n  await loadAghinouTheme();\n  runApp(const AghinouApp());",1)

# Replace app shell with a modern light/dark/system theme shell.
start=text.find('class AghinouApp extends StatelessWidget {')
end=text.find('class LoginPage extends StatefulWidget {', start)
if start!=-1 and end!=-1:
    app="""class AghinouApp extends StatelessWidget {
  const AghinouApp({super.key});
  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final seed = const Color(0xFF6C4CF1);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF101014) : const Color(0xFFF7F7FA),
      appBarTheme: AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: dark ? const Color(0xFF101014) : const Color(0xFFF7F7FA)),
      cardTheme: CardThemeData(elevation: 1.5, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: dark ? const Color(0xFF1B1B21) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 2))),
      navigationBarTheme: NavigationBarThemeData(height: 72, elevation: 8, indicatorColor: scheme.primaryContainer, backgroundColor: dark ? const Color(0xFF18181D) : Colors.white, labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurface)), iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant)),),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), minimumSize: const Size.fromHeight(50))),
    );
  }
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(valueListenable: aghinouThemeMode, builder: (_, mode, __) => MaterialApp(debugShowCheckedModeBanner: false, title: 'آگهینو', theme: _theme(Brightness.light), darkTheme: _theme(Brightness.dark), themeMode: mode, home: const LoginPage()));
}

"""
    text=text[:start]+app+text[end:]

# Make existing auth session open Home immediately; no repeated phone entry.
login_marker="  @override void dispose() { phone.dispose(); super.dispose(); }"
if login_marker in text and 'void _resumeSession()' not in text:
    insert="""
  @override
  void initState() {
    super.initState();
    _resumeSession();
  }

  Future<void> _resumeSession() async {
    final session = supabase.auth.currentSession;
    if (session == null || !mounted) return;
    try {
      await supabase.auth.refreshSession();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (_) {
      await supabase.auth.signOut();
    }
  }
"""
    text=text.replace(login_marker, insert+'\n'+login_marker,1)

# Better colored category tiles.
old="""child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(aghinouCategoryIcons[name] ?? Icons.category_rounded, size: 31),
                        const SizedBox(height: 7),
                        Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ]),"""
new="""child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 54, height: 54, decoration: BoxDecoration(color: _categoryColor(name).withValues(alpha: 0.14), shape: BoxShape.circle), child: Icon(aghinouCategoryIcons[name] ?? Icons.category_rounded, size: 30, color: _categoryColor(name))),
                        const SizedBox(height: 7),
                        Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _categoryColor(name))),
                      ]),"""
text=text.replace(old,new)

# Give ad cards breathing room and reduce their visual dominance.
text=text.replace("crossAxisSpacing: 10, mainAxisSpacing: 2, childAspectRatio: 0.72", "crossAxisSpacing: 12, mainAxisSpacing: 14, childAspectRatio: 0.76")
text=text.replace("padding: const EdgeInsets.fromLTRB(10, 9, 10, 11)", "padding: const EdgeInsets.fromLTRB(9, 8, 9, 10)")
text=text.replace("fontSize: 15, height: 1.35", "fontSize: 14, height: 1.3")

# CategoryPage: show ONLY the selected category's subcategories.
start=text.find('class CategoryPage extends StatefulWidget {')
end=text.find('class CityPicker extends StatefulWidget {', start)
if start!=-1 and end!=-1:
    cat="""class CategoryPage extends StatelessWidget {
  final String initialCategory, initialSubcategory;
  const CategoryPage({super.key, required this.initialCategory, required this.initialSubcategory});
  IconData iconFor(String s) => aghinouCategoryIcons[s] ?? Icons.category_rounded;
  @override
  Widget build(BuildContext context) {
    final category = initialCategory;
    final subs = categorySubs[category] ?? const <String>[];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: Text(category == 'همه' ? 'دسته‌بندی‌ها' : category)),
      body: category == 'همه' ? const Center(child: Text('یک دسته را انتخاب کنید')) : GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: subs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.12),
        itemBuilder: (_, i) {
          final s = subs[i];
          final selected = s == initialSubcategory;
          final color = _categoryColor(category);
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.pop(context, '$category|||$s'),
            child: Container(decoration: BoxDecoration(color: selected ? color.withValues(alpha: 0.14) : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? color : Theme.of(context).dividerColor.withValues(alpha: 0.22))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withValues(alpha: 0.13), shape: BoxShape.circle), child: Icon(iconFor(category), color: color, size: 30)), const SizedBox(height: 10), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(s, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14))),]));
        },
      ),
    ));
  }
}

"""
    text=text[:start]+cat+text[end:]

# Replace ad registration city dropdown with searchable modal picker.
old="""Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: city, decoration: const InputDecoration(labelText: 'شهر'), items: allIranCities().map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: publishing ? null : (v) { if (v != null) setState(() => city = v); })),
              IconButton(onPressed: publishing ? null : getLocation, icon: Icon(lat == null ? Icons.my_location : Icons.location_on)),
            ]),"""
new="""Row(children: [
              Expanded(child: InkWell(borderRadius: BorderRadius.circular(16), onTap: publishing ? null : chooseCity, child: InputDecorator(decoration: const InputDecoration(labelText: 'شهر', prefixIcon: Icon(Icons.location_city_outlined)), child: Row(children: [Expanded(child: Text(city)), const Icon(Icons.keyboard_arrow_down)])))),
              const SizedBox(width: 8),
              IconButton.filledTonal(onPressed: publishing ? null : getLocation, icon: Icon(lat == null ? Icons.my_location : Icons.location_on)),
            ]),"""
text=text.replace(old,new)

# Add city chooser state/method to AddAdPage.
needle="  Future<void> chooseCategory() async {"
if needle in text and 'Future<void> chooseCity() async {' not in text[text.find('class _AddAdPageState'):text.find('class MyAdsPage')]:
    method="""
  Future<void> chooseCity() async {
    final p = await showModalBottomSheet<String>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const CityPicker());
    if (p != null && mounted) setState(() => city = p);
  }

"""
    pos=text.find(needle, text.find('class _AddAdPageState'))
    text=text[:pos]+method+text[pos:]

# Vehicle details in two columns.
start=text.find('  Widget vehicleFields() {')
end=text.find('  @override\n  Widget build(BuildContext context) {', start)
if start!=-1 and end!=-1:
    vf="""  Widget vehicleFields() {
    final fields = [
      textField(brand, 'برند خودرو'), textField(model, 'مدل'), textField(year, 'سال ساخت', keyboard: TextInputType.number), textField(mileage, 'کارکرد (کیلومتر)', keyboard: TextInputType.number), textField(color, 'رنگ'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('مشخصات خودرو'),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.6, children: fields),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: DropdownButtonFormField<String>(value: transmission, decoration: const InputDecoration(labelText: 'گیربکس'), items: ['دستی','اتومات','نیمه‌اتومات'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged: publishing?null:(v){if(v!=null)setState(()=>transmission=v); })), const SizedBox(width:10), Expanded(child: DropdownButtonFormField<String>(value:fuel, decoration: const InputDecoration(labelText:'نوع سوخت'), items:['بنزین','گاز','دوگانه‌سوز','دیزل','برقی','هیبریدی'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged:publishing?null:(v){if(v!=null)setState(()=>fuel=v);})),]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: DropdownButtonFormField<String>(value: body, decoration: const InputDecoration(labelText:'وضعیت بدنه'), items:['سالم','یک لکه','چند لکه','رنگ‌شده','تصادفی'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged:publishing?null:(v){if(v!=null)setState(()=>body=v);})), const SizedBox(width:10), Expanded(child: SwitchListTile(contentPadding: EdgeInsets.zero, value: exchange, onChanged: publishing?null:(v)=>setState(()=>exchange=v), title: const Text('معاوضه'))),]),
    ]);
  }

"""
    text=text[:start]+vf+text[end:]

# Theme selector in account screen.
needle="      Card(child: ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('شهر انتخابی'), subtitle: Text(city), onTap: chooseCity)),"
if needle in text and "title: const Text('پوسته برنامه')" not in text:
    theme_card="""      Card(child: ListTile(leading: const Icon(Icons.palette_outlined), title: const Text('پوسته برنامه'), subtitle: const Text('روشن، شب/مشکی یا خودکار دستگاه'), onTap: () async {
        await showModalBottomSheet(context: context, showDragHandle: true, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('انتخاب پوسته', style: TextStyle(fontWeight: FontWeight.bold))),
          RadioListTile(value: ThemeMode.light, groupValue: aghinouThemeMode.value, title: const Text('روشن'), onChanged: (v) { if (v != null) { setAghinouTheme(v); Navigator.pop(ctx); } }),
          RadioListTile(value: ThemeMode.dark, groupValue: aghinouThemeMode.value, title: const Text('شب / مشکی'), onChanged: (v) { if (v != null) { setAghinouTheme(v); Navigator.pop(ctx); } }),
          RadioListTile(value: ThemeMode.system, groupValue: aghinouThemeMode.value, title: const Text('خودکار دستگاه'), onChanged: (v) { if (v != null) { setAghinouTheme(v); Navigator.pop(ctx); } }),
          const SizedBox(height: 12),
        ]))),
"""
    text=text.replace(needle, needle+'\n'+theme_card,1)

# Map on ad detail whenever coordinates exist.
map_marker="""                const Divider(height: 30),
                const Text('توضیحات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),"""
map_block="""                if (a['latitude'] != null && a['longitude'] != null) ...[
                  const Divider(height: 30),
                  const Text('موقعیت آگهی', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 230, child: FlutterMap(options: MapOptions(initialCenter: LatLng(double.parse('${a['latitude']}'), double.parse('${a['longitude']}')), initialZoom: 14), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.aghinou.app'), MarkerLayer(markers: [Marker(point: LatLng(double.parse('${a['latitude']}'), double.parse('${a['longitude']}')), width: 44, height: 44, child: const Icon(Icons.location_pin, color: Colors.red, size: 42))])]))),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse('https://www.openstreetmap.org/?mlat=${a['latitude']}&mlon=${a['longitude']}#map=16/${a['latitude']}/${a['longitude']}')), icon: const Icon(Icons.navigation_outlined), label: const Text('مشاهده و مسیریابی روی نقشه')),
                ],
                const Divider(height: 30),
                const Text('توضیحات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),"""
text=text.replace(map_marker,map_block,1)

# Gate posting by subscription state; browsing remains free.
old_open="""  void openAdd() {
    if (myAds >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سهمیه ۹ آگهی تکمیل شده است.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddAdPage(onPublished: loadAds)));
  }"""
new_open="""  Future<void> openAdd() async {
    if (myAds >= 9) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سهمیه ۹ آگهی تکمیل شده است.'))); return; }
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool('aghinou_subscription_active') ?? false;
    if (!active && mounted) {
      final go = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('اشتراک لازم است'), content: const Text('مشاهده و جستجوی آگهی‌ها رایگان است؛ برای ثبت آگهی اشتراک ماهانه ۳۵٬۰۰۰ تومان لازم است.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('فعلاً نه')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خرید اشتراک ۳۵٬۰۰۰ تومان'))]));
      if (go == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درگاه پرداخت در مرحله اتصال نهایی است؛ پس از اتصال پرداخت، اشتراک فعال می‌شود.')));
      }
      return;
    }
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => AddAdPage(onPublished: loadAds)));
  }"""
text=text.replace(old_open,new_open,1)

# Improve ad image upload reliability: lower image size.
text=text.replace("picker.pickMultiImage(imageQuality: 85)", "picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)")

path.write_text(text,encoding='utf-8')
print('Integrated Aghinou final UI/auth/category/location changes.')
