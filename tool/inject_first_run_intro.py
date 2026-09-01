from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')

if "package:shared_preferences/shared_preferences.dart" not in text:
    text = text.replace(
        "import 'package:supabase_flutter/supabase_flutter.dart';",
        "import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'package:shared_preferences/shared_preferences.dart';",
        1,
    )

old_nav = "      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));"
new_nav = """      final prefs = await SharedPreferences.getInstance();
      final seenIntro = prefs.getBool('aghinou_first_run_intro_seen') ?? false;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => seenIntro ? const HomePage() : const IntroPage(),
          ),
        );
      }"""
if old_nav in text and "aghinou_first_run_intro_seen" not in text:
    text = text.replace(old_nav, new_nav, 1)

marker = "const categoryNames = ['همه', 'خودرو', 'املاک', 'موبایل', 'لوازم خانه', 'کالای دیجیتال', 'پوشاک', 'خدمات'];"
intro = r'''class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  Future<void> continueToHome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aghinou_first_run_intro_seen', true);
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  Future<void> showSubscriptionInfo(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اشتراک آگهینو'),
        content: const Text(
          'اشتراک ثبت آگهی ماهانه ۳۵٬۰۰۰ تومان است.\n\n'
          'مشاهده و جستجوی آگهی‌ها کاملاً رایگان است.\n'
          'پرداخت فقط برای فعال‌کردن امکان ثبت آگهی انجام می‌شود.',
          style: TextStyle(fontSize: 17, height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قبل از شروع')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Column(
                children: [
                  Icon(Icons.storefront_rounded, size: 62),
                  SizedBox(height: 12),
                  Text('به آگهینو خوش آمدید', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('خرید و فروش ساده و سریع', style: TextStyle(fontSize: 17)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.visibility_outlined)),
                title: const Text('مشاهده آگهی‌ها رایگان است', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('جستجو، مشاهده جزئیات و دیدن عکس‌های آگهی‌ها بدون پرداخت هزینه انجام می‌شود.'),
              ),
            ),
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.campaign_outlined)),
                title: const Text('ثبت آگهی با اشتراک ماهانه', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('برای ثبت آگهی، اشتراک ماهانه ۳۵٬۰۰۰ تومان لازم است.'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'نکته: لازم نیست برای ورود یا مشاهده آگهی‌ها اشتراک بخرید؛ هزینه فقط زمانی مطرح می‌شود که بخواهید آگهی ثبت کنید.',
                  style: TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => showSubscriptionInfo(context),
                icon: const Icon(Icons.credit_card_outlined),
                label: const Text('خرید اشتراک ۳۵٬۰۰۰ تومان'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => continueToHome(context),
                child: const Text('ادامه بدون اشتراک'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

'''
if marker in text and "class IntroPage extends StatelessWidget" not in text:
    text = text.replace(marker, intro + marker, 1)

path.write_text(text, encoding='utf-8')
print('First-run intro patch applied.')
