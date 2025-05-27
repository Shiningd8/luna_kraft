#!/usr/bin/env ruby

require 'xcodeproj'

# Path to your Xcode project
project_path = './Runner.xcodeproj'

# Open the Xcode project
project = Xcodeproj::Project.open(project_path)

# Get the main target (usually the first one)
target = project.targets.first

# Check if the target is not nil
if target
  # Get the capabilities attribute (if nil, creates a new one)
  target_attributes = project.root_object.attributes['TargetAttributes'] || {}
  target_attrib = target_attributes[target.uuid] || {}
  
  # Ensure system capabilities key exists
  sys_capabilities = target_attrib['SystemCapabilities'] || {}
  target_attrib['SystemCapabilities'] = sys_capabilities
  
  # Make sure we have the background modes capability
  sys_capabilities['com.apple.BackgroundModes'] = {'enabled' => true}
  
  # Update target attributes in the project
  target_attributes[target.uuid] = target_attrib
  project.root_object.attributes['TargetAttributes'] = target_attributes
  
  # Save the project
  project.save
  
  puts "Successfully updated project with background modes capability."
else
  puts "Target not found in the project."
end 