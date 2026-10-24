import 'package:flutter/material.dart';

/// One app bar for the whole app.
///
/// Every screen used to build its own AppBar, which is why the height, the
/// title font and the colour drifted from page to page. This widget copies
/// the shape the Welcome screen already used (blue bar, 56 height, centred
/// single-line title, circular IR logo on the right) and every page now
/// renders it instead of building its own.
class PMSAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PMSAppBar({
    super.key,
    required this.title,
    this.showDrawer = false,
    this.showBackButton = false,
    this.logoUrl = defaultLogoUrl,
    this.actions = const <Widget>[],
  });

  /// Circular Indian Railways logo, same URL the Welcome screen used.
  static const String defaultLogoUrl =
      "https://cris.org.in/img/footer/redlogo.png";

  /// The single blue used by every app bar in the app.
  static const Color appBarBlue = Color(0xFF1565C0);
  static const double barHeight = 56;
  static const double logoSize = 32;

  final String title;
  final bool showDrawer;
  final bool showBackButton;
  final String logoUrl;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appBarBlue,
      foregroundColor: Colors.white,
      centerTitle: true,
      toolbarHeight: barHeight,
      automaticallyImplyLeading: false,
      titleSpacing: 8,

      // Hamburger on pages that own a drawer, back arrow on pushed pages.
      leading: showDrawer
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,

      // maxLines + ellipsis keeps a long title on one line instead of
      // letting it wrap into three lines.
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),

      actions: [
        // Page-specific actions first, the logo always stays last.
        ...actions,
        ClipOval(
          child: Image.network(
            logoUrl,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.train, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 6),
      ],
    );
  }
}
