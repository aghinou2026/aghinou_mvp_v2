from pathlib import Path
import hashlib

path = Path('lib/main.dart')
s = path.read_text(encoding='utf-8')

# Keep the authentication path byte-for-byte unchanged while applying only the
# small card/grid presentation adjustments planned for the Build 112 baseline.
login_start = s.index('class LoginPage')
intro_start = s.index('class IntroPage')
login_before = s[login_start:intro_start]
login_hash_before = hashlib.sha256(login_before.encode('utf-8')).hexdigest()

replacements = [
    (
        "cardTheme: CardThemeData(elevation: 3, margin: const EdgeInsets.only(bottom: 12),",
        "cardTheme: CardThemeData(elevation: 2, margin: const EdgeInsets.only(bottom: 16),",
        'card theme spacing/elevation',
    ),
    (
        "ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),",
        "ListView(padding:const EdgeInsets.fromLTRB(18,12,18,100),",
        'home horizontal padding',
    ),
    (
        "crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:.72",
        "crossAxisCount:2,crossAxisSpacing:14,mainAxisSpacing:16,childAspectRatio:.75",
        'ad grid spacing and compactness',
    ),
]

for old, new, label in replacements:
    count = s.count(old)
    if count != 1:
        raise SystemExit(f'Expected exactly one occurrence for {label}, found {count}. Aborting without changes.')
    s = s.replace(old, new)

login_after = s[login_start:intro_start]
login_hash_after = hashlib.sha256(login_after.encode('utf-8')).hexdigest()
if login_hash_before != login_hash_after:
    raise SystemExit('SAFETY CHECK FAILED: LoginPage changed.')

if 'force_final_ui.py' in s or 'tool/force_final_ui.py' in s:
    raise SystemExit('SAFETY CHECK FAILED: force_final_ui must not be used.')

path.write_text(s, encoding='utf-8')
print('Safe UI step 1 applied.')
print('Changed: card spacing/elevation + home grid spacing/compactness.')
print('LoginPage hash unchanged:', login_hash_after)
