const {
  withDangerousMod,
  withInfoPlist,
  withXcodeProject,
} = require("@expo/config-plugins");
const fs = require("fs");
const path = require("path");

/**
 * Config plugin for Circle Modular Wallets SDK
 * This plugin:
 * 1. Ensures iOS deployment target is set to 16.0
 * 2. Adds Face ID usage description to Info.plist
 * 3. Configures Swift Package Manager for the Circle SDK
 * 4. Integrates the Swift Package into the Xcode project
 */
const withCircleModularWallets = (config) => {
  // Step 1: Ensure iOS deployment target is set to 16.0
  if (!config.ios) config.ios = {};
  config.ios.deploymentTarget = "16.0";

  // Step 2: Add Face ID usage description to Info.plist
  config = withInfoPlist(config, (config) => {
    const infoPlist = config.modResults;

    // Add Face ID usage description if not already present
    if (!infoPlist.NSFaceIDUsageDescription) {
      infoPlist.NSFaceIDUsageDescription =
        "This app uses Face ID to authenticate wallet transactions";
    }

    return config;
  });

  // Step 3: Modify Podfile to ensure iOS 16.0
  config = withDangerousMod(config, [
    "ios",
    async (config) => {
      const podfilePath = path.join(
        config.modRequest.platformProjectRoot,
        "Podfile"
      );

      if (fs.existsSync(podfilePath)) {
        let podfileContent = fs.readFileSync(podfilePath, "utf8");

        // Ensure iOS platform is set to 16.0
        podfileContent = podfileContent.replace(
          /platform :ios, ['"].*['"]/,
          "platform :ios, '16.0'"
        );

        // Add Circle pod
        if (!podfileContent.includes("pod 'Circle'")) {
          const podLine =
            "  pod 'Circle', :path => '../node_modules/modularwallets-react-native-sdk'\n";
          podfileContent = podfileContent.replace(
            /target .* do/,
            `$&\n${podLine}`
          );
        }

        // Add post_install hook if not present
        if (!podfileContent.includes("post_install do |installer|")) {
          podfileContent += `\n  post_install do |installer|
    # Run Circle SDK integration script
    system("cd \#{installer.sandbox.pod_root}/../../ && ruby ios/add_circle_sdk.rb")
    
    # iOS deployment target configuration
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      end
    end
  end\n`;
        }

        fs.writeFileSync(podfilePath, podfileContent);
      }

      return config;
    },
  ]);

  // Step 4: Add Swift Package Manager configuration for Circle SDK
  config = withDangerousMod(config, [
    "ios",
    async (config) => {
      const iosDir = config.modRequest.platformProjectRoot;

      // Create a directory for the Swift Package Manager configuration
      const spmConfigDir = path.join(iosDir, "CircleSDK");
      if (!fs.existsSync(spmConfigDir)) {
        fs.mkdirSync(spmConfigDir, { recursive: true });
      }

      // Create Package.swift file
      const packageSwiftPath = path.join(spmConfigDir, "Package.swift");
      const packageSwiftContent = `// swift-tools-version:5.5
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
`;
      fs.writeFileSync(packageSwiftPath, packageSwiftContent);

      // Create a dummy Swift file to make the package valid
      const dummySwiftPath = path.join(spmConfigDir, "CircleSDK.swift");
      const dummySwiftContent = `// This file is required for the Swift Package Manager
import Foundation
import CircleModularWalletsCore

public struct CircleSDK {
    public static let version = "1.0.0"
}
`;
      fs.writeFileSync(dummySwiftPath, dummySwiftContent);

      // Create Ruby script to add Swift Package to Xcode project
      const rubyScriptPath = path.join(iosDir, "add_circle_sdk.rb");
      const rubyScriptContent = `#!/usr/bin/env ruby
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
`;
      fs.writeFileSync(rubyScriptPath, rubyScriptContent);

      // Make the script executable
      try {
        fs.chmodSync(rubyScriptPath, "755");
      } catch (error) {
        console.warn("Could not make script executable:", error);
      }

      return config;
    },
  ]);

  // Step 5: Use withXcodeProject to add a build script that runs our Ruby script
  config = withXcodeProject(config, async (config) => {
    const xcodeProject = config.modResults;
    const appTarget = xcodeProject.getFirstTarget();

    if (appTarget) {
      // Check if we already have a script phase for Circle SDK
      const existingScriptPhase = appTarget.buildPhases.find(
        (phase) =>
          phase.isa === "PBXShellScriptBuildPhase" &&
          phase.name === "Integrate Circle SDK"
      );

      if (!existingScriptPhase) {
        // Add a script phase to run our Ruby script
        xcodeProject.addBuildPhase(
          [],
          "PBXShellScriptBuildPhase",
          "Integrate Circle SDK",
          appTarget,
          {
            shellPath: "/bin/sh",
            shellScript: 'ruby "${SRCROOT}/add_circle_sdk.rb"',
          }
        );
      }
    }

    return config;
  });

  return config;
};

module.exports = withCircleModularWallets;
