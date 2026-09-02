from pathlib import Path
import re

p = Path('lib/main.dart')
s = p.read_text(encoding='utf-8')

# Ensure required imports exist even when the first-run script runs before this patch.
for imp, anchor in [
    ("import 'package:shared_preferences/shared_preferences.dart';", "import 'package:geolocator/geolocator.dart';"),
    ("import 'package:flutter_map/flutter_map.dart';", "import 'package:shared_preferences/shared_preferences.dart';"),
    ("import 'package:latlong2/latlong.dart';", "import 'package:flutter_map/flutter_map.dart';"),
    ("import 'package:url_launcher/url_launcher.dart';", "import 'package:latlong2/latlong2.dart';"),
]:
    if imp not in s:
        if 'latlong2/latlong2.dart' in imp:
            continue
        s = s.replace(anchor, anchor + '\n' + imp, 1)

# Fix the typo-safe url_launcher insertion separately.
if "package:url_launcher/url_launcher.dart" not in s:
    s = s.replace("import 'package:latlong2/latlong2.dart';", "import 'package:latlong2/latlong2.dart';\nimport 'package:url_launcher/url_launcher.dart';", 1)

# Category colors used by both category grids and subcategory pages.
if 'Color _categoryColor(String name)' not in s:
    marker = "const categoryNames = ['همه', 'خودرو', 'املاک', 'موبایل', 'لوازم خانه', 'کالای دیجیتال', 'پوشاک', 'خدمات'];"
    helper = """Color _categoryColor(String name) {
  const colors = <String, Color>{
    'خودرو': Color(0xFFEF5350), 'املاک': Color(0xFF42A5F5), 'موبایل': Color(0xFFAB47BC),
    'لوازم خانه': Color(0xFF26A69A), 'کالای دیجیتال': Color(0xFF5C6BC0), 'پوشاک': Color(0xFFEC407A),
    'خدمات': Color(0xFFFFA726),
  };
  return colors[name] ?? const Color(0xFF6C4CF1);
}

"""
    s = s.replace(marker, helper + marker, 1)

# Persisted theme controller.
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

# Resume a valid Supabase session instead of asking for the phone on every launch.
if 'Future<void> _resumeSession() async' not in s:
    marker = "  @override void dispose() { phone.dispose(); super.dispose(); }"
    resume = """
  @override
  void initState() { super.initState(); _resumeSession(); }
  Future<void> _resumeSession() async {
    if (!mounted || supabase.auth.currentSession == null) return;
    try { await supabase.auth.refreshSession(); if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())); }
    catch (_) { await supabase.auth.signOut(); }
  }
"""
    s = s.replace(marker, resume + '\n' + marker, 1)

# Replace the category page with a true single-category subcategory screen.
start = s.find('class CategoryPage extends StatefulWidget {')
if start < 0:
    start = s.find('class CategoryPage extends StatelessWidget {')
end = s.find('class CityPicker extends StatefulWidget {', start)
if start >= 0 and end > start:
    cat = """class CategoryPage extends StatelessWidget {
  final String initialCategory, initialSubcategory;
  const CategoryPage({super.key, required this.initialCategory, required this.initialSubcategory});
  @override Widget build(BuildContext context) {
    final category = initialCategory;
    final subs = categorySubs[category] ?? const <String>[];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: Text(category == 'همه' ? 'دسته‌بندی‌ها' : category)),
      body: category == 'همه' ? const Center(child: Text('یک دسته را انتخاب کنید')) : GridView.builder(
        padding: const EdgeInsets.all(16), itemCount: subs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.12),
        itemBuilder: (_, i) { final sub = subs[i]; final c = _categoryColor(category); final selected = sub == initialSubcategory; return InkWell(
          borderRadius: BorderRadius.circular(18), onTap: () => Navigator.pop(context, '$category|||$sub'),
          child: Container(decoration: BoxDecoration(color: selected ? c.withValues(alpha: .14) : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? c : Theme.of(context).dividerColor.withValues(alpha: .22))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 58, height: 58, decoration: BoxDecoration(color: c.withValues(alpha: .13), shape: BoxShape.circle), child: Icon(aghinouCategoryIcons[category] ?? Icons.category_rounded, color: c, size: 31)), const SizedBox(height: 10), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(sub, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: c, fontSize: 14))),
          ])));
        },
      ),
    ));
  }
}

"""
    s = s[:start] + cat + s[end:]

