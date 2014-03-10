#!/bin/bash
#----------AUTHOR------------
	# Jacob Salmela
	# 9 July 2013
	# https://github.com/jakesalmela/

#----------RESOURCES---------
	# http://www.mactricksandtips.com/2012/02/stress-test-your-mac-and-cpu.html
	# http://macfidelity.de/2009/05/10/mac-how-to-stress-test-your-cpu-in-mac-os-x/
	# http://osxdaily.com/2012/10/02/stress-test-mac-cpu/
	# http://stackoverflow.com/questions/15534595/bash-scripting-multiple-conditions-in-while-loop
	# http://macfidelity.de/2009/06/17/mac-how-to-display-hardware-temperature-on-your-desktop-with-geektool/index.html
	# http://www.bresink.com/osx/0TemperatureMonitor/download.php
	# https://mjung.net/publications/20121023-JAMF-NUC-The_College_Challenge-Macs_at_Oxford/Marko%20Jung%20-%20JAMF%20Software%20NUC%202012%20Minneapolis%20-%20Managing%20Macs%20at%20Oxford%20-%2020121018-1455-web.pdf
	# http://superuser.com/questions/495554/term-enviroment-variable-not-set-when-executing-a-bash-file-via-ssh
	# http://stackoverflow.com/questions/7884285/how-can-i-script-a-shutdown-r-1-and-return-an-exit-status
	
#---------DESCRIPTION--------
	# A script that is useful for automating the draining of computer batteries to 50% for storing over long periods of time
	# This was originally used in an educational setting for discharging laptops while they were not being used over the summer

#-----------USAGE------------
	# To run: 
	#
	# 	0. Set the desired battery percentage in the variable below	 
	#	1. Run locally: ./Battery-Drain-to-50-Percent.sh
	#	2. Run remotely: Execute from Casper Remote or ARD

#----------VARIABLES---------			
	# Change this to the percent you want the battery drained to--whole integers only
	# Default is 50%
	desiredPercentage="50"

#----------FUNCTIONS---------	
########################
function preRequisites()
	{
	# Set the terminal to avoid errors when executing via SSH, ARD, or Casper Remote
	export TERM=xterm
	echo "Terminal: $TERM"
	
	# echo the starting charge
	echo "Starting charge:"
	pmset -g batt | grep -o "[0-9]\+%;" | cut -d"%" -f1
	
	# Return 0 if all is well
	return 0 
	}
	
	
################################
function announceAndLockScreen()
	{
	# Set the volume so we can hear it 
	osascript -e 'set volume 8'
	
	# Announce the discharge is beginning since we cannot view the progress if running from Casper Remote
	# Activate the screen lock so that we can see the script is actually running
	# The lock screen is different depending on the OS, we need to use a case statement to pick the right one

	case ${OSTYPE} in
	
		# Snow Leopard
 		darwin10*) say -v "Cellos" "I am about to dishcharge Here I go I will shut down when I am done." &> /dev/null;;
	 			
		# Lion
		darwin11*) say -v "Cellos" "I am about to dishcharge Here I go I will shut down when I am done." &> /dev/null;;
		
		# Mountain Lion 
		darwin12*) say -v "Cellos" "I am about to dishcharge Here I go I will shut down when I am done." &> /dev/null;;
		
		# Mavericks
		darwin13*) say -v "Cellos" "I am about to dishcharge Here I go I will shut down when I am done." &> /dev/null;;
		
		# Default action
		*) 			say -v "Cellos" "Something went wrong and I need help" &> /dev/null;
					echo "No actions available...default response of case statement.";;
	
	esac
	
	# Return 0 if all is well
	return 0 
	}
	
###################
waitForDisconnect()
	{
	# Until the battery status is "discharging"
	until [ "$battStatus" = "discharging" ]
	do
		# Kill yes so it is not running while plugged in
		killall yes
		# Clear the screen
		clear
		# Tell the user to unplug the power adapter
		echo -e "\n\n\n\n\tWaiting for you to unplug me...\n\n\n\n"
		# Check the battery status to know when they unplug it
		battStatus=$(pmset -g batt | awk '/charging|discharging|charged/ {print $3}' | cut -d";" -f1)
	done
		
	# Inform the user that it can discharge now
	echo -e "\n\n\n\n\n\tNow I can discharge.  Thanks.\n\n\n"
	
	# Run the function to drain the battery, which just runs "yes"
	yesDrainTheBattery
	
	return 0
	}
	
