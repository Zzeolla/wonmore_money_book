# ios/Flutter/podhelper.rb

require 'json'

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __dir__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

def flutter_ios_engine_dir
  File.expand_path(File.join('..', 'engine'), __dir__)
end

def flutter_ios_podfile_setup
  # Prepare symlinks folder. We use symlinks to avoid having Podfile.lock
  # referring to absolute paths on developers' machines.

  symlink_dir = File.expand_path('.symlinks', __dir__)
  system('rm', '-rf', symlink_dir) # Avoid the complication of dependencies like FileUtils.

  symlink_plugins_dir = File.expand_path('plugins', symlink_dir)
  system('mkdir', '-p', symlink_plugins_dir)

  plugin_pods_json_path = File.expand_path(File.join('..', '.flutter-plugins-dependencies'), __dir__)
  plugin_pods = JSON.parse(File.read(plugin_pods_json_path))
  plugin_pods['plugins']['ios'].each do |plugin_hash|
    name = plugin_hash['name']
    path = plugin_hash['path']
    symlink = File.join(symlink_plugins_dir, name)
    File.symlink(path, symlink)
  end
end

def flutter_install_ios_plugin_pods(ios_application_path = nil)
  ios_application_path ||= File.dirname(__dir__)
  symlink_dir = File.expand_path('.symlinks', __dir__)
  plugin_pods_json_path = File.expand_path(File.join('..', '.flutter-plugins-dependencies'), __dir__)
  plugin_pods = JSON.parse(File.read(plugin_pods_json_path))
  plugin_pods['plugins']['ios'].each do |plugin_hash|
    name = plugin_hash['name']
    path = File.join(symlink_dir, 'plugins', name)
    pod name, :path => File.join(path, 'ios')
  end
end

def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_install_ios_plugin_pods(ios_application_path)
end
