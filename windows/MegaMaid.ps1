function RedLightGreenLight {
    $results = New-Object System.Collections.Generic.List[PSObject]
    
    # Get all tasks once to save processing time
    $allTasks = Get-ScheduledTask
    
    foreach ($task in $allTasks) {
        $hasBad = $false
        
        # Check if the task has any actions (some are empty/stub tasks)
        if ($null -eq $task.Actions) { continue }

        foreach ($action in $task.Actions) {
            # We only care about 'Execute' actions (paths to files)
            if ($null -eq $action.Execute) { continue }

            # 1. Expand variables like %SystemRoot%
            $rawPath = [System.Environment]::ExpandEnvironmentVariables($action.Execute)
            
            # 2. Clean the path (remove quotes if they exist)
            $cleanPath = $rawPath.Replace('"', '')

            # 3. Verify the file exists
            if (-not (Test-Path $cleanPath)) {
                $hasBad = $true
                break
            }

            # 4. Check the signature
            $sig = Get-AuthenticodeSignature -FilePath $cleanPath -ErrorAction SilentlyContinue
            if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch "Microsoft") {
                $hasBad = $true
                break
            }
        }

        if ($hasBad) { $results.Add($task) }
    }
    return $results
}

function DoomHoover {
    Write-Host "--- DOOM HOOVER INITIALIZING ---" -ForegroundColor Cyan
    
    while ($true) {
        Write-Host "Scanning tasks at $(Get-Date -Format 'HH:mm:ss')..." -ForegroundColor Yellow
        
        $badTasks = RedLightGreenLight
        $allTasks = Get-ScheduledTask

        foreach ($task in $allTasks) {
            # Logic: Is this specific task in our 'bad' list?
            $isMatch = $badTasks | Where-Object { $_.TaskName -eq $task.TaskName -and $_.TaskPath -eq $task.TaskPath }
            
            if ($isMatch) {
                Write-Host "[!] UNSIGNED: $($task.TaskName)" -ForegroundColor Red
            } else {
                # Optional: Uncomment the line below to see EVERY task
                # Write-Host "[ ] Verified: $($task.TaskName)" -ForegroundColor DarkGray
            }
        }

        Write-Host "Scan complete. Waiting 10 seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

# IMPORTANT: This line actually starts the engine
DoomHoover