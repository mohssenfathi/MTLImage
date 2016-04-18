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
  s.summary          = "GPUImage, but with Metal"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
  A work in progress...
                       DESC

  s.homepage         = "https://github.com/<GITHUB_USERNAME>/MTLImage"
  s.license          = 'MIT'
  s.author           = { "mohssenfathi" => "mmohssenfathi@gmail.com" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/MTLImage.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resources = ['Pod/Classes/CoreData/**/*.xcdatamodeld', 'Pod/Classes/**/*.metallib']
  s.resource_bundles = {
    'MTLImage' => ['Pod/Assets/**/*']
  }

# Unused for now
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

    s.default_subspec = 'Core'

    s.subspec 'Core' do |core|
      # Basic version, without FaceDetection and maybe some others later
    end

    s.subspec 'FaceDetection' do |fd|
      fd.xcconfig   =  { 'OTHER_CFLAGS' => '$(inherited) -MTLIMAGE_FACE_DETECTION' }
      fd.library = 'c++'
#     fd.vendored_frameworks = "Pod/Classes/FaceDetection/opencv2.framework"
#     fd.frameworks = 'Accelerate', 'libc++'
    end
end
