Pod::Spec.new do |spec|
  spec.name         = "CRepository"
  spec.version      = "1.0.0"
  spec.summary      = "Компоненты и утилиты для iOS"
  spec.description  = <<-DESC
  Библиотека содержит компоненты для работы прилолжением iOS
                   DESC
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Ayham Hylam" => "Ayham Hylam" }
  spec.homepage     = "https://github.com/ayham-achami/CRepository.git"
  spec.ios.deployment_target = "11.0"
  spec.source       = {
      :git => "git@github.com:ayham-achami/CRepository.git",
      :tag => spec.version.to_s
  }
  spec.frameworks   = "Foundation"
  spec.source_files = "Sources/**/*.swift"
  spec.requires_arc = true
  spec.swift_versions = ['5.0', '5.1']
  spec.pod_target_xcconfig = { "SWIFT_VERSION" => "5" }
  spec.pod_target_xcconfig = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES' }
  spec.dependency 'RealmSwift'
end
