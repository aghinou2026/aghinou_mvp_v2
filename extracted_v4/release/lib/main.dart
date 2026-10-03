import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const String supabaseUrl = 'https://acfawprpdkzjpyblseay.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_uHov32wG1uTxNIkbQbaQmQ_6W5mCwKf';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const AghinouApp());
}

final supabase = Supabase.instance.client;

const String currentTermsVersion = '1.0';
const String termsTitle = 'قوانین و مقررات آگهینو';
const List<String> aghinouTerms = ['آگهینو بستری برای انتشار آگهی و ارتباط میان کاربران است و طرف معامله میان خریدار و فروشنده نیست.','مسئولیت صحت اطلاعات، قیمت، تصاویر و توضیحات هر آگهی بر عهده آگهی‌دهنده است.','انتشار کالا، خدمات یا فعالیت‌های غیرقانونی یا فاقد مجوز لازم ممنوع است.','کلاهبرداری، فریب، جعل هویت، کالای سرقتی یا تقلبی و اطلاعات گمراه‌کننده ممنوع است.','محتوای توهین‌آمیز، تهدیدآمیز، خشونت‌آمیز یا ناقض حقوق دیگران ممنوع است.','انتشار محتوایی که حقوق مالکیت فکری یا حقوق اشخاص دیگر را نقض کند ممنوع است.','آگهی‌دهنده باید مشخصات کالا یا خدمت را صادقانه، دقیق و روشن اعلام کند.','کاربران نباید رمز، کد تأیید بانکی یا اطلاعات حساس خود را در اختیار افراد ناشناس قرار دهند.','انجام معامله، پرداخت وجه، بررسی کالا و هویت طرف مقابل بر عهده خود کاربران است و آگهینو تضمین‌کننده معامله میان کاربران نیست.','آگهینو می‌تواند آگهی‌های مغایر با قوانین یا مقررات داخلی برنامه را حذف یا از انتشار آنها جلوگیری کند.','کاربران می‌توانند آگهی‌های مشکوک یا مغایر با قوانین را گزارش کنند.','هر کاربر مسئول فعالیت‌هایی است که با حساب خودش انجام می‌دهد و نباید حساب خود را در اختیار دیگران قرار دهد.','قوانین ممکن است به‌روزرسانی شوند و نسخه جدید آنها از طریق برنامه منتشر خواهد شد.'];


const Map<String, List<String>> iranProvinceCities = {"اردبيل":["اصلاندوز","آبی بیگلو","بیله سوار","پارس آباد","تازه کند","تازه کندانگوت","جعفرآباد","خلخال","رضی","سرعین","عنبران","فخرآباد","کلور","کوراییم","گرمی","گیوی","لاهرود","مرادلو","مشگین شهر","نمین","نیر","هشتجین","هیر"],"اصفهان":["ابریشم","ابوزیدآباد","اردستان","اژیه","اصفهان","افوس","انارک","ایمانشهر","آران وبیدگل","بادرود","باغ بهادران","بافران","برزک","برف انبار","بوئین ومیاندشت","بهاران شهر","بهارستان","پیربکران","تودشک","تیران","جندق","جوزدان","جوشقان وکامو","چادگان","چرمهین","چمگردان","حبیب آباد","حسن آباد","حنا","خالدآباد","خمینی شهر","خوانسار","خور","خوراسگان","خورزوق","داران","دامنه","درچه پیاز","دستگرد","دولت آباد","دهاقان","دهق","دیزیچه","رزوه","رضوانشهر","زاینده رود","زرین شهر","زواره","زیباشهر","سده لنجان","سفیدشهر","سگزی","سمیرم","شاپورآباد","شاهین شهر","شهرضا","طالخونچه","عسگران","علویچه","فرخی","فریدونشهر","فلاورجان","فولادشهر","قمصر","قهجاورستان","قهدریجان","کاشان","کرکوند","کلیشادوسودرجان","کمشچه","کمه","کوشک","کوهپايه","کهریزسنگ","گرگاب","گزبرخوار","گلپایگان","گلدشت","گلشن","گلشهر","گوگد","لای بید","مبارکه","محمدآباد","مشکات","منظریه","مهاباد","میمه","نائین","نجف آباد","نصرآباد","نطنز","نوش آباد","نیاسر","نیک آباد","ورزنه","ورنامخواست","وزوان","ونک","هرند"],"البرز":["اشتهارد","آسارا","تنکمان","چهارباغ","سیف آباد","شهرجدید هشتگرد","طالقان","کرج","کمال شهر","کوهسار","گرمدره","ماهدشت","محمدشهر","مشكين دشت","نظرآباد","هشتگرد"],"ايلام":["ارکواز","ایلام","ایوان","آبدانان","آسمان آباد","بدره","پهله","توحید","چوار","دره شهر","دلگشا","دهلران","زرنه","سراب باغ","سرابله","صالح آباد","لومار","مورموری","موسیان","مهران","میمه"],"آذربايجان شرقي":["اسکو","اهر","ايلخچی","آبش احمد","آذرشهر","آقکند","باسمنج","بخشایش","بستان آباد","بناب","بناب جدید","تبریز","ترک","ترکمانچای","تسوج","تيكمه داش","جلفا","خاروانا","خامنه","خراجو","خسروشهر","خمارلو","خواجه","دوزدوزان","زرنق","زنوز","سراب","سردرود","سيس","سيه رود","شبستر","شربيان","شرفخانه","شندآباد","شهرجدیدسهند","صوفيان","عجب شير","قره آغاج","كشكسرای","كلوانق","كليبر","كوزه كنان","گوگان","ليلان","مراغه","مرند","ملكان","ممقان","مهربان","ميانه","نظركهريزي","وايقان","ورزقان","هاديشهر","هريس","هشترود","هوراند","يامچی"],"آذربايجان غربي":["ارومیه","اشنویه","ایواوغلی","آواجیق","باروق","بازرگان","بوکان","پلدشت","پیرانشهر","تازه شهر","تکاب","چهاربرج","خلیفان","خوی","دیزج دیز","ربط","سردشت","سرو","سلماس","سیلوانه","سیمینه","سیه چشمه","شاهین دژ","شوط","فیرورق","قره ضیاءالدین","قطور","قوشچی","کشاورز","گردکشانه","ماکو","محمدیار","محمودآباد","مهاباد","میاندوآب","میرآباد","نالوس","نقده","نوشین"],"بوشهر":["امام حسن","انارستان","اهرم","آبپخش","آبدان","برازجان","بردخون","بردستان","بندردير","بندرديلم","بندرريگ","بندركنگان","بندرگناوه","بنک","بوشهر","تنگ ارم","جم","چغادک","خارک","خورموج","دالکی","دلوار","ریز","سعدآباد","سیراف","شبانکاره","شنبه","عسلویه","کاکی","کلمه","نخل تقی","وحدتیه"],"تهران":["ارجمند","اسلامشهر","انديشه","آبسرد","آبعلي","باغستان","باقرشهر","بومهن","پاكدشت","پرديس","پيشوا","تجريش","تهران","جوادآباد","چهاردانگه","حسن آباد","دماوند","رباط كريم","رودهن","ري","شاهدشهر","شريف آباد","شهريار","صالح آباد","صباشهر","صفادشت","فردوسيه","فرون آباد","فشم","فيروزكوه","قدس","قرچك","كهريزك","كيلان","گلستان","لواسان","ملارد","نسيم شهر","نصيرآباد","وحيديه","ورامين"],"چهارمحال و بختياري":["اردل","آلونی","باباحیدر","بروجن","بلداجی","بن","جونقان","چلگرد","سامان","سفیددشت","سودجان","سورشجان","شلمزار","شهرکرد","طاقانک","فارسان","فرادنبه","فرخ شهر","کیان","گندمان","گهرو","لردگان","مال خلیفه","ناغان","نافچ","نقنه","هفشجان"],"خراسان جنوبي":["ارسک","اسديه","اسفدن","اسلاميه","آرين شهر","آیسک","بشرويه","بيرجند","حاجي آباد","خضري دشت بياض","خوسف","زهان","سرايان","سربيشه","سه قلعه","شوسف","طبس مسينا","فردوس","قائن","قهستان","گزیک","محمد شهر","مود","نهبندان","نیمبلوک"],"خراسان رضوي":["احمد‌آبادصولت","انابد","باجگیران","باخرز","بار","بایگ","بجستان","بردسکن","بیدخت","تایباد","تربت جام","تربت حیدریه","جغتای","جنگل","چاپشلو","چکنه","چناران","خرو","خلیل‌آباد","خواف","داورزن","درگز","درود","دولت‌آباد","رباط سنگ","رشتخوار","رضویه","روداب","ریوش","سبزوار","سرخس","سفیدسنگ","سلامی","سلطان‌آباد","سنگان","شادمهر","شاندیز","ششتمد","شهرآباد","شهرزو","صالح‌آباد","طرقبه","عشق‌آباد","فرهادگرد","فریمان","فیروزه","فیض‌آباد","قاسم‌آباد","قدمگاه","قلندرآباد","قوچان","کاخک","کاریز","کاشمر","کدکن","کلات","کندر","گلمکان","گناباد","لطف‌آباد","مزدآوند","مشهد","مشهدریزه","ملک‌آباد","نشتیفان","نصرآباد","نقاب","نوخندان","نیشابور","نیل‌شهر","همت‌آباد","یونسی"],"خراسان شمالي":["اسفراين","ايور","آشخانه","بجنورد","پيش قلعه","تيتكانلو","جاجرم","حصارگرمخان","درق","راز","سنخواست","شوقان","شيروان","صفي آباد","فاروج","قاضي","گرمه","لوجلی"],"خوزستان":["اروندکنار","الوان","امیدیه","اندیمشک","اهواز","ایذه","آبادان","آغاجاری","باغ ملک","بستان","بندرامام خمینی","بندرماهشهر","بهبهان","ترکالکی","جایزان","جنت مکان","چغامیش","چمران","چوئبده","حر","حسینیه","حمزه","حمیدیه","خرمشهر","دارخوین","دزآب","دزفول","دهدز","رامشیر","رامهرمز","رفیع","زهره","سالند","سردشت","سماله","سوسنگرد","شادگان","شاوور","شرافت","شوش","شوشتر","شیبان","صالح‌شهر","صالح مشطط","صفی‌آباد","صیدون","قلعه‌تل","قلعه‌خواجه","گتوند","گوریه","لالی","مسجدسلیمان","مشراگه","مقاومت","ملاثانی","میانرود","میداود","مینوشهر","ویس","هفتگل","هندیجان","هویزه"],"زنجان":["ابهر","ارمغانخانه","آب بر","چورزق","حلب","خرمدره","دندی","زرین آباد","زرین رود","زنجان","سجاس","سلطانیه","سهرورد","صائین قلعه","قیدار","گرماب","ماه نشان","هیدج"],"سمنان":["امیریه","ایوانکی","آرادان","بسطام","بیارجمند","دامغان","درجزین","دیباج","سرخه","سمنان","شاهرود","شهمیرزاد","کلاته خیج","گرمسار","مجن","مهدی شهر","میامی"],"سيستان وبلوچستان":["ادیمی","اسپکه","ایرانشهر","بزمان","بمپور","بنت","بنجار","پیشین","جالق","چاه بهار","خاش","دوست محمد","راسک","زابل","زابلی","زاهدان","زرآباد","زهک","سراوان","سرباز","سوران","سیرکان","علی اکبر","فنوج","قصرقند","کنارک","گشت","گلمورتی","محمدان","محمد آباد","محمدی","میرجاوه","نصرت آباد","نگور","نوک آباد","نیک شهر","هیدوج"],"فارس":["اردکان","ارسنجان","استهبان","اسیر","اشکنان","افزر","اقلید","امام شهر","اوز","اهل","ایج","ایزدخواست","آباده","آباده طشک","باب انار","بالاده","بنارویه","بوانات","بهمن","بیرم","بیضا","جنت شهر","جویم","جهرم","حاجی آباد","حسامی","حسن آباد","خانه زنیان","خاوران","خرامه","خشت","خنج","خور","خومه زار","داراب","داریان","دبیران","دژکرد","دوبرجی","دوزه","دهرم","رامجرد","رونیز","زاهدشهر","زرقان","سده","سروستان","سعادت شهر","سورمق","سیدان","ششده","شهر جدید صدرا","شهرپیر","شیراز","صغاد","صفاشهر","علامرودشت","عمادده","فدامی","فراشبند","فسا","فیروزآباد","قادرآباد","قائمیه","قطب آباد","قطرویه","قیر","کارزین","کازرون","کامفیروز","کره ای","کنارتخته","کوار","کوهنجان","گراش","گله دار","لار","لامرد","لپوئی","لطیفی","مبارک آباد","مرودشت","مشکان","مصیری","مهر","میمند","نوبندگان","نوجین","نودان","نورآباد","نی ریز","وراوی","هماشهر"],"قزوين":["ارداق","اسفرورین","اقبالیه","الوند","آبگرم","آبیک","آوج","بوئین زهرا","بیدستان","تاکستان","خاکعلی","خرمدشت","دانسفهان","رازمیان","سگزآباد","سیردان","شال","شریفیه","ضیاءآباد","قزوین","کوهین","محمدیه","محمودآبادنمونه","معلم کلايه","نرجه"],"قم":["جعفریه","دستجرد","سلفچگان","قم","قنوات","کهک"],"كردستان":["آرمرده","بابارشانی","بانه","بلبان آباد","بوئین سفلی","بیجار","چناره","دزج","دلبران","دهگلان","دیواندره","زرینه","سروآباد","سریش آباد","سقز","سنندج","شویشه","صاحب","قروه","کامیاران","کانی دینار","کانی سور","مریوان","موچش","یاسوکند"],"کرمان":["اختیارآباد","ارزوئیه","امین شهر","انار","اندوهجرد","باغین","بافت","بردسیر","بروات","بزنجان","بم","بهرمان","پاریز","جبالبارز","جوپار","جوزم","جیرفت","چترود","خاتون آباد","خانوک","خورسند","درب بهشت","دوساری","دهج","رابر","راور","راین","رفسنجان","رودبار","ریحان شهر","زرند","زنگی آباد","زیدآباد","سرچشمه","سیرجان","شهداد","شهربابک","صفائیه","عنبرآباد","فاریاب","فهرج","قلعه گنج","کاظم آباد","کرمان","کشکوئیه","کوهبنان","کهنوج","کیانشهر","گلباف","گلزار","لاله زار","ماهان","محمد آباد","محی آباد","مردهک","منوجان","نجف شهر","نرماشیر","نظام شهر","نگار","نودژ","هجدک","هماشهر","یزدان شهر"],"کرمانشاه":["ازگله","اسلام‌آبادغرب","باینگان","بیستون","پاوه","تازه‌آباد","جوانرود","حمیل","رباط","روانسر","سرپل‌ذهاب","سرمست","سطر","سنقر","سومار","شاهو","صحنه","قصرشیرین","کرمانشاه","کرندغرب","کنگاور","کوزران","گهواره","گیلان غرب","میان‌راهان","نودشه","نوسود","هرسین","هلشی"],"کهگلویه و بويراحمد":["باشت","پاتاوه","چرام","چیتاب","دوگنبدان","دهدشت","دیشموک","سوق","سی‌سخت","قلعه‌رئیسی","گراب‌سفلی","لنده","لیکک","مادوان","مارگون","یاسوج"],"گلستان":["انبارآلوم","اینچه برون","آزادشهر","آق‌قلا","بندرگز","ترکمن","جلین","خان‌ببین","دلند","رامیان","سرخنکلاته","سیمین‌شهر","علی‌آباد","فاضل‌آباد","کردکوی","کلاله","گالیکش","گرگان","گمیش‌تپه","گنبدکاووس","مراوه‌تپه","مینودشت","نگین‌شهر","نوده‌خاندوز"],"گيلان":["احمدسرگوراب","اسالم","اطاقور","املش","آستارا","آستانه اشرفیه","بازارجمعه","بره سر","بندرانزلی","پره سر","توتکابن","جیرنده","چابکسر","چاف وچمخاله","چوبر","حویق","خشکبیجار","خمام","دیلمان","رانکوه","رحیم آباد","رستم آباد","رشت","رضوانشهر","رودبار","رودبنه","رودسر","سنگر","سیاهکل","شفت","شلمان","صومعه سرا","فومن","کلاچای","کوچصفهان","کومله","کیاشهر","گوراب زرمیخ","لاهیجان","لشت نشاء","لنگرود","لوشان","لولمان","لوندویل","لیسار","ماسال","ماسوله","مرجقل","منجیل","واجارگاه","هشتپر"],"لرستان":["ازنا","اشترینان","الشتر","الیگودرز","بروجرد","پلدختر","چالانچولان","چغلوندی","چقابل","خرم آباد","درب گنبد","دورود","زاغه","سپیددشت","سراب دوره","شول آباد","فیروز آباد","کونانی","کوهدشت","گراب","معمولان","مؤمن آباد","نور آباد","ویسیان","هفت چشمه"],"مازندران":["امیرکلا","ایزدشهر","آلاشت","آمل","بابل","بابلسر","بلده","بهشهر","بهنمیر","پل سفید","پول","تنکابن","جویبار","چالوس","چمستان","خرم آباد","خلیل شهر","خوش رودپی","دابودشت","رامسر","رستمکلا","رویان","رینه","زرگر محله","زیرآب","ساری","سرخرود","سلمان شهر","سورک","شیرگاه","شیرود","عباس آباد","فریدونکنار","فریم","قائم شهر","کتالم وسادات شهر","کلارآباد","کلاردشت","کله بست","کوهی خیل","کیاسر","کیاکلا","گتاب","گزنک","گلوگاه","محمود آباد","مرزن آباد","مرزیکلا","نشتارود","نکا","نور"],"مركزي":["اراک","آستانه","آشتیان","پرندک","تفرش","توره","جاورسیان","خشکرود","خمین","خنداب","داودآباد","دلیجان","رازقان","زاویه","ساروق","ساوه","سنجان","شازند","شهرجدیدمهاجران","غرق آباد","فرمهین","قورچی باشی","کرهرود","کمیجان","مأمونیه","محلات","میلاجرد","نراق","نوبران","نیمور","هندودر"],"هرمزگان":["ابوموسی","بستک","بندرجاسک","بندرچارک","بندرعباس","بندرلنگه","بیکاه","پارسیان","تخت","جناح","حاجی آباد","خمیر","درگهان","دهبارز","رویدر","زیارتعلی","سردشت بشاگرد","سرگز","سندرک","سوزا","سیریک","فارغان","فین","قشم","قلعه قاضی","کنگ","کوشکنار","کیش","گوهران","میناب","هرمز","هشتبندی"],"همدان":["ازندریان","اسدآباد","برزول","بهار","تویسرکان","جورقان","جوکار","دمق","رزن","زنگنه","سامن","سرکان","شیرین سو","صالح آباد","فامنین","فرسفج","فیروزان","قروه در جزین","قهاوند","کبودرآهنگ","گل تپه","گیان","لالجین","مریانج","ملایر","نهاوند","همدان"],"يزد":["ابرکوه","احمدآباد","اردکان","اشکذر","بافق","بفروئیه","بهاباد","تفت","حمیدیا","خضرآباد","دیهوک","زارچ","شاهدیه","طبس","عشق‌آباد","عقدا","مروست","مهردشت","مهریز","میبد","ندوشن","نیر","هرات","یزد"]};

