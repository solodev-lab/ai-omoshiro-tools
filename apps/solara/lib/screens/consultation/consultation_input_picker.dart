// Consultation Input Screen — 具体地点ピッカー部品
// (part of 'consultation_input_screen.dart')
//
// scope='specific' 専用の inline 地点ピッカー (A) を提供する。
// 検索 + LOCATION quick-pick + 「地図で選ぶ」(B) を 1 ユニットに集約。
// 元 consultation_input_widgets.dart から L11-23 (_PickedSpecific) と
// L836-1295 (_SpecificPicker 系) を切り出し (ファイル肥大化対策、2026-05-16)。

part of 'consultation_input_screen.dart';

/// _SpecificPicker からの選択結果を持ち回す軽量レコード。
class _PickedSpecific {
  final LatLng position;
  final String name;
  final String region;
  final String country;

  /// 'named' = 検索/地図で選んだ具体地点 (場所名をそのまま使う) /
  /// 'saved' = ViewPoint/Locations の登録地 (「登録名」という場所、と呼ぶ)。
  final String placeKind;
  const _PickedSpecific({
    required this.position,
    required this.name,
    this.region = '',
    this.country = '',
    this.placeKind = 'named',
  });
}

/// inline 地点ピッカー (A)。検索 + LOCATION quick-pick + 「地図で選ぶ」(B) を集約。
///
/// presetTarget が null の specific スコープ専用。プリセットがあるときは
/// _PresetLocationCard で「✓ 京都 を見ます」を表示するだけで本 picker は出さない。
class _SpecificPicker extends StatefulWidget {
  final _PickedSpecific? selected;
  final ValueChanged<_PickedSpecific> onSelect;
  final VoidCallback onClear;
  final Future<_PickedSpecific?> Function() onOpenMapPicker;

  /// 検索時の bias center (Google Places の locationBias 15km、Nominatim には影響なし)。
  /// 現在地 or プリセットの座標を渡すと、曖昧クエリ ('スターバックス' 等) が
  /// その周辺に寄る。null なら従来の bias 無し検索。
  final LatLng? biasCenter;

  const _SpecificPicker({
    required this.selected,
    required this.onSelect,
    required this.onClear,
    required this.onOpenMapPicker,
    this.biasCenter,
  });

  @override
  State<_SpecificPicker> createState() => _SpecificPickerState();
}

