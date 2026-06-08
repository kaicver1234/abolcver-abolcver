import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/routing_provider.dart';
import '../providers/language_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/app_background.dart';
import '../utils/responsive_helper.dart';

const _kBg = Color(0xFF0A0A0A);
const _kCard = Color(0xFF111111);
const _kBorder = Color(0xFF222222);
const _kAccent = Color(0xFF00D9FF);
const _kDanger = Color(0xFFEF4444);

class RoutingSettingsScreen extends StatefulWidget {
  const RoutingSettingsScreen({super.key});

  @override
  State<RoutingSettingsScreen> createState() => _RoutingSettingsScreenState();
}

class _RoutingSettingsScreenState extends State<RoutingSettingsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'Safheh_Routing');
  }

  bool get _isRtl =>
      Provider.of<LanguageProvider>(context, listen: false)
          .currentLanguage
          .direction ==
      'rtl';

  String _t({required String fa, required String en}) => _isRtl ? fa : en;

  @override
  Widget build(BuildContext context) {
    final isRtl = _isRtl;
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            backgroundColor: _kBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                isRtl
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _t(fa: 'مسیریابی و دور زدن', en: 'Routing & Bypass'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Consumer<RoutingProvider>(
            builder: (context, routing, _) {
              if (!routing.isInitialized) {
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kAccent,
                    ),
                  ),
                );
              }
              final r = ResponsiveHelper(context);
              return ResponsivePageWrapper(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(r.horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(routing),
                      const SizedBox(height: 24),
                      _buildSectionLabel(
                        _t(fa: 'دور زدن سریع', en: 'Quick Bypass'),
                      ),
                      const SizedBox(height: 12),
                      _buildIranToggle(routing),
                      const SizedBox(height: 10),
                      _buildPrivateToggle(routing),
                      const SizedBox(height: 24),
                      _buildSectionLabel(
                        _t(fa: 'سابنت‌های دلخواه', en: 'Custom Subnets'),
                      ),
                      const SizedBox(height: 8),
                      _buildSubnetHint(),
                      const SizedBox(height: 12),
                      _buildSubnetEditor(routing),
                      const SizedBox(height: 24),
                      _buildSectionLabel(
                        _t(fa: 'دامنه‌های دلخواه', en: 'Custom Domains'),
                      ),
                      const SizedBox(height: 8),
                      _buildDomainHint(),
                      const SizedBox(height: 12),
                      _buildDomainEditor(routing),
                      const SizedBox(height: 32),
                      _buildInfoCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(RoutingProvider routing) {
    final activeCount = (routing.bypassIran ? 1 : 0) +
        (routing.bypassPrivate ? 1 : 0) +
        (routing.customSubnets.isNotEmpty ? 1 : 0) +
        (routing.customDomains.isNotEmpty ? 1 : 0);
    final isActive = activeCount > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? _kAccent.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isActive ? _kAccent.withValues(alpha: 0.3) : _kBorder,
              ),
            ),
            child: Icon(
              Icons.alt_route_rounded,
              color: isActive ? _kAccent : Colors.white70,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(fa: 'مسیریابی هوشمند', en: 'Smart Routing'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t(
                    fa: 'ترافیک انتخابی از خارج تونل عبور می‌کند',
                    en: 'Selected traffic skips the VPN tunnel',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIranToggle(RoutingProvider routing) {
    return _buildToggleTile(
      icon: Icons.flag_rounded,
      iconColor: const Color(0xFF22C55E),
      title: _t(fa: 'دور زدن ترافیک ایران', en: 'Bypass Iran traffic'),
      subtitle: _t(
        fa: 'سایت‌ها و سرویس‌های ایرانی بدون VPN باز شوند',
        en: 'Iranian sites and services connect without VPN',
      ),
      value: routing.bypassIran,
      onChanged: routing.setBypassIran,
    );
  }

  Widget _buildPrivateToggle(RoutingProvider routing) {
    return _buildToggleTile(
      icon: Icons.lan_rounded,
      iconColor: const Color(0xFFA78BFA),
      title: _t(fa: 'دور زدن شبکه محلی', en: 'Bypass LAN / Private'),
      subtitle: _t(
        fa: 'پرینتر، روتر و دستگاه‌های شبکه در دسترس باقی بمانند',
        en: 'Keep printers, router, and local devices reachable',
      ),
      value: routing.bypassPrivate,
      onChanged: routing.setBypassPrivate,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: _kAccent,
            onChanged: (v) => onChanged(v),
          ),
        ],
      ),
    );
  }

  Widget _buildSubnetHint() {
    return Text(
      _t(
        fa: 'سابنت‌های اضافی به‌صورت CIDR وارد کنید (مثال: 192.0.2.0/24)',
        en: 'Add extra subnets in CIDR form (example: 192.0.2.0/24)',
      ),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 12,
        height: 1.5,
      ),
    );
  }

  Widget _buildSubnetEditor(RoutingProvider routing) {
    return _ListEditor(
      hint: _t(fa: '10.0.0.0/8', en: '10.0.0.0/8'),
      addLabel: _t(fa: 'افزودن', en: 'Add'),
      emptyLabel: _t(fa: 'موردی اضافه نشده', en: 'Nothing added yet'),
      invalidLabel: _t(
        fa: 'فرمت CIDR نامعتبر است',
        en: 'Invalid CIDR format',
      ),
      duplicateLabel: _t(fa: 'قبلاً اضافه شده', en: 'Already in the list'),
      items: routing.customSubnets,
      validate: RoutingProvider.isValidCidr,
      onAdd: routing.addCustomSubnet,
      onRemove: routing.removeCustomSubnet,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildDomainHint() {
    return Text(
      _t(
        fa: 'دامنه‌ها (example.com)، پیشوندها: domain: full: regexp: geosite:',
        en: 'Plain domains (example.com) or prefixes: domain: full: regexp: geosite:',
      ),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 12,
        height: 1.5,
      ),
    );
  }

  Widget _buildDomainEditor(RoutingProvider routing) {
    return _ListEditor(
      hint: _t(fa: 'example.ir', en: 'example.com'),
      addLabel: _t(fa: 'افزودن', en: 'Add'),
      emptyLabel: _t(fa: 'موردی اضافه نشده', en: 'Nothing added yet'),
      invalidLabel: _t(
        fa: 'دامنه نامعتبر است',
        en: 'Invalid domain rule',
      ),
      duplicateLabel: _t(fa: 'قبلاً اضافه شده', en: 'Already in the list'),
      items: routing.customDomains,
      validate: RoutingProvider.isValidDomain,
      onAdd: routing.addCustomDomain,
      onRemove: routing.removeCustomDomain,
      keyboardType: TextInputType.url,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _kAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t(
                fa: 'تغییر این تنظیمات در حین اتصال، اتصال را بازسازی می‌کند تا قوانین جدید اعمال شوند.',
                en: 'Changing these while connected will reconnect the VPN to apply the new rules.',
              ),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListEditor extends StatefulWidget {
  final String hint;
  final String addLabel;
  final String emptyLabel;
  final String invalidLabel;
  final String duplicateLabel;
  final List<String> items;
  final bool Function(String) validate;
  final Future<bool> Function(String) onAdd;
  final Future<void> Function(String) onRemove;
  final TextInputType keyboardType;

  const _ListEditor({
    required this.hint,
    required this.addLabel,
    required this.emptyLabel,
    required this.invalidLabel,
    required this.duplicateLabel,
    required this.items,
    required this.validate,
    required this.onAdd,
    required this.onRemove,
    required this.keyboardType,
  });

  @override
  State<_ListEditor> createState() => _ListEditorState();
}

class _ListEditorState extends State<_ListEditor> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    if (_busy) return;
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    if (!widget.validate(raw)) {
      setState(() => _error = widget.invalidLabel);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    final ok = await widget.onAdd(raw);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _error = widget.duplicateLabel);
      return;
    }
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  keyboardType: widget.keyboardType,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleAdd(),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(253),
                  ],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: _kAccent,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: _kAccent.withValues(alpha: 0.6), width: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _busy ? null : _handleAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          widget.addLabel,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(color: _kDanger, fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 12),
          if (widget.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                widget.emptyLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            )
          else
            Column(
              children: widget.items
                  .map((value) => _buildChip(value))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () => widget.onRemove(value),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  color: _kDanger.withValues(alpha: 0.85),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
