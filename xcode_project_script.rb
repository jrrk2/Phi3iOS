#!/usr/bin/env ruby
# generate_xcode_project.rb
# Creates an Xcode project for Phi-3 iOS build based on successful Makefile

require 'xcodeproj'

project_name = "Phi3iOS"
project_path = "#{project_name}.xcodeproj"

# Create new project
project = Xcodeproj::Project.new(project_path)

# Add main target
target = project.new_target(:application, project_name, :ios, '12.0')

# Create main group structure
main_group = project.main_group
sources_group = main_group.new_group('Sources')
genai_sources_group = sources_group.new_group('GenAI')
models_group = genai_sources_group.new_group('Models')
frameworks_group = main_group.new_group('Frameworks')

# Source files from successful Makefile build
source_files = [
  # Main sources
  'onnxruntime-genai/src/ort_genai_c.cpp',
  'onnxruntime-genai/src/config.cpp', 
  'onnxruntime-genai/src/generators.cpp',
  'onnxruntime-genai/src/sequences.cpp',
  'onnxruntime-genai/src/json.cpp',
  'onnxruntime-genai/src/logging.cpp',
  'onnxruntime-genai/src/tensor.cpp',
  'onnxruntime-genai/src/search.cpp',
  'onnxruntime-genai/src/beam_search_scorer.cpp',
  'onnxruntime-genai/src/runtime_settings.cpp',
  'onnxruntime-genai/src/softmax_cpu.cpp',
  'onnxruntime-genai/src/cpu/interface.cpp',
  
  # Model sources
  'onnxruntime-genai/src/models/model.cpp',
  'onnxruntime-genai/src/models/decoder_only.cpp',
  'onnxruntime-genai/src/models/decoder_only_pipeline.cpp',
  'onnxruntime-genai/src/models/input_ids.cpp',
  'onnxruntime-genai/src/models/kv_cache.cpp',
  'onnxruntime-genai/src/models/logits.cpp',
  'onnxruntime-genai/src/models/utils.cpp',
  'onnxruntime-genai/src/models/env_utils.cpp',
  'onnxruntime-genai/src/models/extra_inputs.cpp',
  'onnxruntime-genai/src/models/extra_outputs.cpp',
  'onnxruntime-genai/src/models/position_inputs.cpp',
  'onnxruntime-genai/src/models/gpt.cpp',
  'onnxruntime-genai/src/models/adapters.cpp',
  'onnxruntime-genai/src/models/debugging.cpp'
]

# Add source files to project
source_files.each do |source_file|
  if source_file.include?('models/')
    file_ref = models_group.new_file(source_file)
  else
    file_ref = genai_sources_group.new_file(source_file)
  end
  target.source_build_phase.add_file_reference(file_ref)
end

# Add main test file
main_file_ref = sources_group.new_file('test_phi3.cpp')
target.source_build_phase.add_file_reference(main_file_ref)

# Add multimedia stubs
stubs_file_ref = sources_group.new_file('multimedia_stubs.cpp')
target.source_build_phase.add_file_reference(stubs_file_ref)

# Add main.m for iOS app
main_m_ref = sources_group.new_file("#{project_name}/main.m")
target.source_build_phase.add_file_reference(main_m_ref)

# Add Info.plist reference
info_plist_ref = main_group.new_file("#{project_name}/Info.plist")

# Header search paths from successful Makefile
header_search_paths = [
  '$(SRCROOT)/onnxruntime-genai/src',
  '$(SRCROOT)/onnxruntime-genai/src/ort',
  '$(SRCROOT)/onnxruntime-ios/include',  # iOS ONNX Runtime headers
  '$(SRCROOT)/onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/nlohmann_json-src/include',
  '$(SRCROOT)/onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/gsl-src/include',
  '$(SRCROOT)/onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/include',
  '$(SRCROOT)/onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/shared/api',
  '$(SRCROOT)/onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/base',
  '$(SRCROOT)/onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators'
]

# Library search paths for iOS
library_search_paths = [
  '$(SRCROOT)/onnxruntime-ios/lib',
  '$(SRCROOT)/onnxruntime-genai/build/iOS/RelWithDebInfo/lib'  # You'll need iOS build
]

# Static libraries from successful build
static_libraries = [
  'libonnxruntime.a',      # iOS version
  'libortcustomops.a',     # From iOS build
  'libnoexcep_operators.a',
  'libocos_operators.a'
]

# iOS frameworks (subset of macOS frameworks that work on iOS)
ios_frameworks = [
  'Foundation',
  'CoreML',
  'CoreFoundation', 
  'CoreGraphics',
  'ImageIO',
  'Accelerate'  # Better than CoreServices for iOS
]

# Configure build settings
target.build_configurations.each do |config|
  config.build_settings.merge!({
    'HEADER_SEARCH_PATHS' => header_search_paths,
    'LIBRARY_SEARCH_PATHS' => library_search_paths,
    'OTHER_LDFLAGS' => static_libraries.map { |lib| "-l#{lib.gsub(/^lib|\.a$/, '')}" } + 
                       ios_frameworks.map { |fw| "-framework #{fw}" },
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'IPHONEOS_DEPLOYMENT_TARGET' => '12.0',
    'ARCHS' => 'arm64',  # iOS devices only
    'VALID_ARCHS' => 'arm64',
    'GCC_C_LANGUAGE_STANDARD' => 'c11',
    'ENABLE_BITCODE' => 'NO',  # ONNX Runtime typically doesn't support bitcode
    'OTHER_CPLUSPLUSFLAGS' => '-Wall -O2 -fPIC',
    'INFOPLIST_FILE' => "$(SRCROOT)/#{project_name}/Info.plist",
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.yourcompany.phi3ios'
  })
  
  if config.name == 'Debug'
    config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['DEBUG=1']
  else
    config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '2'
  end
end

# Add iOS frameworks
ios_frameworks.each do |framework_name|
  framework_ref = frameworks_group.new_file("System/Library/Frameworks/#{framework_name}.framework")
  framework_ref.source_tree = 'SDKROOT'
  target.frameworks_build_phase.add_file_reference(framework_ref)
end

# Create main app files
app_delegate_content = <<~OBJC
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}
@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
OBJC

info_plist_content = <<~XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
XML

# Save project
project.save

# Create additional files
FileUtils.mkdir_p(project_name)
File.write("#{project_name}/main.m", app_delegate_content)
File.write("#{project_name}/Info.plist", info_plist_content)

puts "✅ Xcode project created: #{project_path}"
puts ""
puts "📋 Next steps:"
puts "1. Open #{project_path} in Xcode"
puts "2. Add your iOS ONNX Runtime 1.20.0 libraries to the project"
puts "3. Update library search paths to point to your iOS libraries"
puts "4. Build and test on iOS simulator/device"
puts ""
puts "📦 Required iOS libraries:"
static_libraries.each { |lib| puts "   - #{lib}" }
puts ""
puts "🔧 You may need to:"
puts "   - Build onnxruntime-genai for iOS to get iOS versions of custom operator libraries"
puts "   - Adjust header paths if using different ONNX Runtime iOS distribution"
puts "   - Test on iOS simulator first, then device"
