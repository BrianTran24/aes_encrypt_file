Pod::Spec.new do |s|
  s.name             = 'aes_encrypt_file'
  s.version          = '0.0.8'
  s.summary          = 'A Flutter plugin for AES-256 file encryption with native performance.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.swift_version = '5.0'

  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.requires_arc = true
  
  # Required system frameworks for encryption
  s.frameworks = 'Security'

  # C settings - Enable maximum optimizations for performance
  s.compiler_flags = '-O3' # Optimization level 3 for performance
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_CFLAGS' => '-O3'
  }
end
