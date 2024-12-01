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
          if target.name == 'BoringSSL-GRPC'
            target.source_build_phase.files.each do |file|
              if file.settings && file.settings['COMPILER_FLAGS']
                flags = file.settings['COMPILER_FLAGS'].split
                flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
                file.settings['COMPILER_FLAGS'] = flags.join(' ')
              end
            end
          end
            target.build_configurations.each do |config|
              config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            xcconfig_path = config.base_configuration_reference.real_path
            xcconfig = File.read(xcconfig_path)
            xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
            File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
            end
        end

    end
  
end