class AghinouApp extends StatelessWidget {
  const AghinouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'آگهینو',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'sans',
        scaffoldBackgroundColor: const Color(0xFFEEF8F8),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF006D77),
          onPrimary: Colors.white,
          secondary: Color(0xFF0A9396),
          onSecondary: Colors.white,
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF17212B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE1F3F3),
          foregroundColor: Color(0xFF17212B),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFD7F0F1),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      home: supabase.auth.currentSession == null ? const LoginPage() : const HomePage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController(); final lastName = TextEditingController();
  bool loading = false; bool registerMode = false; bool acceptedTerms = false;

  @override
  void dispose() {
    phone.dispose(); password.dispose(); firstName.dispose(); lastName.dispose();
    super.dispose();
  }

  String normalized() {
    var v = phone.text.trim()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      v = v.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }
    if (v.startsWith('0098')) v = '+98' + v.substring(4);
    if (v.startsWith('98') && !v.startsWith('+')) v = '+$v';
    if (v.startsWith('0')) v = '+98' + v.substring(1);
    return v;
  }

  String authEmailForPhone(String normalizedPhone) {
    final digits = normalizedPhone.replaceAll('+', '');
    return 'u$digits@aghinou.app';
  }

  String authErrorMessage(AuthException e, {bool registerMode = false}) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'شماره موبایل یا رمز ورود نادرست است. شماره و رمز را بررسی کنید.';
    }
    if (m.contains('user already registered') || m.contains('already registered')) {
      return 'این شماره قبلاً ثبت شده است. از بخش «ورود» با رمز همان حساب استفاده کنید.';
    }
    if (m.contains('password') && m.contains('6')) {
      return 'رمز ورود باید حداقل ۶ کاراکتر باشد.';
    }
    if (m.contains('email not confirmed') || m.contains('phone not confirmed')) {
      return 'تأیید ایمیل در Supabase باید خاموش باشد تا ثبت‌نام بدون کد انجام شود.';
    }
    return (registerMode ? 'ثبت‌نام: ' : 'ورود: ') + e.message;
  }

  Future<void> login() async {
    final v = normalized();
    final p = password.text;
    if (!RegExp(r'^\+98\d{10}$').hasMatch(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل را صحیح وارد کنید.')),
      );
      return;
    }
    if (p.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز ورود باید حداقل ۶ کاراکتر باشد.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final r = await supabase.auth.signInWithPassword(email: authEmailForPhone(v), password: p);
      final u = r.user;
      if (u == null) throw Exception('ورود انجام نشد.');
      // ورود باید به‌خاطر خطای جانبی جدول پروفایل شکست نخورد.
      // احراز هویت با Supabase انجام شده؛ همگام‌سازی پروفایل جداگانه است.
      try {
        final existing = await supabase.from('profiles').select('iidd').eq('iidd',u.id).maybeSingle();
        if (existing == null) {
          await supabase.from('profiles').insert({
            'iidd': u.id,
            'cphone': v,
            'name': 'کاربر آگهینو',
          });
        } else {
          await supabase.from('profiles').update({'cphone': v}).eq('iidd',u.id);
        }
      } catch (_) {
        // RLS/profile sync must never block a successful login.
      }
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ورود انجام نشد: ${e}')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> register() async {
    final v=normalized(), p=password.text, fn=firstName.text.trim(), ln=lastName.text.trim();
    if(!RegExp(r'^\+98\d{10}$').hasMatch(v)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره موبایل را صحیح وارد کنید.')));return;}
    if(fn.isEmpty||ln.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('نام و نام خانوادگی را وارد کنید.')));return;}
    if(p.length<6){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('رمز ورود باید حداقل ۶ کاراکتر باشد.')));return;}
    if(!acceptedTerms){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('برای ساخت حساب باید قوانین و مقررات آگهینو را بپذیرید.')));return;}
    setState(()=>loading=true);
    try{
      final r=await supabase.auth.signUp(email:authEmailForPhone(v),password:p); final u=r.user;
      if(u==null)throw Exception('ساخت حساب انجام نشد.'); if(r.session==null)throw Exception('حساب ساخته شد، اما تأیید ایمیل فعال است.');
      await supabase.from('profiles').upsert({'iidd':u.id,'cphone':v,'first_name':fn,'last_name':ln,'name':'$fn $ln','accepted_terms_version':currentTermsVersion,'accepted_terms_at':DateTime.now().toUtc().toIso8601String()},onConflict:'iidd');
      if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomePage()));
    }on AuthException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(authErrorMessage(e,registerMode:true))));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت‌نام انجام نشد: $e')));}
    finally{if(mounted)setState(()=>loading=false);}
  }

  @override
  Widget build(BuildContext c) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF006D77), Color(0xFF0A9396)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 46, color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text('آگهینو', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF17212B))),
                const SizedBox(height: 6),
                Text(registerMode ? 'ساخت حساب جدید' : 'بازار ساده، امن و حرفه‌ای', style: const TextStyle(color: Color(0xFF60727A), fontSize: 14)),
                const SizedBox(height: 30),
                if (registerMode) ...[
                  TextField(controller: firstName, decoration: const InputDecoration(labelText: 'نام', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: lastName, decoration: const InputDecoration(labelText: 'نام خانوادگی', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                ],
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل', hintText: '09121234567', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'رمز ورود', hintText: 'حداقل ۶ کاراکتر', border: OutlineInputBorder())),
                if (registerMode) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(value: acceptedTerms, onChanged: loading ? null : (v) => setState(() => acceptedTerms = v == true)),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                children: [
                                  const Text('قوانین و مقررات آگهینو را مطالعه کرده‌ام و می‌پذیرم. '),
                                  InkWell(
                                    onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const TermsPage())),
                                    child: const Text('مشاهده قوانین', style: TextStyle(color: Color(0xFF006D77), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : (registerMode ? register : login),
                    child: Text(loading ? (registerMode ? 'در حال ساخت حساب...' : 'در حال ورود...') : (registerMode ? 'ساخت حساب' : 'ورود')),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: loading ? null : () => setState(() => registerMode = !registerMode),
                    child: Text(registerMode ? 'بازگشت به ورود' : 'ساخت حساب جدید'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text(termsTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نسخه 1.0', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006D77))),
                    const SizedBox(height: 12),
                    ...List.generate(
                      aghinouTerms.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text((i + 1).toString() + '. ' + aghinouTerms[i], style: const TextStyle(height: 1.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, IconData> aghinouCategoryIcons = {
  'خودرو': Icons.directions_car_filled_outlined,
  'املاک': Icons.home_work_outlined,
  'موبایل و تبلت': Icons.phone_android_outlined,
  'لوازم دیجیتال': Icons.devices_other_outlined,
  'لوازم خانگی': Icons.kitchen_outlined,
  'مبلمان و دکوراسیون': Icons.chair_outlined,
  'پوشاک و کیف و کفش': Icons.checkroom_outlined,
  'وسایل نقلیه': Icons.pedal_bike_outlined,
  'خدمات': Icons.handyman_outlined,
  'استخدام و کاریابی': Icons.work_outline,
  'لوازم شخصی': Icons.watch_outlined,
  'سرگرمی و ورزش': Icons.sports_soccer_outlined,
  'کشاورزی و دامداری': Icons.agriculture_outlined,
  'ابزار و تجهیزات': Icons.build_outlined,
  'حیوانات': Icons.pets_outlined,
  'سایر': Icons.category_outlined,
};

const Map<String,List<String>> categoryDetailFields = {
  'خودرو':['برند','مدل','سال ساخت','کارکرد (کیلومتر)','رنگ','گیربکس','وضعیت بدنه','سوخت','معاوضه'],
  'املاک':['متراژ (متر)','تعداد اتاق','طبقه','تعداد طبقات','سال ساخت','پارکینگ','انباری','آسانسور','سند','نوع کاربری'],
  'موبایل و تبلت':['برند','مدل','حافظه داخلی','رم','رنگ','وضعیت باتری','گارانتی','رجیستری','دو سیم‌کارت'],
  'لوازم دیجیتال':['برند','مدل','سال تولید','وضعیت','گارانتی','مشخصات فنی'],
  'لوازم خانگی':['برند','مدل','سال تولید','رنگ','وضعیت','گارانتی','مصرف انرژی'],
  'مبلمان و دکوراسیون':['برند/سازنده','جنس','رنگ','ابعاد','تعداد نفرات','وضعیت','سن کالا'],
  'پوشاک و کیف و کفش':['برند','سایز','جنس','رنگ','مناسب برای','وضعیت','کشور سازنده'],
  'وسایل نقلیه':['برند','مدل','سال ساخت','کارکرد','رنگ','وضعیت','سوخت','مشخصات فنی'],
  'خدمات':['نوع خدمت','مدت/زمان انجام','محدوده ارائه','سابقه کار','قیمت پایه','شرایط انجام'],
  'استخدام و کاریابی':['عنوان شغلی','نوع همکاری','سابقه موردنیاز','حقوق','ساعت کاری','محدوده کاری','مزایا'],
  'لوازم شخصی':['برند','مدل','جنس','رنگ','سایز','وضعیت','گارانتی'],
  'سرگرمی و ورزش':['برند/سازنده','مدل','نوع','سن مناسب','وضعیت','لوازم همراه'],
  'کشاورزی و دامداری':['نوع محصول/دام','نژاد/رقم','سن/وزن','مقدار','محل تولید','وضعیت','توضیحات فنی'],
  'ابزار و تجهیزات':['برند','مدل','توان/ظرفیت','سال تولید','وضعیت','گارانتی','لوازم همراه'],
  'حیوانات':['نوع','نژاد','سن','جنسیت','رنگ','وضعیت سلامت','واکسیناسیون','شناسنامه'],
  'سایر':['برند/سازنده','مدل','سال تولید','رنگ','ابعاد','وضعیت','گارانتی','مشخصات تکمیلی'],
};
class HomeCategoryData {
  static const Map<String,List<String>> categorySubs={
    'خودرو':['سواری','شاسی‌بلند','وانت','پیکاپ','موتورسیکلت','کامیون','کامیونت','کشنده','اتوبوس','مینی‌بوس','ون','خودرو کلاسیک','خودرو برقی و هیبریدی','خودرو کار و خدماتی','ماشین‌آلات سنگین'],
    'املاک':['آپارتمان','خانه و ویلا','زمین','مغازه و تجاری'],
    'موبایل و تبلت':['موبایل','تبلت','لوازم جانبی'],
    'لوازم دیجیتال':['لپ‌تاپ','کامپیوتر','تلویزیون','دوربین'],
    'لوازم خانگی':['یخچال و فریزر','لباسشویی','اجاق و گاز','کولر و تهویه'],
    'مبلمان و دکوراسیون':['مبل','میز و صندلی','تخت و سرویس خواب','دکوراسیون'],
    'پوشاک و کیف و کفش':['لباس زنانه','لباس مردانه','کیف','کفش'],
    'وسایل نقلیه':['دوچرخه','قایق','قطعات و لوازم'],
    'خدمات':['فنی و تعمیرات','نظافت','آموزش','حمل و نقل'],
    'استخدام و کاریابی':['تمام‌وقت','پاره‌وقت','دورکاری','کارآموزی'],
    'لوازم شخصی':['ساعت و اکسسوری','زیورآلات','عینک'],
    'سرگرمی و ورزش':['ورزش','کتاب','بازی و کنسول','آلات موسیقی'],
    'کشاورزی و دامداری':['دام','طیور','ماشین‌آلات کشاورزی','محصولات کشاورزی'],
    'ابزار و تجهیزات':['ابزار دستی','ابزار برقی','تجهیزات کارگاهی','تجهیزات ایمنی'],
    'حیوانات':['سگ','گربه','پرندگان','آبزیان'],
    'سایر':['متفرقه'],
  };
  static List<String> subsFor(String category)=>categorySubs[category]??const [];
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loadingAds = true;
  bool loadingSubscription = true;
  bool hasActiveSubscription = false;
  bool isAdmin = false;
  int adsUsed = 0;
  int adLimit = 9;
  DateTime? subscriptionExpiresAt;
  String searchQuery = '';
  String? selectedCategory;
  String? selectedSubcategory;
  String? selectedProvince;
  String? selectedCity;
  Map<String, List<String>> categorySubs = {};
  String sortMode = 'newest';
  int? minPrice;
  int? maxPrice;
  List<String> recentSearches = [];
  List<Map<String, dynamic>> ads = []; String profileFirstName=''; String profileLastName=''; String profilePhone='';

  static const categories = <String>[
    'خودرو','املاک','موبایل و تبلت','لوازم دیجیتال','لوازم خانگی','مبلمان و دکوراسیون','پوشاک و کیف و کفش','وسایل نقلیه','خدمات','استخدام و کاریابی','لوازم شخصی','سرگرمی و ورزش','کشاورزی و دامداری','ابزار و تجهیزات','حیوانات','سایر',
  ];

  @override
  void initState() {
    super.initState();
    loadAds();
    loadCategories();
    loadSubscription();
    loadAdmin(); loadProfile();
  }

  Future<void> loadProfile() async{final uid=supabase.auth.currentUser?.id;if(uid==null)return;try{final p=await supabase.from('profiles').select('first_name,last_name,cphone,name').eq('iidd',uid).maybeSingle();if(!mounted||p==null)return;setState((){profileFirstName=p['first_name']?.toString()??'';profileLastName=p['last_name']?.toString()??'';profilePhone=p['cphone']?.toString()??'';});}catch(_){}}
  Future<void> loadCategories() async {
    try {
      final cats = await supabase.from('categories').select('id,name');
      final subs = await supabase.from('subcategories').select('category_id,name').eq('active', true).order('name');
      final ids = <String, String>{};
      for (final c in cats) { ids[c['id'].toString()] = c['name'].toString(); }
      final map = <String, List<String>>{};
      for (final s in subs) {
        final cat = ids[s['category_id']?.toString() ?? ''] ?? '';
        final name = s['name']?.toString() ?? '';
        if (cat.isNotEmpty && name.isNotEmpty) map.putIfAbsent(cat, () => []).add(name);
      }
      if (mounted) setState(() => categorySubs = map);
    } catch (_) {}
  }

  Future<void> openCategory(String category) async {
    // Prefer database categories, but always fall back to the built-in catalog
    // so a temporary RLS/network issue can never make a category appear empty.
    final dbSubs = categorySubs[category] ?? const <String>[];
    final fallbackSubs = HomeCategoryData.subsFor(category);
    final subs = dbSubs.isNotEmpty ? dbSubs : fallbackSubs;
    setState(() {
      selectedCategory = selectedCategory == category ? null : category;
      selectedSubcategory = null;
    });
    if (subs.isEmpty) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
          Text('زیرمجموعه‌های «$category»', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(leading: const Icon(Icons.apps), title: const Text('همه زیرمجموعه‌ها'), onTap: () => Navigator.pop(context, '')),
          ...subs.map((s) => ListTile(leading: const Icon(Icons.chevron_left), title: Text(s), onTap: () => Navigator.pop(context, s))),
        ])),
      ),
    );
    if (!mounted || chosen == null) return;
    setState(() => selectedSubcategory = chosen.isEmpty ? null : chosen);
  }

  Future<void> loadAdmin() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final result = await supabase.rpc('is_current_user_admin');
      if (mounted) setState(() => isAdmin = result == true);
    } catch (_) {}
  }

  Future<void> loadSubscription() async {
    final uid=supabase.auth.currentUser?.id;
    if(uid==null){if(mounted)setState(()=>loadingSubscription=false);return;}
    try{
      final row=await supabase.from('subscriptions').select('expires_at,ads_used,ad_limit,status').eq('user_id',uid).eq('status','active').gt('expires_at',DateTime.now().toIso8601String()).order('expires_at',ascending:false).limit(1).maybeSingle();
      final expiresRaw=row?['expires_at']?.toString();
      final expires=expiresRaw==null?null:DateTime.tryParse(expiresRaw);
      if(!mounted)return;
      setState((){subscriptionExpiresAt=expires;hasActiveSubscription=expires!=null&&expires.isAfter(DateTime.now());adsUsed=(row?['ads_used'] as num?)?.toInt()??0;adLimit=(row?['ad_limit'] as num?)?.toInt()??9;loadingSubscription=false;});
    }catch(e){if(mounted){setState(()=>loadingSubscription=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('بررسی اشتراک انجام نشد: $e')));}}
  }
  Future<void> loadAds() async {
    try {
      final rows = await supabase
          .from('ads')
          .select('*, ad_images(image_url,sort_order,is_primary)')
          .eq('publish_status', 'published')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        ads = List<Map<String, dynamic>>.from(rows);
        loadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت آگهی‌ها انجام نشد: $e')),
      );
    }
  }

  int get myAdsCount {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    return ads.where((ad) => ad['seller_id'] == uid).length;
  }

  String normalizeFa(String value) {
    return value
        .toLowerCase()
        .replaceAll('ي','ی')
        .replaceAll('ى','ی')
        .replaceAll('ك','ک')
        .replaceAll('ة','ه')
        .replaceAll('ۀ','ه')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .replaceAll('‌',' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String relativeTime(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.isNegative) return 'همین حالا';
    if (diff.inMinutes < 1) return 'همین حالا';
    if (diff.inMinutes < 60) return '\${diff.inMinutes} دقیقه پیش';
    if (diff.inHours < 24) return '\${diff.inHours} ساعت پیش';
    if (diff.inDays < 7) return '\${diff.inDays} روز پیش';
    if (diff.inDays < 30) return '\${(diff.inDays / 7).floor()} هفته پیش';
    if (diff.inDays < 365) return '\${(diff.inDays / 30).floor()} ماه پیش';
    return '\${(diff.inDays / 365).floor()} سال پیش';
  }

  List<Map<String, dynamic>> get filteredAds {
    final q = normalizeFa(searchQuery);
    final result = ads.where((ad) {
      final categoryOk = selectedCategory == null || '${ad['category'] ?? ''}' == selectedCategory;
      final subcategoryOk = selectedSubcategory == null || '${ad['subcategory'] ?? ''}' == selectedSubcategory;
      final provinceOk = selectedProvince == null || '${ad['province'] ?? ''}' == selectedProvince;
    final cityOk = selectedCity == null || '${ad['city'] ?? ''}' == selectedCity;
      final price = (ad['price'] as num?)?.toInt();
      final minOk = minPrice == null || (price != null && price >= minPrice!);
      final maxOk = maxPrice == null || (price != null && price <= maxPrice!);
      final text = normalizeFa('${ad['title'] ?? ''} ${ad['edescription'] ?? ''} ${ad['province'] ?? ''} ${ad['city'] ?? ''} ${ad['category'] ?? ''} ${ad['subcategory'] ?? ''}');
      final searchOk = q.isEmpty || text.contains(q);
      return categoryOk && subcategoryOk && provinceOk && cityOk && minOk && maxOk && searchOk;
    }).toList();
    if(sortMode=='cheapest') result.sort((a,b)=>((a['price'] as num?)??0).compareTo((b['price'] as num?)??0));
    if(sortMode=='expensive') result.sort((a,b)=>((b['price'] as num?)??0).compareTo((a['price'] as num?)??0));
    return result;
  }

  void openFilters() {
    final min=TextEditingController(text:minPrice?.toString()??'');
    final max=TextEditingController(text:maxPrice?.toString()??'');
    showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>StatefulBuilder(builder:(ctx,setSheet)=>Directionality(
      textDirection:TextDirection.rtl,
      child:Padding(padding:EdgeInsets.only(left:16,right:16,top:16,bottom:MediaQuery.of(ctx).viewInsets.bottom+16),child:ListView(shrinkWrap:true,children:[
        const Text('فیلتر آگهی‌ها',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(
          value:selectedProvince,
          items:[null,...iranProvinceCities.keys].map((x)=>DropdownMenuItem<String>(value:x,child:Text(x??'همه استان‌ها'))).toList(),
          onChanged:(v)=>setSheet(() { selectedProvince=v; selectedCity=null; }),
          decoration:const InputDecoration(labelText:'استان',border:OutlineInputBorder())),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(
          value:(selectedProvince!=null && iranProvinceCities[selectedProvince!]?.contains(selectedCity)==true)?selectedCity:null,
          items:[null,...(selectedProvince==null?const <String>[]:(iranProvinceCities[selectedProvince!]??const <String>[]))].map((x)=>DropdownMenuItem<String>(value:x,child:Text(x??'همه شهرهای استان'))).toList(),
          onChanged:(v)=>setSheet(() { selectedCity=v; }),
          decoration:const InputDecoration(labelText:'شهر',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:min,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'حداقل قیمت',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:max,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'حداکثر قیمت',border:OutlineInputBorder())),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:sortMode,items:const [
          DropdownMenuItem(value:'newest',child:Text('جدیدترین')),
          DropdownMenuItem(value:'cheapest',child:Text('ارزان‌ترین')),
          DropdownMenuItem(value:'expensive',child:Text('گران‌ترین')),
        ],onChanged:(v)=>setSheet(() { sortMode=v??'newest'; }),decoration:const InputDecoration(labelText:'مرتب‌سازی',border:OutlineInputBorder())),
        const SizedBox(height:14),
        Row(children:[
          Expanded(child:OutlinedButton.icon(
            onPressed:(){
              setState((){
                selectedProvince=null;
                selectedCity=null;
                minPrice=null;
                maxPrice=null;
                sortMode='newest';
              });
              Navigator.pop(ctx);
            },
            icon:const Icon(Icons.clear_all),
            label:const Text('پاک کردن فیلترها'),
          )),
          const SizedBox(width:10),
          Expanded(child:FilledButton(
            onPressed:(){
              setState(() { minPrice=int.tryParse(min.text); maxPrice=int.tryParse(max.text); });
              Navigator.pop(ctx);
            },
            child:const Text('اعمال فیلتر'),
          )),
        ]),
      ])))));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'آگهینو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (isAdmin)
              IconButton(
                tooltip: 'پنل مدیریت',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())),
                icon: const Icon(Icons.admin_panel_settings_outlined),
              ),
            IconButton(
              onPressed: loadAds,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? const FavoritesPage()
                : tab == 2
                    ? const MessagesPage()
                    : account(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAdd,
          icon: const Icon(Icons.add),
          label: const Text('ثبت آگهی'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حساب',
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    if (loadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children:[
            Expanded(child:TextField(
            onSubmitted:(value){if(value.trim().isNotEmpty&&!recentSearches.contains(value.trim()))setState(()=>recentSearches=[value.trim(),...recentSearches].take(8).toList());},
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'چی می‌خوای پیدا کنی؟',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
            )),
            const SizedBox(width:8),
            IconButton.filledTonal(onPressed:saveCurrentSearch,icon:const Icon(Icons.bookmark_add_outlined),tooltip:'ذخیره جست‌وجو'),
            const SizedBox(width:2),
            IconButton.filledTonal(onPressed:openFilters,icon:const Icon(Icons.tune),tooltip:'فیلتر'),
          ]),
          if(recentSearches.isNotEmpty && searchQuery.isEmpty)
            SizedBox(height:40,child:ListView(scrollDirection:Axis.horizontal,children:recentSearches.map((x)=>Padding(padding:const EdgeInsets.only(left:6),child:ActionChip(label:Text(x),onPressed:()=>setState(()=>searchQuery=x)))).toList())),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006D77), Color(0xFF0A9396)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '“همانا با سختی، آسانی است.”',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  'Qur\'an 94:6',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'دسته‌بندی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.45,
                ),
                itemBuilder: (_, index) {
                  if (index == 0) {
                    final selected = selectedCategory == null;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() { selectedCategory = null; selectedSubcategory = null; }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFD7F0F1) : const Color(0xFFF5F8FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? const Color(0xFF0A9396) : const Color(0xFFE1E8EA),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apps_outlined, color: Color(0xFF006D77)),
                            SizedBox(width: 7),
                            Text('همه دسته‌ها', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    );
                  }
                  final item = categories[index - 1];
                  final selected = selectedCategory == item;
                  final sub = selectedSubcategory != null && selected ? selectedSubcategory! : '';
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => openCategory(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFD7F0F1) : const Color(0xFFF5F8FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? const Color(0xFF0A9396) : const Color(0xFFE1E8EA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF006D77) : Colors.white,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              aghinouCategoryIcons[item] ?? Icons.category_outlined,
                              size: 21,
                              color: selected ? Colors.white : const Color(0xFF006D77),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sub.isEmpty ? item : '$item\n$sub',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'جدیدترین آگهی‌ها',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (filteredAds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('هنوز آگهی‌ای ثبت نشده است.'),
              ),
            )
          else
            ...filteredAds.map((ad) {
              final images = ad['ad_images'];
              final firstUrl = images is List && images.isNotEmpty
                  ? images.first['image_url']?.toString()
                  : null;
              final title = ad['title']?.toString() ?? 'بدون عنوان';
              final category = ad['category']?.toString() ?? '';
              final subcategory = ad['subcategory']?.toString() ?? '';
              final city = ad['city']?.toString() ?? '';
              final price = ad['price'] == null || ad['price'].toString().isEmpty
                  ? 'توافقی'
                  : '${ad['price']} تومان';
              final time = relativeTime(ad['created_at']);
              final typeLine = [category, subcategory].where((x) => x.trim().isNotEmpty).join(' • ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdDetailPage(ad: ad)),
                    ),
                    child: AspectRatio(
                      aspectRatio: 0.92,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (firstUrl != null && firstUrl.isNotEmpty)
                            Image.network(
                              firstUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFEFF3F4),
                                child: const Center(
                                  child: Icon(Icons.image_outlined, size: 64, color: Color(0xFF8A9A9D)),
                                ),
                              ),
                            )
                          else
                            Container(
                              color: const Color(0xFFEFF3F4),
                              child: const Center(
                                child: Icon(Icons.image_outlined, size: 64, color: Color(0xFF8A9A9D)),
                              ),
                            ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.08),
                                    Colors.black.withOpacity(0.62),
                                  ],
                                  stops: const [0.0, 0.48, 0.70, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            left: 14,
                            bottom: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (typeLine.isNotEmpty)
                                  Text(
                                    typeLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 21, height: 1.25, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 7),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: [
                                    Text(price, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800)),
                                    if (city.isNotEmpty) Text(city, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                                    if (time.isNotEmpty) Text(time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> saveCurrentSearch() async {
    final uid=supabase.auth.currentUser?.id;if(uid==null)return;
    if(searchQuery.trim().isEmpty&&selectedCategory==null&&selectedProvince==null&&selectedCity==null&&minPrice==null&&maxPrice==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ابتدا یک عبارت یا فیلتر برای ذخیره انتخاب کنید.')));return;}
    try{await supabase.from('saved_searches').insert({'user_id':uid,'query':searchQuery.trim(),'filters':{'category':selectedCategory,'subcategory':selectedSubcategory,'province':selectedProvince,'city':selectedCity,'min_price':minPrice,'max_price':maxPrice,'sort':sortMode}});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('جست‌وجو ذخیره شد.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره جست‌وجو: $e')));}
  }

  Future<void> buySubscription() async {
    if(!mounted)return;
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>const SubscriptionPage()));
    await loadSubscription();
  }

  Widget account() {
    final remaining = (adLimit - adsUsed).clamp(0, adLimit);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child:CircleAvatar(radius:38,backgroundColor:const Color(0xFFD7F0F1),child:Text(profileFirstName.isNotEmpty?profileFirstName.substring(0,1):'آ',style:const TextStyle(fontSize:34,fontWeight:FontWeight.bold,color:Color(0xFF006D77))))),
        const SizedBox(height:10),
        Center(child:Text((profileFirstName.isNotEmpty?profileFirstName:'کاربر')+' '+profileLastName,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),
        if(profilePhone.isNotEmpty)Center(child:Padding(padding:const EdgeInsets.only(top:4),child:Text(profilePhone,style:const TextStyle(color:Color(0xFF60727A))))),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('ویرایش پروفایل'),
            subtitle: const Text('نام، نام خانوادگی و شماره موبایل'),
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(
                    firstName: profileFirstName,
                    lastName: profileLastName,
                    phone: profilePhone,
                  ),
                ),
              );
              if (changed == true) {
                await loadProfile();
              }
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('تغییر رمز ورود'),
            subtitle: const Text('رمز ورود حساب خود را تغییر دهید'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('اشتراک'),
            subtitle: Text(
              hasActiveSubscription && subscriptionExpiresAt != null
                  ? 'فعال تا ${subscriptionExpiresAt!.toLocal().toString().split('.').first}'
                  : 'غیرفعال • ۳۹٬۰۰۰ تومان / ماه • حداکثر ۹ آگهی',
            ),
            trailing: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionPage()),
              ),
              child: const Text('خرید اشتراک'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('آگهی‌های من'),
            subtitle: const Text('ویرایش و مدیریت آگهی‌های شما'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsPage())),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('اعلان‌ها'),
            subtitle: const Text('مشاهده و مدیریت اعلان‌های حساب'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark_outline),
            title: const Text('جست‌وجوهای ذخیره‌شده'),
            subtitle: const Text('مدیریت جست‌وجوهای ذخیره‌شده'),
            onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const SavedSearchesPage()),
              );
              if (!mounted || result == null) return;
              final f = result['filters'] is Map
                  ? Map<String, dynamic>.from(result['filters'])
                  : <String, dynamic>{};
              setState(() {
                searchQuery = result['query']?.toString() ?? '';
                selectedCategory = f['category']?.toString();
                selectedSubcategory = f['subcategory']?.toString();
                selectedProvince = f['province']?.toString();
                selectedCity = f['city']?.toString();
                minPrice = (f['min_price'] as num?)?.toInt();
                maxPrice = (f['max_price'] as num?)?.toInt();
                sortMode = f['sort']?.toString() ?? 'newest';
                tab = 0;
              });
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('سهمیه ثبت آگهی'),
            subtitle: Text(
              '$adsUsed از $adLimit آگهی استفاده شده • $remaining باقی‌مانده',
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (isAdmin)
          Card(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('پنل مدیریت'),
              subtitle: const Text('مدیریت آگهی‌ها، کاربران، پرداخت‌ها و تنظیمات'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('خروج'),
        ),
      ],
    );
  }

  void openAdd() {
    if (loadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال بررسی اشتراک هستیم...')),
      );
      return;
    }

    if (!hasActiveSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت آگهی ابتدا اشتراک پایه را فعال کنید.'),
        ),
      );
      setState(() => tab = 3);
      return;
    }

    if (adsUsed >= adLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سهمیه آگهی این دوره تکمیل شده است.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdPage(
          onPublished: loadAds,
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });
  final String firstName;
  final String lastName;
  final String phone;
  @override State<EditProfilePage> createState() => _EditProfilePageState();
}
class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController firstName;
  late final TextEditingController lastName;
  late final TextEditingController phone;
  bool saving = false;
  @override void initState() {
    super.initState();
    firstName = TextEditingController(text: widget.firstName);
    lastName = TextEditingController(text: widget.lastName);
    phone = TextEditingController(text: widget.phone);
  }
  @override void dispose() {
    firstName.dispose(); lastName.dispose(); phone.dispose(); super.dispose();
  }
  Future<void> save() async {
    final fn=firstName.text.trim(), ln=lastName.text.trim(), ph=phone.text.trim();
    if(fn.isEmpty||ln.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('نام و نام خانوادگی را کامل وارد کنید.')));return;}
    if(ph.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره موبایل را وارد کنید.')));return;}
    setState(()=>saving=true);
    try {
      final response=await supabase.functions.invoke('update-profile',body:{'first_name':fn,'last_name':ln,'phone':ph});
      if(!mounted)return;
      if(response.data is Map && response.data['success']==true){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('پروفایل با موفقیت ذخیره شد.')));
        Navigator.pop(context,true);
      } else {
        final message=response.data is Map?response.data['error']?.toString():null;
        throw Exception(message??'ذخیره پروفایل انجام نشد.');
      }
    } on FunctionException catch(e) {
      if(!mounted)return;
      final data=e.details;
      final message=data is Map?data['error']?.toString():null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message??'ذخیره پروفایل انجام نشد.')));
    } catch(e) {
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره پروفایل انجام نشد: $e')));
    } finally { if(mounted)setState(()=>saving=false); }
  }
  @override Widget build(BuildContext context) {
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('ویرایش پروفایل')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        TextField(controller:firstName,textInputAction:TextInputAction.next,decoration:const InputDecoration(labelText:'نام',border:OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller:lastName,textInputAction:TextInputAction.next,decoration:const InputDecoration(labelText:'نام خانوادگی',border:OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller:phone,keyboardType:TextInputType.phone,textDirection:TextDirection.ltr,decoration:const InputDecoration(labelText:'شماره موبایل',hintText:'09123456789',border:OutlineInputBorder())),
        const SizedBox(height:18),
        FilledButton.icon(onPressed:saving?null:save,icon:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save_outlined),label:Text(saving?'در حال ذخیره...':'ذخیره تغییرات')),
      ]),
    ));
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  bool hideCurrent = true;
  bool hideNext = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    final oldPassword = current.text;
    final newPassword = next.text;
    final confirmPassword = confirm.text;
    final user = supabase.auth.currentUser;

    if (user == null) return;
    if (oldPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز فعلی را وارد کنید.')));
      return;
    }
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز جدید باید حداقل ۶ کاراکتر باشد.')));
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تکرار رمز جدید با رمز جدید یکسان نیست.')));
      return;
    }
    if (newPassword == oldPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز جدید باید با رمز فعلی متفاوت باشد.')));
      return;
    }

    setState(() => loading = true);
    try {
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw const AuthException('حساب کاربری برای تغییر رمز آماده نیست.');
      }
      await supabase.auth.signInWithPassword(email: email, password: oldPassword);
      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز ورود با موفقیت تغییر کرد.')),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      final m = e.message.toLowerCase();
      final message = m.contains('invalid login credentials')
          ? 'رمز فعلی نادرست است.'
          : 'تغییر رمز انجام نشد: ' + e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تغییر رمز انجام نشد: ' + e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تغییر رمز ورود')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline, size: 54, color: Color(0xFF006D77)),
                    const SizedBox(height: 10),
                    const Text(
                      'برای امنیت حساب، رمز فعلی و رمز جدید را وارد کنید.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.6),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: current,
                      obscureText: hideCurrent,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'رمز فعلی',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.key_outlined),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => hideCurrent = !hideCurrent),
                          icon: Icon(hideCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: next,
                      obscureText: hideNext,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'رمز جدید',
                        helperText: 'حداقل ۶ کاراکتر؛ حروف انگلیسی و اعداد مجاز است.',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => hideNext = !hideNext),
                          icon: Icon(hideNext ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirm,
                      obscureText: hideConfirm,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => loading ? null : changePassword(),
                      decoration: InputDecoration(
                        labelText: 'تکرار رمز جدید',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => hideConfirm = !hideConfirm),
                          icon: Icon(hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: loading ? null : changePassword,
                        icon: loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_outlined),
                        label: Text(loading ? 'در حال تغییر...' : 'تغییر رمز'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyAdsPage extends StatefulWidget {
  const MyAdsPage({super.key});
  @override State<MyAdsPage> createState()=>_MyAdsPageState();
}
class _MyAdsPageState extends State<MyAdsPage>{
  bool loading=true; List<Map<String,dynamic>> ads=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    try{
      final uid=supabase.auth.currentUser?.id;if(uid==null)return;
      final r=await supabase.from('ads').select('*, ad_images(image_url,sort_order,is_primary)').eq('seller_id',uid).order('created_at',ascending:false);
      if(mounted)setState((){ads=List<Map<String,dynamic>>.from(r);loading=false;});
    }catch(e){if(mounted)setState(()=>loading=false);}
  }
  Future<void> removeAd(String id)async{
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('حذف آگهی'),content:const Text('آیا از حذف آگهی مطمئن هستید؟'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حذف'))]));
    if(ok!=true)return;
    try{await supabase.from('ads').delete().eq('idd',id).eq('seller_id',supabase.auth.currentUser!.id);await load();}catch(e){}
  }
  @override Widget build(BuildContext c){
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('آگهی‌های من')),body:
      loading?const Center(child:CircularProgressIndicator()):ads.isEmpty?const Center(child:Text('هنوز آگهی‌ای ثبت نکرده‌اید.')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:ads.length,itemBuilder:(_,i){
        final a=ads[i];final ims=List<Map<String,dynamic>>.from(a['ad_images']??const[]);ims.sort((x,y)=>((x['sort_order'] as num?)??0).compareTo((y['sort_order'] as num?)??0));
        final img=ims.isEmpty?null:ims.first['image_url']?.toString();final s=a['publish_status']?.toString()??'pending';final st=s=='published'?'منتشر شده':s=='rejected'?'رد شده':s=='paused'?'متوقف شده':'در انتظار تأیید';
        return Card(child:ListTile(leading:img==null?const CircleAvatar(child:Icon(Icons.image)):Image.network(img,width:60,height:60,fit:BoxFit.cover),title:Text(a['title']?.toString()??''),subtitle:Text((a['price']??0).toString()+' تومان • '+st),trailing:PopupMenuButton<String>(itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('ویرایش')),PopupMenuItem(value:'delete',child:Text('حذف'))],onSelected:(v)async{if(v=='edit'){await Navigator.push(c,MaterialPageRoute(builder:(_)=>EditAdPage(ad:a)));await load();}else{await removeAd(a['idd'].toString());}})));
      })));
  }
}
class EditAdPage extends StatefulWidget{
  final Map<String,dynamic> ad;const EditAdPage({super.key,required this.ad});
  @override State<EditAdPage> createState()=>_EditAdPageState();
}
class _EditAdPageState extends State<EditAdPage>{
  late TextEditingController title,desc,price,neighborhood,vehicleBrand,vehicleModel,vehicleYear,vehicleMileage,vehicleColor;
  late String category,province,city,condition,subcategory,vehicleTransmission,vehicleBodyCondition,vehicleFuel;
  bool vehicleExchange=false;
  bool saving=false;
  final Map<String,TextEditingController> detailControllers={};
  void resetDetailControllers(Map<String,dynamic>? values){for(final x in detailControllers.values)x.dispose();detailControllers.clear();final d=values?['details'] is Map?Map<String,dynamic>.from(values!['details']):<String,dynamic>{};for(final f in categoryDetailFields[category]??const <String>[]){detailControllers[f]=TextEditingController(text:d[f]?.toString()??'');}}
  @override void initState(){super.initState();final a=widget.ad;title=TextEditingController(text:a['title']?.toString()??'');desc=TextEditingController(text:a['edescription']?.toString()??'');price=TextEditingController(text:(a['price'] as num?)?.toInt().toString()??'');neighborhood=TextEditingController(text:a['neighborhood']?.toString()??'');vehicleBrand=TextEditingController(text:a['vehicle_brand']?.toString()??'');vehicleModel=TextEditingController(text:a['vehicle_model']?.toString()??'');vehicleYear=TextEditingController(text:a['vehicle_year']?.toString()??'');vehicleMileage=TextEditingController(text:a['vehicle_mileage']?.toString()??'');vehicleColor=TextEditingController(text:a['vehicle_color']?.toString()??'');category=a['category']?.toString()??'سایر';province=a['province']?.toString()??'تهران';city=a['city']?.toString()??(iranProvinceCities['تهران']?.first??'تهران');condition=a['item_condition']?.toString()??'در حد نو';subcategory=a['subcategory']?.toString()??'سایر';vehicleTransmission=a['vehicle_transmission']?.toString()??'دستی';vehicleBodyCondition=a['vehicle_body_condition']?.toString()??'سالم';vehicleFuel=a['vehicle_fuel']?.toString()??'بنزینی';vehicleExchange=a['vehicle_exchange']==true;resetDetailControllers(a);}
  @override void dispose(){title.dispose();desc.dispose();price.dispose();neighborhood.dispose();vehicleBrand.dispose();vehicleModel.dispose();vehicleYear.dispose();vehicleMileage.dispose();vehicleColor.dispose();for(final x in detailControllers.values)x.dispose();super.dispose();}
  List<String> get subs {
  final list=HomeCategoryData.subsFor(category);
  return list.isEmpty?const ['سایر']:list;
}
  Future<void> save()async{
    final p=int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'),''));final uid=supabase.auth.currentUser?.id;if(p==null||uid==null)return;
    setState(()=>saving=true);try{
      await supabase.rpc('update_own_ad',params:{'p_ad_id':widget.ad['idd'],'p_details':Map<String,String>.fromEntries(detailControllers.entries.where((e)=>e.value.text.trim().isNotEmpty).map((e)=>MapEntry(e.key,e.value.text.trim()))),'p_title':title.text.trim(),'p_description':desc.text.trim(),'p_price':p,'p_city':city,'p_province':province,'p_category':category,'p_subcategory':subcategory,'p_condition':condition,'p_neighborhood':neighborhood.text.trim().isEmpty?null:neighborhood.text.trim(),'p_vehicle_brand':category=='خودرو'&&vehicleBrand.text.trim().isNotEmpty?vehicleBrand.text.trim():null,'p_vehicle_model':category=='خودرو'&&vehicleModel.text.trim().isNotEmpty?vehicleModel.text.trim():null,'p_vehicle_year':category=='خودرو'?int.tryParse(vehicleYear.text.trim()):null,'p_vehicle_mileage':category=='خودرو'?int.tryParse(vehicleMileage.text.trim()):null,'p_vehicle_color':category=='خودرو'&&vehicleColor.text.trim().isNotEmpty?vehicleColor.text.trim():null,'p_vehicle_transmission':category=='خودرو'?vehicleTransmission:null,'p_vehicle_body_condition':category=='خودرو'?vehicleBodyCondition:null,'p_vehicle_fuel':category=='خودرو'?vehicleFuel:null,'p_vehicle_exchange':category=='خودرو'?vehicleExchange:false});
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تغییرات ذخیره شد و آگهی برای بررسی دوباره ارسال شد.')));Navigator.pop(context);}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره تغییرات: '+e.toString())));}finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('ویرایش آگهی')),body:ListView(padding:const EdgeInsets.all(16),children:[
    DropdownButtonFormField<String>(value:category,items:_HomePageState.categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)setState((){category=v;subcategory=HomeCategoryData.subsFor(v).isEmpty?'سایر':HomeCategoryData.subsFor(v).first;resetDetailControllers(widget.ad);});},decoration:const InputDecoration(labelText:'دسته‌بندی',border:OutlineInputBorder())),
    const SizedBox(height:12),DropdownButtonFormField<String>(value:subs.contains(subcategory)?subcategory:subs.first,items:subs.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>subcategory=v??subs.first),decoration:const InputDecoration(labelText:'زیر‌دسته',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:desc,maxLines:5,decoration:const InputDecoration(labelText:'توضیحات',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'قیمت (تومان)',border:OutlineInputBorder())),
    const SizedBox(height:12),DropdownButtonFormField<String>(value:const['نو','در حد نو','کارکرده'].contains(condition)?condition:'در حد نو',items:const['نو','در حد نو','کارکرده'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>condition=v??condition),decoration:const InputDecoration(labelText:'وضعیت',border:OutlineInputBorder())),
          if(category=='خودرو')...[
            const SizedBox(height:12),TextField(controller:vehicleBrand,decoration:const InputDecoration(labelText:'برند خودرو',border:OutlineInputBorder())),
            const SizedBox(height:12),TextField(controller:vehicleModel,decoration:const InputDecoration(labelText:'مدل خودرو',border:OutlineInputBorder())),
            const SizedBox(height:12),TextField(controller:vehicleYear,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'سال ساخت',border:OutlineInputBorder())),
            const SizedBox(height:12),TextField(controller:vehicleMileage,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'کارکرد (کیلومتر)',border:OutlineInputBorder())),
            const SizedBox(height:12),TextField(controller:vehicleColor,decoration:const InputDecoration(labelText:'رنگ',border:OutlineInputBorder())),
            const SizedBox(height:12),DropdownButtonFormField<String>(value:vehicleTransmission,items:const['دستی','اتوماتیک','نیمه‌اتوماتیک'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>vehicleTransmission=v??vehicleTransmission),decoration:const InputDecoration(labelText:'گیربکس',border:OutlineInputBorder())),
            const SizedBox(height:12),DropdownButtonFormField<String>(value:vehicleBodyCondition,items:const['سالم','رنگ‌شده','تصادفی','نیازمند تعمیر'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>vehicleBodyCondition=v??vehicleBodyCondition),decoration:const InputDecoration(labelText:'وضعیت بدنه',border:OutlineInputBorder())),
            const SizedBox(height:12),DropdownButtonFormField<String>(value:vehicleFuel,items:const['بنزینی','دوگانه‌سوز','دیزلی','هیبریدی','برقی'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>vehicleFuel=v??vehicleFuel),decoration:const InputDecoration(labelText:'سوخت',border:OutlineInputBorder())),
            SwitchListTile(value:vehicleExchange,onChanged:(v)=>setState(()=>vehicleExchange=v),title:const Text('معاوضه می‌شود')),
          ],
    const SizedBox(height:12),DropdownButtonFormField<String>(value:iranProvinceCities[province]?.contains(city)==true?city:iranProvinceCities[province]!.first,items:(iranProvinceCities[province]??const <String>[]).map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>city=v??city),decoration:const InputDecoration(labelText:'شهر',border:OutlineInputBorder())),
    const SizedBox(height:12),DropdownButtonFormField<String>(value:iranProvinceCities.containsKey(province)?province:iranProvinceCities.keys.first,items:iranProvinceCities.keys.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState((){province=v??province;city=iranProvinceCities[province]!.first;}),decoration:const InputDecoration(labelText:'استان',border:OutlineInputBorder())),
          const SizedBox(height:12),TextField(controller:neighborhood,decoration:const InputDecoration(labelText:'محله',border:OutlineInputBorder())),
    if((categoryDetailFields[category]??const <String>[]).isNotEmpty) ...[
      const SizedBox(height:14),const Text('جزئیات آگهی',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),
      ...(categoryDetailFields[category]??const <String>[]).map((f)=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:detailControllers[f],decoration:InputDecoration(labelText:f,border:const OutlineInputBorder())))),
    ],
    const SizedBox(height:18),FilledButton(onPressed:saving?null:save,child:Text(saving?'در حال ذخیره...':'ذخیره تغییرات')),
  ])));
}
class AddAdPage extends StatefulWidget {
  final Future<void> Function() onPublished;
  const AddAdPage({super.key, required this.onPublished});
  @override State<AddAdPage> createState()=>_AddAdPageState();
}

