on run args
	
	set waitForProgressApplication to false
	set alwaysRaiseError to false
	set askForError to false
	set automaticallyClose to false
	set skipCleanup to false
	
	-- Parse parameters
	repeat with i from 1 to count of args
		
		if item i of args is "--raise-error" then
			set alwaysRaiseError to true
		else if item i of args is "--show-dialog" then
			set askForError to true
		else if item i of args is "--wait" then
			set waitForProgressApplication to true
		else if item i of args is "--close" then
			set automaticallyClose to true
		else if item i of args is "--skip-cleanup" then
			set skipCleanup to true
		end if
		
	end repeat
	
	if waitForProgressApplication then
		
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
			
			delay 1
			
		end repeat
		
		if processFound is false then
			error "Timeout while waiting for Progress application to launch"
		end if
		
	end if
	
	try
		
		-- Initialize Progress
		tell application "Progress"
			
			launch
			
			set myIndicator to make new indicator with properties {title:"Preparing…", icon:"/System/Library/CoreServices/Dock.app/Contents/Resources/url@2x.png", percentage:-1}
			
			show myIndicator
			
			delay 0.5
			
			tell myIndicator to set title to "Still preparing…"
			
			delay 0.2
			
			tell myIndicator to set title to "Almost ready"
			
			delay 0.5
			
			tell myIndicator to set title to "Demonstrating some progress"
			
		end tell
		
		
		
		repeat with i from 1 to 100
			
			-- Update Progress Message
			tell application "Progress" to tell myIndicator to set message to "Iteration " & i & " of 100"
			
			
			if (askForError or alwaysRaiseError) and i is 75 then
				
				try
					
					if alwaysRaiseError then error 1
					
					activate
					set theButton to button returned of (display dialog "Demonstrate an error?" buttons {"Raise Error", "Continue"} default button 2 cancel button 1)
					
				on error eMsg number eNum
					error "This should be an error message" number 123
				end try
				
			end if
			
			-- Increment Progress
			tell application "Progress" to tell myIndicator to set percentage to i
			
			delay 0.01
			
		end repeat
		
		-- Hide Progress
		if automaticallyClose then
			tell application "Progress" to close myIndicator
		end if
		
	on error eMsg number eNum
		
		if skipCleanup then return
		
		if eNum = -128 then -- User canceled
			
			-- Hide Progress
			tell application "Progress" to quit
			
		else
			
			-- Abort Progress
			tell application "Progress"
				
				tell myIndicator to set title to "Something went wrong"
				tell myIndicator to set message to eMsg & " (" & (eNum as text) & ")"
				tell myIndicator to abort
				
			end tell
			
		end if
		
	end try
	
end run
