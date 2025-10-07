import 'dart:io';

/// Helper class to monitor RAM usage during encryption/decryption operations
class MemoryMonitor {
  int? _startRss;
  int? _peakRss;

  /// Start monitoring memory
  void start() {
    // For ProcessInfo, we need to check platform
    if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS) {
      try {
        final processInfo = ProcessInfo.currentRss;
        _startRss = processInfo;
        _peakRss = processInfo;
      } catch (e) {
      }
    }
  }

  /// Update peak memory usage
  void updatePeak() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS) {
      try {
        final currentRss = ProcessInfo.currentRss;
        if (_peakRss == null || currentRss > _peakRss!) {
          _peakRss = currentRss;
        }
      } catch (e) {
        // Ignore errors
      }
    }
  }

  /// Get memory usage report
  MemoryUsageReport getReport() {
    int? currentRss;
    if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS) {
      try {
        currentRss = ProcessInfo.currentRss;
      } catch (e) {
        // Ignore
      }
    }

    return MemoryUsageReport(
      startRss: _startRss,
      peakRss: _peakRss,
      currentRss: currentRss,
    );
  }

  /// Format bytes to human readable string
  static String formatBytes(int? bytes) {
    if (bytes == null) return 'N/A';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }
}

/// Memory usage report
class MemoryUsageReport {
  final int? startRss;
  final int? peakRss;
  final int? currentRss;

  MemoryUsageReport({
    this.startRss,
    this.peakRss,
    this.currentRss,
  });

  /// Get RSS (Resident Set Size) increase
  int? get rssIncrease {
    if (startRss != null && currentRss != null) {
      return currentRss! - startRss!;
    }
    return null;
  }

  /// Get peak RSS increase
  int? get peakRssIncrease {
    if (startRss != null && peakRss != null) {
      return peakRss! - startRss!;
    }
    return null;
  }

  /// Convert to string
  String toDisplayString() {
    final lines = <String>[];
    
    if (startRss != null || peakRss != null || currentRss != null) {
      lines.add('RAM Usage (RSS):');
      if (startRss != null) {
        lines.add('  Bắt đầu: ${MemoryMonitor.formatBytes(startRss)}');
      }
      if (peakRss != null) {
        lines.add('  Đỉnh: ${MemoryMonitor.formatBytes(peakRss)}');
      }
      if (currentRss != null) {
        lines.add('  Kết thúc: ${MemoryMonitor.formatBytes(currentRss)}');
      }
      if (peakRssIncrease != null) {
        lines.add('  Tăng (đỉnh): ${MemoryMonitor.formatBytes(peakRssIncrease)}');
      }
    } else {
      lines.add('RAM Usage: Không khả dụng trên nền tảng này');
    }
    
    return lines.join('\n');
  }
}
