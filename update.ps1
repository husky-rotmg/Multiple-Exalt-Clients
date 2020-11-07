Function Update-MEC
{
    param($Current, $Latest, $File)
    
    Write-Host "Removing old update files..."
    Remove-Item -Path "update.zip" -Force -ErrorAction Ignore
    Remove-Item -Path "update\" -Force -Recurse -ErrorAction Ignore

    Write-Host "Downloading latest version ($Latest) from https://github.com/husky-rotmg/multiple-exalt-clients/archive/v$Latest.zip"
    Invoke-WebRequest -Uri "https://github.com/husky-rotmg/multiple-exalt-clients/archive/v$Latest.zip" -OutFile "update.zip"
    
    Write-Host "Expanding update archive..."
    Expand-Archive -Path "update.zip"

    Write-Host "Removing update.zip..."
    Remove-Item -Path "update.zip" -Force

    Write-Host "Updating files..."
    Get-ChildItem -Path $(Get-ChildItem -Path "update\")[0].FullName |
    Foreach-Object {
        $file = $_
        if (@("accounts.ini") -contains $file.Name)
        {
            return
        }
        Write-Host "Updating $file..."
        Move-Item -Path $file.FullName -Destination $file.Name -Force -ErrorAction Inquire
    }

    Write-Host "Removing update archive..."
    Remove-Item -Path "update\" -Force -Recurse -ErrorAction Stop

    . .\RunExaltAsUser.ps1

    if ($running_vers -eq [Version]$Latest)
    {
        Write-Host "Successfully Updated"
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Updated Multiple-Exalt-Clients from version $Current to $Latest.", "Updated Successfully", "OK", "info")
    
    } else {
        Write-Host "There was a problem updating the clients..."
        Write-Host "Manually download the update from https://github.com/husky-rotmg/multiple-exalt-clients/archive/v$Latest.zip"
        [System.Windows.Forms.MessageBox]::Show("There was a problem updating the clients... Manually download the update from https://github.com/husky-rotmg/multiple-exalt-clients/archive/v$Latest.zip", "Update Failed", "OK", "Error")
    }
    if ($File -eq $null)
    {
        $File = "accounts.ini"
    }
    RunExalt -File $File 
}