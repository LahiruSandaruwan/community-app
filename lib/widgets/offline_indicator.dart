import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/theme.dart';

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({Key? key}) : super(key: key);

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenToConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivity == ConnectivityResult.none;
    });
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.warningColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            'No internet connection - Working offline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
