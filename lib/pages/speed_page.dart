import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:davinci_lighter/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SpeedPage extends StatefulWidget {
  const SpeedPage({super.key});

  @override
  State<SpeedPage> createState() => _SpeedPageState();
}

class _SpeedPageState extends State<SpeedPage> {
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;
  String? _elapsedTime;
  StreamSubscription<LocationData>? _positionSubscription;
  List<_PositionSample> _positions = [];
  List<double> _speeds = [];
  List<_MinuteSpeed> _minuteSpeeds = [];
  List<SpeedRecord> _records = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRecords();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        setState(() {
          _elapsedTime = _formatDuration(
            DateTime.now().difference(_startTime!),
          );
        });
      }
    });
  }

  Future<void> _loadRecords() async {
    final appState = context.read<AppState>();
    final recordsJson = appState.getSpeedRecords();
    setState(() {
      _records =
          recordsJson
              .map((json) => SpeedRecord.fromJson(jsonDecode(json)))
              .toList();
    });
  }

  Future<void> _saveRecords() async {
    final appState = context.read<AppState>();
    final recordsJson =
        _records.map((record) => jsonEncode(record.toJson())).toList();
    appState.saveSpeedRecords(recordsJson);
  }

  void _resetState({required bool isRunning}) {
    setState(() {
      _isRunning = isRunning;
      _isPaused = false;
      _startTime = isRunning ? DateTime.now() : null;
      _elapsedTime = "00:00:00";
      _positions = [];
      _speeds = [];
      _minuteSpeeds = [];
    });
  }

  void _start() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    if (permissionGranted == PermissionStatus.deniedForever) return;
    location.enableBackgroundMode(enable: true);

    _resetState(isRunning: true);

    _positionSubscription = location.onLocationChanged
        .timeout(Duration(seconds: 10))
        .listen((locationData) {
          _onPositionUpdate(locationData);
        });

    _positionSubscription?.onError((error) {
      _showSnackbar('位置信息获取失败: $error', duration: 5);
    });

    _positionSubscription?.onDone(() {
      _stop();
    });

    _showSnackbar('测速已开始，请不要关闭位置信息', duration: 2);
  }

  _showSnackbar(String content, {int duration = 1}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(content), duration: Duration(seconds: duration)),
    );
  }

  Future<void> _pauseOrResume() async {
    if (_isPaused) {
      // 恢复
      setState(() {
        _isPaused = false;
      });
      _positionSubscription?.resume();
      _showSnackbar('测速已恢复');
    } else {
      // 暂停
      setState(() {
        _isPaused = true;
      });
      _positionSubscription?.pause();
      _showSnackbar('测速已暂停');
    }
  }

  void _stop() {
    _positionSubscription?.cancel();

    if (_positions.length < 2) {
      _showSnackbar('测速已结束，未记录到数据');
    } else {
      _showSnackbar('测速已完成 ，已保存本次记录');
      _generateStats();
    }

    _resetState(isRunning: false);
  }

  void _onPositionUpdate(LocationData position) {
    if (!_isRunning || _isPaused) return;

    final now = DateTime.now();
    final sample = _PositionSample(
      now,
      position.latitude!,
      position.longitude!,
    );
    setState(() {
      _positions.add(sample);
      if (_positions.length > 1) {
        final prev = _positions[_positions.length - 2];
        final dist = _calcDistance(
          prev.lat,
          prev.lng,
          sample.lat,
          sample.lng,
        ); // 单位米
        final dt = sample.time.difference(prev.time).inSeconds;
        if (dt > 0) {
          final speed = dist / dt * 3.6; // m/s转km/h
          _speeds.add(speed);
        }
      }
    });
  }

  void _generateStats() async {
    final totalTime = _positions.last.time.difference(_startTime!).inSeconds;
    final totalDist = _calcTotalDistance();
    final avgSpeed = totalTime > 0 ? totalDist / totalTime * 3.6 : 0.0;
    final maxSpeed =
        _speeds.isNotEmpty ? _speeds.reduce((a, b) => a > b ? a : b) : 0.0;
    final minSpeed =
        _speeds.isNotEmpty ? _speeds.reduce((a, b) => a < b ? a : b) : 0.0;

    // 保存测速记录
    final record = SpeedRecord(
      _startTime!,
      DateTime.now(),
      avgSpeed,
      totalDist,
    );
    setState(() {
      _records.insert(0, record);
    });
    await _saveRecords();
    // 每分钟平均速度
    _minuteSpeeds = [];
    if (_positions.length > 1) {
      DateTime minuteStart = _positions.first.time;
      double dist = 0;
      int count = 0;
      for (int i = 1; i < _positions.length; i++) {
        final prev = _positions[i - 1];
        final curr = _positions[i];
        dist += _calcDistance(prev.lat, prev.lng, curr.lat, curr.lng);
        count++;
        if (curr.time.difference(minuteStart).inMinutes >= 1) {
          final dt = curr.time.difference(minuteStart).inSeconds;
          final minAvg = dt > 0 ? dist / dt * 3.6 : 0.0;
          _minuteSpeeds.add(_MinuteSpeed(minuteStart, minAvg));
          minuteStart = curr.time;
          dist = 0;
          count = 0;
        }
      }
      // 最后一段
      if (dist > 0 && count > 0) {
        final dt = _positions.last.time.difference(minuteStart).inSeconds;
        final minAvg = dt > 0 ? dist / dt * 3.6 : 0.0;
        _minuteSpeeds.add(_MinuteSpeed(minuteStart, minAvg));
      }
    }

    _showSpeedRecordDetailDialog(
      totalTime,
      totalDist,
      avgSpeed,
      maxSpeed,
      minSpeed,
    );
  }

  void _showSpeedRecordDetailDialog(
    int totalTime,
    double totalDist,
    double avgSpeed,
    double maxSpeed,
    double minSpeed,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('测速统计'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // speedRecord
                Text('用时: ${_formatDuration(Duration(seconds: totalTime))}'),
                Text('总距离: ${totalDist.toStringAsFixed(2)} m'),
                Text('平均速度: ${avgSpeed.toStringAsFixed(2)} km/h'),
                Text('最高速度: ${maxSpeed.toStringAsFixed(2)} km/h'),
                Text('最低速度: ${minSpeed.toStringAsFixed(2)} km/h'),
                const SizedBox(height: 8),
                const Text('每分钟平均速度:'),
                ..._minuteSpeeds.map(
                  (e) => Text(
                    '${e.time.hour}:${e.time.minute.toString().padLeft(2, '0')} - ${e.avgSpeed.toStringAsFixed(2)} km/h',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  double _calcDistance(double lat1, double lng1, double lat2, double lng2) {
    // Haversine公式计算两点间距离（米）
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLng = (lng2 - lng1) * pi / 180.0;
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _calcTotalDistance() {
    double dist = 0;
    for (int i = 1; i < _positions.length; i++) {
      dist += _calcDistance(
        _positions[i - 1].lat,
        _positions[i - 1].lng,
        _positions[i].lat,
        _positions[i].lng,
      );
    }
    return dist;
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  String get _totalDistance {
    return _formatDistance(_calcTotalDistance());
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _timer?.cancel(); // 清理定时器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('距离测速')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    _speeds.isNotEmpty
                        ? _speeds.last.toStringAsFixed(2)
                        : '00.00',
                    style: GoogleFonts.ramabhadra(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('km/h', style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('启动'),
                  onPressed: _isRunning ? null : _start,
                ),
                const SizedBox(width: 16),
                FilledButton.tonalIcon(
                  icon: Icon(_isPaused ? Icons.replay : Icons.pause),
                  label: Text(_isPaused ? '恢复' : '暂停'),
                  onPressed: _isRunning ? _pauseOrResume : null,
                ),
                const SizedBox(width: 16),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                  onPressed: _isRunning ? _stop : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text('行驶: $_totalDistance'),
                Text('耗时: $_elapsedTime'),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            GestureDetector(
              child: const Text(
                '历史记录',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                _loadRecords();
                _showSnackbar('已获取最新记录');
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final record = _records[index];
                  return ListTile(
                    title: Text(
                      '${record.startTime.month}月${record.startTime.day}日 ${record.startTime.hour}:${record.startTime.minute.toString().padLeft(2, '0')} - '
                      '${record.endTime.hour}:${record.endTime.minute.toString().padLeft(2, '0')}',
                    ),
                    subtitle: Text(
                      '平均速度: ${record.avgSpeed.toStringAsFixed(2)} km/h\n'
                      '距离: ${(record.distance / 1000).toStringAsFixed(2)} km',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionSample {
  final DateTime time;
  final double lat;
  final double lng;
  _PositionSample(this.time, this.lat, this.lng);
}

class _MinuteSpeed {
  final DateTime time;
  final double avgSpeed;
  _MinuteSpeed(this.time, this.avgSpeed);
}

class SpeedRecord {
  final DateTime startTime;
  final DateTime endTime;
  final double avgSpeed;
  final double distance;

  SpeedRecord(this.startTime, this.endTime, this.avgSpeed, this.distance);

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'avgSpeed': avgSpeed,
    'distance': distance,
  };

  factory SpeedRecord.fromJson(Map<String, dynamic> json) => SpeedRecord(
    DateTime.parse(json['startTime']),
    DateTime.parse(json['endTime']),
    json['avgSpeed'],
    json['distance'],
  );
}
