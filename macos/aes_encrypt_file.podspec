Pod::Spec.new do |s|
  s.name             = 'aes_encrypt_file'
  s.version          = '0.0.13'
  s.summary          = 'High-performance AES-256 file encryption and decryption plugin for Flutter.'
  s.description      = <<-DESC
High-performance Flutter plugin for AES-256 file encryption and decryption with native C/C++ implementation.
                       DESC
  s.homepage         = 'https://github.com/BrianTran24/aes_encrypt_file'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BrianTran24' => 'briantran24@users.noreply.github.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.requires_arc = true

  # Required system frameworks for encryption
  s.frameworks = 'Security'

  # C settings - Enable maximum optimizations for performance
  s.compiler_flags = '-O3'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_CFLAGS' => '-O3'
  }
end
