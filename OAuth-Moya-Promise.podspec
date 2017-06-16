# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html

Pod::Spec.new do |s|
  s.name             = 'OAuth-Moya-Promise'
  s.version          = '0.1.0'
  s.summary          = 'A short description of OAuth-Moya-Promise.'

  s.description      = <<-DESC
TODO: Adds OAuth, Moya, Promises and JSON mapping into one library.
                       DESC

	s.homepage         = 'https://github.com/Genhain/OAuth-Moya-Promise'
	s.license          = { :type => 'MIT', :file => 'LICENSE' }
	s.author           = { 'Genhain' => 'voxhavoccanis@gmail.com' }
	s.source           = { :git => 'https://github.com/Genhain/OAuth-Moya-Promise.git', :tag => s.version.to_s }

	s.ios.deployment_target = '8.0'

	s.source_files = 'OAuth-Moya-Promise/Classes/**/*'

	s.framework = 'Foundation'
	s.dependency 'Moya'
	s.dependency 'Moya-ObjectMapper'
	s.dependency 'PromiseKit'
end
