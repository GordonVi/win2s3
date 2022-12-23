function multithread_commands([string[]]$list) {
	
	
# --------------------------------------------------

$threads = 50 # how many simultanious threads. I've tested up to 1000 ok against ~3600 local IPs, ~900 active.


# --------------------------------------------------
	
$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0 , 1
write-host "       Threads: " -nonewline -foregroundcolor yellow
$threads
"    Build Pool: "
"    Drain Pool: "
" ---------------------"
write-host "   Total Files: $($list.count)"


# BLOCK 1: Create and open runspace pool, setup runspaces array with min and max threads
$pool = [RunspaceFactory]::CreateRunspacePool(1, $threads)
$pool.ApartmentState = "MTA"
$pool.Open()
$runspaces = $results = @()

# --------------------------------------------------
    
# BLOCK 2: Create reusable scriptblock. This is the workhorse of the runspace. Think of it as a function.
$scriptblock = {
    Param (
    [string]$command
    )

 $temp = invoke-expression $command
 
 return $temp
 
}

# --------------------------------------------------
 
# BLOCK 3: Create runspace and add to runspace pool
$counter=0
foreach ($command in $list) {
 
    $runspace = [PowerShell]::Create()
    $null = $runspace.AddScript($scriptblock)
    $null = $runspace.AddArgument($command)

    $runspace.RunspacePool = $pool
 
# BLOCK 4: Add runspace to runspaces collection and "start" it
    # Asynchronously runs the commands of the PowerShell object pipeline
    $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }

	$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 16 , 2
	$counter++
	write-host "$counter " -nonewline
}

# --------------------------------------------------
 
# BLOCK 5: Wait for runspaces to finish

<#
do {
	$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 5 , 9
	$cnt = ($runspaces | Where {$_.Result.IsCompleted -ne $true}).Count
	write-host "$cnt   "
	
	} while ($cnt -gt 0)
#>

# --------------------------------------------------

$total=$counter
$counter=0

# BLOCK 6: Clean up
foreach ($runspace in $runspaces ) {
    # EndInvoke method retrieves the results of the asynchronous call
    $results += $runspace.Pipe.EndInvoke($runspace.Status)
    $runspace.Pipe.Dispose()
	
	$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 16 , 3
	$counter++
	write-host "$($total-$counter) " -nonewline

}
    
$pool.Close() 
$pool.Dispose()

}
