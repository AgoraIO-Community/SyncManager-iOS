Pod::Spec.new do |spec|
  spec.name         = "AgoraSyncManager"
  spec.version      = "1.0.0"
  spec.summary      = "AgoraSyncManager"
  spec.description  = "AgoraSyncManager"

  spec.homepage     = "https://www.agora.io"
  spec.license      = "MIT"
  spec.author       = { "ZYP" => "zhuyuping@agora.io" }
  spec.ios.deployment_target = "10.0"
  spec.source       = { :git => "https://github.com/AgoraIO-Community/SyncManager-iOS.git", :tag => "1.0.0" }
  spec.source_files  = "**/*.swift"
  spec.dependency "AgoraRtm_iOS", "1.4.8"
end
