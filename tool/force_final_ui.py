from pathlib import Path
import re

p = Path('lib/main.dart')
s = p.read_text(encoding='utf-8')

# Make sure the runtime packages used by the integrated UI are imported.
imports = [
    "import 'package:shared_preferences/shared_preferences.dart';",
    "import 'package:flutter_map/flutter_map.dart';",
    "import 'package:latlong2/latlong.dart';",
    "import 'package:url_launcher/url_launcher.dart';",
]
anchor = "import 'package:geolocator/geolocator.dart';"
missing = [x for x in imports if x not in s]
if missing and anchor in s:
    s = s.replace(anchor, anchor + '\n' + '\n'.join(missing), 1)

# Ensure category icons exist exactly once.
if 'const Map<String, IconData> aghinouCategoryIcons' not in s:
    marker = "const categoryNames = ['همه', 'خودرو', 'املاک', 'موبایل', 'لوازم خانه', 'کالای دیجیتال', 'پوشاک', 'خدمات'];"
    icons = """const Map<String, IconData> aghinouCategoryIcons = <String, IconData>{
  'خودرو': Icons.directions_car_rounded,
  'املاک': Icons.home_work_rounded,
  'موبایل': Icons.phone_iphone_rounded,
  'لوازم خانه': Icons.chair_rounded,
  'کالای دیجیتال': Icons.devices_rounded,
  'پوشاک': Icons.checkroom_rounded,
  'خدمات': Icons.handyman_rounded,
};

"""
    if marker in s:
        s = s.replace(marker, icons + marker, 1)

# The system may be dark on the phone. Start Aghinou in light mode unless the
# user has explicitly saved another choice.
s = s.replace("ThemeMode>(ThemeMode.system)", "ThemeMode>(ThemeMode.light)", 1)
s = s.replace("p.getString('aghinou_theme_mode') ?? 'system'", "p.getString('aghinou_theme_mode') ?? 'light'", 1)

# Replace the old single category Card on Home with a compact 3-column grid.
old_home = """          Card(child: ListTile(leading: const Icon(Icons.category_outlined), title: Text(category == 'همه' ? 'انتخاب دسته‌بندی' : '$category${subcategory != 'همه' ? ' • $subcategory' : ''}'), subtitle: const Text('برای مشاهده زیر‌دسته‌ها لمس کنید'), trailing: const Icon(Icons.chevron_left), onTap: chooseCategory)),
          const SizedBox(height: 20),"""
new_home = """          Row(children: [
            const Expanded(child: Text('دسته‌بندی‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
            if (category != 'همه') TextButton(onPressed: () => setState(() { category = 'همه'; subcategory = 'همه'; }), child: const Text('همه')),
          ]),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryNames.length - 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.02),
            itemBuilder: (_, i) {
              final c = categoryNames[i + 1];
              final active = category == c;
              final color = _categoryColor(c);
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => CategoryPage(initialCategory: c, initialSubcategory: 'همه')));
                  if (result != null && mounted) {
                    final parts = result.split('|||');
                    setState(() { category = parts[0]; subcategory = parts.length > 1 ? parts[1] : 'همه'; });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(color: active ? color.withValues(alpha: .16) : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: active ? color : Theme.of(context).dividerColor.withValues(alpha: .22))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(aghinouCategoryIcons[c] ?? Icons.category_rounded, color: color, size: 32),
                    const SizedBox(height: 7),
                    Text(c, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12.5)),
                  ]),
                ),
              );
            },
          ),
          if (category != 'همه') ...[
            const SizedBox(height: 12),
            Card(child: ListTile(leading: Icon(aghinouCategoryIcons[category] ?? Icons.category, color: _categoryColor(category)), title: Text(subcategory == 'همه' ? 'همه زیر‌دسته‌های $category' : subcategory), subtitle: const Text('برای تغییر زیر‌دسته لمس کنید'), trailing: const Icon(Icons.chevron_left), onTap: chooseCategory)),
          ],
          const SizedBox(height: 20),"""
if old_home in s:
    s = s.replace(old_home, new_home, 1)

# Replace CategoryPage with a two-level visual flow: 3-column categories first,
# then only the selected category's subcategories.
start = s.find('class CategoryPage extends StatefulWidget {')
if start == -1:
    start = s.find('class CategoryPage extends StatelessWidget {')
