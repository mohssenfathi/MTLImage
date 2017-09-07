
#
# Be sure to run `pod lib lint MTLImage.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MTLImage"
  s.version          = "0.0.1"
  s.summary          = "Image processing framework built on top of Metal"

  s.description      = <<-DESC
  A framework to simplify data processing on the GPU using Metal.
  DESC

  s.homepage         = "https://github.com/mohssenfathi/MTLImage"
  s.license          = 'MIT'
  s.author           = { "mohssenfathi" => "mmohssenfathi@gmail.com" }
  s.source           = { :git => "https://github.com/mohssenfathi/MTLImage.git", :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
# s.tvos.deployment_target = '10.0'
  s.requires_arc = true

  s.ios.resources = 'MTLImage/Sources/iOS/CoreData/*.xcdatamodeld', 'MTLImage/Sources/Shared/Shaders/*.metallib'
  s.ios.source_files = 'MTLImage/Sources/Shared/**/*.{swift, m, h, mm, hpp, cpp, c}', 'MTLImage/Sources/iOS/**/*.{swift, m, h, mm, hpp, cpp, c}'

  s.osx.resources = 'MTLImage/Sources/Shared/Shaders/*.metallib'
  s.osx.source_files = 'MTLImage/Sources/Shared/**/*.{swift, m, h, mm, hpp, cpp, c}', 'MTLImage/Sources/macOS/**/*.{swift, m, h, mm, hpp, cpp, c}'

  # Unused for now
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  # s.public_header_files = 'Pod/Classes/**/*.h'

end
