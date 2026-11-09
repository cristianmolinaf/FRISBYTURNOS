import 'dart:async';
import 'package:flutter/material.dart';
import '../../google_fonts_wrapper.dart';

/// Shiftbase-inspired Punch Clock (Reloj Checador de Turno)
/// Cloned from the Shiftbase iOS mobile app hero card.
class ShiftbasePunchClock extends StatefulWidget {
  final String collaboratorName;
  final String storeName;
  final String station;
  final String scheduledShift;
  final bool isDark;
  final VoidCallback? onClockToggle;
  final VoidCallback? onSwitchShift;

  const ShiftbasePunchClock({
    super.key,
    required this.collaboratorName,
    required this.storeName,
    required this.station,
    required this.scheduledShift,
    this.isDark = false,
    this.onClockToggle,
    this.onSwitchShift,
  });

  @override
  State<ShiftbasePunchClock> createState() => _ShiftbasePunchClockState();
}

class _ShiftbasePunchClockState extends State<ShiftbasePunchClock> {
  bool _isClockedIn = true;
  bool _isOnBreak = false;
  Duration _elapsed = const Duration(hours: 0, minutes: 52, seconds: 18);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isClockedIn && !_isOnBreak && mounted) {
        setState(() {
          _elapsed = _elapsed + const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatSeconds(Duration d) {
    return (d.inSeconds % 60).toString().padLeft(2, '0');
  }

  void _handleClockAction() {
    setState(() {
      _isClockedIn = !_isClockedIn;
      if (!_isClockedIn) {
        _isOnBreak = false;
      } else {
        _elapsed = Duration.zero;
      }
    });
    widget.onClockToggle?.call();
  }

  void _handleBreakAction() {
    setState(() {
      _isOnBreak = !_isOnBreak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _isClockedIn
        ? [
            const Color(0xFFFF523B), // Shiftbase Vibrant Orange
            const Color(0xFFE01867), // Shiftbase Magenta Pink
          ]
        : [
            const Color(0xFF4A5568),
            const Color(0xFF2D3748),
          ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Vertical accent strip + Status indicator + Clock-in start time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _isClockedIn
                          ? const Color(0xFF00E676)
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isClockedIn
                        ? (_isOnBreak ? 'EN PAUSA' : 'TURNO ACTIVO')
                        : 'FUERA DE TURNO',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isClockedIn ? 'Desde 08:49 AM' : 'Programado: ${widget.scheduledShift}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Timer Display (Big bold numbers with seconds)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _isClockedIn ? _formatDuration(_elapsed) : '00:00',
                style: GoogleFonts.sora(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.2,
                ),
              ),
              if (_isClockedIn) ...[
                Text(
                  ':${_formatSeconds(_elapsed)}',
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle: Shift name • Store • Department
          Text(
            '${widget.scheduledShift} • ${widget.storeName} | ${widget.station}',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),

          // Action Buttons: Clock out / Clock in + Switch shift / Break
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleClockAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2129),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isClockedIn
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_fill_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isClockedIn ? 'Finalizar Turno' : 'Iniciar Turno',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isClockedIn ? _handleBreakAction : widget.onSwitchShift,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      _isClockedIn
                          ? (_isOnBreak ? 'Reanudar' : 'Pausa')
                          : 'Cambiar',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
