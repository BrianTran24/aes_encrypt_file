import 'package:file_encrypter/file_encrypter.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:aes_encrypt_file/aes_encrypt_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'memory_monitor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _platformVersion = 'Unknown';
  final _aesEncryptFilePlugin = AesEncryptFile();
  final _fileEncryptor = FileEncrypter();
  String? _selectedVideoPath;
  String? _encryptedPath;
  String? _encryptedPathFileEncryptor;
  bool _isEncrypting = false;
  bool _isDecrypting = false;
  bool _isEncryptingFileEncryptor = false;
  bool _isDecryptingFileEncryptor = false;
  String _statusMessage = '';

  var encryptionKey;
  @override
  void initState() {
    super.initState();
  }


  // Chọn video từ thư viện
  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideoPath = result.files.single.path;
          _statusMessage = 'Đã chọn video: ${result.files.single.name}';
        });
      } else {
        setState(() {
          _statusMessage = 'Không chọn video nào';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi khi chọn video: $e';
      });
    }
  }

  // Mã hóa video đã chọn
  Future<void> _encryptVideo() async {
    if (_selectedVideoPath == null) {
      setState(() {
        _statusMessage = 'Vui lòng chọn video trước';
      });
      return;
    }

    setState(() {
      _isEncrypting = true;
      _statusMessage = 'Đang mã hóa video...';
    });

    try {
      // Tạo đường dẫn cho file đã mã hóa
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _selectedVideoPath!.split('/').last;
      final encryptedPath = '${directory.path}/encrypted_$fileName';

      // Khóa mã hóa (trong thực tế nên sử dụng khóa an toàn hơn)
      const encryptionKey = 'mySecretKey12345';

      this.encryptionKey = encryptionKey;

      final stopwatch = Stopwatch()..start();
      final memoryMonitor = MemoryMonitor();
      memoryMonitor.start();

      // Thực hiện mã hóa
      final success = await _aesEncryptFilePlugin.encryptFile(
        inputPath: _selectedVideoPath!,
        outputPath: encryptedPath,
        key: encryptionKey,
        iv: 'mySecretIV'
      );

      memoryMonitor.updatePeak();
      stopwatch.stop();
      final memoryReport = memoryMonitor.getReport();

      if (success) {
        final encryptedFile = File(encryptedPath);
        final encryptedSize = await encryptedFile.length();
        setState(() {
          _encryptedPath = encryptedPath;
          _statusMessage =
              'Mã hóa Native thành công!\n'
              'Thời gian: ${stopwatch.elapsedMilliseconds}ms\n'
              'Kích thước: $encryptedSize bytes\n'
              '${memoryReport.toDisplayString()}\n'
              'File đã lưu tại: $encryptedPath';
        });
      } else {
        setState(() {
          _statusMessage = 'Mã hóa thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi khi mã hóa: $e';
      });
    } finally {
      setState(() {
        _isEncrypting = false;
      });
    }
  }

  // Giải mã bằng pure Dart để kiểm tra
  Future<void> _decryptWithDart() async {
    if (_encryptedPath == null) {
      setState(() {
        _statusMessage = 'Vui lòng mã hóa video trước';
      });
      return;
    }

    setState(() {
      _isDecrypting = true;
      _statusMessage = 'Đang giải mã bằng Dart...';
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _selectedVideoPath!.split('/').last;
      final decryptedPath = '${directory.path}/decrypted_dart_$fileName';

      const encryptionKey = 'mySecretKey12345';

      final stopwatch = Stopwatch()..start();
      final memoryMonitor = MemoryMonitor();
      memoryMonitor.start();

      // Thực hiện giải mã bằng pure Dart
      final success = await _aesEncryptFilePlugin.decryptFile(
        inputPath: _encryptedPath!,
        outputPath: decryptedPath,
        key: encryptionKey,

      );

      memoryMonitor.updatePeak();
      stopwatch.stop();
      final memoryReport = memoryMonitor.getReport();

      if (success) {
        // Kiểm tra kích thước file để xác minh
        final originalFile = File(_selectedVideoPath!);
        final decryptedFile = File(decryptedPath);

        final originalSize = await originalFile.length();
        final decryptedSize = await decryptedFile.length();

        setState(() {
          _statusMessage =
              'Giải mã Native thành công!\n'
              'Thời gian: ${stopwatch.elapsedMilliseconds}ms\n'
              'File gốc: $originalSize bytes\n'
              'File giải mã: $decryptedSize bytes\n'
              '${memoryReport.toDisplayString()}\n'
              'Đã lưu tại: $decryptedPath';
        });
      } else {
        setState(() {
          _statusMessage = 'Giải mã Native thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi khi giải mã Native: $e';
      });
    } finally {
      setState(() {
        _isDecrypting = false;
      });
    }
  }

  // Mã hóa bằng file_encryptor
  Future<void> _encryptWithFileEncryptor() async {
    if (_selectedVideoPath == null) {
      setState(() {
        _statusMessage = 'Vui lòng chọn video trước';
      });
      return;
    }

    setState(() {
      _isEncryptingFileEncryptor = true;
      _statusMessage = 'Đang mã hóa bằng file_encryptor...';
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _selectedVideoPath!.split('/').last;
      final encryptedPath = '${directory.path}/encrypted_fe_$fileName';



      final stopwatch = Stopwatch()..start();
      final memoryMonitor = MemoryMonitor();
      memoryMonitor.start();

      // Thực hiện mã hóa bằng file_encryptor
      encryptionKey =  await FileEncrypter.encrypt(
        inFileName: _selectedVideoPath!,
        outFileName: encryptedPath,

        // filePath: _selectedVideoPath!,
        // outputPath: encryptedPath,
        // key: encryptionKey,
      );

      memoryMonitor.updatePeak();
      stopwatch.stop();
      final memoryReport = memoryMonitor.getReport();

      final encryptedFile = File(encryptedPath);
      if (await encryptedFile.exists()) {
        final encryptedSize = await encryptedFile.length();
        setState(() {
          _encryptedPathFileEncryptor = encryptedPath;
          _statusMessage =
              'Mã hóa file_encryptor thành công!\n'
              'Thời gian: ${stopwatch.elapsedMilliseconds}ms\n'
              'Kích thước: $encryptedSize bytes\n'
              '${memoryReport.toDisplayString()}\n'
              'File đã lưu tại: $encryptedPath';
        });
      } else {
        setState(() {
          _statusMessage = 'Mã hóa file_encryptor thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi khi mã hóa file_encryptor: $e';
      });
    } finally {
      setState(() {
        _isEncryptingFileEncryptor = false;
      });
    }
  }

  // Giải mã bằng file_encryptor
  Future<void> _decryptWithFileEncryptor() async {
    if (_encryptedPathFileEncryptor == null) {
      setState(() {
        _statusMessage = 'Vui lòng mã hóa bằng file_encryptor trước';
      });
      return;
    }

    setState(() {
      _isDecryptingFileEncryptor = true;
      _statusMessage = 'Đang giải mã bằng file_encryptor...';
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _selectedVideoPath!.split('/').last;
      final decryptedPath = '${directory.path}/decrypted_fe_$fileName';

      // const encryptionKey = 'mySecretKey12345';

      final stopwatch = Stopwatch()..start();
      final memoryMonitor = MemoryMonitor();
      memoryMonitor.start();

      // Thực hiện giải mã bằng file_encryptor
      await FileEncrypter.decrypt(
        inFileName: _encryptedPathFileEncryptor!,
        outFileName: decryptedPath,
        key: encryptionKey,
      );

      memoryMonitor.updatePeak();
      stopwatch.stop();
      final memoryReport = memoryMonitor.getReport();

      final decryptedFile = File(decryptedPath);
      if (await decryptedFile.exists()) {
        final originalFile = File(_selectedVideoPath!);
        final originalSize = await originalFile.length();
        final decryptedSize = await decryptedFile.length();

        setState(() {
          _statusMessage =
              'Giải mã file_encryptor thành công!\n'
              'Thời gian: ${stopwatch.elapsedMilliseconds}ms\n'
              'File gốc: $originalSize bytes\n'
              'File giải mã: $decryptedSize bytes\n'
              '${memoryReport.toDisplayString()}\n'
              'Đã lưu tại: $decryptedPath';
        });
      } else {
        setState(() {
          _statusMessage = 'Giải mã file_encryptor thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi khi giải mã file_encryptor: $e';
      });
    } finally {
      setState(() {
        _isDecryptingFileEncryptor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AES Video Encryption Example'),
          backgroundColor: Colors.blue,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chạy trên: $_platformVersion',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Nút chọn video
                ElevatedButton.icon(
                  onPressed:
                      (_isEncrypting ||
                          _isDecrypting ||
                          _isEncryptingFileEncryptor ||
                          _isDecryptingFileEncryptor)
                      ? null
                      : _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: const Text(
                    'Chọn Video từ Thư viện',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Nút mã hóa video
                ElevatedButton.icon(
                  onPressed:
                      (_selectedVideoPath != null &&
                          !_isEncrypting &&
                          !_isDecrypting &&
                          !_isEncryptingFileEncryptor &&
                          !_isDecryptingFileEncryptor)
                      ? _encryptVideo
                      : null,
                  icon: _isEncrypting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock),
                  label: Text(
                    _isEncrypting ? 'Đang mã hóa...' : 'Mã hóa Video (Native)',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Nút giải mã bằng Dart
                ElevatedButton.icon(
                  onPressed:
                      (_encryptedPath != null &&
                          !_isEncrypting &&
                          !_isDecrypting &&
                          !_isEncryptingFileEncryptor &&
                          !_isDecryptingFileEncryptor)
                      ? _decryptWithDart
                      : null,
                  icon: _isDecrypting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_open),
                  label: Text(
                    _isDecrypting
                        ? 'Đang giải mã...'
                        : 'Giải mã video (Native)',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Divider để phân tách
                const Divider(thickness: 2),
                const Text(
                  'File Encryptor Library (Để so sánh tốc độ)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Nút mã hóa bằng file_encryptor
                ElevatedButton.icon(
                  onPressed:
                      (_selectedVideoPath != null &&
                          !_isEncrypting &&
                          !_isDecrypting &&
                          !_isEncryptingFileEncryptor &&
                          !_isDecryptingFileEncryptor)
                      ? _encryptWithFileEncryptor
                      : null,
                  icon: _isEncryptingFileEncryptor
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock),
                  label: Text(
                    _isEncryptingFileEncryptor
                        ? 'Đang mã hóa...'
                        : 'Mã hóa Video (file_encryptor)',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Nút giải mã bằng file_encryptor
                ElevatedButton.icon(
                  onPressed:
                      (_encryptedPathFileEncryptor != null &&
                          !_isEncrypting &&
                          !_isDecrypting &&
                          !_isEncryptingFileEncryptor &&
                          !_isDecryptingFileEncryptor)
                      ? _decryptWithFileEncryptor
                      : null,
                  icon: _isDecryptingFileEncryptor
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_open),
                  label: Text(
                    _isDecryptingFileEncryptor
                        ? 'Đang giải mã...'
                        : 'Giải mã bằng file_encryptor',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Hiển thị thông tin
                if (_selectedVideoPath != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Video đã chọn:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedVideoPath!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Hiển thị trạng thái
                if (_statusMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _statusMessage.contains('thành công')
                          ? Colors.green.shade50
                          : _statusMessage.contains('Lỗi') ||
                                _statusMessage.contains('thất bại')
                          ? Colors.red.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _statusMessage.contains('thành công')
                            ? Colors.green.shade200
                            : _statusMessage.contains('Lỗi') ||
                                  _statusMessage.contains('thất bại')
                            ? Colors.red.shade200
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: _statusMessage.contains('thành công')
                            ? Colors.green.shade900
                            : _statusMessage.contains('Lỗi') ||
                                  _statusMessage.contains('thất bại')
                            ? Colors.red.shade900
                            : Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
