#!/bin/bash
PROJ="NetSpeedMonitor.xcodeproj/project.pbxproj"

# 1. MenuBarState.swift -> SettingsViewModel.swift
sed -i '' 's/MenuBarState\.swift/SettingsViewModel.swift/g' $PROJ
sed -i '' 's/path = SettingsViewModel.swift;/path = ViewModels\/SettingsViewModel.swift;/g' $PROJ

# 2. ColorArchive.swift -> SystemMonitorViewModel.swift
sed -i '' 's/ColorArchive\.swift/SystemMonitorViewModel.swift/g' $PROJ
sed -i '' 's/path = SystemMonitorViewModel.swift;/path = ViewModels\/SystemMonitorViewModel.swift;/g' $PROJ

# 3. MenuBarState+AudioMixer.swift -> AudioMixerViewModel.swift
sed -i '' 's/"MenuBarState+AudioMixer\.swift"/AudioMixerViewModel.swift/g' $PROJ
sed -i '' 's/path = AudioMixerViewModel.swift;/path = ViewModels\/AudioMixerViewModel.swift;/g' $PROJ
sed -i '' 's/MenuBarState+AudioMixer\.swift/AudioMixerViewModel.swift/g' $PROJ

# 4. MenuBarState+IconRefresh.swift -> MenuBarIconViewModel.swift
sed -i '' 's/"MenuBarState+IconRefresh\.swift"/MenuBarIconViewModel.swift/g' $PROJ
sed -i '' 's/path = MenuBarIconViewModel.swift;/path = ViewModels\/MenuBarIconViewModel.swift;/g' $PROJ
sed -i '' 's/MenuBarState+IconRefresh\.swift/MenuBarIconViewModel.swift/g' $PROJ

# 5. MenuBarState+MusicBlocker.swift -> MusicBlockerViewModel.swift
sed -i '' 's/"MenuBarState+MusicBlocker\.swift"/MusicBlockerViewModel.swift/g' $PROJ
sed -i '' 's/path = MusicBlockerViewModel.swift;/path = ViewModels\/MusicBlockerViewModel.swift;/g' $PROJ
sed -i '' 's/MenuBarState+MusicBlocker\.swift/MusicBlockerViewModel.swift/g' $PROJ

# 6. Remove MenuBarState+SystemMonitoring.swift (FileRef 4DCDCB3FFEE190B13CD46494, BuildFile C77C50F59DC8EAD80F77B5D5)
sed -i '' '/4DCDCB3FFEE190B13CD46494/d' $PROJ
sed -i '' '/C77C50F59DC8EAD80F77B5D5/d' $PROJ

echo "Project updated."
