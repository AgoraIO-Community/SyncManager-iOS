Pod::Spec.new do |spec|
  spec.name         = "AgoraSyncManager-overseas"
  spec.version      = "3.0.6"
  spec.summary      = "AgoraSyncManager-overseas"
  spec.description  = "AgoraSyncManager overseas"

  spec.homepage     = "https://www.agora.io"
  spec.license      = "MIT"
  spec.author       = { "ZYQ" => "zhaoyongqiang@agora.io" }
  spec.ios.deployment_target = "10.0"
  spec.source       = { :git => "https://github.com/AgoraIO-Community/SyncManager-iOS.git", :tag => spec.version }
  spec.source_files  = "AgoraSyncManager/**/*.swift"
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'DEFINES_MODULE' => 'YES' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'DEFINES_MODULE' => 'YES' }
  spec.ios.deployment_target = '11.0'
  spec.swift_versions = "5.0"
  # spec.dependency "AgoraRtm_iOS", "1.4.9"
  spec.dependency 'SocketRocket'
end
