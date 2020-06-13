global myIndicator

on run
	
	try
		
		indicatorInitialize("Preparing…", "")
		
		delay 1 -- For demonstration purposes
		
		-- Find PNGs in Resources for Dock.app
		set findOutput to do shell script "find /System/Library/CoreServices/Dock.app/Contents/Resources -iname '*@2x.png'"
		set pngPaths to reverse of paragraphs of findOutput
		set pngCount to count of pngPaths
		
		indicatorIcon(item -1 of pngPaths)
		indicatorTitle("Processing " & ((count of pngPaths) as text) & " images")
		
		delay 1 -- For demonstration purposes
		
		repeat with i from 1 to pngCount
			
			indicatorIcon(item i of pngPaths)
			indicatorMessage((i as text) & ": " & item -1 of explodeString(item i of pngPaths, "/", false))
			
			-- Calculate new percentage
			set perc to round (100 * i / pngCount) rounding down
			
			indicatorPercentage(perc)
			
			delay 0.05 -- For demonstration purposes
			
		end repeat
		
		indicatorIcon("/System/Library/CoreServices/Dock.app/Contents/Resources/finder@2x.png")
		indicatorTitle("Done")
		
	on error eMsg number eNum
		
		if eNum = -128 then -- User canceled
			
			indicatorClose()
			
		else
			
			indicatorIcon("/System/Library/CoreServices/Dock.app/Contents/Resources/finder@2x.png")
			indicatorTitle("Something went wrong")
			indicatorMessage(eMsg & " (" & (eNum as text) & ")")
			indicatorAbort()
			
		end if
		
	end try
	
end run

on indicatorInitialize(indicatorTitle, indicatorIcon)
	
	-- Initialize indicator
	
	try
		
		tell application "Finder" to get application file id "de.adriannier.progress"
		
		tell application "Progress"
			launch
			set myIndicator to make new indicator with properties {visible:true, title:indicatorTitle, icon:indicatorIcon}
		end tell
		
	on error eMsg
		
		log eMsg
		
		set myIndicator to false
		
	end try
	
end indicatorInitialize

on indicatorTitle(aTitle)
	
	-- Set indicator title
	
	if myIndicator is not false then
		
		tell application "Progress" to tell myIndicator
			set title to aTitle
		end tell
		
	end if
	
end indicatorTitle

on indicatorPercentage(aPercentage)
	
	-- Set indicator percentage (0 to 100.0)
	
	if myIndicator is not false then
		
		tell application "Progress" to tell myIndicator
			set percentage to aPercentage
		end tell
		
	end if
	
end indicatorPercentage

on indicatorMessage(aMessage)
	
	-- Set indicator message
	
	if myIndicator is not false then
		
		tell application "Progress" to tell myIndicator
			set message to aMessage
		end tell
		
	end if
	
end indicatorMessage

on indicatorIcon(aPath)
	
	-- Set indicator icon
	
	if myIndicator is not false then
		
		tell application "Progress" to tell myIndicator
			set icon to aPath
		end tell
		
	end if
	
end indicatorIcon

on indicatorClose()
	
	-- Close the indicator
	
	if myIndicator is not false then
		
		tell application "Progress" to close myIndicator
		
	end if
	
end indicatorClose

on indicatorAbort()
	
	-- Abort the indicator
	
	if myIndicator is not false then
		
		tell application "Progress" to tell myIndicator to abort
		
	end if
	
end indicatorAbort

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
