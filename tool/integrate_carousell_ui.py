from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')

# Extra packages used by the integrated final UI.
imports = """import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
"""
if "package:shared_preferences/shared_preferences.dart" not in text:
    text = text.replace("import 'package:geolocator/geolocator.dart';", "import 'package:geolocator/geolocator.dart';\n" + imports.rstrip(), 1)

# Persistent theme controller.
if 'final ValueNotifier<ThemeMode> aghinouThemeMode' not in text:
    marker = "final supabase = Supabase.instance.client;"
    helper = """
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

Color _categoryColor(String name) {
  const colors = <String, Color>{
    'خودرو': Color(0xFFEF5350), 'املاک': Color(0xFF42A5F5), 'موبایل': Color(0xFFAB47BC),
    'لوازم خانه': Color(0xFF26A69A), 'کالای دیجیتال': Color(0xFF5C6BC0), 'پوشاک': Color(0xFFEC407A),
    'خدمات': Color(0xFFFFA726),
  };
  return colors[name] ?? const Color(0xFF6C4CF1);
}

"""
    text = text.replace(marker, marker + '\n' + helper, 1)
    text = text.replace("  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);\n  runApp(const AghinouApp());", "  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);\n  await loadAghinouTheme();\n  runApp(const AghinouApp());", 1)

# Modern light/dark/system Material shell.
start = text.find('class AghinouApp extends StatelessWidget {')
end = text.find('class LoginPage extends StatefulWidget {', start)
if start != -1 and end != -1:
    app = """class AghinouApp extends StatelessWidget {
  const AghinouApp({super.key});
  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6C4CF1), brightness: brightness);
    return ThemeData(
      useMaterial3: true, colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF101014) : const Color(0xFFF7F7FA),
      appBarTheme: AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: dark ? const Color(0xFF101014) : const Color(0xFFF7F7FA)),
      cardTheme: CardThemeData(elevation: 1.5, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: dark ? const Color(0xFF1B1B21) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 2)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72, elevation: 8, indicatorColor: scheme.primaryContainer,
        backgroundColor: dark ? const Color(0xFF18181D) : Colors.white,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurface)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), minimumSize: const Size.fromHeight(50))),
    );
  }
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: aghinouThemeMode,
    builder: (_, mode, __) => MaterialApp(debugShowCheckedModeBanner: false, title: 'آگهینو', theme: _theme(Brightness.light), darkTheme: _theme(Brightness.dark), themeMode: mode, home: const LoginPage()),
  );
}

"""
    text = text[:start] + app + text[end:]

# Resume a valid persisted Supabase session; do not ask for phone again.
if 'Future<void> _resumeSession() async' not in text:
    marker = "  @override void dispose() { phone.dispose(); super.dispose(); }"
    resume = """
  @override
  void initState() {
    super.initState();
    _resumeSession();
  }

  Future<void> _resumeSession() async {
    if (!mounted || supabase.auth.currentSession == null) return;
    try {
      await supabase.auth.refreshSession();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (_) {
      await supabase.auth.signOut();
    }
  }
"""
    text = text.replace(marker, resume + '\n' + marker, 1)

# Replace category page so tapping a category opens only its own subcategories.
start = text.find('class CategoryPage extends StatefulWidget {')
if start == -1:
    start = text.find('class CategoryPage extends StatelessWidget {')
end = text.find('class CityPicker extends StatefulWidget {', start)
if start != -1 and end != -1:
    cat = """class CategoryPage extends StatelessWidget {
  final String initialCategory, initialSubcategory;
  const CategoryPage({super.key, required this.initialCategory, required this.initialSubcategory});
  @override
  Widget build(BuildContext context) {
    final category = initialCategory;
    final subs = categorySubs[category] ?? const <String>[];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: Text(category == 'همه' ? 'دسته‌بندی‌ها' : category)),
      body: category == 'همه'
          ? const Center(child: Text('یک دسته را انتخاب کنید'))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), itemCount: subs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.12),
              itemBuilder: (_, i) {
                final s = subs[i]; final selected = s == initialSubcategory; final color = _categoryColor(category);
                return InkWell(borderRadius: BorderRadius.circular(18), onTap: () => Navigator.pop(context, '$category|||$s'),
                  child: Container(decoration: BoxDecoration(color: selected ? color.withValues(alpha: .14) : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? color : Theme.of(context).dividerColor.withValues(alpha: .22))),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: color.withValues(alpha: .13), shape: BoxShape.circle), child: Icon(aghinouCategoryIcons[category] ?? Icons.category_rounded, color: color, size: 31)), const SizedBox(height: 10), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(s, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)))]));
              },
            ),
    ));
  }
}

"""
    text = text[:start] + cat + text[end:]

# City picker in AddAdPage: use the existing searchable CityPicker instead of a huge dropdown.
old = """Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: city, decoration: const InputDecoration(labelText: 'شهر'), items: allIranCities().map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: publishing ? null : (v) { if (v != null) setState(() => city = v); })),
              IconButton(onPressed: publishing ? null : getLocation, icon: Icon(lat == null ? Icons.my_location : Icons.location_on)),
            ]),"""
