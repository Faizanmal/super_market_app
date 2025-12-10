import 'package:flutter/material.dart';
import '../../services/voice_command_service.dart';

class VoiceFAB extends StatefulWidget {
  const VoiceFAB({Key? key}) : super(key: key);

  @override
  State<VoiceFAB> createState() => _VoiceFABState();
}

class _VoiceFABState extends State<VoiceFAB> with SingleTickerProviderStateMixin {
  final VoiceCommandService _service = VoiceCommandService();
  bool _isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _service.init();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() => _isListening = true);
    _showListeningDialog();
    
    _service.startListening(
      onResult: (text) {
        Navigator.of(context).pop(); // Close dialog
        setState(() => _isListening = false);
        
        final command = _service.processCommand(text);
        if (command != null) {
          _handleCommand(command);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Heard: "$text" (No command match)')),
          );
        }
      },
      onError: (msg) {
        if (mounted && _isListening) {
          Navigator.of(context).pop();
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    );
  }

  void _showListeningDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _animationController,
              child: const Icon(Icons.mic, color: Colors.blue, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Listening...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Try "Show expired items" or "Search for milk"'),
          ],
        ),
      ),
    ).then((_) {
      if (_isListening) {
        _service.stopListening();
        if (mounted) setState(() => _isListening = false);
      }
    });
  }

  void _handleCommand(VoiceCommand command) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Executing: ${command.action.name}'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Command Routing Logic
    switch (command.action) {
      case VoiceAction.showExpired:
        Navigator.pushNamed(context, '/expiry_alerts'); // Assuming route exists
        break;
      case VoiceAction.search:
        // Handle search
         break;
      case VoiceAction.showDashboard:
        Navigator.pushNamed(context, '/dashboard');
        break;
      // Add more cases
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _startListening,
      child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      backgroundColor: _isListening ? Colors.redAccent : Theme.of(context).primaryColor,
      elevation: 6,
    );
  }
}
