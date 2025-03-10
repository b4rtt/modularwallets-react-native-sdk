require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "Circle"
  s.version      = package['version']
  s.summary      = package['description']
  s.homepage     = package['homepage'] || "https://github.com/circlefin/modularwallets-react-native-sdk"
  s.license      = package['license']
  s.author       = package['author']
  s.platform     = :ios, "16.0"
  s.source       = { :git => "https://github.com/circlefin/modularwallets-react-native-sdk.git", :tag => "v#{s.version}" }
  s.source_files = "ios/**/*.{h,m,swift}"
  s.requires_arc = true
  s.swift_version = '5.7'

  s.dependency "React-Core"
  
  # Add the Circle Modular Wallets SDK dependency
  s.dependency "CircleModularWalletsCore", "~> 1.0.0"
  
  # This is needed for Swift support
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }
end
