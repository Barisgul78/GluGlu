import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/snackbars.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/models/health_card.dart';
import '../../data/services/profile_service.dart';
import '../widgets/health_card_widgets.dart';

// Sağlık kartı oluştur (initial == null) / düzenle (initial dolu) formu.
// popOnSave: düzenlemede kayıttan sonra geri döner; oluşturmada ekranı
// HealthCardScreen'in stream'i kendiliğinden kart görünümüne çevirir.
class HealthCardFormScreen extends StatefulWidget {
  const HealthCardFormScreen({super.key, this.initial, this.popOnSave = false});

  final HealthCard? initial;
  final bool popOnSave;

  @override
  State<HealthCardFormScreen> createState() => _HealthCardFormScreenState();
}

class _HealthCardFormScreenState extends State<HealthCardFormScreen> {
  final _adCtrl = TextEditingController();
  final _avoidedCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final Set<HealthNeed> _needs = {};
  bool _crossContact = false;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  bool get _valid =>
      _adCtrl.text.trim().length >= 2 &&
      _needs.isNotEmpty &&
      _avoidedCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _adCtrl.text = initial.adSoyad;
      _avoidedCtrl.text = initial.avoided;
      _noteCtrl.text = initial.note;
      _needs.addAll(initial.needs);
      _crossContact = initial.crossContact;
    } else {
      _prefillName();
    }
  }

  // Ad soyad profilden önerilir; kullanıcı bu arada yazmaya başladıysa dokunulmaz.
  Future<void> _prefillName() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;
    try {
      final data = (await ProfileService.getUser(uid)).data();
      final name = [data?['ad'], data?['soyad']]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ');
      if (!mounted || name.isEmpty || _adCtrl.text.isNotEmpty) return;
      setState(() => _adCtrl.text = name);
    } catch (e) {
      debugPrint('Profil adı okunamadı: $e');
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _avoidedCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    final uid = AuthService.currentUserId;
    if (uid == null) {
      showErrorSnackBar(context, 'Kartı kaydetmek için giriş yapman gerekiyor.');
      return;
    }
    final card = HealthCard(
      adSoyad: _adCtrl.text.trim(),
      needs: HealthNeed.values.where(_needs.contains).toList(),
      avoided: _avoidedCtrl.text.trim(),
      crossContact: _crossContact,
      note: _noteCtrl.text.trim(),
    );

    setState(() => _saving = true);
    try {
      await ProfileService.saveHealthCard(uid, card);
      if (!mounted) return;
      if (widget.popOnSave) {
        showInfoSnackBar(context, 'Sağlık kartın güncellendi.');
        context.pop();
      }
    } catch (e) {
      debugPrint('Sağlık kartı kaydedilemedi: $e');
      if (!mounted) return;
      showErrorSnackBar(
          context, 'Sağlık kartı kaydedilemedi. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            HealthCardAppBar(
              title: _isEdit ? 'Sağlık kartını düzenle' : 'Sağlık kartı oluştur',
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPaddingH,
                  vertical: AppSizes.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(),
                    const SizedBox(height: AppSizes.lg),
                    _label('Ad soyad *'),
                    const SizedBox(height: AppSizes.sm + 2),
                    TextField(
                      controller: _adCtrl,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      style: _inputStyle,
                      decoration: _decoration('Adını ve soyadını yaz'),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    _label('Beslenme ihtiyacın *'),
                    const SizedBox(height: AppSizes.xs),
                    _hint('Sana uygun olanları seçebilirsin.'),
                    const SizedBox(height: AppSizes.sm + 4),
                    _buildNeeds(),
                    const SizedBox(height: AppSizes.lg),
                    _label('Tüketemediğin besinler *'),
                    const SizedBox(height: AppSizes.sm + 2),
                    TextField(
                      controller: _avoidedCtrl,
                      maxLength: 300,
                      minLines: 3,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      style: _inputStyle,
                      decoration: _decoration(
                        'Örn. buğday, arpa, çavdar ve bunları içeren ürünler',
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _buildCrossContact(),
                    const SizedBox(height: AppSizes.lg),
                    _label('Eklemek istediğin bir not var mı?'),
                    const SizedBox(height: AppSizes.xs),
                    _hint('İsteğe bağlı · Kartında aynen görünür.'),
                    const SizedBox(height: AppSizes.sm + 2),
                    TextField(
                      controller: _noteCtrl,
                      maxLength: HealthCard.maxNoteLength,
                      minLines: 3,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      style: _inputStyle,
                      decoration:
                          _decoration('Mekânın bilmesini istediğin diğer ihtiyaçların...'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_noteCtrl.text.length} / ${HealthCard.maxNoteLength}',
                        style: GoogleFonts.manrope(
                          color: kOnSurfaceVariant,
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _buildDisclaimer(),
                    const SizedBox(height: AppSizes.md),
                    _buildSubmit(),
                    const SizedBox(height: AppSizes.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _inputStyle => GoogleFonts.manrope(
        color: kOnSurface,
        fontWeight: FontWeight.w600,
        fontSize: AppSizes.fontLg - 1,
      );

  // Sayaç `counterText: ''` ile gizli; sınırı maxLength uygular.
  InputDecoration _decoration(String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        color: kOnSurfaceVariant.withValues(alpha: 0.8),
        fontWeight: FontWeight.w600,
        fontSize: AppSizes.fontLg - 1,
      ),
      counterText: '',
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.md,
      ),
      enabledBorder: border(kOutlineVariant.withValues(alpha: 0.6)),
      focusedBorder: border(kPrimary),
      border: border(kOutlineVariant.withValues(alpha: 0.6)),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.manrope(
          color: kOnSurface,
          fontWeight: FontWeight.bold,
          fontSize: AppSizes.fontLg,
        ),
      );

  Widget _hint(String text) => Text(
        text,
        style: GoogleFonts.manrope(
          color: kOnSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: AppSizes.fontMd - 1,
        ),
      );

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İhtiyaçlarını birlikte anlatalım.',
          style: GoogleFonts.manrope(
            color: kOnSurface,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontXxl,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Beslenme bilgilerini ekle, mekânlarda kolayca gösterebileceğin kartını oluştur.',
          style: GoogleFonts.manrope(
            color: kOnSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.fontMd,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          '* Zorunlu alanlar',
          style: GoogleFonts.manrope(
            color: kOnSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.fontSm,
          ),
        ),
      ],
    );
  }

  Widget _buildNeeds() {
    const values = HealthNeed.values;
    final rows = <Widget>[];
    for (var i = 0; i < values.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: _needTile(values[i])),
          const SizedBox(width: AppSizes.sm + 4),
          Expanded(
            child: i + 1 < values.length
                ? _needTile(values[i + 1])
                : const SizedBox.shrink(),
          ),
        ],
      ));
      if (i + 2 < values.length) rows.add(const SizedBox(height: AppSizes.sm + 4));
    }
    return Column(children: rows);
  }

  void _toggleNeed(HealthNeed need, bool selected) {
    setState(() => selected ? _needs.add(need) : _needs.remove(need));
  }

  Widget _needTile(HealthNeed need) {
    final selected = _needs.contains(need);
    return GestureDetector(
      onTap: () => _toggleNeed(need, !selected),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm + 4,
          vertical: AppSizes.sm + 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: selected ? kPrimary : kOutlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            _checkbox(selected, (v) => _toggleNeed(need, v)),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                need.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: kOnSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.fontMd - 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkbox(bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: kPrimary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildCrossContact() {
    return GestureDetector(
      onTap: () => setState(() => _crossContact = !_crossContact),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: kPrimaryFixed.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _checkbox(_crossContact, (v) => setState(() => _crossContact = v)),
            const SizedBox(width: AppSizes.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Çapraz temas uyarısı ekle',
                    style: GoogleFonts.manrope(
                      color: kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.fontMd + 1,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Kartında ayrı ve temiz ekipman, yağ ve yüzey kullanılması gerektiği belirtilir.',
                    style: GoogleFonts.manrope(
                      color: kOnSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontMd - 1,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: kOnSurfaceVariant, size: AppSizes.icon20),
        const SizedBox(width: AppSizes.sm + 4),
        Expanded(
          child: Text(
            'Bilgilerin kartında görünür. Bu kart senin beyanına dayanır; tıbbi belge değildir. Daha sonra düzenleyebilirsin.',
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: AppSizes.fontSm + 1,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // AppButton pasifte beyaz yazı kullandığı için burada pasif görünüm yerel.
  Widget _buildSubmit() {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: FilledButton(
        onPressed: _valid && !_saving ? _save : null,
        style: FilledButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kPrimaryFixed.withValues(alpha: 0.6),
          disabledForegroundColor: kOnSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: kPrimary),
              )
            : Text(
                _isEdit ? 'Değişiklikleri kaydet' : 'Kartımı oluştur',
                style: GoogleFonts.manrope(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
