import 'package:flutter/material.dart';
import '../../core/theme.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  bool _calculated = false;

  void _calculateRoute() {
    setState(() {
      _calculated = true;
      FocusScope.of(context).unfocus();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route calculated with 1 charging stop')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Planner')),
      body: Column(
        children: [
          // Input Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                    prefixIcon: Icon(Icons.my_location),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _endController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculateRoute,
                    child: const Text('Find Charging Route'),
                  ),
                ),
              ],
            ),
          ),

          // Map Result (Placeholder for Web Demo)
          Expanded(
            child: Container(
              color: Colors.grey[200],
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!_calculated)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enter locations to see route',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),

                  if (_calculated) ...[
                    // Mock route visualization
                    CustomPaint(
                      size: const Size(300, 300),
                      painter: _RoutePainter(),
                    ),
                    const Positioned(
                      bottom: 20,
                      child: Text(
                        'Map Visualization Only (No API Key)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Trip Summary (Visible when calculated)
          if (_calculated)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TripStat(
                    icon: Icons.timer,
                    value: '1h 15m',
                    label: 'Duration',
                  ),
                  _TripStat(
                    icon: Icons.ev_station,
                    value: '1 Stop',
                    label: 'Charging',
                  ),
                  _TripStat(icon: Icons.bolt, value: '24 kWh', label: 'Energy'),
                  _TripStat(
                    icon: Icons.euro,
                    value: '€8.50',
                    label: 'Est. Cost',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _TripStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryTeal),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw route line
    final paint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.8); // Start
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width * 0.8,
      size.height * 0.2,
    ); // End

    canvas.drawPath(path, paint);

    // Draw points (Start, End, Charging)
    final dotPaint = Paint()..color = AppColors.accentOrange;

    // Start
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 8, dotPaint);

    // End
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 8, dotPaint);

    // Charging station
    final stationPaint = Paint()..color = AppColors.primaryTeal;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.48),
      10,
      stationPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