class _AddAdPageState extends State<AddAdPage>{
  final title=TextEditingController(),desc=TextEditingController(),price=TextEditingController(),neighborhood=TextEditingController();
  final vehicleBrand=TextEditingController(),vehicleModel=TextEditingController(),vehicleYear=TextEditingController(),vehicleMileage=TextEditingController(),vehicleColor=TextEditingController();
  String category='موبایل و تبلت',province='تهران',city='تهران',condition='در حد نو',subcategory='',vehicleTransmission='دستی',vehicleBodyCondition='سالم',vehicleFuel='بنزینی';
  bool vehicleExchange=false;
  bool publishing=false;
  final picker=ImagePicker();
  final List<XFile> selectedImages=[];
  final Map<String,TextEditingController> detailControllers={};
  void resetDetailControllers(){ for(final x in detailControllers.values)x.dispose(); detailControllers.clear(); for(final f in categoryDetailFields[category]??const <String>[]){ detailControllers[f]=TextEditingController(); } }

  List<String> get subcategories {
    final list=HomeCategoryData.subsFor(category);
    return list.isEmpty?const ['سایر']:list;
  }

  @override void initState(){super.initState(); subcategory=subcategories.first; resetDetailControllers();}
  @override void dispose(){title.dispose();desc.dispose();price.dispose();neighborhood.dispose();vehicleBrand.dispose();vehicleModel.dispose();vehicleYear.dispose();vehicleMileage.dispose();vehicleColor.dispose();for(final x in detailControllers.values)x.dispose();super.dispose();}

