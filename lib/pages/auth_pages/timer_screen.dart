import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart'; // For vibration support

class TimerScreen extends StatefulWidget {
  final Function showNotification;

  TimerScreen({required this.showNotification});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  int _studyTimeInMinutes = 0;
  late Timer _timer;
  bool _isTimerRunning = false;
  bool _isPaused = false;
  int _remainingTimeInSeconds = 0;
  int _goalTimeInMinutes = 0;
  bool _focusFailed = false;
  static const int maxTimeInMinutes = 180;
  static const int inactivityThreshold = 30; // 30 seconds inactivity threshold
  Timer? _inactivityTimer;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    if (_inactivityTimer != null && _inactivityTimer!.isActive) {
      _inactivityTimer!.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Initialise local notifications
  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_stat_access_alarms');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Play alarm and notify user when timer ends
  Future<void> _playAlarm() async {
    widget.showNotification('Study Session Over', 'Time to take a break!');
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate();
    }
  }

  // Function to start study timer
  void _startTimer() {
    setState(() {
      _goalTimeInMinutes = _studyTimeInMinutes;
      _remainingTimeInSeconds = _studyTimeInMinutes * 60;
      _isTimerRunning = true;
      _focusFailed = false;
    });

    // Start countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingTimeInSeconds == 0) {
        setState(() {
          _isTimerRunning = false; // Stop the timer when time runs out
        });
        _timer.cancel();
        _playAlarm();
      } else {
        setState(() {
          _remainingTimeInSeconds--;
        });
      }
    });
  }

  // Increment the study time by 5 minutes
  void _incrementTime() {
    if (_studyTimeInMinutes + 5 <= maxTimeInMinutes) {
      setState(() {
        _studyTimeInMinutes += 5;
        _remainingTimeInSeconds = _studyTimeInMinutes * 60;
      });
    }
  }

  // Decrement the study time by 5 minutes
  void _decrementTime() {
    if (_studyTimeInMinutes - 5 >= 0) {
      setState(() {
        _studyTimeInMinutes -= 5;
        _remainingTimeInSeconds = _studyTimeInMinutes * 60;
      });
    }
  }

  // Format time in MM:SS format display
  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _pauseTimer() {
    if (_timer.isActive) _timer.cancel();
    setState(() {
      _isPaused = true; //Mark timer as paused
      _isTimerRunning = false; //Stop timer
    });
  }

  void _continueTimer() {
    setState(() {
      _isPaused = false; // Resume timer from being paused
      _focusFailed = false; // Reset focus failure state
      _isTimerRunning = true; // Continue timer
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingTimeInSeconds == 0) {
        setState(() {
          _isTimerRunning = false;
        });
        _timer.cancel();
        _playAlarm();
      } else {
        setState(() {
          _remainingTimeInSeconds--;
        });
      }
    });
  }

  // Function to reset timer to 0
  void _resetTimer() {
    setState(() {
      _studyTimeInMinutes = 0;
      _remainingTimeInSeconds = 0;
      _goalTimeInMinutes = 0;
      _isPaused = false;
      _isTimerRunning = false;
      _focusFailed = false;
    });
  }

  // Handle back button restriction when timer still running
  Future<bool> _onWillPop() async {
    if (_isTimerRunning) {
      _showRunningTimerMessage(); // Show a message that timer is still running
      return false; // Prevent leaving if timer is still running
    }
    return true; // Allow to leave if timer hasn't started or has finished
  }

  // Show a message when trying to leave while timer is running
  void _showRunningTimerMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Timer is still active. Please end the timer before exiting.'),
      ),
    );
  }

  // Lifecycle event handling: pause/resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _inactivityTimer = Timer(Duration(seconds: inactivityThreshold), () {
        setState(() {
          _focusFailed = true;
        });
        _pauseTimer(); // Pause timer when app is in the background for more than 30secs
      });
    } else if (state == AppLifecycleState.resumed) {
      if (_inactivityTimer != null && _inactivityTimer!.isActive) {
        _inactivityTimer!.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Timer'),
        ),
        backgroundColor: theme.colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Study Timer',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Reminder: Please avoid using other apps while the timer is running.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _goalTimeInMinutes > 0
                    ? 'Goal: $_goalTimeInMinutes minutes'
                    : 'Set your timer',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              if (!_isTimerRunning && !_isPaused) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _decrementTime,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: const Text('-5 min'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _incrementTime,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: const Text('+5 min'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Text(
                _formatTime(_remainingTimeInSeconds),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              if (_focusFailed) ...[
                const Text(
                  'Focus failed. You left the app for too long.',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _continueTimer,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: const Text('Continue Timer'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _resetTimer,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: const Text('Dismiss Timer'),
                    ),
                  ],
                ),
              ] else if (!_isPaused && !_isTimerRunning) ...[
                ElevatedButton(
                  onPressed: _startTimer,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: const Text('Start Timer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