# Searchable city selector: province + city list, with a live search box.
start = s.find('class CityPicker extends StatefulWidget {')
if start >= 0:
    # Replace through the next top-level class.
    m = re.search(r'\nclass (?!CityPicker\b)[A-Za-z_][A-Za-z0-9_]*', s[start+10:])
    if m:
        end = start + 10 + m.start()
        picker = """class CityPicker extends StatefulWidget {
  const CityPicker({super.key});
  @override State<CityPicker> createState() => _CityPickerState();
}
class _CityPickerState extends State<CityPicker> {
  final controller = TextEditingController();
  String q = '';
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final query = q.trim().toLowerCase();
    final cities = allIranCities().where((x) => query.isEmpty || x.toLowerCase().contains(query)).toList();
    return Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), child: Column(children: [
      TextField(controller: controller, autofocus: true, onChanged: (v) => setState(() => q = v), decoration: InputDecoration(hintText: 'جستجوی شهر...', prefixIcon: const Icon(Icons.search), suffixIcon: q.isNotEmpty ? IconButton(onPressed: () { controller.clear(); setState(() => q = ''); }, icon: const Icon(Icons.close)) : null)),
      const SizedBox(height: 10), Expanded(child: ListView.separated(itemCount: cities.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.location_city_outlined), title: Text(cities[i]), onTap: () => Navigator.pop(context, cities[i])))),
    ]))));
  }
}

"""
        s = s[:start] + picker + s[end:]

# Compact two-column vehicle fields if the original vertical version survived.
start = s.find('  Widget vehicleFields() {')
end = s.find('  @override\n  Widget build(BuildContext context) {', start)
if start >= 0 and end > start:
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
    s = s[:start] + vf + s[end:]

# Replace the giant city dropdown in AddAdPage.
s = s.replace("""Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: city, decoration: const InputDecoration(labelText: 'شهر'), items: allIranCities().map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: publishing ? null : (v) { if (v != null) setState(() => city = v); })),
              IconButton(onPressed: publishing ? null : getLocation, icon: Icon(lat == null ? Icons.my_location : Icons.location_on)),
            ]),""", """Row(children: [
              Expanded(child: InkWell(onTap: publishing ? null : chooseCity, borderRadius: BorderRadius.circular(16), child: InputDecorator(decoration: const InputDecoration(labelText: 'شهر', prefixIcon: Icon(Icons.location_city_outlined)), child: Row(children: [Expanded(child: Text(city)), const Icon(Icons.keyboard_arrow_down)])))),
              const SizedBox(width: 8), IconButton.filledTonal(onPressed: publishing ? null : getLocation, icon: Icon(lat == null ? Icons.my_location : Icons.location_on)),
            ]),""", 1)

# Add searchable city method to AddAdPage.
section_start = s.find('class _AddAdPageState')
section_end = s.find('class MyAdsPage', section_start)
section = s[section_start:section_end]
if 'Future<void> chooseCity() async {' not in section:
    pos = s.find('  Future<void> chooseCategory() async {', section_start)
    if pos >= 0:
        s = s[:pos] + """  Future<void> chooseCity() async {
    final value = await showModalBottomSheet<String>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const CityPicker());
    if (value != null && mounted) setState(() => city = value);
  }

""" + s[pos:]

# Add theme chooser to HomePage's top row, so it is easy to find.
needle = "IconButton(onPressed: loadAds, icon: const Icon(Icons.refresh_rounded)),"
if needle in s and "aghinou_theme_mode" in s:
    s = s.replace(needle, """IconButton(onPressed: () => showModalBottomSheet(context: context, showDragHandle: true, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: Column(mainAxisSize: MainAxisSize.min, children: [const ListTile(title: Text('پوسته برنامه', style: TextStyle(fontWeight: FontWeight.bold))), RadioListTile(value: ThemeMode.light, groupValue: aghinouThemeMode.value, title: const Text('روشن'), onChanged: (v) { if (v != null) { setAghinouTheme(v); Navigator.pop(ctx); } }), RadioListTile(value: ThemeMode.dark, groupValue: aghinouThemeMode.value, title: const Text('شب / مشکی'), onChanged: (v) { if (v != null) { setAghinouTheme(v); Navigator.pop(ctx); } }), RadioListTile(value: ThemeMode.system, groupValue: aghinouThemeMode.value, title: const Text('خودکار دستگاه'), onChanged: (v) { if (v != null) { setAghinouTheme(v); Navigator.pop(ctx); } })])), icon: const Icon(Icons.palette_outlined)),
          """ + needle, 1)

# Make network images decode at a sane size on phones and cache them.
s = s.replace("Image.network(imgs.first, fit: BoxFit.cover", "Image.network(imgs.first, fit: BoxFit.cover, cacheWidth: 700, cacheHeight: 700")

# Preserve release signing and use the current app version as the next integrated build.
s = s.replace('version: 0.5.0+6', 'version: 0.5.0+7')
p.write_text(s, encoding='utf-8')
print('Final Aghinou polish applied.')
