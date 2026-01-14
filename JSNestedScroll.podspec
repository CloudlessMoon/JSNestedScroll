Pod::Spec.new do |s|
  s.name                  = "JSNestedScroll"
  s.version               = "1.1.0"
  s.summary               = "嵌套滚动组件"
  s.homepage              = "https://github.com/jiasongs/JSNestedScroll"
  s.license               = "MIT"
  s.author                = { "ruanmei" => "jiasong@ruanmei.com" }
  s.source                = { :git => "https://github.com/jiasongs/JSNestedScroll", :tag => "#{s.version}" }
  s.platform              = :ios, "13.0"
  s.swift_versions        = ["5.1"]
  s.static_framework      = true
  s.requires_arc          = true
  s.frameworks            = "UIKit"

  s.dependency "JSCoreKit", "~> 1.0"

  s.source_files          = "Sources/**/*.{swift,h,m}"
end