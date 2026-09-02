from pathlib import Path
import re

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')

# Add each integration import independently. The first-run intro pass may have
# already added shared_preferences, so never use that import as the gate for
# the other packages.
imports = [
    "import 'package:shared_preferences/shared_preferences.dart';",
    "import 'package:flutter_map/flutter_map.dart';",
    "import 'package:latlong2/latlong.dart';",
    "import 'package:url_launcher/url_launcher.dart';",
]
anchor = "import 'package:geolocator/geolocator.dart';"
missing = [line for line in imports if line not in text]
if missing and anchor in text:
    text = text.replace(anchor, anchor + '\n' + '\n'.join(missing), 1)

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

"""
    # Base project already contains _categoryColor under a slightly different
    # parameter name. Do not add a second top-level declaration.
    if not re.search(r'\bColor\s+_categoryColor\s*\(', text):
        helper += """Color _categoryColor(String name) {
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

start = text.find('class AghinouApp extends StatelessWidget {')
end = text.find('class LoginPage extends StatefulWidget {', start)
if start != -1 and end != -1:
    app = """class AghinouApp extends StatelessWidget {
  const AghinouApp({super.key});
  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6C4CF1), brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF101014) : const Color(0xFFF7F7FA),
      appBarTheme: AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: dark ? const Color(0xFF101014) : const Color(0xFFF7F7FA)),
      cardTheme: CardThemeData(elevation: 1.5, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1B1B21) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 2)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 8,
        indicatorColor: scheme.primaryContainer,
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
    final color = _categoryColor(category);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(category == 'همه' ? 'دسته‌بندی‌ها' : category)),
        body: category == 'همه'
            ? const Center(child: Text('یک دسته را انتخاب کنید'))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: subs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05),
                itemBuilder: (_, i) {
                  final s = subs[i];
                  final selected = s == initialSubcategory;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.pop(context, '$category|||$s'),
                    child: Container(
                      decoration: BoxDecoration(color: selected ? color.withValues(alpha: .14) : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? color : Theme.of(context).dividerColor.withValues(alpha: .22))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 58, height: 58, decoration: BoxDecoration(color: color.withValues(alpha: .13), shape: BoxShape.circle), child: Icon(aghinouCategoryIcons[category] ?? Icons.category_rounded, color: color, size: 31)),
                          const SizedBox(height: 10),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(s, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14))),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

"""
    text = text[:start] + cat + text[end:]

if 'const Map<String, IconData> aghinouCategoryIcons' not in text:
    marker = "const categoryNames = ['همه', 'خودرو', 'املاک', 'موبایل', 'لوازم خانه', 'کالای دیجیتال', 'پوشاک', 'خدمات'];"
    helper = """
const Map<String, IconData> aghinouCategoryIcons = <String, IconData>{
  'خودرو': Icons.directions_car_rounded,
  'املاک': Icons.home_work_rounded,
  'موبایل': Icons.phone_iphone_rounded,
  'لوازم خانه': Icons.chair_rounded,
  'کالای دیجیتال': Icons.devices_rounded,
  'پوشاک': Icons.checkroom_rounded,
  'خدمات': Icons.handyman_rounded,
};

"""
    if marker in text:
        text = text.replace(marker, helper + marker, 1)

old = """Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: city, decoration: const InputDecoration(labelText: 'شهر'), items: allIranCities().map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: publishing ? null : (v) { if (v != null) setState(() => city = v); })),"""
new = """Row(children: [
              Expanded(child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.location_city_outlined), title: Text(city), subtitle: const Text('برای جستجوی شهر لمس کنید'), onTap: publishing ? null : () async { final c = await showModalBottomSheet<String>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const CityPicker()); if (c != null && mounted) setState(() => city = c); })),"""
text = text.replace(old, new, 1)

old_vehicle = """TextField(controller: brand, decoration: const InputDecoration(labelText: 'برند خودرو')),
          TextField(controller: model, decoration: const InputDecoration(labelText: 'مدل خودرو')),
          TextField(controller: year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سال')),
          TextField(controller: mileage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کارکرد')),
          TextField(controller: color, decoration: const InputDecoration(labelText: 'رنگ')),"""
new_vehicle = """Row(children: [
            Expanded(child: TextField(controller: brand, decoration: const InputDecoration(labelText: 'برند خودرو'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: model, decoration: const InputDecoration(labelText: 'مدل خودرو'))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سال'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: mileage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کارکرد'))),
          ]),
          const SizedBox(height: 10),
          TextField(controller: color, decoration: const InputDecoration(labelText: 'رنگ')),"""
text = text.replace(old_vehicle, new_vehicle, 1)

text = text.replace('_picker.pickMultiImage(imageQuality: 90)', '_picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)')
text = text.replace('picker.pickMultiImage(imageQuality: 90)', 'picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)')

needle = "Text('${a['city'] ?? ''} • ${a['category'] ?? ''} • ${a['subcategory'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5)),"
map_block = """
                if (a['latitude'] != null && a['longitude'] != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(height: 220, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: FlutterMap(options: MapOptions(initialCenter: LatLng(double.tryParse('${a['latitude']}') ?? 35.6892, double.tryParse('${a['longitude']}') ?? 51.3890), initialZoom: 14), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'ir.aghinou.app'), MarkerLayer(markers: [Marker(point: LatLng(double.tryParse('${a['latitude']}') ?? 35.6892, double.tryParse('${a['longitude']}') ?? 51.3890), width: 46, height: 46, child: const Icon(Icons.location_on, size: 42))])]))),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: () { final lat = a['latitude']; final lng = a['longitude']; launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'), mode: LaunchMode.externalApplication); }, icon: const Icon(Icons.navigation_outlined), label: const Text('مسیریابی')),
                ],"""
text = text.replace(needle, needle + map_block, 1)

path.write_text(text, encoding='utf-8')
print('Integrated Aghinou final UI/auth/category/location changes.')
