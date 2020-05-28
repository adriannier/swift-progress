on run
	
	set parentDirectory to hfsPathForParent(path to me as text)
	
	set argumentRoulette to {"--raise-error", "--raise-error --skip-cleanup", "--close", ""}
	
	set processFound to false
	
	repeat 10 times
		
		tell application "System Events"
			set processExists to exists process "Progress"
		end tell
		
		if processExists then
			
			-- Just because it exists doesn't mean it's ready to receive events
			
			try
				tell application "Progress" to get indicators
				set processFound to true
				exit repeat
			end try
			
		end if
		
		delay 0.5
		
	end repeat
	
	if processFound is false then
		error "Timeout while waiting for Progress application to launch"
	end if
	
	repeat with i from 1 to 10
		
		set scriptPath to parentDirectory & "test.applescript"
		
		set r to random number from 1 to count of argumentRoulette
		
		do shell script "/usr/bin/osascript " & quoted form of (POSIX path of scriptPath) & " " & item r of argumentRoulette & " > /dev/null 2>&1 &"
		
		delay 1
		
	end repeat
	
end run

on hfsPathForParent(anyPath)
	
	-- Convert path to text
	set anyPath to anyPath as text
	
	-- Remove quotes
	if anyPath starts with "'" and anyPath ends with "'" then
		set anyPath to text 2 thru -2 of anyPath
	end if
	
	-- Expand tilde
	if anyPath starts with "~" then
		
		-- Get the path to the user’s home folder
		set userPath to POSIX path of (path to home folder)
		
		-- Remove trailing slash
		if userPath ends with "/" then set userPath to text 1 thru -2 of userPath as text
		
		if anyPath is "~" then
			set anyPath to userPath
		else
			set anyPath to userPath & text 2 thru -1 of anyPath
		end if
		
	end if
	
	-- Convert to HFS style path if necessary
	if anyPath does not contain ":" then set anyPath to (POSIX file anyPath) as text
	
	-- For simplification make sure every path ends with a colon
	if anyPath does not end with ":" then set anyPath to anyPath & ":"
	
	-- Get rid of the last path component
	set prvDlmt to text item delimiters
	set text item delimiters to ":"
	set parentPath to (text items 1 thru -3 of anyPath as text) & ":"
	set text item delimiters to prvDlmt
	
	return parentPath
	
end hfsPathForParent
