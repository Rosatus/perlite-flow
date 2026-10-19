import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/server_profile.dart';
import '../services/perlite_client.dart';
import '../state/app_state.dart';

/// IM-style login screen: a hero header with the app mark and a focused
/// card holding server URL, credentials, and the save/auto-login
/// toggles. Existing profiles appear as quick-pick chips; the URL is
/// probed on-the-fly (debounced) so mistakes surface before submit.
class LoginPage extends StatefulWidget {
  final AppState app;

  /// Pre-fill from an existing profile when editing it.
  final ServerProfile? editing;

  const LoginPage({super.key, required this.app, this.editing});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  final _urlFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _savePassword = true;
  bool _autoLogin = false;
  bool _obscure = true;
  bool _connecting = false;

  /// Live URL probe state (debounced on-typing).
  Timer? _probeTimer;
  bool _probing = false;
  String? _probeResult; // null => ok
  String _lastProbedUrl = '';

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();

    final p = widget.editing;
    if (p != null) {
      _urlCtrl.text = p.baseUrl;
      _userCtrl.text = p.username;
      _nameCtrl.text = p.name;
      _savePassword = p.savePassword;
      _autoLogin = p.autoLogin;
      _loadSavedPassword(p.id);
    }
    _urlCtrl.addListener(_scheduleProbe);
  }

  Future<void> _loadSavedPassword(String id) async {
    final pwd = await widget.app.store.readPassword(id);
    if (pwd != null && mounted) _passCtrl.text = pwd;
  }

  @override
  void dispose() {
    _probeTimer?.cancel();
    _anim.dispose();
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _urlFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _scheduleProbe() {
    _probeTimer?.cancel();
    final raw = _urlCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _probeResult = null;
        _lastProbedUrl = '';
      });
      return;
    }
    _probeTimer = Timer(const Duration(milliseconds: 800), _probeUrl);
  }

  Future<void> _probeUrl() async {
    final url = AppState.normalizeBaseUrl(_urlCtrl.text);
    if (url.isEmpty || url == _lastProbedUrl) return;
    setState(() => _probing = true);
    final probe = PerliteClient(
      baseUrl: url,
      username: _userCtrl.text.isEmpty ? null : _userCtrl.text,
      password: _passCtrl.text,
      timeout: const Duration(seconds: 8),
    );
    final err = await probe.probe();
    if (!mounted) return;
    setState(() {
      _probing = false;
      _lastProbedUrl = url;
      _probeResult = err;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _connecting = true);
    final err = await widget.app.login(
      baseUrl: _urlCtrl.text,
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      savePassword: _savePassword,
      autoLogin: _autoLogin,
      profileId: widget.editing?.id,
      name: _nameCtrl.text.trim().isEmpty
          ? widget.editing?.name
          : _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _connecting = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _pickProfile(ServerProfile p) async {
    final pwd = await widget.app.store.readPassword(p.id);
    setState(() {
      _urlCtrl.text = p.baseUrl;
      _userCtrl.text = p.username;
      _passCtrl.text = pwd ?? '';
      _nameCtrl.text = p.name;
      _savePassword = p.savePassword;
      _autoLogin = p.autoLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profiles = widget.app.profiles;
    final editing = widget.editing != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroMark(color: cs.primary, onSurface: cs.onSurface),
                      const SizedBox(height: 28),
                      if (profiles.isNotEmpty) ...[
                        Text(
                          '已保存的服务器',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final p in profiles)
                              InputChip(
                                avatar: const Icon(Symbols.dns, size: 18),
                                label: Text(
                                    p.name.isEmpty ? p.baseUrl : p.name),
                                selected: widget.editing?.id == p.id,
                                onSelected: (_) => _pickProfile(p),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        color: cs.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: '名称（可选）',
                                    hintText: '我的笔记',
                                    prefixIcon: Icon(Symbols.bookmark),
                                    border: OutlineInputBorder(),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.words,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _urlCtrl,
                                  focusNode: _urlFocus,
                                  keyboardType: TextInputType.url,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: '服务器地址',
                                    hintText: 'https://notes.example.com',
                                    prefixIcon: const Icon(Symbols.link),
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _buildProbeSuffix(cs),
                                  ),
                                  validator: (v) {
                                    final t = v?.trim() ?? '';
                                    if (t.isEmpty) return '请输入服务器地址';
                                    final u =
                                        AppState.normalizeBaseUrl(t);
                                    final host =
                                        Uri.tryParse(u)?.host ?? '';
                                    if (host.isEmpty) return 'URL 格式不正确';
                                    return null;
                                  },
                                ),
                                if (_probeResult != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 6, left: 4),
                                    child: Text(
                                      _probeResult!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.error,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _userCtrl,
                                  focusNode: _userFocus,
                                  decoration: const InputDecoration(
                                    labelText: '用户名（无 Basic Auth 可留空）',
                                    prefixIcon: Icon(Symbols.person),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passCtrl,
                                  focusNode: _passFocus,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: '密码',
                                    prefixIcon: const Icon(Symbols.lock),
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Symbols.visibility
                                            : Symbols.visibility_off,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscure = !_obscure),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CheckboxListTile(
                                  value: _savePassword,
                                  onChanged: (v) => setState(
                                      () => _savePassword = v ?? true),
                                  title: const Text('保存密码'),
                                  subtitle:
                                      const Text('保存在系统安全存储中'),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                                CheckboxListTile(
                                  value: _autoLogin,
                                  onChanged: (v) => setState(
                                      () => _autoLogin = v ?? false),
                                  title: const Text('自动登录'),
                                  subtitle:
                                      const Text('下次启动直接进入'),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed:
                                      _connecting ? null : _submit,
                                  icon: _connecting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2),
                                        )
                                      : Icon(editing
                                          ? Symbols.save
                                          : Symbols.login),
                                  label: Text(_connecting
                                      ? '连接中…'
                                      : editing
                                          ? '保存并重连'
                                          : '连接'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '凭证只保存在本设备，不会上传到任何第三方服务',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildProbeSuffix(ColorScheme cs) {
    if (_probing) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_lastProbedUrl.isEmpty) return null;
    if (_probeResult == null) {
      return Icon(Symbols.check_circle, color: cs.primary);
    }
    return Icon(Symbols.error, color: cs.error);
  }
}

/// Brand mark: a soft two-tone tile with the app icon, app name and a
/// one-line value prop. Keeps the screen feeling like a product, not a
/// form.
class _HeroMark extends StatelessWidget {
  final Color color;
  final Color onSurface;
  const _HeroMark({required this.color, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Perlite Flow',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '连接你的 Perlite 知识库',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
