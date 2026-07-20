require 'xcodeproj'

project_path = 'NetSpeedMonitor.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Files to remove
files_to_remove = [
    'MenuBarState.swift',
    'MenuBarState+AudioMixer.swift',
    'MenuBarState+IconRefresh.swift',
    'MenuBarState+MusicBlocker.swift',
    'MenuBarState+SystemMonitoring.swift',
    'ColorArchive.swift'
]

# Remove files
target.source_build_phase.files.each do |build_file|
    if build_file.file_ref && files_to_remove.include?(build_file.file_ref.name) || files_to_remove.include?(build_file.file_ref.path)
        build_file.file_ref.remove_from_project
        build_file.remove_from_project
    end
end

project.files.each do |file|
    if files_to_remove.include?(file.name) || files_to_remove.include?(file.path)
        file.remove_from_project
    end
end

# Add new files
group = project.main_group.find_subpath('NetSpeedMonitor/ViewModels', true)
new_files = [
    'NetSpeedMonitor/ViewModels/SettingsViewModel.swift',
    'NetSpeedMonitor/ViewModels/SystemMonitorViewModel.swift',
    'NetSpeedMonitor/ViewModels/AudioMixerViewModel.swift',
    'NetSpeedMonitor/ViewModels/MusicBlockerViewModel.swift',
    'NetSpeedMonitor/ViewModels/MenuBarIconViewModel.swift'
]

new_files.each do |file_path|
    file_ref = group.new_reference("../" + file_path)
    target.source_build_phase.add_file_reference(file_ref)
end

project.save
puts "Project updated successfully!"