  Future<void> pickImages() async {
    try{
      final settings=await supabase.from('subscription_settings').select('image_limit').eq('id',true).maybeSingle();
      final maxImages=(settings?['image_limit'] as num?)?.toInt()??10;
      if(selectedImages.length>=maxImages){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حداکثر $maxImages عکس مجاز است.')));
        return;
      }
      final xs=await picker.pickMultiImage(imageQuality:85,maxWidth:1800,maxHeight:1800);
      if(!mounted)return;
      final remaining=maxImages-selectedImages.length;
      setState(()=>selectedImages.addAll(xs.take(remaining)));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت تنظیمات عکس: $e')));
    }
  }
  void removeImage(int i)=>setState(()=>selectedImages.removeAt(i));

  Future<void> publish() async {
    if(title.text.trim().isEmpty||desc.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('عنوان و توضیحات را کامل کنید.')));return;
    }
    final u=supabase.auth.currentUser;
    if(u==null)return;
    final p=int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'),''));
    if(p==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('قیمت را صحیح وارد کنید.')));return;}
    setState(()=>publishing=true);
    String? createdAdId;
    final uploadedPaths=<String>[];
    try{
      createdAdId=(await supabase.rpc('publish_ad',params:{
        'p_title':title.text.trim(),
        'p_description':desc.text.trim(),
        'p_price':p,
        'p_city':city,
        'p_province':province,
        'p_category':category,
        'p_subcategory':subcategory,
        'p_condition':condition,
        'p_neighborhood':neighborhood.text.trim().isEmpty?null:neighborhood.text.trim(),
        'p_details':Map<String,String>.fromEntries(detailControllers.entries.where((e)=>e.value.text.trim().isNotEmpty).map((e)=>MapEntry(e.key,e.value.text.trim()))),
        'p_vehicle_brand':category=='خودرو'&&vehicleBrand.text.trim().isNotEmpty?vehicleBrand.text.trim():null,
        'p_vehicle_model':category=='خودرو'&&vehicleModel.text.trim().isNotEmpty?vehicleModel.text.trim():null,
        'p_vehicle_year':category=='خودرو'?int.tryParse(vehicleYear.text.trim()):null,
        'p_vehicle_mileage':category=='خودرو'?int.tryParse(vehicleMileage.text.trim()):null,
        'p_vehicle_color':category=='خودرو'&&vehicleColor.text.trim().isNotEmpty?vehicleColor.text.trim():null,
        'p_vehicle_transmission':category=='خودرو'?vehicleTransmission:null,
        'p_vehicle_body_condition':category=='خودرو'?vehicleBodyCondition:null,
        'p_vehicle_fuel':category=='خودرو'?vehicleFuel:null,
        'p_vehicle_exchange':category=='خودرو'?vehicleExchange:false,
      })).toString();

      for(var i=0;i<selectedImages.length;i++){
        final x=selectedImages[i];
        final bytes=await x.readAsBytes();
        final ext=x.name.contains('.')?x.name.split('.').last.toLowerCase():'jpg';
        final safe=<String>{'jpg','jpeg','png','webp'}.contains(ext)?ext:'jpg';
        final path='public/'+u.id+'/'+createdAdId+'/'+i.toString()+'_'+DateTime.now().microsecondsSinceEpoch.toString()+'.'+safe;
        await supabase.storage.from('ad-images').uploadBinary(path,bytes,fileOptions:FileOptions(
          contentType:safe=='png'?'image/png':safe=='webp'?'image/webp':'image/jpeg'));
        uploadedPaths.add(path);
        await supabase.from('ad_images').insert({'ad_id':createdAdId,'image_url':supabase.storage.from('ad-images').getPublicUrl(path),'sort_order':i,'is_primary':i==0});
      }
      await widget.onPublished();
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('آگهی ثبت شد و برای تأیید مدیر ارسال شد.')));
        Navigator.pop(context);
      }
    }catch(e){
      if(createdAdId!=null){
        try{if(uploadedPaths.isNotEmpty)await supabase.storage.from('ad-images').remove(uploadedPaths);}catch(_){ }
        try{await supabase.from('ad_images').delete().eq('ad_id',createdAdId!);}catch(_){ }
        try{await supabase.from('ads').delete().eq('idd',createdAdId!);}catch(_){ }
      }
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت آگهی انجام نشد و تغییرات ناقص پاک شد: '+e.toString())));
    }finally{if(mounted)setState(()=>publishing=false);}
  }
  Future<void> preview() async {
    if(title.text.trim().isEmpty||desc.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ابتدا عنوان و توضیحات را کامل کنید.')));return;
    }
    await showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Directionality(
      textDirection:TextDirection.rtl,
      child:SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('پیش‌نمایش آگهی',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        Text(title.text,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        Text(price.text+' تومان'),
        Text(city+' • '+subcategory+' • '+condition),
        if(neighborhood.text.trim().isNotEmpty)Text('محله: '+neighborhood.text.trim()),
        const SizedBox(height:10),
        Text(desc.text,maxLines:5,overflow:TextOverflow.ellipsis),
        const SizedBox(height:16),
        Text('تعداد عکس انتخاب‌شده: '+selectedImages.length.toString()),
        const SizedBox(height:12),
        FilledButton(onPressed:publishing?null:(){Navigator.pop(context);publish();},child:const Text('تأیید و انتشار')),
      ])))));
  }

  @override Widget build(BuildContext c) {
    return Directionality(
      textDirection:TextDirection.rtl,
      child:Scaffold(
        appBar:AppBar(title:const Text('ثبت آگهی')),
        body:ListView(padding:const EdgeInsets.all(16),children:[
          DropdownButtonFormField<String>(value:category,items:_HomePageState.categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(v){if(v==null)return;setState(() { category=v;subcategory=subcategories.first;resetDetailControllers(); });},decoration:const InputDecoration(labelText:'دسته‌بندی',border:OutlineInputBorder())),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(value:subcategory,items:subcategories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(v)=>setState(()=>subcategory=v??subcategories.first),decoration:const InputDecoration(labelText:'زیر‌دسته',border:OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان آگهی',border:OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(controller:desc,maxLines:5,decoration:const InputDecoration(labelText:'توضیحات',border:OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'قیمت (تومان)',border:OutlineInputBorder())),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(value:condition,items:const ['نو','در حد نو','کارکرده'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(v)=>setState(()=>condition=v??condition),decoration:const InputDecoration(labelText:'وضعیت کالا',border:OutlineInputBorder())),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(value:iranProvinceCities.containsKey(province)?province:iranProvinceCities.keys.first,items:iranProvinceCities.keys.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(v)=>setState((){province=v??province;city=iranProvinceCities[province]!.first;}),decoration:const InputDecoration(labelText:'استان',border:OutlineInputBorder())),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(value:iranProvinceCities[province]?.contains(city)==true?city:iranProvinceCities[province]!.first,items:(iranProvinceCities[province]??const <String>[]).map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(v)=>setState(()=>city=v??city),decoration:const InputDecoration(labelText:'شهر',border:OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(controller:neighborhood,decoration:const InputDecoration(labelText:'محله (اختیاری)',border:OutlineInputBorder())),
          if((categoryDetailFields[category]??const <String>[]).isNotEmpty) ...[
            const SizedBox(height:14),const Text('جزئیات آگهی',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),
            ...(categoryDetailFields[category]??const <String>[]).map((f)=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:detailControllers[f],decoration:InputDecoration(labelText:f,border:const OutlineInputBorder())))),
          ],
          const SizedBox(height:14),
          OutlinedButton.icon(onPressed:publishing?null:pickImages,icon:const Icon(Icons.add_a_photo_outlined),label:Text('افزودن عکس '+selectedImages.length.toString()+'/حداکثر')),
          if(selectedImages.isNotEmpty)SizedBox(height:132,child:ReorderableListView.builder(
            scrollDirection:Axis.horizontal,
            buildDefaultDragHandles:false,
            itemCount:selectedImages.length,
            onReorder:(oldIndex,newIndex){setState((){if(newIndex>oldIndex)newIndex--;final x=selectedImages.removeAt(oldIndex);selectedImages.insert(newIndex,x);});},
            itemBuilder:(_,i){final img=selectedImages[i];return Padding(
              key:ValueKey(img.path),
              padding:const EdgeInsets.only(right:8),
              child:Stack(children:[
                ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(File(img.path),width:110,height:110,fit:BoxFit.cover)),
                Positioned(top:3,right:3,child:CircleAvatar(radius:14,child:IconButton(padding:EdgeInsets.zero,onPressed:()=>removeImage(i),icon:const Icon(Icons.close,size:16)))),
                Positioned(bottom:3,left:3,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(8)),child:Text(i==0?'عکس اصلی':'${i+1}',style:const TextStyle(color:Colors.white,fontSize:11))))
              ]));}
          )),
          if(selectedImages.length>1)const Padding(padding:EdgeInsets.only(top:6),child:Text('برای تغییر عکس اصلی، عکس اول را جابه‌جا کنید.')),
          const SizedBox(height:16),
          OutlinedButton(onPressed:publishing?null:preview,child:const Text('پیش‌نمایش')),
          const SizedBox(height:8),
          FilledButton(onPressed:publishing?null:publish,child:publishing?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2)):const Text('ثبت و انتشار')),
        ]),
      ),
    );
  }
}
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override State<AdminPage> createState()=>_AdminPageState();
}
class _AdminPageState extends State<AdminPage>{
  bool loading=true,working=false;
  List<Map<String,dynamic>> payments=[],ads=[],users=[],reports=[];
  Map<String,dynamic>? stats;
  final price=TextEditingController(),days=TextEditingController(),limit=TextEditingController(),images=TextEditingController(),card=TextEditingController(),holder=TextEditingController(),bank=TextEditingController(),instructions=TextEditingController(),userSearch=TextEditingController(),adSearch=TextEditingController();
  bool enabled=true;
  @override void initState(){super.initState();load();}
  @override void dispose(){for(final c in [price,days,limit,images,card,holder,bank,instructions,userSearch,adSearch])c.dispose();super.dispose();}
  Future<void> load() async {
    try{
      final r=await supabase.from('subscription_settings').select('*').eq('id',true).maybeSingle();
      final p=await supabase.from('payments').select('id,user_id,amount,status,payment_note,payment_code,metadata,provider,created_at,paid_at,confirmed_at').inFilter('status',['pending','checking']).order('created_at',ascending:false);
      final st=await supabase.rpc('admin_dashboard_stats');
      final rr=await supabase.from('reports').select('id,reporter_id,ad_id,reason,details,status,created_at,ads(title,city)').order('created_at',ascending:false).limit(100);
      final aa=await supabase.from('ads').select('idd,title,price,city,category,seller_id,publish_status,created_at').order('created_at',ascending:false).limit(100);
      final uu=await supabase.from('profiles').select('iidd,name,first_name,last_name,cphone,created_at').order('created_at',ascending:false).limit(100);
      if(r!=null){price.text=r['price'].toString();days.text=r['duration_days'].toString();limit.text=r['ad_limit'].toString();images.text=r['image_limit'].toString();card.text=r['destination_card']?.toString()??'';holder.text=r['card_holder']?.toString()??'';bank.text=r['bank_name']?.toString()??'';instructions.text=r['instructions']?.toString()??'';enabled=r['enabled']==true;}
      if(mounted)setState(() { stats=Map<String,dynamic>.from(st); payments=List<Map<String,dynamic>>.from(p); ads=List<Map<String,dynamic>>.from(aa); users=List<Map<String,dynamic>>.from(uu); reports=List<Map<String,dynamic>>.from(rr); loading=false; });
    }catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('پنل مدیریت: $e')));}}
  }
  Future<void> saveSettings() async {setState(()=>working=true);try{await supabase.rpc('update_subscription_settings',params:{'p_price':int.parse(price.text),'p_duration_days':int.parse(days.text),'p_ad_limit':int.parse(limit.text),'p_image_limit':int.parse(images.text),'p_destination_card':card.text.trim(),'p_card_holder':holder.text.trim(),'p_bank_name':bank.text.trim(),'p_instructions':instructions.text.trim(),'p_enabled':enabled});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تنظیمات ذخیره شد.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره تنظیمات: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Future<void> decide(String id,bool approve) async {if(working)return;setState(()=>working=true);try{await supabase.rpc('confirm_payment',params:{'p_payment_id':id,'p_approve':approve,'p_reason':approve?null:'تأیید نشد توسط مدیر'});if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(approve?'پرداخت تأیید و اشتراک فعال شد.':'پرداخت رد شد.')));await load();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('عملیات: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Future<void> moderateAd(String id,String status) async {if(working)return;setState(()=>working=true);try{await supabase.rpc('moderate_ad',params:{'p_ad_id':id,'p_status':status,'p_reason':status=='rejected'?'آگهی مطابق قوانین تأیید نشد.':null});if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(status=='published'?'آگهی تأیید شد.':status=='paused'?'آگهی متوقف شد.':'آگهی رد شد.')));await load();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تغییر وضعیت آگهی: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Future<void> setReportStatus(String id,String status) async {if(working)return;setState(()=>working=true);try{await supabase.rpc('admin_set_report_status',params:{'p_report_id':id,'p_status':status});if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('وضعیت گزارش به‌روزرسانی شد.')));await load();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('گزارش: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Future<void> deleteAd(String id) async {if(working)return;setState(()=>working=true);try{await supabase.from('ads').delete().eq('idd',id);if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('آگهی حذف شد.')));await load();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حذف آگهی: $e')));}finally{if(mounted)setState(()=>working=false);}}
  Widget field(TextEditingController c,String label,{TextInputType type=TextInputType.text})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,keyboardType:type,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
  Widget stat(String label,dynamic value,IconData icon)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(children:[Icon(icon,size:24),Text(value?.toString()??'0',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),Text(label)]))));
  @override Widget build(BuildContext context){
    if(loading)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:CircularProgressIndicator())));
    final uq=userSearch.text.trim().toLowerCase(),aq=adSearch.text.trim().toLowerCase();
    final fu=users.where((x){final full=((x['first_name']??'').toString()+' '+(x['last_name']??'').toString()).trim();return uq.isEmpty||full.toLowerCase().contains(uq)||x['name'].toString().toLowerCase().contains(uq)||x['cphone'].toString().contains(uq);}).toList();
    final fa=ads.where((x)=>aq.isEmpty||x['title'].toString().toLowerCase().contains(aq)||x['city'].toString().toLowerCase().contains(aq)).toList();
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('پنل مدیریت'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),body:ListView(padding:const EdgeInsets.all(12),children:[
      const Text('داشبورد',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Row(children:[stat('کاربران',stats?['users'],Icons.people),stat('آگهی‌ها',stats?['ads'],Icons.list_alt)]),Row(children:[stat('در انتظار پرداخت',stats?['pending_payments'],Icons.hourglass_top),stat('پرداخت موفق',stats?['paid_payments'],Icons.payments)]),Row(children:[stat('درآمد',stats?['revenue'],Icons.account_balance_wallet),const Spacer()]),
      ExpansionTile(title:const Text('تنظیمات اشتراک و کارت‌به‌کارت'),children:[Padding(padding:const EdgeInsets.all(12),child:Column(children:[field(price,'قیمت اشتراک',type:TextInputType.number),field(days,'مدت (روز)',type:TextInputType.number),field(limit,'سهمیه آگهی',type:TextInputType.number),field(images,'حداکثر عکس',type:TextInputType.number),field(card,'شماره کارت مقصد'),field(holder,'صاحب کارت'),field(bank,'بانک'),field(instructions,'توضیحات'),SwitchListTile(value:enabled,onChanged:(v)=>setState(()=>enabled=v),title:const Text('فروش اشتراک فعال باشد')),FilledButton(onPressed:working?null:saveSettings,child:const Text('ذخیره'))]))]),
      ExpansionTile(title:Text('مدیریت کاربران (${stats?['users'] ?? users.length})'),children:[Padding(padding:const EdgeInsets.all(12),child:TextField(controller:userSearch,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'نام یا شماره',prefixIcon:Icon(Icons.search),border:OutlineInputBorder()))),...fu.take(50).map((u)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text((((u['first_name']??'').toString()+' '+(u['last_name']??'').toString()).trim().isNotEmpty)?((u['first_name']??'').toString()+' '+(u['last_name']??'').toString()).trim():(u['name']?.toString()??'کاربر')),subtitle:Text(u['cphone']?.toString()??'-')))]),
      ExpansionTile(title:Text('مدیریت آگهی‌ها (${fa.length})'),children:[Padding(padding:const EdgeInsets.all(12),child:TextField(controller:adSearch,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'عنوان یا شهر',prefixIcon:Icon(Icons.search),border:OutlineInputBorder()))),...fa.take(50).map((ad)=>ListTile(title:Text(ad['title']?.toString()??'بدون عنوان'),subtitle:Text('${ad['city']??''} • ${ad['category']??''} • ${ad['price']??'توافقی'} تومان'),trailing:Wrap(children:[IconButton(tooltip:'تأیید',onPressed:working?null:()=>moderateAd(ad['idd'].toString(),'published'),icon:const Icon(Icons.check_circle_outline)),IconButton(tooltip:'رد',onPressed:working?null:()=>moderateAd(ad['idd'].toString(),'rejected'),icon:const Icon(Icons.cancel_outlined)),IconButton(tooltip:'توقف',onPressed:working?null:()=>moderateAd(ad['idd'].toString(),'paused'),icon:const Icon(Icons.pause_circle_outline)),IconButton(icon:const Icon(Icons.delete_outline),onPressed:working?null:()=>deleteAd(ad['idd'].toString()))])))]),
      ExpansionTile(
        title:Text('پرداخت‌های در انتظار (${payments.length})'),
        children:payments.map((p) {
          final meta=p['metadata'] is Map ? Map<String,dynamic>.from(p['metadata']) : <String,dynamic>{};
          final refCode=p['payment_code']?.toString() ?? '-';
          final last4=meta['payer_card_last4']?.toString() ?? '-';
          final transferAt=meta['transfer_at']?.toString() ?? '-';
          return Card(
            margin:const EdgeInsets.only(bottom:8),
            child:ListTile(
              isThreeLine:true,
              leading:const CircleAvatar(child:Icon(Icons.payments_outlined)),
              title:Text('${p['amount'] ?? '-'} تومان',style:const TextStyle(fontWeight:FontWeight.bold)),
              subtitle:Text('شماره پیگیری: $refCode\n۴ رقم آخر کارت: $last4\nزمان انتقال: $transferAt'),
              onTap:() => showDialog(
                context:context,
                builder:(_) => AlertDialog(
                  title:const Text('جزئیات پرداخت'),
                  content:SingleChildScrollView(
                    child:Text('مبلغ: ${p['amount'] ?? '-'} تومان\nشماره پیگیری: $refCode\n۴ رقم آخر کارت: $last4\nزمان انتقال: $transferAt\nیادداشت: ${p['payment_note'] ?? '-'}'),
                  ),
                  actions:[
                    TextButton(onPressed:() => Navigator.pop(context),child:const Text('بستن')),
                  ],
                ),
              ),
              trailing:Wrap(
                children:[
                  IconButton(tooltip:'تأیید پرداخت',onPressed:working ? null : () => decide(p['id'].toString(),true),icon:const Icon(Icons.check_circle_outline)),
                  IconButton(tooltip:'رد پرداخت',onPressed:working ? null : () => decide(p['id'].toString(),false),icon:const Icon(Icons.cancel_outlined)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ])));
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override State<NotificationsPage> createState()=>_NotificationsPageState();
}
class _NotificationsPageState extends State<NotificationsPage> {
  bool loading=true; List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final uid=supabase.auth.currentUser?.id;if(uid==null){if(mounted)setState(()=>loading=false);return;}
    try{final r=await supabase.from('notifications').select('id,title,body,type,read_at,created_at').eq('user_id',uid).order('created_at',ascending:false).limit(100);if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});}
    catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت اعلان‌ها انجام نشد: $e')));}}
  }
  Future<void> markRead(String id) async {try{await supabase.from('notifications').update({'read_at':DateTime.now().toIso8601String()}).eq('id',id).eq('user_id',supabase.auth.currentUser!.id);if(mounted)setState((){final i=rows.indexWhere((x)=>x['id'].toString()==id);if(i>=0)rows[i]['read_at']=DateTime.now().toIso8601String();});}catch(_){ }}
  Future<void> markAllRead() async {final uid=supabase.auth.currentUser?.id;if(uid==null)return;try{await supabase.from('notifications').update({'read_at':DateTime.now().toIso8601String()}).eq('user_id',uid).isFilter('read_at',null);await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('علامت‌گذاری اعلان‌ها: $e')));}}
  @override Widget build(BuildContext context){
    final unread=rows.where((x)=>x['read_at']==null).length;
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:Text('اعلان‌ها${unread>0?' ($unread)':''}'),actions:[if(unread>0)TextButton(onPressed:markAllRead,child:const Text('همه خوانده شد'))]),
      body:loading?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('اعلانی ندارید.')):ListView.builder(
        padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(_,i){final n=rows[i];final unreadItem=n['read_at']==null;return Card(child:ListTile(
          leading:Icon(unreadItem?Icons.notifications_active:Icons.notifications_none),
          title:Text(n['title']?.toString()??'اعلان آگهینو',style:TextStyle(fontWeight:unreadItem?FontWeight.bold:FontWeight.normal)),
          subtitle:Text('${n['body']??''}\\n${n['created_at']??''}'),
          onTap:()=>markRead(n['id'].toString()),
        ));},
      ),
    ));
  }
}
class SavedSearchesPage extends StatefulWidget {
  const SavedSearchesPage({super.key});
  @override State<SavedSearchesPage> createState()=>_SavedSearchesPageState();
}
class _SavedSearchesPageState extends State<SavedSearchesPage>{
  bool loading=true;List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {final uid=supabase.auth.currentUser?.id;if(uid==null){if(mounted)setState(()=>loading=false);return;}try{final r=await supabase.from('saved_searches').select('id,query,filters,created_at').eq('user_id',uid).order('created_at',ascending:false);if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});}catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت جست‌وجوهای ذخیره‌شده: $e')));}}}
  Future<void> deleteSearch(String id) async {final uid=supabase.auth.currentUser?.id;if(uid==null)return;try{await supabase.from('saved_searches').delete().eq('id',id).eq('user_id',uid);await load();}catch(_){ }}
  Future<void> useSearch(Map<String,dynamic> r) async {
    final f = r['filters'] is Map
        ? Map<String, dynamic>.from(r['filters'])
        : <String, dynamic>{};
    if(!mounted)return;
    Navigator.pop(context, <String, dynamic>{
      'query': r['query']?.toString() ?? '',
      'filters': f,
    });
  }
  @override Widget build(BuildContext context){return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('جست‌وجوهای ذخیره‌شده')),body:loading?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('جست‌وجوی ذخیره‌شده‌ای ندارید.')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(_,i){final r=rows[i];final f=r['filters'] is Map?Map<String,dynamic>.from(r['filters']):<String,dynamic>{};final d=<String>[if(f['city']!=null&&f['city'].toString().isNotEmpty)'شهر: ${f['city']}',if(f['category']!=null&&f['category'].toString().isNotEmpty)'دسته: ${f['category']}'].join(' • ');return Card(child:ListTile(title:Text(r['query']?.toString().isNotEmpty==true?r['query'].toString():'جست‌وجوی بدون کلمه'),subtitle:Text(d.isEmpty?'بدون فیلتر':d),trailing:Row(mainAxisSize:MainAxisSize.min,children:[
  IconButton(tooltip:'اجرای جست‌وجو',icon:const Icon(Icons.play_arrow_outlined),onPressed:()=>useSearch(r)),
  IconButton(tooltip:'حذف',icon:const Icon(Icons.delete_outline),onPressed:()=>deleteSearch(r['id'].toString())),
])));},)));}}
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override State<FavoritesPage> createState() => _FavoritesPageState();
}
class _FavoritesPageState extends State<FavoritesPage> {
  bool loading=true; List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async { final u=supabase.auth.currentUser; if(u==null){if(mounted)setState(()=>loading=false);return;} try{final r=await supabase.from('favorites').select('ad_id,ads(*)').eq('user_id',u.id);if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}
  @override Widget build(BuildContext c){if(loading)return const Center(child:CircularProgressIndicator());return Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(16),children:[const Text('آگهی‌های ذخیره‌شده',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),if(rows.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('آگهی ذخیره‌شده‌ای ندارید.')), ...rows.map((r){final ad=r['ads'] is Map?Map<String,dynamic>.from(r['ads']):<String,dynamic>{};return Card(child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>AdDetailPage(ad:ad))),title:Text(ad['title']?.toString()??'بدون عنوان'),subtitle:Text((ad['price']?.toString()??'توافقی')+' تومان • '+(ad['city']?.toString()??''))));})]));}
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override State<SubscriptionPage> createState()=>_SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String,dynamic>? settings;
  final reference=TextEditingController();
  final payerLast4=TextEditingController();
  final note=TextEditingController();
  DateTime? transferAt;
  bool loading=true,sending=false;

  @override void initState(){super.initState();load();}
  @override void dispose(){reference.dispose();payerLast4.dispose();note.dispose();super.dispose();}

  Future<void> load() async {
    try{
      final r=await supabase.from('subscription_settings').select('price,duration_days,ad_limit,image_limit,destination_card,card_holder,bank_name,instructions,enabled').eq('id',true).maybeSingle();
      if(mounted)setState((){settings=r;loading=false;});
    }catch(e){
      if(mounted){
        setState(()=>loading=false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('دریافت اطلاعات اشتراک: $e')));
      }
    }
  }

  String two(int n)=>n.toString().padLeft(2,'0');
  String formatDateTime(DateTime d)=>'${d.year}/${two(d.month)}/${two(d.day)} - ${two(d.hour)}:${two(d.minute)}';

  Future<void> pickTransferTime() async {
    final now=DateTime.now();
    final date=await showDatePicker(
      context:context,
      initialDate:transferAt??now,
      firstDate:DateTime(now.year-1),
      lastDate:DateTime(now.year,now.month,now.day),
      helpText:'تاریخ انتقال را انتخاب کنید',
      confirmText:'تأیید',
      cancelText:'لغو',
    );
    if(date==null||!mounted)return;
    final time=await showTimePicker(
      context:context,
      initialTime:TimeOfDay.fromDateTime(transferAt??now),
      helpText:'ساعت انتقال را انتخاب کنید',
      confirmText:'تأیید',
      cancelText:'لغو',
    );
    if(time==null||!mounted)return;
    setState(()=>transferAt=DateTime(date.year,date.month,date.day,time.hour,time.minute));
  }

  Future<void> submit() async {
    final u=supabase.auth.currentUser;
    final s=settings;
    final ref=reference.text.trim();
    final last4=payerLast4.text.trim();

    if(u==null||s==null||s['enabled']!=true)return;
    if(ref.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره پیگیری/مرجع انتقال را وارد کنید.')));
      return;
    }
    if(last4.isNotEmpty&&!RegExp(r'^\d{4}$').hasMatch(last4)){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('۴ رقم آخر کارت باید دقیقاً ۴ رقم باشد.')));
      return;
    }
    if(transferAt==null){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تاریخ و ساعت انتقال را انتخاب کنید.')));
      return;
    }

    setState(()=>sending=true);
    try{
      final amount=(s['price'] as num).toInt();
      await supabase.from('payments').insert({
        'user_id':u.id,
        'amount':amount,
        'plan':'base_monthly',
        'status':'checking',
        'provider':'manual_card_to_card',
        'payment_note':note.text.trim().isEmpty?null:note.text.trim(),
        'payment_code':ref,
        'metadata':{
          'method':'card_to_card',
          'payer_card_last4':last4.isEmpty?null:last4,
          'transfer_at':transferAt!.toIso8601String(),
          'submitted_at':DateTime.now().toIso8601String(),
        },
      });

      if(!mounted)return;
      await showDialog(
        context:context,
        builder:(_)=>AlertDialog(
          title:const Text('درخواست ثبت شد'),
          content:const Text('اطلاعات پرداخت برای بررسی مدیر ارسال شد. اشتراک فقط بعد از تطبیق انتقال با حساب مقصد و تأیید مدیر فعال می‌شود.'),
          actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('متوجه شدم'))],
        ),
      );
      if(mounted)Navigator.pop(context);
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت پرداخت: $e')));
    }finally{
      if(mounted)setState(()=>sending=false);
    }
  }

  @override Widget build(BuildContext c){
    if(loading)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:CircularProgressIndicator())));
    final s=settings;
    if(s==null||s['enabled']!=true)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:Text('فروش اشتراک فعال نیست.'))));

    final card=s['destination_card']?.toString()??'';
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('خرید اشتراک')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Container(
          padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(
            gradient:const LinearGradient(colors:[Color(0xFF006D77),Color(0xFF0A9396)],begin:Alignment.topRight,end:Alignment.bottomLeft),
            borderRadius:BorderRadius.circular(20),
          ),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('اشتراک آگهینو',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w800)),
            const SizedBox(height:8),
            Text('${s['price']} تومان',style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)),
            const SizedBox(height:6),
            Text('${s['duration_days']} روز • ${s['ad_limit']} آگهی • ${s['image_limit']} عکس برای هر آگهی',style:const TextStyle(color:Colors.white70)),
          ]),
        ),
        const SizedBox(height:12),
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('۱) انتقال کارت‌به‌کارت',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          Row(children:[
            Expanded(child:SelectableText(card.isEmpty?'شماره کارت تنظیم نشده':card,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),
            if(card.isNotEmpty)IconButton(tooltip:'کپی شماره کارت',onPressed:()async{await Clipboard.setData(ClipboardData(text:card));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره کارت کپی شد.')));},icon:const Icon(Icons.copy_all_outlined)),
          ]),
          const SizedBox(height:8),
          Text('صاحب کارت: ${s['card_holder']?.toString()??'-'}'),
          if (card.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'شماره کارت مقصد هنوز توسط مدیر تنظیم نشده است.',
                style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.w600),
              ),
            ),
          Text('بانک: ${s['bank_name']?.toString()??'-'}'),
          const SizedBox(height:10),
          Text(s['instructions']?.toString()??'مبلغ دقیق اشتراک را به کارت مقصد انتقال دهید.'),
        ]))),
        const SizedBox(height:6),
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('۲) مشخصات انتقال',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          TextField(controller:reference,keyboardType:TextInputType.text,decoration:const InputDecoration(labelText:'شماره پیگیری / شماره مرجع انتقال *',hintText:'مثلاً 123456789',border:OutlineInputBorder())),
          const SizedBox(height:10),
          TextField(controller:payerLast4,keyboardType:TextInputType.number,maxLength:4,inputFormatters:[FilteringTextInputFormatter.digitsOnly],decoration:const InputDecoration(labelText:'۴ رقم آخر کارت پرداخت‌کننده (اختیاری)',counterText:'',border:OutlineInputBorder())),
          const SizedBox(height:10),
          InkWell(
            onTap:pickTransferTime,
            borderRadius:BorderRadius.circular(14),
            child:InputDecorator(
              decoration:const InputDecoration(labelText:'تاریخ و ساعت انتقال *',border:OutlineInputBorder()),
              child:Text(transferAt==null?'انتخاب کنید':formatDateTime(transferAt!)),
            ),
          ),
          const SizedBox(height:10),
          TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'توضیح اضافی (اختیاری)',hintText:'مثلاً انتقال از کارت شخص دیگر انجام شده است.',border:OutlineInputBorder())),
        ]))),
        const SizedBox(height:8),
        Card(child:ListTile(
          leading:const Icon(Icons.verified_user_outlined),
          title:const Text('فعال‌سازی امن'),
          subtitle:const Text('ثبت درخواست به‌تنهایی اشتراک را فعال نمی‌کند. مدیر باید انتقال واقعی را با حساب مقصد تطبیق و تأیید کند.'),
        )),
        const SizedBox(height:10),
        SizedBox(height:52,child:FilledButton.icon(
          onPressed:sending || card.isEmpty ? null : submit,
          icon:sending?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded),
          label:Text(sending?'در حال ثبت...':'ثبت اطلاعات برای بررسی'),
        )),
      ]),
    ));
  }
}

