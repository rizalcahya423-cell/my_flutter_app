import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/auth_provider.dart';
import 'remote_screen.dart';


class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with TickerProviderStateMixin {
  String _selectedTab = 'GUIDE';
  final int _gems = 79;

  // Animations
  late AnimationController _pulseCtrl, _floatCtrl, _bgCtrl;
  late Animation<double> _pulseAnim, _floatAnim;

  // Realtime: Battery
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  Timer? _batteryTimer;

  // Realtime: Connectivity
  List<ConnectivityResult> _connectivityResult = [ConnectivityResult.wifi];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Animations
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 15))
      ..repeat();

    // Init realtime battery
    _initBattery();
    // Init realtime connectivity
    _initConnectivity();
  }

  Future<void> _initBattery() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _batteryState = await _battery.batteryState;
      if (mounted) setState(() {});

      _battery.onBatteryStateChanged.listen((state) {
        if (mounted) {
          setState(() => _batteryState = state);
          _battery.batteryLevel.then((level) {
            if (mounted) setState(() => _batteryLevel = level);
          });
        }
      });

      // Poll battery level every 5 seconds to ensure pure real-time updating
      _batteryTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          final level = await _battery.batteryLevel;
          final state = await _battery.batteryState;
          if (mounted) {
            setState(() {
              _batteryLevel = level;
              _batteryState = state;
            });
          }
        } catch (_) {}
      });
    } catch (_) {
      // Web/unsupported platform fallback
      if (mounted) setState(() => _batteryLevel = -1);
    }
  }

  Future<void> _initConnectivity() async {
    try {
      _connectivityResult = await Connectivity().checkConnectivity();
      if (mounted) setState(() {});

      Connectivity().onConnectivityChanged.listen((result) {
        if (mounted) setState(() => _connectivityResult = result);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _connectivityResult = [ConnectivityResult.none]);
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _bgCtrl.dispose();
    _batteryTimer?.cancel();
    super.dispose();
  }

  // ═══ Helpers untuk battery & connectivity ═══
  IconData get _batteryIcon {
    if (_batteryState == BatteryState.charging) return Icons.battery_charging_full;
    if (_batteryLevel < 0) return Icons.battery_unknown;
    if (_batteryLevel > 80) return Icons.battery_full;
    if (_batteryLevel > 60) return Icons.battery_5_bar;
    if (_batteryLevel > 40) return Icons.battery_4_bar;
    if (_batteryLevel > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  Color get _batteryColor {
    return const Color(0xFF4CAF50); // Selalu warna hijau sesuai permintaan user
  }

  String get _batteryText {
    if (_batteryLevel < 0) return '??%';
    return '$_batteryLevel%';
  }

  IconData get _signalIcon {
    if (_connectivityResult.contains(ConnectivityResult.wifi)) {
      return Icons.wifi;
    } else if (_connectivityResult.contains(ConnectivityResult.mobile)) {
      return Icons.signal_cellular_alt;
    } else if (_connectivityResult.contains(ConnectivityResult.ethernet)) {
      return Icons.lan;
    } else if (_connectivityResult.contains(ConnectivityResult.none)) {
      return Icons.signal_wifi_off;
    }
    return Icons.signal_cellular_alt;
  }

  Color get _signalColor {
    if (_connectivityResult.contains(ConnectivityResult.none)) {
      return const Color(0xFFFF5252);
    }
    return const Color(0xFF4CAF50);
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ═══ DYNAMIC MOVING BACKGROUND ═══
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: AbstractMovingBackgroundPainter(_bgCtrl.value),
                );
              },
            ),
          ),

          // ═══ MAIN LAYOUT ═══
          Column(
            children: [
              const SizedBox(height: 4),
              _buildTopBar(),
              Expanded(
                child: Row(
                  children: [
                    _buildSidebar(),
                    Expanded(child: _buildCenterArena()),
                    _buildLeaderboard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SizedBox(
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Profil kiri atas ──
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _showLogoutDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [Color(0xFF4A148C), Color(0xFF1A237E)]),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white70, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text('USER_01',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // ── Logo BATTLEBOT INDONESIA (Mathematic Center) ──
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('BATTLEBOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                              color:
                                  const Color(0xFF2979FF).withValues(alpha: 0.8),
                              blurRadius: 12),
                        ],
                      )),
                  Text('INDONESIA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        shadows: [
                          Shadow(
                              color:
                                  const Color(0xFF2979FF).withValues(alpha: 0.5),
                              blurRadius: 8),
                        ],
                      )),
                ],
              ),
            ),

            // ── Indikator kanan atas (REALTIME) ──
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Diamond + jumlah
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF2979FF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.diamond,
                            color: Color(0xFF42A5F5), size: 16),
                        const SizedBox(width: 4),
                        Text('$_gems',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Plus button
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              const Color(0xFF4CAF50).withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.add,
                        color: Color(0xFF4CAF50), size: 14),
                  ),
                  const SizedBox(width: 10),

                  // ═══ SIGNAL (REALTIME via connectivity_plus) ═══
                  Icon(_signalIcon, color: _signalColor, size: 18),
                  const SizedBox(width: 6),

                  // ═══ BATTERY (REALTIME via battery_plus) ═══
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _batteryColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_batteryIcon, color: _batteryColor, size: 14),
                        const SizedBox(width: 2),
                        Text(_batteryText,
                            style: TextStyle(
                              color: _batteryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
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

  // ═══════════════════════════════════════════════════════
  // SIDEBAR KIRI (transparan, full ke kiri)
  // ═══════════════════════════════════════════════════════
  Widget _buildSidebar() {
    final items = [
      ('SHOP', Icons.shopping_cart_outlined, 'Shop'),
      ('INVENTORY', Icons.inventory_2_outlined, 'Inventory'),
      ('GUIDE', Icons.menu_book_outlined, 'Guide'),
      ('PENGATURAN', Icons.settings_outlined, 'Pengaturan'),
    ];

    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border(
            right: BorderSide(
                color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.map((item) {
          final isActive = _selectedTab == item.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isActive
                        ? const Color(0xFF42A5F5).withValues(alpha: 0.4)
                        : Colors.transparent),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$2,
                      color: isActive
                          ? const Color(0xFF42A5F5)
                          : Colors.white38,
                      size: 22),
                  const SizedBox(height: 4),
                  Text(item.$3,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white38,
                        fontSize: 9,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // CENTER ARENA (floating)
  // ═══════════════════════════════════════════════════════
  Widget _buildCenterArena() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arena platform floating
        Positioned(
          left: 0, right: 0, top: 0, bottom: 60,
          child: Align(
            alignment: const Alignment(0, -0.05),
            child: AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, child) => Transform.translate(
                  offset: Offset(0, _floatAnim.value), child: child),
              child: _FloatingArena(pulseAnim: _pulseAnim),
            ),
          ),
        ),

        // MASUK LOBBY button
        Positioned(
          bottom: 12, left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RemoteScreen())),
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 300, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      const Color(0xFF1A237E).withValues(alpha: 0.8),
                      const Color(0xFF0D47A1).withValues(alpha: 0.8),
                      const Color(0xFF1A237E).withValues(alpha: 0.8),
                    ]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color.lerp(const Color(0xFF42A5F5),
                              Colors.white, _pulseAnim.value * 0.3)!
                          .withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2979FF)
                            .withValues(alpha: _pulseAnim.value * 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text('MASUK LOBBY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(
                                color: const Color(0xFF42A5F5)
                                    .withValues(alpha: 0.8),
                                blurRadius: 8),
                          ],
                        )),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // LEADERBOARD KANAN (transparan)
  // ═══════════════════════════════════════════════════════
  Widget _buildLeaderboard() {
    final players = [
      (1, 'NeonStrider'),
      (2, 'Cipher'),
      (3, 'VoidWalker'),
      (4, 'ApexSumo'),
      (5, 'TitanSmasher'),
    ];

    return Container(
      width: 220,
      margin: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: const Text('LEADERBOARD GLOBAL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                )),
          ),
          // Player list
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              itemCount: players.length,
              itemBuilder: (_, i) {
                final rank = players[i].$1;
                final name = players[i].$2;
                final color = _rankColor(rank);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: rank <= 3
                            ? color.withValues(alpha: 0.2)
                            : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A2E),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white54, size: 16),
                      ),
                      const SizedBox(width: 8),
                      // Name
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      // Rank badge
                      // TODO: Top 3 → Image.asset('assets/rank_$rank.png')
                      _buildRankBadge(rank, color),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) => switch (rank) {
        1 => const Color(0xFFFFD700),
        2 => const Color(0xFFB0BEC5),
        3 => const Color(0xFFE67E22),
        4 => const Color(0xFF00E5A0),
        _ => const Color(0xFF9C5FFF),
      };

  Widget _buildRankBadge(int rank, Color color) {
    // Placeholder badge — nanti bisa diganti asset gambar
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1),
              ]
            : null,
      ),
      child: Center(
        child: Text('$rank',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            )),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title:
            const Text('Keluar', style: TextStyle(color: Color(0xFF42A5F5))),
        content: const Text('Apakah Anda ingin keluar?',
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1744),
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
// FLOATING ARENA (PNG transparan via screen blend)
// ═══════════════════════════════════════════════════════
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
    final data = await rootBundle.load('assets/arena_diorama.png');
    final codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _arenaImage = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Glow shadow beneath arena
        AnimatedBuilder(
          animation: widget.pulseAnim,
          builder: (_, __) => Positioned(
            bottom: -10,
            child: Container(
              width: 520, height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2979FF).withValues(
                       alpha: 0.3 + 0.2 * widget.pulseAnim.value),
                    blurRadius: 40,
                    spreadRadius: 12,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF1744).withValues(
                       alpha: 0.15 + 0.1 * widget.pulseAnim.value),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Arena image (normal drawing, no screen blend to prevent background from covering it)
        if (_arenaImage != null)
          OverflowBox(
            minWidth: 780,
            maxWidth: 780,
            minHeight: 500,
            maxHeight: 500,
            child: SizedBox(
              width: 780, height: 500,
              child: CustomPaint(
                  painter: _ScreenBlendPainter(image: _arenaImage!)),
            ),
          )
        else
          const OverflowBox(
            minWidth: 780,
            maxWidth: 780,
            minHeight: 500,
            maxHeight: 500,
            child: SizedBox(width: 780, height: 500),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// ARENA PAINTER (normal drawing - maintains transparency)
// ═══════════════════════════════════════════════════════
class _ScreenBlendPainter extends CustomPainter {
  final ui.Image image;
  const _ScreenBlendPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final double srcWidth = image.width.toDouble();
    final double srcHeight = image.height.toDouble();
    
    // Hitung aspect ratio agar TIDAK GEPENG
    final double srcAspect = srcWidth / srcHeight;
    final double dstAspect = size.width / size.height;
    
    double drawWidth;
    double drawHeight;
    
    if (srcAspect > dstAspect) {
      // Gambar lebih lebar dibanding container, batasi lebar
      drawWidth = size.width;
      drawHeight = size.width / srcAspect;
    } else {
      // Gambar lebih tinggi dibanding container, batasi tinggi
      drawHeight = size.height;
      drawWidth = size.height * srcAspect;
    }
    
    // Posisikan gambar di tengah container
    final double dx = (size.width - drawWidth) / 2;
    final double dy = (size.height - drawHeight) / 2;
    final Rect destRect = Rect.fromLTWH(dx, dy, drawWidth, drawHeight);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, srcWidth, srcHeight),
      destRect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant _ScreenBlendPainter old) =>
      old.image != image;
}

