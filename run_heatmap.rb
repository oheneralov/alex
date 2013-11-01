#!/usr/bin/env ruby

require 'rubygems'
require 'xmlsimple' 
require 'logger'

#This script downloads the latest sequenceL installer and runs a heatmap
#Do not forget to add the path to sequenceL to $PATH

#returns the last build : ctk query "SELECT MAX(Build) FROM tasks;"
def get_latest_build()
    log = Logger.new("error-log.txt")
    log.debug("Determining the version of the latest build")
    ctk_query = `de query "SELECT MAX(Build) FROM tasks;"`
    log.debug("result of de query is #{ctk_query}")
    latest_build = /(\d)*/.match(ctk_query)
    log.debug("The latest build is #{latest_build}")
    return latest_build[0].to_i
end

#download the latest build
#copy manually ssh keys into .ssh directory
def download(build, installer_name)
    #delete the installer if there is with the similar name to make sure we are running the correct one
	File.delete(installer_name) if File.exist?(installer_name)
	raise "Could not determine the latest build\n" if build <= 0 #Expected value is more than zero
	download_result = `scp oheneralov@tmt.calavista.com://opt//ctk//builds//numbered//sequenceL-Root-#{build}/#{$os_name}//installer.run #{installer_name}`
	raise "Error! The installer was not downloaded\n" unless File.exist?(installer_name)
	#error if the installer size is less than 5 MB
	raise "The installer is broken!" unless File.size(installer_name)/(1024*1024) > 5

end

#installs the installer
def install(build, installer_name)
	log = Logger.new("error-log.txt")
	log.debug("Installing the installer")
	if File.exist?("uninstall")
		log.debug("The previous version of the installer is found, uninstalling")
		`.//uninstall --mode unattended`
	end
	#checking if the installer is uninstalled
	if File.exist?("uninstall")
		log.debug("The previous version of the installer was not uninstalled")
		raise "Error! The previous version of the installer was not uninstalled!"
	end
	
	#installing the new installer
	result = `.//#{installer_name} --mode unattended --installdir ~/sequenceL`
	log.debug("Installation completed : #{result}")
end

#main function
#Linux
$os_name = "CentOS_64-bit"
#Windows
#os_name = "Windows_GPU_64-bit"


log = Logger.new("error-log.txt")
result = Dir.mkdir("sequenceL") unless File.exists?("sequenceL")
log.debug "#{result}"
build = get_latest_build()
installer_name = "installer_#{$os_name}_#{build}.run"
download(build, installer_name)
puts "The installer is downloaded!"
log.debug("THe installer is downloaded!")
puts "Installing the installer"
install(build, installer_name)
puts "Done"
log.debug "Downloading heatmap" 
result = `de view -m heatmap -d ~`
log.debug "#{result}"
log.debug "Removing testsuite" 
result = `rm -fr ~/sequenceL/testsuite`
log.debug "#{result}"
log.debug "Copying testsuite from the heatmap module to sequenceL module"
result = `cp -r ~/heatmap/testsuite ~/sequenceL/testsuite`
log.debug "#{result}"
result = 'chmod 777 -R ~/sequenceL'
log.debug "#{result}"
log.debug "Building and running heatmap"
result = `cd ~/sequenceL/testsuite && nohup ruby normal.rb`
log.debug "#{result}"
log.debug "Finish!"