class AdDetailPage extends StatefulWidget {
  final Map<String,dynamic> ad;
  const AdDetailPage({super.key,required this.ad});
  @override State<AdDetailPage> createState()=>_AdDetailPageState();
}
class _AdDetailPageState extends State<AdDetailPage>{
  bool saved=false,loading=true;
  List<Map<String,dynamic>> images=[],similar=[];
  Map<String,dynamic>? seller;

  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final u=supabase.auth.currentUser?.id;
    final id=widget.ad['idd']?.toString();
    if(id==null){if(mounted)setState(()=>loading=false);return;}

    try { await supabase.rpc('increment_ad_view',params:{'p_ad_id':id}); } catch (_) {}
    if(u!=null){
      try{
        final fav=await supabase.from('favorites').select('ad_id').eq('user_id',u).eq('ad_id',id).maybeSingle();
        if(mounted)setState(()=>saved=fav!=null);
      }catch(_){}
    }

    List<Map<String,dynamic>> loadedImages=[];
    Map<String,dynamic>? sp;
    List<Map<String,dynamic>> sims=[];
    try{
      final imgs=await supabase.from('ad_images').select('image_url,sort_order,is_primary').eq('ad_id',id).order('sort_order',ascending:true);
      loadedImages=List<Map<String,dynamic>>.from(imgs);
    }catch(_){}

