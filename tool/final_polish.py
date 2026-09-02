from pathlib import Path
import re

p = Path('lib/main.dart')
s = p.read_text(encoding='utf-8')

# The integrated UI script already owns the major transformations. This final pass
# is intentionally idempotent: it only adds missing support code and normalizes
# accidental duplicate declarations so the build can safely run both scripts.

# Required imports (add only when missing).
imports = [
    "import 'package:shared_preferences/shared_preferences.dart';",
    "import 'package:flutter_map/flutter_map.dart';",
    "import 'package:latlong2/latlong.dart';",
    "import 'package:url_launcher/url_launcher.dart';",
]
anchor = "import 'package:geolocator/geolocator.dart';"
for imp in imports:
    if imp not in s:
        if anchor in s:
            s = s.replace(anchor, anchor + '\n' + imp, 1)
        else:
            s = imp + '\n' + s
        anchor = imp

# Category icons are referenced by the Carousell category page. Add them once.
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

# Keep exactly one _categoryColor declaration. The integrated script is the
# canonical source; if an earlier/later pass duplicated it, remove later copies.
def_block = re.compile(r"\n?Color _categoryColor\(String name\) \{.*?\n\}\n", re.S)
matches = list(def_block.finditer(s))
if len(matches) > 1:
    keep = matches[0].group(0)
    out = []
    last = 0
    for i, m in enumerate(matches):
        if i == 0:
            out.append(s[last:m.end()])
        else:
            out.append(s[last:m.start()])
        last = m.end()
    out.append(s[last:])
    s = ''.join(out)

# If there is more than one CityPicker declaration, keep the first complete
# declaration and remove later copies. Do not rewrite the picker here because
# integrate_carousell_ui.py already provides the searchable implementation.
starts = [m.start() for m in re.finditer(r'class CityPicker extends StatefulWidget \{', s)]
if len(starts) > 1:
    first = starts[0]
    second = starts[1]
    next_class = s.find('\nclass ', second + 1)
    if next_class == -1:
        next_class = len(s)
    # Remove the later CityPicker block only; preserve everything after it.
    s = s[:second] + s[next_class:]

# Reduce selected-image memory/transfer size when the picker call is present.
s = s.replace(
    'picker.pickMultiImage(imageQuality: 85)',
    'picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)'
)
s = s.replace(
    '_picker.pickMultiImage(imageQuality: 85)',
    '_picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)'
)

p.write_text(s, encoding='utf-8')
print('Final Aghinou polish applied safely.')
