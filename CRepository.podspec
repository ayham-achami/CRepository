Pod::Spec.new do |spec|
  spec.name         = "CRepository"
  spec.version      = "1.0.0"
  spec.summary      = "Библиотека компонентов для работы с базой данных."
  spec.description  = <<-DESC
  Библиотека компонентов для работы с базой данных.
                   DESC
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Ayham Hylam" => "Ayham Hylam" }
  spec.homepage     = "https://github.com/ayham-achami/CRepository.git"
  spec.ios.deployment_target = "13.0"
  spec.source       = {
      :git => "git@github.com:ayham-achami/CRepository.git",
      :tag => spec.version.to_s
  }
  spec.frameworks   = "Foundation"
  spec.source_files = "Sources/**/*.swift"
  spec.requires_arc = true
  spec.pod_target_xcconfig = { "SWIFT_VERSION" => "5" }
  spec.pod_target_xcconfig = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES' }
  spec.dependency 'RealmSwift'
end
