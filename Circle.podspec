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
  
  # This is needed for Swift support
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }
  
  # Add the Circle Modular Wallets SDK via Swift Package Manager
  s.prepare_command = <<-CMD
    echo 'Setting up Circle Modular Wallets SDK via Swift Package Manager'
    
    # Create Swift Package Manager configuration
    mkdir -p ios/CircleSDK
    cat > ios/CircleSDK/Package.swift << EOL
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CircleSDK",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "CircleSDK", targets: ["CircleSDK"])
    ],
    dependencies: [
        .package(url: "https://github.com/circlefin/modularwallets-ios-sdk.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "CircleSDK",
            dependencies: [
                .product(name: "CircleModularWalletsCore", package: "modularwallets-ios-sdk")
            ],
            path: "."
        )
    ]
)
EOL

    # Create a dummy Swift file to make the package valid
    cat > ios/CircleSDK/CircleSDK.swift << EOL
// This file is required for the Swift Package Manager
import Foundation
import CircleModularWalletsCore

public struct CircleSDK {
    public static let version = "1.0.0"
}
EOL

    # Create a script that will be run during Xcode build to add and resolve the package
    cat > ios/add_circle_sdk.rb << EOL
#!/usr/bin/env ruby
require 'xcodeproj'

# Find the Xcode project
project_path = Dir.glob("*.xcodeproj").first
if project_path.nil?
  puts "Error: Could not find Xcode project"
  exit 1
end

puts "Adding Circle SDK to \#{project_path}"
project = Xcodeproj::Project.open(project_path)

# Add Swift Package
package_url = "https://github.com/circlefin/modularwallets-ios-sdk.git"
package_requirement = { :kind => :up_to_next_major, :minimum_version => "1.0.0" }

# Check if package already exists
existing_package = project.root_object.package_references.find { |ref| ref.package_url == package_url }
if existing_package
  puts "Circle SDK package already added to project"
else
  puts "Adding Circle SDK package to project"
  package_ref = project.root_object.add_package_reference(package_url, package_requirement)
  
  # Add package product to main target
  main_target = project.targets.first
  if main_target
    puts "Adding package product to main target: \#{main_target.name}"
    main_target.add_package_product_dependency(
      package_product_name: "CircleModularWalletsCore",
      package_reference: package_ref
    )
  else
    puts "Warning: Could not find main target"
  end
end

# Save project
project.save
puts "Successfully updated Xcode project"
EOL

    # Make the script executable
    chmod +x ios/add_circle_sdk.rb
    
    # Install xcodeproj gem if needed
    gem list -i xcodeproj > /dev/null || gem install xcodeproj
  CMD
  
  # Add post_install hook to run the script
  s.post_install do |installer|
    system("cd #{installer.sandbox.pod_root}/../../ && ruby ios/add_circle_sdk.rb")
  end
end
