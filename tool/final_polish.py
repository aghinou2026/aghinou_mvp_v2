from pathlib import Path

p = Path('lib/main.dart')
s = p.read_text(encoding='utf-8')

# Structural UI declarations are owned by integrate_carousell_ui.py.
# Keep this final pass deliberately non-destructive: do not rewrite category
# pages, icon maps, color helpers, authentication, or other declarations.

# Keep image uploads reasonably sized for mobile/storage reliability.
s = s.replace(
    'picker.pickMultiImage(imageQuality: 85)',
    'picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)',
)
s = s.replace(
    '_picker.pickMultiImage(imageQuality: 85)',
    '_picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)',
)

p.write_text(s, encoding='utf-8')
print('Final Aghinou polish applied without structural declaration rewrites.')