    try{
      final sellerId=widget.ad['seller_id']?.toString();
      if(sellerId!=null){
        sp=Map<String,dynamic>.from((await supabase.from('profiles').select('iidd,name,cphone,created_at').eq('iidd',sellerId).maybeSingle())??{});
      }
    }catch(_){}

    try{
      final r=await supabase.from('ads').select('idd,title,price,city,category,subcategory,publish_status,details,ad_images(image_url,sort_order,is_primary)').eq('category',widget.ad['category']?.toString()??'').eq('publish_status','published').neq('idd',id).limit(6);
      sims=List<Map<String,dynamic>>.from(r);
    }catch(_){}

    if(mounted)setState((){
      images=loadedImages;
      seller=sp;
      similar=sims;
      loading=false;
    });
  }

  void openImageViewer(int initial) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text('${images.length} عکس')),
        body: PageView.builder(
          controller: PageController(initialPage: initial),
          itemCount: images.length,
          itemBuilder: (_, i) => Center(child: InteractiveViewer(
            minScale: 0.8, maxScale: 4.0,
            child: Image.network(images[i]['image_url'].toString(), fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null ? child : const CircularProgressIndicator(),
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 70)),
          )),
        ),
      ),
    )));
  }

  Future<void> deleteOwnAd() async {
    final u=supabase.auth.currentUser?.id;
    final id=widget.ad['idd']?.toString();
    final sellerId=widget.ad['seller_id']?.toString();
    if(u==null||id==null||sellerId!=u)return;
    final ok=await showDialog<bool>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('حذف آگهی'),
        content:const Text('آیا مطمئن هستید که می‌خواهید این آگهی و عکس‌های آن حذف شود؟'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),
          FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حذف')),
        ],
      ),
    );
    if(ok!=true)return;
    try{
      await supabase.from('ad_images').delete().eq('ad_id',id);
      await supabase.from('ads').delete().eq('idd',id).eq('seller_id',u);
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('آگهی و عکس‌های آن حذف شد.')));
      Navigator.pop(context,true);
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حذف آگهی انجام نشد: $e')));
    }
  }

  Future<void> toggle() async {
    final u=supabase.auth.currentUser?.id,id=widget.ad['idd']?.toString();
    if(u==null||id==null)return;
    try{
      if(saved) await supabase.from('favorites').delete().eq('user_id',u).eq('ad_id',id);
      else await supabase.from('favorites').insert({'user_id':u,'ad_id':id});
      if(mounted)setState(()=>saved=!saved);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره آگهی: '+e.toString())));}
  }

  Future<void> report() async {
    final id=widget.ad['idd']?.toString(),u=supabase.auth.currentUser?.id;
    if(id==null||u==null)return;
    final reason=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(
      title:const Text('گزارش آگهی'),
      children:['کلاهبرداری','کالای غیرقانونی','اطلاعات نادرست','قیمت نادرست','محتوای نامناسب','آگهی تکراری','سایر']
        .map((x)=>SimpleDialogOption(onPressed:()=>Navigator.pop(context,x),child:Text(x))).toList()));
    if(reason==null)return;
    try{
      await supabase.from('reports').insert({'reporter_id':u,'ad_id':id,'reason':reason});
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('گزارش شما ثبت شد.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('گزارش: '+e.toString())));}
  }

  Future<void> shareAd() async {
    final text='آگهی آگهینو: ${widget.ad['title']??''} • ${widget.ad['city']??''}';
    await Clipboard.setData(ClipboardData(text:text));
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('متن آگهی کپی شد.')));
  }

  Future<void> startChat() async {
    final u=supabase.auth.currentUser?.id,sellerId=widget.ad['seller_id']?.toString(),adId=widget.ad['idd']?.toString();
    if(u==null||sellerId==null||adId==null||sellerId==u){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('امکان شروع گفت‌وگو وجود ندارد.')));return;}
    try{
      final ex=await supabase.from('conversations').select('id').eq('ad_id',adId).eq('buyer_id',u).eq('seller_id',sellerId).maybeSingle();
      final cid=ex?['id']?.toString()??(await supabase.from('conversations').insert({'buyer_id':u,'seller_id':sellerId,'ad_id':adId,'title':widget.ad['title']?.toString()??'گفت‌وگو'}).select('id').single())['id'].toString();
      if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>ConversationPage(conversationId:cid,title:widget.ad['title']?.toString()??'گفت‌وگو')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('شروع گفت‌وگو: '+e.toString())));}
  }

  Future<void> callSeller() async {
    final sellerId=widget.ad['seller_id']?.toString();
    final phone=seller?['cphone']?.toString();
    if(sellerId==null||phone==null||phone.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره تماس فروشنده در دسترس نیست.')));return;}
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Widget _specRow(String label, String value, IconData icon, {bool emphasize=false}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Row(
              children: [
                Icon(icon, size: 19, color: const Color(0xFF006D77)),
                const SizedBox(width: 7),
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: emphasize ? 16.5 : 14.5,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override Widget build(BuildContext c){
    final title=widget.ad['title']?.toString()??'بدون عنوان';
    final price=widget.ad['price']?.toString()??'توافقی';
    final city=widget.ad['city']?.toString()??'';
    final cat=widget.ad['category']?.toString()??'';
    final desc=widget.ad['edescription']?.toString()??'توضیحی ثبت نشده است.';
    final condition=widget.ad['item_condition']?.toString()??'';
    final neighborhood=widget.ad['neighborhood']?.toString()??'';
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('جزئیات آگهی'),actions:[
        if(widget.ad['seller_id']?.toString()==supabase.auth.currentUser?.id)
          IconButton(onPressed:deleteOwnAd,tooltip:'حذف آگهی',icon:const Icon(Icons.delete_outline)),
        IconButton(onPressed:shareAd,icon:const Icon(Icons.share_outlined)),
        IconButton(onPressed:toggle,icon:Icon(saved?Icons.favorite:Icons.favorite_border)),
      ]),
      body:loading?const Center(child:CircularProgressIndicator()):ListView(
        children:[
          if (images.isNotEmpty)
            SizedBox(
              height: 270,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => openImageViewer(i),
                  child: Image.network(
                    images[i]['image_url'].toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined, size: 60),
                    ),
                  ),
                ),
              ),
            ),
          Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),
            const SizedBox(height:14),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _specRow('قیمت', price == 'توافقی' ? 'توافقی' : '$price تومان', Icons.payments_outlined, emphasize: true),
                    _specRow('دسته‌بندی', cat, Icons.category_outlined),
                    _specRow('زیرمجموعه', widget.ad['subcategory']?.toString() ?? '', Icons.account_tree_outlined),
                    _specRow('وضعیت', condition, Icons.verified_outlined),
                    if (cat == 'خودرو') ...[
                      _specRow('برند', widget.ad['vehicle_brand']?.toString() ?? '', Icons.directions_car_outlined),
                      _specRow('مدل خودرو', widget.ad['vehicle_model']?.toString() ?? '', Icons.drive_file_rename_outline),
                      _specRow('سال ساخت', widget.ad['vehicle_year']?.toString() ?? '', Icons.calendar_month_outlined),
                      _specRow('کارکرد', widget.ad['vehicle_mileage'] == null ? '' : '${widget.ad['vehicle_mileage']} کیلومتر', Icons.speed_outlined),
                      _specRow('رنگ', widget.ad['vehicle_color']?.toString() ?? '', Icons.color_lens_outlined),
                      _specRow('گیربکس', widget.ad['vehicle_transmission']?.toString() ?? '', Icons.settings_outlined),
                      _specRow('وضعیت بدنه', widget.ad['vehicle_body_condition']?.toString() ?? '', Icons.car_repair_outlined),
                      _specRow('سوخت', widget.ad['vehicle_fuel']?.toString() ?? '', Icons.local_gas_station_outlined),
                      _specRow('معاوضه', widget.ad['vehicle_exchange'] == true ? 'بله' : '', Icons.swap_horiz_outlined),
                    ],
                    _specRow('استان', widget.ad['province']?.toString() ?? '', Icons.map_outlined),
                    _specRow('شهر', city, Icons.location_on_outlined),
                    _specRow('محله', neighborhood, Icons.place_outlined),
                    if(widget.ad['details'] is Map && (widget.ad['details'] as Map).isNotEmpty) ...[
                      const Divider(height:24),
                      ...(widget.ad['details'] as Map).entries.map((e)=>_specRow(e.key.toString(),e.value.toString(),Icons.info_outline)),
                    ],
                    _specRow('بازدید', '${widget.ad['view_count'] ?? 0}', Icons.visibility_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height:18),
            const Text('توضیحات آگهی',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
            const SizedBox(height:6),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(desc, style: const TextStyle(fontSize: 15.5, height: 1.8)),
              ),
            ),
            const SizedBox(height:20),
            if(seller!=null)Card(child:ListTile(
              leading:const CircleAvatar(child:Icon(Icons.person)),
              title:Text(seller!['name']?.toString()??'فروشنده'),
              subtitle:Text('عضویت: ${seller!['created_at']?.toString().split('T').first??'-'}'),
              trailing:const Icon(Icons.person_outline),
              onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SellerProfilePage(sellerId:seller!['iidd'].toString()))),
            )),
            const SizedBox(height:8),
            Row(children:[
              Expanded(child:FilledButton.icon(onPressed:callSeller,icon:const Icon(Icons.phone),label:const Text('تماس'))),
              const SizedBox(width:8),
              Expanded(child:OutlinedButton.icon(onPressed:startChat,icon:const Icon(Icons.chat),label:const Text('پیام'))),
            ]),
            const SizedBox(height:8),
            OutlinedButton.icon(onPressed:report,icon:const Icon(Icons.flag_outlined),label:const Text('گزارش آگهی')),
            if(similar.isNotEmpty)...[
              const SizedBox(height:18),
              const Text('آگهی‌های مشابه',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
              const SizedBox(height:8),
              SizedBox(height:145,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:similar.length,itemBuilder:(_,i){
                final x=similar[i];
                return SizedBox(width:190,child:Card(child:ListTile(
                  title:Text(x['title']?.toString()??'',maxLines:2,overflow:TextOverflow.ellipsis),
                  subtitle:Text((x['price']?.toString()??'توافقی')+' تومان\n'+(x['city']?.toString()??'')),
                  onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdDetailPage(ad:x))),
                )));
              },separatorBuilder:(_,__)=>const SizedBox(width:8))),
            ],
          ])),
        ],
      ),
    ));
  }
}
class SellerProfilePage extends StatefulWidget {
  final String sellerId;
  const SellerProfilePage({super.key, required this.sellerId});
  @override State<SellerProfilePage> createState()=>_SellerProfilePageState();
}
class _SellerProfilePageState extends State<SellerProfilePage>{
  bool loading=true; Map<String,dynamic>? profile; List<Map<String,dynamic>> ads=[]; int views=0;
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    try{
      final p=await supabase.from('profiles').select('iidd,name,cphone,city,created_at,avatar_url,profile_views').eq('iidd',widget.sellerId).maybeSingle();
      final a=await supabase.from('ads').select('idd,title,price,city,category,view_count,publish_status,details').eq('seller_id',widget.sellerId).eq('publish_status','published').limit(50);
      final pv=(p?['profile_views'] as int?)??0;
      if(mounted)setState((){profile=p;ads=List<Map<String,dynamic>>.from(a);views=pv;loading=false;});
      try{await supabase.rpc('increment_profile_view',params:{'p_seller_id':widget.sellerId});}catch(_){ }
    }catch(_){if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context){
    if(loading)return const Center(child:CircularProgressIndicator());
    final p=profile??{}; final name=p['name']?.toString()??'فروشنده آگهینو';
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('پروفایل فروشنده')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:ListTile(
          leading:CircleAvatar(backgroundImage:(p['avatar_url']?.toString().isNotEmpty==true)?NetworkImage(p['avatar_url'].toString()):null,child:(p['avatar_url']?.toString().isNotEmpty==true)?null:const Icon(Icons.person)),
          title:Text(name,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
          subtitle:Text('${p['city']??''}\nعضویت: ${p['created_at']?.toString().split('T').first??'-'}'),
        )),
        Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[Text('آگهی‌ها: ${ads.length}'),Text('مشاهده پروفایل: ${views+1}')]),
        const SizedBox(height:16),
        const Text('آگهی‌های فعال',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        if(ads.isEmpty)const Text('آگهی فعالی ندارد.'),
        ...ads.map((ad)=>Card(
          child:ListTile(
            title:Text(ad['title']?.toString()??''),
            subtitle:Text('${ad['price']??'توافقی'} تومان • ${ad['city']??''}'),
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdDetailPage(ad:ad))),
          ),
         )),
      ]),
    ));
  }
}
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override State<MessagesPage> createState()=>_MessagesPageState();
}
class _MessagesPageState extends State<MessagesPage>{
  bool loading=true; List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final u=supabase.auth.currentUser;
    if(u==null){if(mounted)setState(()=>loading=false);return;}
    try{
      final r=await supabase.from('conversations').select('*').or('buyer_id.eq.${u.id},seller_id.eq.${u.id}').order('created_at',ascending:false);
      if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});
    }catch(_){if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext c){
    if(loading)return const Center(child:CircularProgressIndicator());
    return Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('پیام‌ها',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      if(rows.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('هنوز گفت‌وگویی ندارید.')),
      ...rows.map((r)=>Card(child:ListTile(
        title:Text(r['title']?.toString()??'گفت‌وگو'),
        subtitle:Text(r['updated_at']?.toString()??r['created_at']?.toString()??''),
        leading:const Icon(Icons.chat_bubble_outline),
        onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ConversationPage(conversationId:r['id'].toString(),title:r['title']?.toString()??'گفت‌وگو'))),
      ))),
    ]));
  }
}
class ConversationPage extends StatefulWidget {
  final String conversationId, title;
  const ConversationPage({super.key, required this.conversationId, required this.title});
  @override State<ConversationPage> createState() => _ConversationPageState();
}
class _ConversationPageState extends State<ConversationPage> {
  final input=TextEditingController();
  bool loading=true, sending=false;
  List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  @override void dispose(){input.dispose();super.dispose();}
  Future<void> load() async {
    try {
      final r=await supabase.from('messages').select('*').eq('conversation_id',widget.conversationId).order('created_at');
      final uid=supabase.auth.currentUser?.id;
      if(uid!=null){
        await supabase.from('messages').update({'read_at':DateTime.now().toIso8601String()})
          .eq('conversation_id',widget.conversationId).neq('sender_id',uid).isFilter('read_at',null);
      }
      if(mounted)setState((){rows=List<Map<String,dynamic>>.from(r);loading=false;});
    } catch(e) { if(mounted)setState(()=>loading=false); }
  }
  Future<void> deleteConversation() async {
    final ok=await showDialog<bool>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('حذف گفتگو'),
        content:const Text('این گفتگو برای شما حذف می‌شود. ادامه می‌دهید؟'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),
          FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حذف')),
        ],
      ),
    );
    if(ok!=true)return;
    try{
      await supabase.from('messages').delete().eq('conversation_id',widget.conversationId);
      await supabase.from('conversations').delete().eq('id',widget.conversationId);
      if(mounted)Navigator.pop(context,true);
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حذف گفتگو: $e')));
    }
  }

  Future<void> send() async {
    final body=input.text.trim(); final u=supabase.auth.currentUser?.id;
    if(body.isEmpty||u==null)return;
    setState(()=>sending=true);
    try {
      await supabase.from('messages').insert({'conversation_id':widget.conversationId,'sender_id':u,'body':body});
      input.clear(); await load();
    } catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ارسال پیام: '+e.toString()))); }
    finally { if(mounted)setState(()=>sending=false); }
  }
  @override Widget build(BuildContext c) {
    final u=supabase.auth.currentUser?.id;
    return Directionality(
      textDirection:TextDirection.rtl,
      child:Scaffold(
        appBar:AppBar(
          title:Text(widget.title),
          actions:[
            IconButton(
              tooltip:'حذف گفتگو',
              icon:const Icon(Icons.delete_outline),
              onPressed:deleteConversation,
            ),
          ],
        ),
        body:Column(
          children:[
            Expanded(
              child:loading
                ? const Center(child:CircularProgressIndicator())
                : ListView(
                    padding:const EdgeInsets.all(12),
                    children:rows.map((r){
                      final mine=r['sender_id']==u;
                      return Align(
                        alignment:mine?Alignment.centerLeft:Alignment.centerRight,
                        child:Card(child:Padding(padding:const EdgeInsets.all(10),child:Text(r['body']?.toString()??''))),
                      );
                    }).toList(),
                  ),
            ),
            SafeArea(
              child:Row(
                children:[
                  Expanded(child:TextField(controller:input,decoration:const InputDecoration(hintText:'پیام خود را بنویسید'))),
                  IconButton(onPressed:sending?null:send,icon:const Icon(Icons.send)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}