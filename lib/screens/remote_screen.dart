import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../providers/control_provider.dart';
import '../widgets/control_button.dart';
import '../utils/agora_config.dart';

// ═══════════════════════════════════════════════════════════
// REMOTE SCREEN (Controller + Live Camera Background from Agora)
// ═══════════════════════════════════════════════════════════

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  late RtcEngine _engine;
  bool _isJoined = false;
  int? _remoteUid;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      // 1. Buat RtcEngine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // 2. Setup event handler untuk mendeteksi kamera server masuk
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("Berhasil join channel \${connection.channelId}");
            setState(() {
              _isJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("Remote user \$remoteUid joined");
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint("Remote user \$remoteUid left");
            if (_remoteUid == remoteUid) {
              setState(() {
                _remoteUid = null;
              });
            }
          },
          onError: (ErrorCodeType err, String msg) {
            setState(() {
              _isError = true;
            });
          },
        ),
      );

      // 3. Konfigurasi Mode Communication
      await _engine.enableVideo();
      await _engine.disableAudio(); // Tidak butuh audio

      // 4. Join channel
      await _engine.joinChannel(
        token: AgoraConfig.token,
        channelId: AgoraConfig.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: false,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
        ),
      );
    } catch (e) {
      debugPrint("Gagal setup Agora: \$e");
      setState(() {
        _isError = true;
      });
    }
  }

  @override
  void dispose() {
    _leaveChannel();
    super.dispose();
  }

  Future<void> _leaveChannel() async {
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      debugPrint("Error saat dispose: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final control = Provider.of<ControlProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = constraints.biggest.shortestSide;
            final buttonSize = shortestSide < 360 ? 76.0 : 100.0;
            final sideOffset = shortestSide < 360 ? 24.0 : 60.0;
            final bottomOffset = shortestSide < 360 ? 20.0 : 40.0;
            final buttonGap = shortestSide < 360 ? 18.0 : 30.0;

            return Stack(
              children: [
                // Layer 0: Camera stream background (AgoraVideoView)
                Positioned.fill(
                  child: _buildCameraBackground(),
                ),

                // Layer 1: Semi-transparent overlay untuk menonjolkan tombol
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),

                // Back button
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),

                // Status indicator
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildConnectionIndicator(),
                ),

                // Left Control (Forward/Backward)
                Positioned(
                  left: sideOffset,
                  bottom: bottomOffset,
                  child: Column(
                    children: [
                      ControlButton(
                        size: buttonSize,
                        icon: Icons.expand_less,
                        color: const Color(0xFF00E5FF),
                        onTapDown: () => control.updateDirection("F", true),
                        onTapUp: () => control.updateDirection("F", false),
                      ),
                      SizedBox(height: buttonGap),
                      ControlButton(
                        size: buttonSize,
                        icon: Icons.expand_more,
                        color: const Color(0xFF00E5FF),
                        onTapDown: () => control.updateDirection("B", true),
                        onTapUp: () => control.updateDirection("B", false),
                      ),
                    ],
                  ),
                ),

                // Right Control (Left/Right)
                Positioned(
                  right: sideOffset,
                  bottom: bottomOffset,
                  child: Column(
                    children: [
                      ControlButton(
                        size: buttonSize,
                        icon: Icons.chevron_left,
                        color: const Color(0xFFFF1744),
                        onTapDown: () => control.updateDirection("L", true),
                        onTapUp: () => control.updateDirection("L", false),
                      ),
                      SizedBox(height: buttonGap),
                      ControlButton(
                        size: buttonSize,
                        icon: Icons.chevron_right,
                        color: const Color(0xFFFF1744),
                        onTapDown: () => control.updateDirection("R", true),
                        onTapUp: () => control.updateDirection("R", false),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UI HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _buildCameraBackground() {
    if (_isError) {
      return const Center(
        child: Text("Gagal memuat kamera", style: TextStyle(color: Colors.red)),
      );
    }
    
    // Jika belum ada kamera server yang terdeteksi
    if (_remoteUid == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              _isJoined ? "Menunggu Server Kamera..." : "Menghubungkan ke Agora...",
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // Kamera berhasil terhubung, render video dari Agora
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: const RtcConnection(channelId: AgoraConfig.channelName),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    Color dotColor = Colors.white38;
    String tooltip = 'Menghubungkan...';

    if (_isError) {
      dotColor = const Color(0xFFFF1744);
      tooltip = 'Error koneksi';
    } else if (_remoteUid != null) {
      dotColor = const Color(0xFF00E676);
      tooltip = 'Kamera Terhubung';
    } else if (_isJoined) {
      dotColor = const Color(0xFFFFB300);
      tooltip = 'Menunggu Kamera...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tooltip,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
