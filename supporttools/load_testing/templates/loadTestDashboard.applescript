launch "iTerm"

set hostingname to "<?php print $docroot; ?>"

set environment to "<?php print $env; ?>"

set webs to <?php print '{"' . implode($webs, '","') . '"}';?>

set activeBal to "<?php print $bals[0];?>"

set activeDb to "<?php print $dbs[0];?>"


tell application "iTerm"
	
	activate
	
	set myterm to (make new terminal)
	tell myterm
		set number of columns to 330
		set number of rows to 100
		
		-- Stub the first column
		launch session "Default"
		tell last item of sessions
			set name to "WEBS"
			set foreground color to "red"
		end tell
		
		-- mytop spans the next two columns
		
		tell i term application "System Events" to keystroke "d" using command down
		
		tell current session
			set name to "mytop"
			set foreground color to "cyan"
			tell i term application "System Events" to keystroke "---" using command down
			write text "aht @" & hostingname & "." & environment & " mytop"
		end tell
		
		tell i term application "System Events" to keystroke "d" using {command down, shift down}
		
		tell last item of sessions
			set name to "DBS"
			set foreground color to "cyan"
		end tell
		
		------------------------------------------------
		-- Create and populate the column for bal monitoring
		------------------------------------------------
		
		tell i term application "System Events" to keystroke "d" using command down
		tell last item of sessions
			set name to "varnishstat"
			set foreground color to "magenta"
			tell i term application "System Events" to keystroke "---" using command down
			write text "ssh -t " & activeBal & " 'varnishstat -l'"
		end tell
		
		tell i term application "System Events" to keystroke "d" using {command down, shift down}
		tell current session
			set name to "varnishtop"
			set foreground color to "magenta"
			tell i term application "System Events" to keystroke "---" using command down
			write text "ssh -t " & activeBal & " 'varnishtop -i TxHeader'"
		end tell
		
		tell i term application "System Events" to keystroke "d" using {command down, shift down}
		tell current session
			set name to "memcache"
			set foreground color to "magenta"
			tell i term application "System Events" to keystroke "---" using command down
			write text "aht --stages=mc @" & hostingname & "." & environment & " memcache --watch"
		end tell
		-- Backtrack to center column (DBs)
		
		tell i term application "System Events" to keystroke "[" using command down
		tell i term application "System Events" to keystroke "[" using command down
		tell i term application "System Events" to keystroke "[" using command down
		
		tell current session
			set name to "slowlog"
			set foreground color to "cyan"
			tell i term application "System Events" to keystroke "---" using command down
			write text "ssh " & activeDb & " 'sudo tail -f /var/lib/mysql/mysqld-slow.log'"
		end tell
		
		tell i term application "System Events" to keystroke "d" using {command down, shift down}
		
		tell current session
			set name to "iostat"
			set foreground color to "cyan"
			tell i term application "System Events" to keystroke "---" using command down
			write text "ssh " & activeDb & " 'iostat -mx 1'"
		end tell
		
		-- Back up to the first column (WEBS)
		
		tell i term application "System Events" to keystroke "[" using command down
		tell i term application "System Events" to keystroke "[" using command down
		tell i term application "System Events" to keystroke "[" using command down
		
		set counter to 0
		repeat with web in webs
			if counter is not 0 then
				tell i term application "System Events" to keystroke "d" using {command down, shift down}
			end if
			tell current session
				if counter mod 2 is not 0 then
					set sshcommand to "ssh " & web & " 'dstat -lcm 5'"
					set suffix to "dstat"
				else
					set sshcommand to "ssh " & web & " 'sudo tail -f /var/log/apache2/error.log'"
					set suffix to "error.log"
				end if
				
				write text sshcommand
				set name to web & " " & suffix
				set foreground color to "red"
				tell i term application "System Events" to keystroke "---" using command down
			end tell
			set counter to counter + 1
		end repeat
	end tell
end tell
