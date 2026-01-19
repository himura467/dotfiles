on run {input, parameters}
	tell application "System Events"
		set isRunning to (name of processes) contains "Ghostty"
	end tell

	if not isRunning then
		tell application "Ghostty"
			activate
		end tell
	else
		tell application "System Events"
			set isFrontmost to frontmost of process "Ghostty"
		end tell

		if isFrontmost then
			tell application "System Events"
				set visible of process "Ghostty" to false
			end tell
		else
			tell application "Ghostty"
				activate
			end tell
		end if
	end if

	return input
end run
