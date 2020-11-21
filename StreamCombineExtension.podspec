Pod::Spec.new do |s|
  s.name         = 'StreamCombineExtension'
  s.version      = '1.0'
  s.summary      = 'Swift extensions for OutputStream and InputStream, using Combine instead of classic stream delegate to provide input and output data'

  s.description                = <<-DESC
                                   Swift extensions for OutputStream and InputStream, using Combine instead of classic stream delegate to provide input and output data
                                 DESC

  s.homepage                   = 'https://github.com/luneau/StreamCombineExtension'
  s.license                    = 'MIT License'
  s.author                     = { "Sébastien Luneau"}
  s.requires_arc               = true
  s.ios.deployment_target      = '13'
  s.watchos.deployment_target  = '6.0'
  s.macos.deployment_target    = '10.15'
  s.tvos.deployment_target     = '13'

  s.swift_version = '5.0'

  s.source                     = { :git => 'https://github.com/luneau/StreamCombineExtension.git', :tag => s.version }
  
  s.source_files               = 'Sources/StreamCombineExtension/*.swift'
  s.frameworks                 = 'Combine'
  
end