new = """Row(children: [
              Expanded(child: InkWell(borderRadius: BorderRadius.circular(16), onTap: publishing ? null : chooseCity, child: InputDecorator(decoration: const InputDecoration(labelText: 'شهر', prefixIcon: Icon(Icons.location_city_outlined)), child: Row(children: [Expanded(child: Text(city)), const Icon(Icons.keyboard_arrow_down)])))),
              const SizedBox(width: 8),
              IconButton.filledTonal(onPressed: publishing ? null : getLocation, icon: Icon(lat == null ? Icons.my_location : Icons.location_on)),
            ]),"""
text = text.replace(old, new, 1)

# Add a searchable city method if AddAdPage does not already have one.
section_start = text.find('class _AddAdPageState')
section_end = text.find('class MyAdsPage', section_start)
section = text[section_start:section_end] if section_start != -1 and section_end != -1 else ''
if 'Future<void> chooseCity() async {' not in section:
    needle = '  Future<void> chooseCategory() async {'
    pos = text.find(needle, section_start)
    if pos != -1:
        method = """  Future<void> chooseCity() async {
    final p = await showModalBottomSheet<String>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const CityPicker());
    if (p != null && mounted) setState(() => city = p);
  }

"""
        text = text[:pos] + method + text[pos:]

# Two-column vehicle form.
start = text.find('  Widget vehicleFields() {')
end = text.find('  @override\n  Widget build(BuildContext context) {', start)
if start != -1 and end != -1:
    vf = """  Widget vehicleFields() {
    final fields = [textField(brand, 'برند خودرو'), textField(model, 'مدل'), textField(year, 'سال ساخت', keyboard: TextInputType.number), textField(mileage, 'کارکرد (کیلومتر)', keyboard: TextInputType.number), textField(color, 'رنگ')];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('مشخصات خودرو'),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.6, children: fields),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: DropdownButtonFormField<String>(value: transmission, decoration: const InputDecoration(labelText: 'گیربکس'), items: ['دستی','اتومات','نیمه‌اتومات'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged: publishing?null:(v){if(v!=null)setState(()=>transmission=v);})), const SizedBox(width:10), Expanded(child: DropdownButtonFormField<String>(value:fuel, decoration: const InputDecoration(labelText:'نوع سوخت'), items:['بنزین','گاز','دوگانه‌سوز','دیزل','برقی','هیبریدی'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged:publishing?null:(v){if(v!=null)setState(()=>fuel=v);})),]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: DropdownButtonFormField<String>(value: body, decoration: const InputDecoration(labelText:'وضعیت بدنه'), items:['سالم','یک لکه','چند لکه','رنگ‌شده','تصادفی'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged:publishing?null:(v){if(v!=null)setState(()=>body=v);})), const SizedBox(width:10), Expanded(child: SwitchListTile(contentPadding: EdgeInsets.zero, value: exchange, onChanged: publishing?null:(v)=>setState(()=>exchange=v), title: const Text('معاوضه'))),]),
    ]);
  }

"""
    text = text[:start] + vf + text[end:]

# Add map preview + navigation to ad details when coordinates exist.
marker = """                const Divider(height: 30),
                const Text('توضیحات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),"""
block = """                if (a['latitude'] != null && a['longitude'] != null) ...[
                  const Divider(height: 30),
                  const Text('موقعیت آگهی', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 230, child: FlutterMap(options: MapOptions(initialCenter: LatLng(double.parse('${a['latitude']}'), double.parse('${a['longitude']}')), initialZoom: 14), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.aghinou.app'), MarkerLayer(markers: [Marker(point: LatLng(double.parse('${a['latitude']}'), double.parse('${a['longitude']}')), width: 44, height: 44, child: const Icon(Icons.location_pin, color: Colors.red, size: 42))])]))),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse('https://www.openstreetmap.org/?mlat=${a['latitude']}&mlon=${a['longitude']}#map=16/${a['latitude']}/${a['longitude']}')), icon: const Icon(Icons.navigation_outlined), label: const Text('مشاهده و مسیریابی روی نقشه')),
                ],
                const Divider(height: 30),
                const Text('توضیحات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),"""
text = text.replace(marker, block, 1)

# Posting gate: browsing/search stays free; posting requires 35,000 toman subscription.
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
    if (!active && mounted) {
      final go = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('اشتراک لازم است'), content: const Text('مشاهده و جستجوی آگهی‌ها رایگان است؛ برای ثبت آگهی اشتراک ماهانه ۳۵٬۰۰۰ تومان لازم است.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('فعلاً نه')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خرید اشتراک ۳۵٬۰۰۰ تومان'))]));
      if (go == true && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درگاه پرداخت در مرحله اتصال نهایی است؛ پس از اتصال پرداخت، اشتراک فعال می‌شود.')));
      return;
    }
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => AddAdPage(onPublished: loadAds)));
  }"""
text = text.replace(old_open, new_open, 1)

# Smaller source images improve upload reliability on phones.
text = text.replace("picker.pickMultiImage(imageQuality: 85)", "picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)")

path.write_text(text, encoding='utf-8')
print('Integrated Aghinou final UI/auth/category/location changes.')
