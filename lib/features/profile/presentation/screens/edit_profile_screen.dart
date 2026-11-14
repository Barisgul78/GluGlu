import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/snackbars.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/services/profile_service.dart';
import '../widgets/city_picker_sheet.dart';
import '../widgets/profile_ui.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _kullaniciAdiCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _currentUsername = '';
  String? _sehir;
  bool _loading = true;
  bool _saving = false;
  bool _emailVerified = false;
  bool _sendingVerification = false;
  bool _checkingVerification = false;

  @override
  void initState() {
    super.initState();
    _emailVerified = AuthService.currentUser?.emailVerified ?? false;
    _emailCtrl.text = AuthService.currentUser?.email ?? '';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = AuthService.currentUserId;
    if (uid != null) {
      final doc = await ProfileService.getUser(uid);
      final data = doc.data();
      final username = data?['kullaniciAdi'] as String? ?? '';
      final sehir = data?['sehir'] as String?;
      if (mounted) {
        setState(() {
          _adCtrl.text = data?['ad'] as String? ?? '';
          _soyadCtrl.text = data?['soyad'] as String? ?? '';
          _telefonCtrl.text = data?['telefon'] as String? ?? '';
          _sehir = (sehir == null || sehir.isEmpty) ? null : sehir;
          _currentUsername = username;
          _kullaniciAdiCtrl.text = username;
          _loading = false;
        });
      }
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _kullaniciAdiCtrl.dispose();
    _telefonCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _sendingVerification = true);
    try {
      await AuthService.sendEmailVerification();
      if (!mounted) return;
      showInfoSnackBar(context, 'Doğrulama e-postası gönderildi, gelen kutunu kontrol et.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, AuthService.errorMessage(e.code));
    } catch (_) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _sendingVerification = false);
    }
  }

  Future<void> _refreshVerificationStatus() async {
    setState(() => _checkingVerification = true);
    try {
      final verified = await AuthService.reloadAndCheckEmailVerified();
      if (!mounted) return;
      setState(() => _emailVerified = verified);
      showInfoSnackBar(
        context,
        verified ? 'E-postan doğrulanmış! 🎉' : 'Henüz doğrulanmamış görünüyor.',
      );
    } finally {
      if (mounted) setState(() => _checkingVerification = false);
    }
  }

  Future<void> _pickCity() async {
    final city = await showCityPickerSheet(context, selected: _sehir);
    if (!mounted || city == null) return;
    setState(() => _sehir = city);
  }

  Future<void> _save() async {
    final ad = _adCtrl.text.trim();
    final kullaniciAdi = _kullaniciAdiCtrl.text.trim();
    if (ad.isEmpty || kullaniciAdi.isEmpty) {
      showErrorSnackBar(context, 'Ad ve kullanıcı adı boş bırakılamaz.');
      return;
    }
    final phoneError = Validators.phone(_telefonCtrl.text);
    if (phoneError != null) {
      showErrorSnackBar(context, phoneError);
      return;
    }

    setState(() => _saving = true);
    try {
      await AuthService.updateProfileBasics(
        ad: ad,
        soyad: _soyadCtrl.text.trim(),
        currentUsername: _currentUsername,
        newUsername: kullaniciAdi,
      );
      final uid = AuthService.currentUserId;
      if (uid != null) {
        await ProfileService.updateContact(
          uid,
          telefon: Validators.normalizePhone(_telefonCtrl.text),
          sehir: _sehir,
        );
      }
      if (!mounted) return;
      showInfoSnackBar(context, 'Değişiklikler kaydedildi.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('kullanici-adi-alinmis')
          ? 'Bu kullanıcı adı zaten alınmış.'
          : 'Değişiklikler kaydedilemedi. Lütfen tekrar deneyin.';
      showErrorSnackBar(context, message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPaddingH,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatar(user),
                          _sectionHeading('Kişisel bilgiler'),
                          _card(
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _LabeledField(
                                        label: 'Ad',
                                        controller: _adCtrl,
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.sm + 4),
                                    Expanded(
                                      child: _LabeledField(
                                        label: 'Soyad',
                                        controller: _soyadCtrl,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.md),
                                _LabeledField(
                                  label: 'Kullanıcı adı',
                                  controller: _kullaniciAdiCtrl,
                                  icon: Icons.alternate_email,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          _sectionHeading('İletişim bilgileri'),
                          _card(child: _buildEmailBlock()),
                          const SizedBox(height: AppSizes.sm + 4),
                          _card(
                            child: _LabeledField(
                              label: 'Telefon',
                              controller: _telefonCtrl,
                              icon: Icons.phone_outlined,
                              hint: 'Telefon numarası ekle',
                              keyboardType: TextInputType.phone,
                              trailing: const _OptionalLabel(),
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          _sectionHeading('Konum'),
                          _card(
                            child: _LabeledSelect(
                              label: 'Şehir',
                              icon: Icons.location_on_outlined,
                              value: _sehir,
                              hint: 'Şehir seç',
                              trailing: const _OptionalLabel(),
                              onTap: _pickCity,
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          _buildPasswordCard(),
                          const SizedBox(height: AppSizes.lg),
                          AppButton(
                            label: 'Değişiklikleri kaydet',
                            icon: Icons.check,
                            loading: _saving,
                            borderRadius: AppSizes.radiusLg,
                            onPressed: _save,
                          ),
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

  Widget _sectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm + 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: kOnSurface,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: cardDecoration(radius: AppSizes.radiusXl - 4),
      child: child,
    );
  }

  Widget _buildEmailBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabeledField(
          label: 'E-posta',
          controller: _emailCtrl,
          icon: Icons.mail_outline,
          readOnly: true,
          trailing: _StatusPill(verified: _emailVerified),
        ),
        if (!_emailVerified) ...[
          const SizedBox(height: AppSizes.sm + 4),
          Row(
            children: [
              Expanded(
                child: _VerificationButton(
                  loading: _sendingVerification,
                  label: 'Doğrulama maili gönder',
                  icon: Icons.send_outlined,
                  onPressed: _sendVerificationEmail,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              TextButton.icon(
                onPressed: _checkingVerification ? null : _refreshVerificationStatus,
                icon: _checkingVerification
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kOnSurfaceVariant,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 16, color: kOnSurface),
                label: Text(
                  'Yenile',
                  style: GoogleFonts.plusJakartaSans(
                    color: kOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordCard() {
    return GestureDetector(
      onTap: () => showInfoSnackBar(context, 'Yakında'),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: cardDecoration(radius: AppSizes.radiusXl - 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kPastelOrange,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(Icons.lock_outline, color: kSecondary, size: 22),
            ),
            const SizedBox(width: AppSizes.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Şifre değiştir',
                    style: GoogleFonts.plusJakartaSans(
                      color: kOnSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hesap güvenliğini güncelle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sourceSans3(
                      color: kOnSurfaceVariant,
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kOnSurfaceVariant, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPaddingH,
        AppSizes.sm + 4,
        AppSizes.screenPaddingH,
        AppSizes.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: kOnSurface, size: 22),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              'Profili düzenle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: kOnSurface,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontXxl,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Center(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials(user?.displayName),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: AppSizes.fontXxl,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => showInfoSnackBar(context, 'Yakında'),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: kBackground, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm + 4),
            GestureDetector(
              onTap: () => showInfoSnackBar(context, 'Yakında'),
              child: Text(
                'Fotoğrafı değiştir',
                style: GoogleFonts.plusJakartaSans(
                  color: kPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontMd,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'JPG veya PNG · En fazla 5 MB',
              style: GoogleFonts.sourceSans3(
                color: kOnSurfaceVariant,
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kart içi alan: üstte etiket (+ opsiyonel sağ yazı/pill), altında dolgulu input kutusu.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.readOnly = false,
    this.keyboardType,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final String? hint;
  final bool readOnly;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, trailing: trailing),
        const SizedBox(height: AppSizes.sm),
        _FieldBox(
          icon: icon,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            maxLines: 1,
            style: GoogleFonts.plusJakartaSans(
              color: readOnly ? kOnSurfaceVariant : kOnSurface,
              fontWeight: FontWeight.w600,
              fontSize: AppSizes.fontMd + 1,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: kOnSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: AppSizes.fontMd + 1,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// Tıklanınca seçici açan (dropdown görünümlü) alan.
class _LabeledSelect extends StatelessWidget {
  const _LabeledSelect({
    required this.label,
    required this.icon,
    required this.hint,
    required this.onTap,
    this.value,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final String hint;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, trailing: trailing),
        const SizedBox(height: AppSizes.sm),
        _FieldBox(
          icon: icon,
          onTap: onTap,
          suffix: const Icon(Icons.keyboard_arrow_down,
              color: kOnSurfaceVariant, size: 20),
          child: Text(
            value ?? hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: hasValue ? kOnSurface : kOnSurfaceVariant,
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
              fontSize: AppSizes.fontMd + 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sourceSans3(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// Dolgulu, yuvarlak köşeli input kutusu: [ikon] [içerik] [sağ ek].
class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child, this.icon, this.suffix, this.onTap});

  final Widget child;
  final IconData? icon;
  final Widget? suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSizes.sm + 4),
        decoration: BoxDecoration(
          color: kPastelGray,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: kOnSurfaceVariant, size: 20),
              const SizedBox(width: AppSizes.sm + 4),
            ],
            Expanded(child: child),
            if (suffix != null) ...[const SizedBox(width: AppSizes.sm), suffix!],
          ],
        ),
      ),
    );
  }
}

class _OptionalLabel extends StatelessWidget {
  const _OptionalLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'İsteğe bağlı',
      style: GoogleFonts.sourceSans3(
        color: kOnSurfaceVariant,
        fontSize: AppSizes.fontSm,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? kPrimaryFixed : kErrorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        verified ? 'Doğrulandı' : 'Doğrulanmadı',
        style: GoogleFonts.sourceSans3(
          color: verified ? kPrimary : kOnErrorContainer,
          fontSize: AppSizes.fontSm - 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// "Doğrulama maili gönder" — açık yeşil dolgulu, loading'de spinner gösterir.
class _VerificationButton extends StatelessWidget {
  const _VerificationButton({
    required this.loading,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: kPrimaryFixed,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm + 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: kPrimary),
                  const SizedBox(width: AppSizes.sm),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: kPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
