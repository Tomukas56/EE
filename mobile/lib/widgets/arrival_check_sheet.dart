import 'package:flutter/material.dart';
import '../core/theme.dart';

enum CheckAnswer { yes, no, dismissed }

class ArrivalCheckResult {
  const ArrivalCheckResult({
    required this.working,
    required this.freeConnectors,
  });

  final CheckAnswer working;
  final CheckAnswer freeConnectors;

  String get workingApi => _api(working);
  String get freeConnectorsApi => _api(freeConnectors);

  static String _api(CheckAnswer value) {
    switch (value) {
      case CheckAnswer.yes:
        return 'YES';
      case CheckAnswer.no:
        return 'NO';
      case CheckAnswer.dismissed:
        return 'DISMISSED';
    }
  }
}

/// Two questions on arrival: is it working? any free connectors?
/// Each can be Yes, No, or Dismiss.
Future<ArrivalCheckResult?> showArrivalCheckSheet(
  BuildContext context, {
  required String stationName,
}) {
  return showModalBottomSheet<ArrivalCheckResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ArrivalCheckSheet(stationName: stationName),
  );
}

class _ArrivalCheckSheet extends StatefulWidget {
  const _ArrivalCheckSheet({required this.stationName});

  final String stationName;

  @override
  State<_ArrivalCheckSheet> createState() => _ArrivalCheckSheetState();
}

class _ArrivalCheckSheetState extends State<_ArrivalCheckSheet> {
  CheckAnswer? _working;
  CheckAnswer? _free;

  @override
  Widget build(BuildContext context) {
    final canSend = _working != null && _free != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You arrived at ${widget.stationName}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please confirm what you see. Dismiss skips the question.',
            style: TextStyle(color: Color(0xFF3A3A3C), fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Is this station working?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          _ThreeWay(
            value: _working,
            onChanged: (value) => setState(() => _working = value),
          ),
          const SizedBox(height: 16),
          const Text(
            'Are there free connectors?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          _ThreeWay(
            value: _free,
            onChanged: (value) => setState(() => _free = value),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: canSend
                ? () => Navigator.pop(
                      context,
                      ArrivalCheckResult(
                        working: _working!,
                        freeConnectors: _free!,
                      ),
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Send report'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}

class _ThreeWay extends StatelessWidget {
  const _ThreeWay({required this.value, required this.onChanged});

  final CheckAnswer? value;
  final ValueChanged<CheckAnswer> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(CheckAnswer answer, String label) {
      final selected = value == answer;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            onPressed: () => onChanged(answer),
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  selected ? AppColors.primaryBlue : Colors.white,
              foregroundColor:
                  selected ? Colors.white : const Color(0xFF111111),
              side: BorderSide(
                color: selected
                    ? AppColors.primaryBlue
                    : const Color(0xFFD1D1D6),
              ),
            ),
            child: Text(label),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(CheckAnswer.yes, 'Yes'),
        chip(CheckAnswer.no, 'No'),
        chip(CheckAnswer.dismissed, 'Dismiss'),
      ],
    );
  }
}
