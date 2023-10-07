# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'Breaze' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Breaze
  pod 'Alamofire'
  pod 'CodableFirebase'
  pod 'SwiftyJSON'
  pod 'Signals'
  pod 'PromiseKit'
  pod 'Firebase/Core'
  pod 'Firebase/Firestore'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'FirebaseUI' 
  pod 'FirebaseUI/Email'

  target 'BreazeTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'BreazeUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  post_install do |installer|
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
            xcconfig_path = config.base_configuration_reference.real_path
            xcconfig = File.read(xcconfig_path)
            xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
            File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
            end
        end
    end
  
end
