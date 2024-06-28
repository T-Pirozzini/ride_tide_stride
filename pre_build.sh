#!/bin/sh
set -e  # Exit on first failed command
set -x  # Print all executed commands to the log

# Install ffi gem for compatibility with ARM architecture
sudo gem install ffi

# Install the compatible version of the public_suffix gem
sudo gem install public_suffix -v 5.1.1

# Install a specific version of CocoaPods that is compatible with Ruby 2.6.10
sudo gem install cocoapods -v 1.10.0

# Update CocoaPods repository in x86_64 mode
arch -x86_64 pod repo update

# Remove Podfile.lock to avoid version conflicts
cd ios
rm -f Podfile.lock

# Get Flutter dependencies
flutter pub get

# Install and update CocoaPods dependencies in x86_64 mode
arch -x86_64 pod install --repo-update

# Navigate back to the root directory
cd ..