end = s.find('class CityPicker extends StatefulWidget {', start)
if start != -1 and end != -1:
    cat = r'''class CategoryPage extends StatefulWidget {
  final String initialCategory, initialSubcategory;
  const CategoryPage({super.key, required this.initialCategory, required this.initialSubcategory});
  @override State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late String category;
  late String sub;

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
    sub = widget.initialSubcategory;
  }

  void selectCategory(String c) {
    if (c == 'همه') {
      Navigator.pop(context, 'همه|||همه');
      return;
    }
    setState(() {
      category = c;
      sub = 'همه';
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = categoryNames.where((c) => c != 'همه').toList();
    final subs = categorySubs[category] ?? const <String>[];
    final color = category == 'همه' ? Theme.of(context).colorScheme.primary : _categoryColor(category);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(category == 'همه' ? 'دسته‌بندی‌ها' : category),
          leading: category == 'همه' ? null : IconButton(onPressed: () => setState(() { category = 'همه'; sub = 'همه'; }), icon: const Icon(Icons.arrow_back)),
        ),
        body: category == 'همه'
            ? GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.02),
                itemBuilder: (_, i) {
                  final c = categories[i];
                  final cColor = _categoryColor(c);
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => selectCategory(c),
                    child: Container(
                      decoration: BoxDecoration(color: cColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(18), border: Border.all(color: cColor.withValues(alpha: .35))),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(aghinouCategoryIcons[c] ?? Icons.category_rounded, color: cColor, size: 35),
                        const SizedBox(height: 9),
                        Text(c, textAlign: TextAlign.center, style: TextStyle(color: cColor, fontWeight: FontWeight.w800, fontSize: 13)),
                      ]),
                    ),
                  );
                },
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: subs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.08),
                itemBuilder: (_, i) {
                  final item = subs[i];
                  final selected = item == sub;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.pop(context, '$category|||$item'),
                    child: Container(
                      decoration: BoxDecoration(color: selected ? color.withValues(alpha: .18) : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? color : Theme.of(context).dividerColor.withValues(alpha: .22))),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 58, height: 58, decoration: BoxDecoration(color: color.withValues(alpha: .13), shape: BoxShape.circle), child: Icon(aghinouCategoryIcons[category] ?? Icons.category_rounded, color: color, size: 30)),
                        const SizedBox(height: 10),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(item, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14))),
                      ]),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

'''
    s = s[:start] + cat + s[end:]

# Add a persistent theme chooser to Account, if the integration already supplied
# the theme setter. This gives the user explicit روشن / شب / خودکار controls.
if 'title: const Text(\'ظاهر برنامه\')' not in s and 'Future<void> setAghinouTheme' not in s:
    pass
if "title: const Text('ظاهر برنامه')" not in s and 'setAghinouTheme' in s:
    marker = "      Card(child: ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('شهر انتخابی'), subtitle: Text(city), onTap: chooseCity)),"
    theme_card = """      Card(child: ListTile(
        leading: const Icon(Icons.palette_outlined),
        title: const Text('ظاهر برنامه'),
        subtitle: const Text('روشن، شب/مشکی یا خودکار دستگاه'),
        onTap: () async {
          await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
            title: const Text('انتخاب تم'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              RadioListTile<ThemeMode>(value: ThemeMode.light, groupValue: aghinouThemeMode.value, title: const Text('روشن'), onChanged: (v) { if (v != null) { setAghinouTheme(v); Navigator.pop(dialogContext); } }),
              RadioListTile<ThemeMode>(value: ThemeMode.dark, groupValue: aghinouThemeMode.value, title: const Text('شب / مشکی'), onChanged: (v) { if (v != null) { setAghinouTheme(v); Navigator.pop(dialogContext); } }),
              RadioListTile<ThemeMode>(value: ThemeMode.system, groupValue: aghinouThemeMode.value, title: const Text('خودکار دستگاه'), onChanged: (v) { if (v != null) { setAghinouTheme(v); Navigator.pop(dialogContext); } }),
            ]),
          ));
          if (mounted) setState(() {});
        },
      )),"""
    if marker in s:
        s = s.replace(marker, marker + '\n' + theme_card, 1)

p.write_text(s, encoding='utf-8')
print('Forced final visual UI: home 3x3 categories, selected-category subcategories, light default, persistent theme selector.')