####################
yesDrainTheBattery() 
	{	
	# Run multiple instances of the yes command to increase CPU usage and drain the battery fast
	# Could be dangerous if fans are not working
	# Default is to only run the command for a one-core computer
	# Uncomment the other instances of the commands at your own risk
	yes > /dev/null & #yes > /dev/null & #yes > /dev/null & #yes > /dev/null &

	# Return 0 if all is well
	return 0
	}
	
####################
checkBatteryStatus()
	{	
	export battStatus=$(pmset -g batt | awk '/charging|discharging|charged/ {print $3}' | cut -d";" -f1)
	# If the battery is charging or charged, then
	case $battStatus in
		# If charging or charged, stop running yes, and waitForDisconnect
		charging) say "Unplug me, you muppet." &> /dev/null;
					killall yes;
					waitForDisconnect;;
		charged) say "Unplug me, you muppet." &> /dev/null;
					killall yes;
					waitForDisconnect;;
					
		# If discharging, say the current status
		discharging) echo -e "Now I am $battStatus...Thank you" &> /dev/null;;
		
		# "AC" shows up for a brief moment when the adapter is first plugged in
		AC) echo "Hooked up to $battStatus...I should start charging in just a moment" &> /dev/null;
					killall yes;
					waitForDisconnect;;
					
		# For any other potential answer, echo a problem occurred
		*) echo "Something in the case statement went wrong";
					killall yes;
					return 4;;
	# Close the case statement
	esac

	# Return 0 if all is well
	return 0
	}

###########################
function monitorDischarge()
	{
	checkBatteryStatus
	# Run the function to drain the battery, which just runs "yes"
	yesDrainTheBattery
	
	# While the battery is set to "discharging," 
	while [ "$battStatus" = "discharging" ]
		do	
			# Check the status of the battery to make certain it has not changed
			battStatus=$(pmset -g batt | awk '/charging|discharging|charged/ {print $3}' | cut -d";" -f1)
			# Continually check battery percentage and store it in a variable
			currentPercentage=$(pmset -g batt | grep -o "[0-9]\+%;" | cut -d"%" -f1)
			# Continually echo the current variable value for the user to see
			clear
			# Sleep for 20 seconds so the output is readable
			sleep 20
			echo -e "$battStatus....Current level is:\t$currentPercentage%\t\t`date +%T`"
			# Check the battery status to update the variable
			checkBatteryStatus
			# If the current battery is less than or equal to the desired percentage, then
			if [ "$currentPercentage" -le "$desiredPercentage" ];then
				# Use an audible alert to let the user know it is ready and send any messages to the void
				say "I am almost done..." &> /dev/null &
				# Echo a message saying the discharge is complete after clearing the screen
				clear
				echo -e "\n\n\nHONORABLE DISHCARGE....\n\n"
				# Echo the actual percentage
				echo -e "\t\t🔋Final Battery level :\t$currentPercentage%\n\n\n"
				# Break out of loop when condition is no longer true 
				break
			fi 
	# Close the while loop
	done
	
	# Return 0 if all is well
	return 0
	}

###########################
function stopYesAndShutdown()
	{
	# Kill yes 
	killall yes
	
	# Sleep for 5 so the voices do not overlap
	sleep 5
	
	# Set the volume level in case it was off
	osascript -e 'set volume 8'
	
	# Let the user know we are shutting down in case they are not watching it
	say "Shutting down now..." &> /dev/null
	
	# Shutdown
	shutdown -h now &
	
	exit
	}
	
#---------------------
#---------------------
#-------SCRIPT--------
#---------------------
#---------------------
preRequisites
announceAndLockScreen
# Allow the user to cancel it with Ctrl+C	
trap "killall yes;exit 9" INT 
monitorDischarge
if [ $? = 0 ];then
	stopYesAndShutdown
fi