class _SpecificPickerState extends State<_SpecificPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  List<map_search.SearchHit> _hits = const [];

  bool _loadingSlots = true;
  List<VPSlot> _locationSlots = const [];
  List<VPSlot> _viewpointSlots = const [];

  final SlotManager _locMgr =
      SlotManager(storageKey: 'solara_locations');
  final SlotManager _vpMgr =
      SlotManager(storageKey: 'solara_vp_slots');

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    final loc = await _locMgr.load();
    final vp = await _vpMgr.load();
    if (!mounted) return;
    setState(() {
      _locationSlots = loc;
      _viewpointSlots = vp;
      _loadingSlots = false;
    });
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    final q = v.trim();
    if (q.length < 2) {
      setState(() {
        _hits = const [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    // biasCenter があれば Google Places 経由で周辺優先 (Nominatim 経由は無視される)。
    // Daily Transit 起点で具体地点を選ぶときは「現在地周辺」のクエリが多いため、
    // 現在地を bias に使うことで「スタバ」「コンビニ」のような曖昧語が地理的に絞れる。
    final hits =
        await map_search.searchPlaces(q, biasCenter: widget.biasCenter);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
  }

  void _onHitTap(map_search.SearchHit h) {
    final parts = h.name.split(',').map((s) => s.trim()).toList();
    final short = parts.isNotEmpty ? parts.first : h.name;
    // hit.country は Worker レスポンスでは ISO code (大文字小文字混在の可能性)。
    // CandidateLocation.country は大文字慣習なので合わせる。
    final cc = h.country?.toUpperCase() ?? '';
    widget.onSelect(_PickedSpecific(
      position: LatLng(h.lat, h.lng),
      name: short,
      country: cc,
    ));
    _searchCtrl.clear();
    setState(() => _hits = const []);
  }

  void _onSlotTap(VPSlot s) {
    widget.onSelect(_PickedSpecific(
      position: LatLng(s.lat, s.lng),
      name: s.name,
      placeKind: 'saved', // 登録地 → Stella は「登録名」という場所、と呼ぶ
    ));
  }

  Future<void> _openMapPicker() async {
    final picked = await widget.onOpenMapPicker();
    if (picked != null) {
      widget.onSelect(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 選択中表示 (あれば最上段に出す)
        if (selected != null) ...[
          _SelectedSpecificCard(picked: selected, onClear: widget.onClear),
          const SizedBox(height: 12),
        ],

        // 検索フィールド
        Container(
          decoration: BoxDecoration(
            color: const Color(0x10FFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SolaraColors.glassBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              const Icon(Icons.search,
                  size: 18, color: SolaraColors.solaraGold),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    hintText: '住所 / 店名で検索',
                    hintStyle: TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (_searching)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: SolaraColors.solaraGold,
                    ),
                  ),
                ),
              if (_searchCtrl.text.isNotEmpty && !_searching) ...[
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 14, color: SolaraColors.textSecondary),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                  },
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tooltip: 'クリア',
                ),
              ],
            ],
          ),
        ),

        // 検索結果 (最大 5 件、scroll なし)
        if (_hits.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0x10FFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SolaraColors.glassBorder),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _hits.length && i < 5; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: Color(0x11FFFFFF)),
                  _SearchHitRow(
                    index: i + 1,
                    hit: _hits[i],
                    onTap: () => _onHitTap(_hits[i]),
                  ),
                ],
              ],
            ),
          ),
        ],

        // VIEWPOINT 保存地点 (chips) — グループ1
        if (_loadingSlots == false && _viewpointSlots.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            '🔭 視点 (ViewPoint) から',
            style: TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _viewpointSlots.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _LocationChip(
                    slot: _viewpointSlots[i],
                    onTap: () => _onSlotTap(_viewpointSlots[i]),
                  ),
                ],
              ],
            ),
          ),
        ],

        // LOCATIONS 保存地点 (chips) — グループ2
        if (_loadingSlots == false && _locationSlots.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            '📍 保存地点 (Locations) から',
            style: TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _locationSlots.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _LocationChip(
                    slot: _locationSlots[i],
                    onTap: () => _onSlotTap(_locationSlots[i]),
                  ),
                ],
              ],
            ),
          ),
        ],

        // 「地図で選ぶ」 (B picker へ push)
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _openMapPicker,
          icon: const Icon(Icons.map_outlined,
              size: 18, color: SolaraColors.solaraGoldLight),
          label: const Text(
            '地図で選ぶ',
            style: TextStyle(
              color: SolaraColors.solaraGoldLight,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Color(0x66F6BD60)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHitRow extends StatelessWidget {
  final int index;
  final map_search.SearchHit hit;
  final VoidCallback onTap;
  const _SearchHitRow(
      {required this.index, required this.hit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 場所名 + 住所行を組み立てる。
    // Google Places 経路: hit.name = 短い場所名 (例 'Tokyo Tower')、hit.address に formattedAddress
    // Nominatim 経路: hit.name = 'A, B, C, D, ...' の display_name、hit.address は null
    final String short;
    final String sub;
    if (hit.address != null && hit.address!.isNotEmpty) {
      short = hit.name;
      sub = hit.address!;
    } else {
      final parts = hit.name.split(',').map((s) => s.trim()).toList();
      short = parts.isNotEmpty ? parts.first : hit.name;
      sub = parts.length > 1 ? parts.skip(1).join(', ') : '';
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SolaraColors.solaraGold,
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  color: SolaraColors.celestialBlueDark,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    short,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  final VPSlot slot;
  final VoidCallback onTap;
  const _LocationChip({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x10FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SolaraColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(slot.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              slot.name,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedSpecificCard extends StatelessWidget {
  final _PickedSpecific picked;
  final VoidCallback onClear;
  const _SelectedSpecificCard({required this.picked, required this.onClear});

  String? _addressLine() {
    final parts = <String>[
      if (picked.region.isNotEmpty) picked.region,
      if (picked.country.isNotEmpty) picked.country,
    ];
    return parts.isEmpty ? null : parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0x14F6BD60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x66F6BD60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: SolaraColors.solaraGold),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    picked.name,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_addressLine() != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${_addressLine()})',
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close,
                size: 14, color: SolaraColors.textSecondary),
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: '選択を解除',
          ),
        ],
      ),
    );
  }
}
