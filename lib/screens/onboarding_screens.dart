import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository.dart';
import '../i18n.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.tint,
      body: SafeArea(
        child: Column(children: [
          const Spacer(flex: 3),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(36)),
            child: const Icon(Icons.wb_twilight, size: 60, color: C.primary),
          ),
          const SizedBox(height: 24),
          const Row(mainAxisSize: MainAxisSize.min, children: [
            BrandMark(size: 40),
            SizedBox(width: 12),
            Tx('SheRise',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          const Tx('Your safety. Your voice. Your future.',
              style: TextStyle(color: C.muted)),
          const Spacer(flex: 3),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Tx('Designed with care, for women and girls.',
                style: TextStyle(color: C.muted, fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}

class _Slide {
  const _Slide(this.tag, this.title, this.body, this.icon, this.colors);
  final String tag;
  final String title;
  final String body;
  final IconData icon;
  final List<Color> colors;
}

const _slides = [
  _Slide(
    'A space for you',
    'Your voice belongs here.',
    'A private place to speak up, find trusted support and learn about your rights, at your own pace.',
    Icons.record_voice_over_outlined,
    [Color(0xFFE6DAFB), Color(0xFFF6E7F0)],
  ),
  _Slide(
    'You are not alone',
    'Support, on your terms.',
    'Find verified counseling, legal-aid and support services. You decide what to share and with whom.',
    Icons.favorite_outline,
    [Color(0xFFDDE4FB), Color(0xFFE6DAFB)],
  ),
  _Slide(
    'Make room for your future',
    'Your next chapter starts with you.',
    'Discover scholarships, training, mentorship and jobs with clear and fair eligibility.',
    Icons.school_outlined,
    [Color(0xFFF6E7F0), Color(0xFFE6F3E9)],
  ),
];

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _languages = supportedLanguages;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int p) => _controller.animateToPage(p,
      duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    final language = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(children: [
                  const BrandMark(size: 32),
                  const SizedBox(width: 8),
                  const Tx('SheRise',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (!last)
                    TextButton(
                        onPressed: () => _goTo(_slides.length - 1),
                        child: const Tx('Skip introduction')),
                ]),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Pill(s.tag),
                            const SizedBox(height: 16),
                            Container(
                              height: 230,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                    colors: s.colors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                              ),
                              child: Icon(s.icon, size: 84, color: C.primary),
                            ),
                            const SizedBox(height: 20),
                            Tx(s.title,
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15)),
                            const SizedBox(height: 10),
                            Tx(s.body,
                                style: const TextStyle(
                                    color: C.muted, height: 1.45)),
                            if (i == _slides.length - 1) ...[
                              const SizedBox(height: 18),
                              const Tx('Language',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, children: [
                                for (final l in _languages)
                                  ChoiceChip(
                                    label: Tx(l),
                                    selected: language == l,
                                    onSelected: (_) => ref
                                        .read(languageProvider.notifier)
                                        .set(l),
                                  ),
                              ]),
                              const SizedBox(height: 6),
                              const Tx('Your choice is saved.',
                                  style:
                                      TextStyle(color: C.muted, fontSize: 12)),
                            ],
                          ]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < _slides.length; i++)
                      Container(
                        width: i == _page ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _page ? C.primary : C.tintBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  if (!last)
                    PrimaryButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
                        onPressed: () => _goTo(_page + 1))
                  else ...[
                    PrimaryButton(
                        label: 'Create private access',
                        onPressed: () => context.go('/signup')),
                    SecondaryButton(
                        label: 'Sign in',
                        onPressed: () => context.go('/signin')),
                    TextButton(
                        onPressed: () => context.go('/home'),
                        child: const Tx('Continue without an account')),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (!Repo.live) {
      if (Repo.isStaffEmail(email)) {
        final ok = await Repo.staffLogin(email, password);
        if (ok) {
          if (mounted) context.go('/board');
          return;
        } else {
          if (mounted) snack(context, 'Invalid staff credentials');
          return;
        }
      }
      context.go('/home');
      return;
    }
    setState(() => _busy = true);
    try {
      await Repo.signIn(email, password);
      final access = await Repo.myAccess();
      if (mounted) {
        if (access.isStaff) {
          context.go('/board');
        } else {
          context.go('/home');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, 'Could not sign in. Check your connection.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      showBack: true,
      fallback: '/welcome',
      children: [
        GestureDetector(
          onLongPress: () => context.push('/board/login'),
          child: const BrandMark(size: 56),
        ),
        const SizedBox(height: 16),
        const Tx('Welcome back.',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Tx(
            'Sign in for private case access, saved opportunities and your trusted contact.',
            style: TextStyle(color: C.muted, height: 1.4)),
        const SizedBox(height: 20),
        if (!Repo.live)
          const InfoBox(
              title: 'Demo mode',
              text: 'No account is needed yet. Tap Sign in to continue.'),
        LabeledField(
            label: 'Email address',
            controller: _email,
            keyboard: TextInputType.emailAddress),
        LabeledField(label: 'Password', controller: _password, obscure: true),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
              onPressed: () => context.go('/recover'),
              child: const Tx('Forgot access?')),
        ),
        PrimaryButton(
            label: _busy ? 'Signing in…' : 'Sign in',
            onPressed: _busy ? null : _submit),
        SecondaryButton(
            label: 'Create private access',
            onPressed: () => context.go('/signup')),
        Center(
          child: TextButton(
              onPressed: () => context.go('/home'),
              child: const Tx('Continue without an account')),
        ),
      ],
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agree = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!Repo.live) {
      context.go('/home');
      return;
    }
    if (_password.text.length < 8) {
      snack(context, 'Use a password of at least 8 characters.');
      return;
    }
    setState(() => _busy = true);
    try {
      await Repo.signUp(_email.text.trim(), _password.text, _name.text.trim());
      if (mounted) {
        snack(context, 'Account created. Check your email if confirmation is required.');
        context.go('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, 'Could not create the account. Check your connection.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      showBack: true,
      fallback: '/welcome',
      title: 'A little space for you.',
      subtitle: 'Create private access. We only ask for what is needed to manage your account.',
      children: [
        if (!Repo.live)
          const InfoBox(
              title: 'Demo mode', text: 'No account is created in this version.'),
        LabeledField(
            label: 'Name or nickname (optional)',
            controller: _name,
            hint: 'What should we call you?'),
        LabeledField(
            label: 'Email address',
            controller: _email,
            keyboard: TextInputType.emailAddress,
            helper: 'Use an email only you can access.'),
        LabeledField(
            label: 'Password',
            controller: _password,
            obscure: true,
            helper: 'At least 8 characters.'),
        CheckboxListTile(
          value: _agree,
          onChanged: (v) => setState(() => _agree = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Tx(
              'I understand how my information is used and who can see it.',
              style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
            label: _busy ? 'Creating…' : 'Create account',
            onPressed: (_agree && !_busy) ? _submit : null),
      ],
    );
  }
}

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _email = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      if (Repo.live) await Repo.recover(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) snack(context, 'Could not send the email. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      showBack: true,
      fallback: '/signin',
      title: 'Recover your access',
      children: [
        if (!_sent) ...[
          const Tx(
              'Enter your email and we will send a link to reset your password.',
              style: TextStyle(color: C.muted, height: 1.4)),
          const SizedBox(height: 16),
          LabeledField(
              label: 'Email address',
              controller: _email,
              keyboard: TextInputType.emailAddress),
          PrimaryButton(
              label: _busy ? 'Sending…' : 'Send reset link',
              onPressed: _busy ? null : _submit),
        ] else
          const StateView(
            icon: Icons.mark_email_read_outlined,
            title: 'Check your email',
            message:
                'If an account exists for that address, a reset link is on its way.',
          ),
        const InfoBox(
          tone: Tone.warn,
          icon: Icons.key_outlined,
          title: 'Lost a report access code?',
          text:
              'Report codes cannot be recovered. They are never stored in readable form. If you lost one, you can submit a new report.',
        ),
        Center(
          child: TextButton(
              onPressed: () => context.go('/signin'),
              child: const Tx('Back to sign in')),
        ),
      ],
    );
  }
}
