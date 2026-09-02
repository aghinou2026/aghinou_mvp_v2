from pathlib import Path
import re

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')

# Human-readable relative publication time.
helper = r'''
String aghinouTimeAgo(dynamic value) {
  if (value == null) return '';
  final dt = DateTime.tryParse(value.toString())?.toLocal();
  if (dt == null) return '';
  final d = DateTime.now().difference(dt);
  if (d.isNegative || d.inMinutes < 1) return 'همین الان';
  if (d.inMinutes < 60) return '${d.inMinutes} دقیقه پیش';
  if (d.inHours < 24) return '${d.inHours} ساعت پیش';
  if (d.inDays < 7) return '${d.inDays} روز پیش';
  if (d.inDays < 30) return '${(d.inDays / 7).floor()} هفته پیش';
  if (d.inDays < 365) return '${(d.inDays / 30).floor()} ماه پیش';
  return '${(d.inDays / 365).floor()} سال پیش';
}

const aghinouCategoryIcons = <String, IconData>{
  'خودرو': Icons.directions_car_rounded,
  'املاک': Icons.home_work_rounded,
  'موبایل': Icons.phone_android_rounded,
  'لوازم خانه': Icons.chair_rounded,
  'کالای دیجیتال': Icons.devices_other_rounded,
  'پوشاک': Icons.checkroom_rounded,
  'خدمات': Icons.handyman_rounded,
};

'''
if 'String aghinouTimeAgo(dynamic value)' not in text:
    marker = "const categoryNames = ['همه', 'خودرو', 'املاک', 'موبایل', 'لوازم خانه', 'کالای دیجیتال', 'پوشاک', 'خدمات'];"
    text = text.replace(marker, helper + marker, 1)

# Replace the existing horizontal ad card with a compact square-image marketplace card.
start = text.find('  Widget card(Map<String, dynamic> ad) {')
end = text.find('  Widget home() {', start)
if start != -1 and end != -1:
    new_card = r'''  Widget card(Map<String, dynamic> ad) {
    final id = '${ad['idd'] ?? ''}';
    return FutureBuilder<List<String>>(
      future: imageUrls(id),
      builder: (context, s) {
        final imgs = s.data ?? const <String>[];
        final liked = favorites.contains(id);
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1.5,
          child: InkWell(
            onTap: () => openDetails(ad, imgs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imgs.isEmpty
                          ? const ColoredBox(color: Color(0xFFEDEDED), child: Icon(Icons.image_outlined, size: 42))
                          : Image.network(imgs.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE8E0FF), child: Icon(Icons.broken_image))),
                      if (imgs.length > 1)
                        Positioned(bottom: 7, right: 7, child: photoCountBadge(imgs.length)),
                      Positioned(
                        top: 5,
                        left: 5,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: const CircleBorder(),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() { if (liked) { favorites.remove(id); } else { favorites.add(id); } }),
                            icon: Icon(liked ? Icons.favorite : Icons.favorite_border, size: 21),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${ad['title'] ?? 'بدون عنوان'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.35)),
                      const SizedBox(height: 6),
                      Text('${ad['price'] ?? 'توافقی'} تومان', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Text('${ad['city'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
                          const SizedBox(width: 5),
                          Text(aghinouTimeAgo(ad['created_at']), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

'''
    text = text[:start] + new_card + text[end:]

# Replace the home method only; keep the existing navigation/tab shell below it intact.
start = text.find('  Widget home() {')
if start != -1:
    depth = 0
    body_start = text.find('{', start)
    i = body_start
    while i < len(text):
        if text[i] == '{': depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                i += 1
                break
        i += 1
    new_home = r'''  Widget home() {
    if (loading) return const Center(child: CircularProgressIndicator());
    final visibleCategories = categoryNames.where((x) => x != 'همه').toList();
    return RefreshIndicator(
      onRefresh: loadAds,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text('${city == 'همه شهرها' ? 'ایران' : city}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(onPressed: chooseCity, icon: const Icon(Icons.location_on_outlined)),
                  IconButton(onPressed: loadAds, icon: const Icon(Icons.refresh_rounded)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: searchController,
                onChanged: (v) => setState(() => search = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'چی می‌خوای پیدا کنی؟',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: search.isNotEmpty ? IconButton(onPressed: () { searchController.clear(); setState(() => search = ''); }, icon: const Icon(Icons.close)) : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('دسته‌بندی‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  TextButton(onPressed: chooseCategory, child: const Text('همه')),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final name = visibleCategories[index];
                  final selected = category == name;
                  return InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () async {
                      final p = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => CategoryPage(initialCategory: name, initialSubcategory: 'همه')));
                      if (p != null && mounted) {
                        final parts = p.split('|||');
                        setState(() { category = parts[0]; subcategory = parts.length > 1 ? parts[1] : 'همه'; });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.25)),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(aghinouCategoryIcons[name] ?? Icons.category_rounded, size: 31),
                        const SizedBox(height: 7),
                        Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  );
                },
                childCount: visibleCategories.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: 1.02),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 9),
            sliver: SliverToBoxAdapter(child: Text(category == 'همه' ? 'جدیدترین آگهی‌ها' : 'آگهی‌های $category', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
          ),
          if (filtered.isEmpty)
            const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 14), sliver: SliverToBoxAdapter(child: Card(child: Padding(padding: EdgeInsets.all(20), child: Text('آگهی‌ای برای نمایش پیدا نشد.')))))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) => card(filtered[index]), childCount: filtered.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 2, childAspectRatio: 0.72),
              ),
            ),
        ],
      ),
    );
  }'''
    text = text[:start] + new_home + text[i:]

path.write_text(text, encoding='utf-8')
print('Carousell-style compact square-card home UI applied.')
