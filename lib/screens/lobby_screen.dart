import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'remote_screen.dart';

// ═══════════════════════════════════════
// COLOR PALETTE (Battlebot Neon Dark)
// ═══════════════════════════════════════
class _C {
  static const bg = Color(0xFF0A0A0F);
  static const headerBg = Color(0xFF111118);
  static const panelBg = Color(0xFF0D0D14);
  static const panelBorder = Color(0xFF2A2A40);
  static const navBg = Color(0xFF0E0E18);
  static const neonBlue = Color(0xFF00C8FF);
  static const neonRed = Color(0xFFFF3040);
  static const gold = Color(0xFFFF3D3D);     // rank 1 – red-gold like reference
  static const silver = Color(0xFFB0BEC5);    // rank 2
  static const bronze = Color(0xFFE67E22);    // rank 3
  static const teal = Color(0xFF00E5A0);      // rank 4
  static const purple = Color(0xFF9C5FFF);    // rank 5
  static const textPrimary = Colors.white;
  static const textMuted = Color(0xFF8888AA);
  static const btnBorder = Color(0xFF4A4A6A);
  static const btnGlow = Color(0xFF5050A0);
}

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with TickerProviderStateMixin {
  String _selectedTab = 'GUIDE';
  final int _gems = 79;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Button glow pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Arena floating (up/down)
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── A. HEADER ──────────────────────────────────────
          _Header(gems: _gems, onLogout: _showLogoutDialog),

          // ── BODY ROW ───────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── B. LEFT NAV ────────────────────────────
                _LeftNav(
                  selectedTab: _selectedTab,
                  onTabSelected: (t) => setState(() => _selectedTab = t),
                ),

                // ── D. CENTER ARENA ─────────────────────────
                Expanded(
                  child: _CenterArena(
                    pulseAnim: _pulseAnim,
                    floatAnim: _floatAnim,
                    onEnterLobby: _enterLobby,
                  ),
                ),

                // ── C. LEADERBOARD ──────────────────────────
                const _LeaderboardPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _enterLobby() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RemoteScreen()),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.panelBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _C.panelBorder),
        ),
        title: const Text('Keluar', style: TextStyle(color: _C.neonBlue)),
        content: const Text('Apakah Anda ingin keluar?',
            style: TextStyle(color: _C.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: _C.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.neonRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// A. HEADER BAR
// ═══════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final int gems;
  final VoidCallback onLogout;

  const _Header({required this.gems, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: _C.headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Avatar + Username
          GestureDetector(
            onTap: onLogout,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1E2E),
                    border: Border.all(color: _C.textMuted, width: 1.2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white54,
                      size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'USER_01',
                  style: TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Center Title
          const Expanded(
            child: Center(
              child: Text(
                'Battlebot Indonesia',
                style: TextStyle(
                  color: _C.textMuted,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Gems + status
          Row(
            children: [
              // Gem icon + count
              const Icon(Icons.diamond, color: _C.neonBlue, size: 18),
              const SizedBox(width: 6),
              Text(
                '$gems',
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              // Plus button
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: _C.panelBorder, width: 1),
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFF1A1A28),
                ),
                child: const Icon(Icons.add, color: _C.textMuted, size: 14),
              ),
              const SizedBox(width: 16),
              // Signal + Battery
              const Icon(Icons.signal_cellular_alt,
                  color: _C.textMuted, size: 18),
              const SizedBox(width: 8),
              const Icon(Icons.battery_full, color: _C.textMuted, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// B. LEFT NAVIGATION BAR
// ═══════════════════════════════════════════════════════
class _LeftNav extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabSelected;

  const _LeftNav(
      {required this.selectedTab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(id: 'SHOP', label: 'SHOP', icon: Icons.shopping_cart),
      _NavItem(id: 'INVENTORY', label: 'INVENTORY', icon: Icons.inventory_2),
      _NavItem(id: 'GUIDE', label: 'GUIDE', icon: Icons.info_outline),
      _NavItem(id: 'PENGATURAN', label: 'PENGATURAN', icon: Icons.settings),
    ];

    return Container(
      width: 82,
      color: _C.navBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          final isActive = selectedTab == item.id;
          return GestureDetector(
            onTap: () => onTabSelected(item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 74,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? _C.neonBlue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? _C.neonBlue.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: isActive ? _C.neonBlue : _C.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 3),
                  // FittedBox ensures label never wraps/overflows
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: isActive ? Colors.white : _C.textMuted,
                        fontSize: 9,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final String id, label;
  final IconData icon;
  const _NavItem({required this.id, required this.label, required this.icon});
}

// ═══════════════════════════════════════════════════════
// D. CENTER ARENA  (floating transparent PNG on background)
// ═══════════════════════════════════════════════════════
class _CenterArena extends StatefulWidget {
  final Animation<double> pulseAnim;
  final Animation<double> floatAnim;
  final VoidCallback onEnterLobby;

  const _CenterArena({
    required this.pulseAnim,
    required this.floatAnim,
    required this.onEnterLobby,
  });

  @override
  State<_CenterArena> createState() => _CenterArenaState();
}

class _CenterArenaState extends State<_CenterArena> {
  bool _btnHovered = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. STADIUM BACKGROUND (full bleed) ──────────────
        Image.asset(
          'assets/arena_background.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF060610)),
        ),

        // Dark vignette overlays
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.30, 0.65, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
        ),
        // Left edge blend
        Positioned(
          left: 0, top: 0, bottom: 0, width: 55,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
          ),
        ),
        // Right edge blend
        Positioned(
          right: 0, top: 0, bottom: 0, width: 55,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
          ),
        ),

        // ── 2. FLOATING ARENA PLATFORM ────────────────────────
        Positioned(
          left: 0, right: 0,
          top: 0, bottom: 68,
          child: Align(
            // Push arena toward lower center (0 = center, 1.0 = bottom)
            alignment: const Alignment(0, 0.6),
            child: AnimatedBuilder(
              animation: widget.floatAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, widget.floatAnim.value),
                child: child,
              ),
              child: _FloatingArena(pulseAnim: widget.pulseAnim),
            ),
          ),
        ),

        // ── 3. MASUK LOBBY BUTTON ────────────────────────────
        Positioned(
          bottom: 24, left: 0, right: 0,
          child: Center(
            child: MouseRegion(
              onEnter: (_) => setState(() => _btnHovered = true),
              onExit: (_) => setState(() => _btnHovered = false),
              child: GestureDetector(
                onTap: widget.onEnterLobby,
                child: AnimatedScale(
                  scale: _btnHovered ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedBuilder(
                    animation: widget.pulseAnim,
                    builder: (_, __) => Container(
                      width: 320,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D20).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _btnHovered ? _C.neonBlue : _C.btnBorder,
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_btnHovered ? _C.neonBlue : _C.btnGlow)
                                .withValues(alpha: widget.pulseAnim.value * 0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'MASUK LOBBY',
                          style: TextStyle(
                            color: _btnHovered ? _C.neonBlue : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            shadows: _btnHovered
                                ? [const Shadow(color: _C.neonBlue, blurRadius: 10)]
                                : [],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// FLOATING ARENA  (black-bg → transparent via BlendMode.screen)
// ─────────────────────────────────────────────────────────
//
// Cara kerja:
//   1. Load arena_platform.png sebagai dart:ui.Image (async)
//   2. CustomPainter memanggil canvas.saveLayer(BlendMode.screen)
//   3. screen(black,  bg) = bg   → piksel hitam jadi transparan ✓
//   4. screen(color, bg) = vivid → warna neon makin bersinar   ✓
class _FloatingArena extends StatefulWidget {
  final Animation<double> pulseAnim;
  const _FloatingArena({required this.pulseAnim});

  @override
  State<_FloatingArena> createState() => _FloatingArenaState();
}

class _FloatingArenaState extends State<_FloatingArena> {
  ui.Image? _arenaImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/arena_platform.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _arenaImage = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // ── Glow ellipse shadow beneath the platform ──────────
        AnimatedBuilder(
          animation: widget.pulseAnim,
          builder: (_, __) => Positioned(
            bottom: -8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 380,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: _C.neonBlue.withValues(
                          alpha: 0.35 + 0.2 * widget.pulseAnim.value),
                      blurRadius: 45,
                      spreadRadius: 14,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF2050).withValues(
                          alpha: 0.18 + 0.12 * widget.pulseAnim.value),
                      blurRadius: 32,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Arena platform (black bg → transparent via screen blend) ─
        if (_arenaImage != null)
          SizedBox(
            width: 520,
            height: 360,
            child: CustomPaint(
              painter: _ScreenBlendPainter(image: _arenaImage!),
            ),
          )
        else
          // Placeholder while image is loading
          const SizedBox(width: 520, height: 360),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Painter: draws image with canvas.saveLayer(BlendMode.screen)
//   → composites the entire image layer onto what's behind
//     using screen blend → black pixels disappear
// ─────────────────────────────────────────────────────────
class _ScreenBlendPainter extends CustomPainter {
  final ui.Image image;
  const _ScreenBlendPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    // saveLayer composites everything drawn inside it
    // onto the destination using the specified blend mode.
    // BlendMode.screen formula:  result = src + dst - src*dst
    //   src = black (0,0,0)  → result = 0 + dst - 0 = dst  (bg shows) ✓
    //   src = white (1,1,1)  → result = 1                              ✓
    //   src = neon color     → result brightened / vivid               ✓
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..blendMode = BlendMode.screen,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
          0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScreenBlendPainter old) =>
      old.image != image;
}


// ═══════════════════════════════════════════════════════

// C. LEADERBOARD PANEL (Right Sidebar)
// ═══════════════════════════════════════════════════════
class _LeaderboardPanel extends StatelessWidget {
  const _LeaderboardPanel();

  @override
  Widget build(BuildContext context) {
    final players = [
      _Player(rank: 1, name: 'NeonStrider'),
      _Player(rank: 2, name: 'Cipher'),
      _Player(rank: 3, name: 'VoidWalker'),
      _Player(rank: 4, name: 'ApexSumo'),
      _Player(rank: 5, name: 'TitanSmasher'),
    ];

    return Container(
      width: 240,
      color: _C.panelBg,
      child: Column(
        children: [
          // Title Bar
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _C.panelBorder, width: 1),
              ),
            ),
            child: const Text(
              'LEADERBOARD GLOBAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
          ),

          // Player rows
          Expanded(
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              itemCount: players.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _PlayerRow(player: players[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Player {
  final int rank;
  final String name;
  const _Player({required this.rank, required this.name});
}

class _PlayerRow extends StatelessWidget {
  final _Player player;
  const _PlayerRow({required this.player});

  static const _rankColors = {
    1: _C.gold,
    2: _C.silver,
    3: _C.bronze,
    4: _C.teal,
    5: _C.purple,
  };

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColors[player.rank] ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111120),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rankColor.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Rank number (colored)
          SizedBox(
            width: 20,
            child: Text(
              '${player.rank}',
              style: TextStyle(
                color: rankColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar circle
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1A1A2E),
            ),
            child: const Icon(Icons.person, color: Colors.white54, size: 18),
          ),
          const SizedBox(width: 10),

          // Name
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Shield badge with rank number
          _ShieldBadge(rank: player.rank, color: rankColor),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SHIELD BADGE WIDGET
// ═══════════════════════════════════════════════════════
class _ShieldBadge extends StatelessWidget {
  final int rank;
  final Color color;

  const _ShieldBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shield shape via custom paint
          CustomPaint(
            size: const Size(34, 34),
            painter: _ShieldPainter(color: color),
          ),
          // Rank number inside shield
          Text(
            '$rank',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color color;
  const _ShieldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Simple shield path
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.05);
    path.lineTo(w * 0.95, h * 0.22);
    path.lineTo(w * 0.95, h * 0.55);
    path.quadraticBezierTo(w * 0.95, h * 0.82, w * 0.5, h * 0.97);
    path.quadraticBezierTo(w * 0.05, h * 0.82, w * 0.05, h * 0.55);
    path.lineTo(w * 0.05, h * 0.22);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter old) => old.color != color;
}
