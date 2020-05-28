on run args
	
	try
		
		-- Initialize indicator
		tell application "Progress"
			launch
			set myIndicator to make new indicator with properties {visible:true, title:"Preparing…", percentage:-1}
		end tell
		
		delay 1
		
		-- Find PNGs in Resources for Dock.app
		set findOutput to do shell script "find /System/Library/CoreServices/Dock.app/Contents/Resources -iname '*@2x.png'"
		set pngPaths to reverse of paragraphs of findOutput
		set pngCount to count of pngPaths
		
		-- Update indicator
		tell application "Progress" to tell myIndicator
			set icon to item -1 of pngPaths
			set title to "Processing " & ((count of pngPaths) as text) & " images"
			delay 1
		end tell
		
		repeat with i from 1 to pngCount
			
			-- Update Progress Message
			tell application "Progress" to tell myIndicator
				set icon to item i of pngPaths
				set message to (i as text) & ": " & item -1 of my explodeString(item i of pngPaths, "/", false)
			end tell
			
			-- Increment Progress
			set perc to round (100 * i / pngCount) rounding down
			
			tell application "Progress" to tell myIndicator
				if perc is 100 then
					set icon to "/System/Library/CoreServices/Dock.app/Contents/Resources/finder@2x.png"
					set title to "Done"
				end if
				set percentage to perc
			end tell
			
			delay 0.05
			
		end repeat
		
	on error eMsg number eNum
		
		if eNum = -128 then -- User canceled
			
			-- Hide Progress
			tell application "Progress" to close myIndicator
			
		else
			
			-- Abort Progress
			tell application "Progress" to tell myIndicator
				
				set icon to "/System/Library/CoreServices/Dock.app/Contents/Resources/finder@2x.png"
				set title to "Something went terrifically wrong"
				set message to eMsg & " (" & (eNum as text) & ")"
				abort
				
			end tell
			
		end if
		
	end try
	
end run

on explodeString(aString, aDelimiter, lastItem)
	
	try
		
		if lastItem is false then set lastItem to -1
		
		set prvDlmt to AppleScript's text item delimiters
		set AppleScript's text item delimiters to aDelimiter
		set aList to text items 1 thru lastItem of aString
		set AppleScript's text item delimiters to prvDlmt
		
		return aList
		
	on error eMsg number eNum
		error "explodeString(): " & eMsg number eNum
	end try
	
end explodeString
