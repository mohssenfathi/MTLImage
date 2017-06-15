#
# Be sure to run `pod lib lint MTLImage.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MTLImage"
  s.version          = "0.1.0"
  s.summary          = "Data processing with Metal"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
  A framework to simplify data processing on the GPU using Metal.
                       DESC

  s.homepage         = "https://github.com/mohssenfathi/MTLImage"
  s.license          = 'MIT'
  s.author           = { "mohssenfathi" => "mmohssenfathi@gmail.com" }
  s.source           = { :git => "https://github.com/mohssenfathi/MTLImage.git", :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true

  #s.source_files = 'Pod/Classes/**/*{swift, m, h, mm, hpp, cpp, c}'
  s.resources = ['Pod/Classes/CoreData/**/*.xcdatamodeld', 'Pod/Classes/**/*.metallib', 'Pod/Assets/**/*.xcassets']

#s.resource_bundles = {
#   'MTLImage' => ['Pod/Assets/**/*']
# }

# Unused for now
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

    s.default_subspecs = 'Core', 'CoreData', 'CloudKit'

    s.subspec 'Core' do |core|
        core.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -MTLIMAGE_CORE' }
        core.source_files = 'Pod/Classes/Core/**/*{swift, m, h, mm, hpp, cpp, c}'
        core.tvos.exclude_files = 'Pod/Classes/Core/MTLImage/MTLCamera.swift'
    end
 
    s.subspec 'CloudKit' do |ck|
        ck.frameworks = 'CloudKit'
        ck.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -MTLIMAGE_CLOUD_KIT' }
        ck.source_files = 'Pod/Classes/CloudKit/**/*{swift, m, h, mm, hpp, cpp, c}'
    end

    s.subspec 'CoreData' do |cd|
        cd.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -MTLIMAGE_CORE_DATA' }
        cd.source_files = 'Pod/Classes/CoreData/**/*{swift, m, h, mm, hpp, cpp, c}'
    end

    s.subspec 'MachineLearning' do |ml|
        ml.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -MTLIMAGE_MACHINE_LEARNING' }
        ml.source_files = 'Pod/Classes/MachineLearning/**/*{swift, m, h, mm, hpp, cpp, c}'
        ml.ios.deployment_target = '10.0'
    end

end
