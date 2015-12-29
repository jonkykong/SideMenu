#
# Be sure to run `pod lib lint SideMenu.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SideMenu"
  s.version          = "0.1.0"
  s.summary          = "SideMenu is a simple and versatile side menu control."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
  SideMenu is a simple and versatile side menu control. It's highly customizable, but can also be implemented in storyboard without a single line of code. The are three standard animation styles to choose from along with several other options for further customization if desired. Just type SideMenuManager.menu... and code completion will show you everything you can customize.
                       DESC

  s.homepage         = "https://github.com/jonkykong/SideMenu"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "jonkykong" => "jonk@jonked.com" }
  s.source           = { :git => "https://github.com/jonkykong/SideMenu.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'SideMenu' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end