// ═══════════════════════════════════════════════════════
// ABSTRACT MOVING BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════
class AbstractMovingBackgroundPainter extends CustomPainter {
  final double animationValue;
  AbstractMovingBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw solid dark base
    final basePaint = Paint()..color = const Color(0xFF070010);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    final double w = size.width;
    final double h = size.height;

    // Blob 1: Vibrant Red on the left-ish side
    final double x1 = w * 0.25 + math.sin(animationValue * 2 * math.pi) * w * 0.15;
    final double y1 = h * 0.4 + math.cos(animationValue * 2 * math.pi) * h * 0.2;
    final double r1 = math.min(w, h) * 0.45 + math.sin(animationValue * 2 * math.pi) * 40;

    final paintRed = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 130);

    canvas.drawCircle(Offset(x1, y1), r1, paintRed);

    // Blob 2: Vibrant Blue on the right-ish side
    final double x2 = w * 0.75 + math.cos(animationValue * 2 * math.pi) * w * 0.15;
    final double y2 = h * 0.5 + math.sin(animationValue * 2 * math.pi) * h * 0.2;
    final double r2 = math.min(w, h) * 0.45 + math.cos(animationValue * 2 * math.pi) * 40;

    final paintBlue = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 140);

    canvas.drawCircle(Offset(x2, y2), r2, paintBlue);

    // Blob 3: Deep Royal Blue in the center-right
    final double x3 = w * 0.6 + math.sin(animationValue * 2 * math.pi + 1.0) * w * 0.2;
    final double y3 = h * 0.3 + math.cos(animationValue * 2 * math.pi + 1.0) * h * 0.15;
    final double r3 = math.min(w, h) * 0.5 + math.sin(animationValue * 2 * math.pi + 1.0) * 30;

    final paintRoyal = Paint()
      ..color = const Color(0xFF2979FF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 150);

    canvas.drawCircle(Offset(x3, y3), r3, paintRoyal);

    // Blob 4: Deep Crimson Red in the center-left
    final double x4 = w * 0.4 + math.cos(animationValue * 2 * math.pi + 2.0) * w * 0.2;
    final double y4 = h * 0.7 + math.sin(animationValue * 2 * math.pi + 2.0) * h * 0.15;
    final double r4 = math.min(w, h) * 0.45 + math.cos(animationValue * 2 * math.pi + 2.0) * 30;

    final paintCrimson = Paint()
      ..color = const Color(0xFFD50000).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    canvas.drawCircle(Offset(x4, y4), r4, paintCrimson);
  }

  @override
  bool shouldRepaint(covariant AbstractMovingBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
