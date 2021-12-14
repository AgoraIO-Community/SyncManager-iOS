Pod::Spec.new do |spec|
  spec.name         = "SyncManager"
  spec.version      = "1.0.0"
  spec.summary      = "SyncManager"
  spec.description  = "SyncManager"

  spec.homepage     = "https://www.agora.io"
  spec.license      = "MIT"
  spec.author       = { "ZYP" => "zhuyuping@agora.io" }
  spec.ios.deployment_target = "10.0"
  spec.source       = { :git => "ssh://bitbucket.agoralab.co/users/xianing_agora.io/repos/syncmanager/browse" }
  spec.source_files  = "**/*.swift"
  spec.dependency "AgoraRtm_iOS", "1.4.8"
end
