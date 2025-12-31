import 'dart:async';

class GlobalRefreshEvent {
  // Singleton instance
  static final GlobalRefreshEvent _instance = GlobalRefreshEvent._internal();

  factory GlobalRefreshEvent() {
    return _instance;
  }

  GlobalRefreshEvent._internal();

  static GlobalRefreshEvent get instance => _instance;

  // Stream controller to broadcast events
  final _controller = StreamController<void>.broadcast();

  // Stream used by listeners
  Stream<void> get refreshStream => _controller.stream;

  // Method to trigger a refresh
  void notify() {
    _controller.add(null);
    print("🔄 GlobalRefreshEvent Triggered!");
  }

  // Dispose method (usually not needed for a singleton app-wide event)
  void dispose() {
    _controller.close();
  }
}
