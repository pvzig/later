platform :osx, '10.11'
use_frameworks!

target 'Later' do
	pod 'Alamofire', '~> 4.0.1'
end

target 'Read It Later' do
	pod 'Alamofire', '~> 4.0.1'
end

# Set SWIFT_VERSION to 3.0 manually
post_install do |installer|
  installer.pods_project.targets.each do |target|
  	target.build_configurations.each do |config|
    	config.build_settings['SWIFT_VERSION'] = '3.0'
  	end
  end
end