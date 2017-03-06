#
# Be sure to run `pod lib lint SideMenu.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SideMenu"
  s.version          = "2.3.0"
  s.summary          = "Simple side menu control for iOS in Swift inspired by Facebook. Right and Left sides. No coding required."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  

  s.description      = <<-DESC
  SideMenu is a simple and versatile side menu control. It's highly customizable, but can also be implemented in storyboard without a single line of code. The are three standard animation styles to choose from along with several other options for further customization if desired. Just type SideMenuManager.menu... and code completion will show you everything you can customize.
                       DESC

  s.homepage         = "https://github.com/jonkykong/SideMenu"
  s.screenshots      = [ "https://raw.githubusercontent.com/jonkykong/SideMenu/master/etc/SlideOut.gif", "https://raw.githubusercontent.com/jonkykong/SideMenu/master/etc/SlideIn.gif", "https://raw.githubusercontent.com/jonkykong/SideMenu/master/etc/Dissolve.gif", "https://raw.githubusercontent.com/jonkykong/SideMenu/master/etc/InOut.gif" ]
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "jonkykong" => "contact@jonkent.me" }
  s.source           = { :git => "https://github.com/jonkykong/SideMenu.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Pod/Classes/**/*'
  # s.resource_bundles = {
  #    'SideMenu' => ['Pod/Assets/*.png']
  #  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
