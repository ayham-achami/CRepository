# Sources
source 'https://github.com/CocoaPods/specs.git'

install! 'cocoapods', :warn_for_unused_master_specs_repo => false

# Project
project 'CRepository.xcodeproj'

# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

def common_pods
  # Database
  pod 'RealmSwift'
  # Control
  pod 'SwiftLint'
end

target 'CRepository' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  # Pods for CRepository
  common_pods
  target 'CRepositoryTests' do
    inherit! :search_paths
    # Pods for testing
    common_pods
  end
end

target 'Playground' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Common
  common_pods
  # Pods for Playground
end
