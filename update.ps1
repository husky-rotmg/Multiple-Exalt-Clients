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
        if ($_.Name -eq $File)
        {
            return
        }
        Write-Host "Updating $_..."
        Move-Item -Path $_.FullName -Destination $_.Name -Force -ErrorAction Ignore
    }

    Write-Host "Removing update archive..."
    Remove-Item -Path "update\" -Force -Recurse -ErrorAction Ignore
    
    Add-Type -AssemblyName System.Windows.Forms

    Write-Host "Successfully Updated"
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Updated Multiple-Exalt-Clients from version $Current to $Latest.", "Updated Successfully", "OK", "info")

    .\RunExaltAM.cmd -File $File
}