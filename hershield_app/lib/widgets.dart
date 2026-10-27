import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'i18n.dart';
import 'theme.dart';

/// Translating text widget (use Tx instead of Text). It translates its content into
/// the current language and updates instantly when the language changes.
class Tx extends StatelessWidget {
  const Tx(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (_, lang, _) => Text(
        trFor(lang, data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: C.primary,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(Icons.wb_twilight, color: Colors.white, size: size * 0.58),
      );
}

/// Standard scrolling page with optional back row and quick-exit button.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.stepLabel,
    this.quickExit = false,
    this.fallback = '/home',
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;
  final bool showBack;
  final String? stepLabel;
  final bool quickExit;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                if (showBack || stepLabel != null || quickExit)
                  Row(children: [
                    if (showBack)
                      TextButton.icon(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(fallback),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Tx('Back'),
                      ),
                    const Spacer(),
                    if (stepLabel != null)
                      Tx(stepLabel!,
                          style: const TextStyle(
                              fontSize: 11, color: C.muted, letterSpacing: .5)),
                    if (quickExit)
                      TextButton.icon(
                        onPressed: () => context.go('/quick-exit'),
                        icon: const Icon(Icons.exit_to_app, size: 18),
                        label: const Tx('Quick exit'),
                      ),
                  ]),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Tx(title!,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.15)),
                  ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Tx(subtitle!,
                        style: const TextStyle(color: C.muted, height: 1.4)),
                  ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.border = C.line,
    this.padding = const EdgeInsets.all(16),
    this.bottom = 12,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final Color border;
  final EdgeInsets padding;
  final double bottom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Material(
          color: color,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: border),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

enum Tone { info, danger, warn, ok }

class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.title,
    this.text,
    this.icon = Icons.info_outline,
    this.tone = Tone.info,
  });

  final String title;
  final String? text;
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    late Color bg, fg, border;
    switch (tone) {
      case Tone.danger:
        bg = C.dangerBg; fg = C.danger; border = const Color(0xFFF5C6CA);
      case Tone.warn:
        bg = C.warnBg; fg = C.warn; border = const Color(0xFFF2DEAE);
      case Tone.ok:
        bg = C.okBg; fg = C.ok; border = const Color(0xFFBFE3CC);
      case Tone.info:
        bg = C.tint; fg = C.primary; border = C.tintBorder;
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: fg, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Tx(title,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
            if (text != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Tx(text!,
                    style: const TextStyle(
                        fontSize: 13, color: C.ink, height: 1.4)),
              ),
          ]),
        ),
      ]),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.bg = C.tint, this.fg = C.primary});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Tx(label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: C.primary,
      disabledBackgroundColor: C.line,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: icon == null
            ? FilledButton(
                onPressed: onPressed, style: style, child: Tx(label))
            : FilledButton.icon(
                onPressed: onPressed,
                style: style,
                icon: Icon(icon, size: 18),
                label: Tx(label)),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: C.primary,
      backgroundColor: Colors.white,
      side: const BorderSide(color: C.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: icon == null
            ? OutlinedButton(
                onPressed: onPressed, style: style, child: Tx(label))
            : OutlinedButton.icon(
                onPressed: onPressed,
                style: style,
                icon: Icon(icon, size: 18),
                label: Tx(label)),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.actionLabel, this.onAction});
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        child: Row(children: [
          Expanded(
              child: Tx(text,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700))),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Tx(actionLabel!,
                  style: const TextStyle(
                      color: C.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
        ]),
      );
}

class StepBar extends StatelessWidget {
  const StepBar(this.step, {super.key, this.total = 3});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: List.generate(
            total,
            (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: i < step ? C.primary : C.tintBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      );
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.obscure = false,
    this.keyboard,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final bool obscure;
  final TextInputType? keyboard;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Tx(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint == null ? null : tr(hint!),
            helperText: helper == null ? null : tr(helper!),
            helperMaxLines: 3,
            filled: true,
            fillColor: Colors.white,
            border: b(C.line),
            enabledBorder: b(C.line),
            focusedBorder: b(C.primary),
          ),
        ),
      ]),
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        color: selected ? C.tint : Colors.white,
        border: selected ? C.primary : C.line,
        padding: const EdgeInsets.all(14),
        bottom: 10,
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, color: C.primary, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Tx(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Tx(subtitle!,
                      style: const TextStyle(
                          color: C.muted, fontSize: 13, height: 1.4)),
                ),
            ]),
          ),
          Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? C.primary : C.tintBorder),
        ]),
      );
}

/// Used for empty, offline and error states.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: C.tint, borderRadius: BorderRadius.circular(22)),
            child: Icon(icon, size: 34, color: C.primary),
          ),
          const SizedBox(height: 16),
          Tx(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Tx(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, height: 1.4)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Tx(actionLabel!)),
          ],
        ]),
      );
}

void snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Tx(message)));
}
