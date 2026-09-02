from pathlib import Path
import re

p = Path('lib/main.dart')
s = p.read_text(encoding='utf-8')

# Structural UI declarations are owned by integrate_carousell_ui.py.
# Do not remove/recreate category helpers here: the integration pass has already
# resolved them and the base app may already provide _categoryColor.

# Ensure exactly one generated category icon map exists. If integration already
# created it, leave it alone; otherwise add it before categoryNames.
icon_map = """const Map<String, IconData> aghinouCategoryIcons = <String, IconData>{
  'خودرو': Icons.directions_car_rounded,
  'املاک': Icons.home_work_rounded,
  'موبایل': Icons.phone_iphone_rounded,
  'لوازم خانه': Icons.chair_rounded,
  'کالای دیجیتال': Icons.devices_rounded,
  'پوشاک': Icons.checkroom_rounded,
  'خدمات': Icons.handyman_rounded,
};
"""
marker = "const categoryNames = ['همه', 'خودرو', 'املاک', 'موبایل', 'لوازم خانه', 'کالای دیجیتال', 'پوشاک', 'خدمات'];"
if marker in s and not re.search(r'\bconst\s+Map<String,\s*IconData>\s+aghinouCategoryIcons\s*=', s):
    s = s.replace(marker, icon_map + '\n' + marker, 1)

# Keep uploads reasonably sized for mobile/storage reliability.
s = s.replace(
    'picker.pickMultiImage(imageQuality: 85)',
    'picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)',
)
s = s.replace(
    '_picker.pickMultiImage(imageQuality: 85)',
    '_picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)',
)

p.write_text(s, encoding='utf-8')
print('Final Aghinou polish applied without destructive declaration rewrites.')
