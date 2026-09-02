from pathlib import Path
import re

p = Path('lib/main.dart')
s = p.read_text(encoding='utf-8')

# Keep this pass safe when the earlier integration script has already applied
# the UI. Only repair missing support declarations and accidental duplicates.
required_imports = [
    "import 'package:shared_preferences/shared_preferences.dart';",
    "import 'package:flutter_map/flutter_map.dart';",
    "import 'package:latlong2/latlong.dart';",
    "import 'package:url_launcher/url_launcher.dart';",
]
anchor = "import 'package:geolocator/geolocator.dart';"
for imp in required_imports:
    if imp not in s:
        if anchor in s:
            s = s.replace(anchor, anchor + '\n' + imp, 1)
        else:
            s = imp + '\n' + s
        anchor = imp

# The category page may reference this map. Define it once if absent.
if 'aghinouCategoryIcons' not in s:
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
    if marker in s:
        s = s.replace(marker, helper + marker, 1)

# Remove duplicate _categoryColor declarations, retaining the first.
def_re = re.compile(r"\n?Color _categoryColor\(String name\) \{.*?\n\}\n", re.S)
matches = list(def_re.finditer(s))
if len(matches) > 1:
    first_end = matches[0].end()
    parts = [s[:first_end]]
    cursor = first_end
    for m in matches[1:]:
        parts.append(s[cursor:m.start()])
        cursor = m.end()
    parts.append(s[cursor:])
    s = ''.join(parts)

# Remove duplicate CityPicker declarations while retaining the first one.
starts = [m.start() for m in re.finditer(r'class CityPicker extends StatefulWidget \{', s)]
if len(starts) > 1:
    second = starts[1]
    next_class = s.find('\nclass ', second + 1)
    if next_class == -1:
        next_class = len(s)
    s = s[:second] + s[next_class:]

# Keep uploads reasonably sized for mobile/storage reliability.
s = s.replace('picker.pickMultiImage(imageQuality: 85)', 'picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)')
s = s.replace('_picker.pickMultiImage(imageQuality: 85)', '_picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)')

p.write_text(s, encoding='utf-8')
print('Final Aghinou polish applied safely.')
