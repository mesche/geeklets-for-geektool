#    ::::::::::::::: www.blogging-it.com :::::::::::::::
#    
# Version: 1.3
#
# Copyright (C) 2014 Markus Eschenbach. All rights reserved.
# 
# 
# This software is provided on an "as-is" basis, without any express or implied warranty.
# In no event shall the author be held liable for any damages arising from the
# use of this software.
# 
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter and redistribute it,
# provided that the following conditions are met:
# 
# 1. All redistributions of source code files must retain all copyright
#    notices that are currently in place, and this list of conditions without
#    modification.
# 
# 2. All redistributions in binary form must retain all occurrences of the
#    above copyright notice and web site addresses that are currently in
#    place (for example, in the About boxes).
# 
# 3. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software to
#    distribute a product, an acknowledgment in the product documentation
#    would be appreciated but is not required.
# 
# 4. Modified versions in source or binary form must be plainly marked as
#    such, and must not be misrepresented as being the original software.
#    
#    ::::::::::::::: www.blogging-it.com :::::::::::::::

@NEWLINE = "\n"
@user = `whoami`
@system = `scutil --get ComputerName`
@ipLan = (`ifconfig en0 | grep netmask`).split
@ipWLan = (`ifconfig en1 | grep netmask`).split
@externalIP = `curl -s http://checkip.dyndns.org/ | sed 's/[a-zA-Z<>/ :]//g'`
@prodName = (`sw_vers -productName`)
@prodVers = (`sw_vers | grep ProductVersion`).split
@memory = (`top -l 1 | grep 'PhysMem'`).split
@uptime = `uptime | awk '{sub("2 users", " ", $6); sub(",", " ", $6); sub("mins", " min ", $6); sub(",", " min ", $5); sub(":", " h ", $5); sub("day,", " day ", $4); sub("days,", " days ", $4); sub("mins,", " min ", $4); sub("min,",  " min ", $4); sub("hrs,", " h ", $4); sub(":", " h ", $3); sub(",", " min ", $3); sub("2", "", $4); sub("1", "", $4); print $3 $4}'`
@now = `date +"%d.%m.%Y %H:%M:%S"`
@tmbackup = (`date -jf "%F %T %z" "$( defaults read /private/var/db/.TimeMachine.Results BACKUP_COMPLETED_DATE )" +"%d.%m.%Y %H:%M"`).split
@cpuInfo = `sysctl -n machdep.cpu.brand_string | sed -e 's/([^)]*)//g' | tr '@' '-'`
@hostInfo = `sysctl -n kern.hostname`
@freeDiscSpace = (`df -hl | grep 'disk0s2'`).split
if (@freeDiscSpace.length == 0)
  @freeDiscSpace = (`df -hl | grep 'disk1'`).split
end

#POWER INFO START
@notebook_PowerInfo = `ioreg -rc "AppleSmartBattery"`
@bat_status = %w(CurrentCapacity MaxCapacity FullyCharged IsCharging TimeRemaining).inject({}) do |hash, property|
  hash[property.to_sym] = @notebook_PowerInfo[/"#{property}" = (.*)$/, 1]; hash
end

@battery_percentage     = (@bat_status[:CurrentCapacity].to_f/@bat_status[:MaxCapacity].to_f).to_s[2..3] + '%'
@battery_full, @battery_charging = @bat_status[:FullyCharged] == 'Yes', @bat_status[:IsCharging] == 'Yes' && !@battery_full
@battery_remaining      = sprintf("%d:%02d", *@bat_status[:TimeRemaining].to_i.divmod(60))
@battery_timeleft         = (@battery_full && '[==]') || "#{@battery_charging ? '⇡' : '⇣'} #{@battery_remaining}"

@power_isextern = `ioreg -w0 -l | grep ExternalConnected | awk '{print $5}'`.strip
@notebook_PowerInfo = (@power_isextern  == 'Yes') ? `echo "external Source"` : `echo "Battery (#{@battery_percentage})    #{@battery_timeleft} residual"`

@keyboard_Percent = `ioreg -c AppleBluetoothHIDKeyboard | grep BatteryPercent | sed 's/[a-z,A-Z, ,|,",=]//g' | tail -1 | awk '{print $1"%"}'`
@mouse_Percent = `ioreg -c BNBMouseDevice | grep BatteryPercent | sed 's/[a-z,A-Z, ,|,",=]//g' | tail -1 | awk '{print $1"%"}'`
@trackpad_Percent = `ioreg -c BNBTrackpadDevice | grep BatteryPercent | sed 's/[a-z,A-Z, ,|,",=]//g' | tail -1 | awk '{print $1"%"}'`
#POWER INFO END



def label(lbl) return "    \033[1m" + lbl + ": \033[0m" end
def header(lbl) return "\033[33m" + lbl.upcase + ": \033[0m" end

puts header("COMPUTER")
puts label("User") + "#{@user}"
puts label("Computer") + "#{@system}"
puts label("Hostname") + "#{@hostInfo}"
puts label("Processor") + "#{@cpuInfo}"
puts "#{@NEWLINE}"

puts header("OPERATING SYSTEM")
puts label("OS Name") + "#{@prodName}"
puts label("OS Version") + "#{@prodVers[1]}"
puts "#{@NEWLINE}"

puts header("NETWORK")
puts label("IP-External") + (@externalIP != '' ? "#{@externalIP}" : "inactive")
puts label("IP-LAN") + (!@ipLan[1].nil? ? "#{@ipLan[1]}" : "inactive")
puts label("IP-WLAN") + (!@ipWLan[1].nil? ? "#{@ipWLan[1] }" : "inactive")
puts "#{@NEWLINE}"

@mem_used = (@memory[2] == 'used') ? @memory[1] : @memory[7]
@mem_free = (@memory[2] == 'used') ? @memory[5] : @memory[9]
puts header("STORAGE")
puts label("RAM") +  "#{@mem_used} / #{@mem_free} free"
puts label("Harddisk") + "#{@freeDiscSpace[1]} / #{@freeDiscSpace[3]} free (#{@freeDiscSpace[4]} used)"
puts "#{@NEWLINE}"

puts header("ENERGY") 
puts label("Notebook") + "#{@notebook_PowerInfo}"
puts label("Mouse") + ((@mouse_Percent != '') ? "#{@mouse_Percent}" : "not connected")
puts label("Keyboard") + ((@keyboard_Percent != '') ? "#{@keyboard_Percent}" : "not connected")
puts label("Trackpad") + ((@trackpad_Percent != '') ?  "#{@trackpad_Percent}" : "not connected")
puts "#{@NEWLINE}"

puts header("MISC") 
puts label("Uptime") + "#{@uptime}"
puts label("TM-Backup") + "#{@tmbackup[0]} #{@tmbackup[1]}"
puts "#{@NEWLINE}"

puts label("Refreshed") + "#{@now}"

