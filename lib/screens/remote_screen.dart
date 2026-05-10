import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/control_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/control_button.dart';

class RemoteScreen extends StatelessWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final control = Provider.of<ControlProvider>(context, listen: false);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF2C2C2C), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Logout Button
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white54),
                  onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
                ),
              ),

              // Left Control (Forward/Backward)
              Positioned(
                left: 60,
                bottom: 40,
                child: Column(
                  children: [
                    ControlButton(
                      icon: Icons.expand_less,
                      onTapDown: () => control.updateDirection("F", true),
                      onTapUp: () => control.updateDirection("F", false),
                    ),
                    const SizedBox(height: 30),
                    ControlButton(
                      icon: Icons.expand_more,
                      onTapDown: () => control.updateDirection("B", true),
                      onTapUp: () => control.updateDirection("B", false),
                    ),
                  ],
                ),
              ),

              // Right Control (Left/Right)
              Positioned(
                right: 60,
                bottom: 40,
                child: Row(
                  children: [
                    ControlButton(
                      icon: Icons.chevron_left,
                      onTapDown: () => control.updateDirection("L", true),
                      onTapUp: () => control.updateDirection("L", false),
                    ),
                    const SizedBox(width: 30),
                    ControlButton(
                      icon: Icons.chevron_right,
                      onTapDown: () => control.updateDirection("R", true),
                      onTapUp: () => control.updateDirection("R", false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
