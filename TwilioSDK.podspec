Pod::Spec.new do |s|
  s.name         = "TwilioSDK"
  s.version      = "1.2.5"
  s.summary      = "Twilio Client SDK"
  s.description  = "Twilio Client has the features that make it easy to embed VoIP directly into your iOS apps."
  s.homepage     = "http://www.twilio.com/client"
  s.platform     = :ios, "6.0"
  s.license      = { 
    :type => "Commercial", 
    :text => "Copyright 2011-2015 Twilio. All rights reserved. Use of this software is subject to the terms and conditions of the Twilio Terms of Service located at http://www.twilio.com/legal/tos"
  }
  s.author       = { "Twilio" => "help@twilio.com" }
  s.source       = { :http    => "http://static.twilio.com/sdk/ios/twilioclient-ios-1.2.5.b76-eb6f40d.tar.bz2" }

  s.source_files          = "Headers/*.h"
  s.public_header_files   = "Headers/*.h"
  s.vendored_library      = "Libraries/libTwilioClient.a", "Libraries/libcrypto.a", "Libraries/libssl.a"
  s.resources             = "Resources/*.wav"
  s.frameworks            = "AudioToolbox", "AVFoundation", "CFNetwork", "SystemConfiguration"
  s.requires_arc          = true
  s.xcconfig              = { 'OTHER_LDFLAGS' => '-read_only_relocs suppress' }
end
