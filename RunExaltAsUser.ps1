$running_vers = [Version]"1.7"


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Drawing

Function RunExalt
{
    param(
        $Username,
        $Password,
        $B64P,
        $File
    )

    if (-not($File -eq "" -or $File -eq $null)) 
    {
        RunExaltFromList($File)
    }
    else
    {
        RunExaltAsUser -Username $Username -Password $Password -B64P $B64P
    }
}

Function RunExaltAsUser
{
    [CmdletBinding()]
    param(
        $Username,
        $Password,
        $B64P
    )
    
    #If a password was not supplied, ask for it
    If ([string]::IsNullOrWhiteSpace($Password))
    {
        $credentials = PromptNewCredentials -base64 $B64P -Username $Username
        if (!$credentials)
        {
            return
        }
        $Username = $credentials.UserName
        $Password = $credentials.Password
    }

    try {
        $encoded_username=[Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Username))
        $encoded_password = $Password
        #Convert secure string encoded password to base64 string
        If (-not($B64P)) {
            $encoded_password = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Password))
        } 
            
    } catch {
        [System.Windows.MessageBox]::Show("There was an issue converting your credentials.`n$_", "Credential Conversion Error", "OK", "Error")
        return
    }

    $exalt_args="data:{platform:Deca,password:$encoded_password,guid:$encoded_username,env:4}"
    Start-Process -FilePath "$env:USERPROFILE\Documents\RealmOfTheMadGod\Production\RotMG Exalt.exe" -ArgumentList $exalt_args
}

Function RunExaltFromList
{
    param($File)

    $data = Get-Settings $File
    $base64 = $false

    if (-not($data.Settings -eq $null) -and -not($data.Settings.base64 -eq $null) -and $data.Settings.base64 -eq $true)
    {
        $base64 = $true
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Select an Account'
    $form.Size = New-Object System.Drawing.Size(295, 438)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $btnConfirm = New-Object System.Windows.Forms.Button
    $btnConfirm.Location = New-Object System.Drawing.Point(10, 370)
    $btnConfirm.Size = New-Object System.Drawing.Size(75, 23)
    $btnConfirm.Text = "Login"
    $btnConfirm.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $btnConfirm
    $form.Controls.Add($btnConfirm)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Location = New-Object System.Drawing.Point(195, 370)
    $btnCancel.Size = New-Object System.Drawing.Size(75, 23)
    $btnCancel.Text = 'Cancel'
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $btnCancel
    $form.Controls.Add($btnCancel)

    $btnAdd = New-Object System.Windows.Forms.Button
    $btnAdd.Location = New-Object System.Drawing.Point(10, 325)
    $btnAdd.Size = New-Object System.Drawing.Size(75, 23)
    $btnAdd.Text = 'Add'
    $btnAdd.Add_Click({
        try {
            $creds = PromptNewCredentials -base64 $base64
            if ($creds)
            {
                $lbAccounts.Items.Add($creds.Username)
                $data.Accounts.Add($creds.Username, $creds.Password)
                Save-Settings -Data $data -File $File
            }
        } catch { }
    })
    $form.Controls.Add($btnAdd)

    $btnRemove = New-Object System.Windows.Forms.Button
    $btnRemove.Location = New-Object System.Drawing.Point(195, 325)
    $btnRemove.Size = New-Object System.Drawing.Size(75, 23)
    $btnRemove.Text = 'Remove'
    $btnRemove.Add_Click({
        foreach ($selected in @($lbAccounts.SelectedItems))
        {
            $lbAccounts.Items.Remove($selected)
            $data.Accounts.Remove($selected)
        }            
        Save-Settings -Data $data -File $File
    })
    $form.Controls.Add($btnRemove)

    $btnEdit = New-Object System.Windows.Forms.Button
    $btnEdit.Location = New-Object System.Drawing.Point(100, 325)
    $btnEdit.Size = New-Object System.Drawing.Size(75, 23)
    $btnEdit.Text = 'Edit'
    $btnEdit.Add_Click({
        $selected = $lbAccounts.SelectedItem
        if ($selected -eq $null) {
            return
        }
        try {
            $creds = PromptNewCredentials -Username $selected -base64 $base64
            if ($creds)
            {
                $lbAccounts.Items.Remove($selected)
                $lbAccounts.Items.Add($creds.Username)
                $data.Accounts.Remove($selected)
                $data.Accounts.Add($creds.Username, $creds.Password)
                Save-Settings -Data $data -File $File
            }
        } catch { }
        
    })
    $form.Controls.Add($btnEdit)


    $label = New-Object System.Windows.Forms.label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(280, 20)
    $label.Text = "Select an Account"
    $form.Controls.Add($label)

    $lbAccounts = New-Object System.WIndows.Forms.ListBox
    $lbAccounts.Location = New-Object System.Drawing.Point(10, 40)
    $lbAccounts.Size = New-Object System.Drawing.Size(260, 20)
    $lbAccounts.Height = 260
    $lbAccounts.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended
    $lbAccounts.Sorted = $true
    if ($data.Accounts.Keys)
    {
        $lbAccounts.Items.AddRange($data.Accounts.Keys)
    }
    $form.Controls.Add($lbAccounts)

    $chkRemember = New-Object System.Windows.Forms.CheckBox
    $chkRemember.Location = New-Object System.Drawing.Point(10, 290)
    $chkRemember.Width = 260
    if ($data.Settings.remember -eq $null) {
        $data.Settings.remember = "True"
        Save-Settings -Data $data -File $File
    }

    $chkRemember.Text = "Remember previous selections?"
    $chkRemember.Checked = $false
    if ($data.Settings.remember -ne "False")
    {
        $chkRemember.Checked = $true
        if ($data.Settings.previous) {
            foreach ($name in $data.Settings.previous.split(" ")) {
                $lbAccounts.SelectedItems.Add($name)
            }
        }
    }
    $chkRemember.Add_CheckStateChanged({
        $data.Settings.remember = $chkRemember.Checked
        Save-Settings -Data $data -File $File
    })

    $form.Controls.Add($chkRemember)

    $form.Topmost = $true
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        if ($data.Settings.remember)
        {
            $data.Settings.previous = $lbAccounts.SelectedItems
            Save-Settings -Data $data -File $File
        }
        foreach ($username in $lbAccounts.SelectedItems)
        {
            $password = $data.Accounts.Get_Item($username)
            & RunExaltAsUser -Username $username -Password $password -B64P $base64
        }
    }
}

Function PromptNewCredentials
{
    param($base64,$Username)

    $credentials = Get-Credential -Message "Enter your RotMG Exalt credentials." -UserName $Username
    if (!$credentials)
    {
        return $null
    }    
    #If the username is empty or the password was truly empty, error out
    If ([string]::IsNullOrWhiteSpace($credentials.UserName) -or $credentials.Password.Length -eq 0)
    {
        [System.Windows.MessageBox]::Show('You require both a username and a password', 'Invalid Credentials', 'OK', 'Error')
        return
    }
    $Username = $credentials.UserName
    $Password = $credentials.Password
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    If ($base64)
    {
        $Password = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Password))
    }

    return New-Object -TypeName PSObject -Property @{
        Username = $Username
        Password = $Password
    }
}
Function Get-Settings
{
    param($File)
    $data = $null
    try 
    {
        $data = Get-IniFile $File
    } 
    catch
    {
        $data = @{
            Settings = @{
                base64="true"
                checkUpdates="true"
            };
            Accounts = @{
            };
        }
        Save-Settings -Data $data -File $File
    }

    try {
        $latest = ConvertFrom-Json $(Invoke-WebRequest -Uri "https://api.github.com/repos/husky-rotmg/multiple-exalt-clients/releases/latest").Content
        $latest_vers = [Version]($latest.tag_name.substring(1))
        $latest_body = $latest.body
        $latest_title = $latest.name
        $latest_url = $latest.html_url
        if ($latest_vers -gt $running_vers -and $data.Settings.checkUpdates -ne $false)
        {
            $form = New-Object System.Windows.Forms.Form
            $form.Text = 'Updates Found'
            $form.Size = New-Object System.Drawing.Size(290, 280)
            $form.StartPosition = 'CenterScreen'
            $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
            $form.MaximizeBox = $false
            $form.MinimizeBox = $false

            $chkAsk = New-Object System.Windows.Forms.CheckBox
            $chkAsk.Text = "Continue to ask when a new update is available?"
            $chkAsk.Location = New-Object System.Drawing.Point(10, 180)
            $chkAsk.MaximumSize = New-Object System.Drawing.Size(270, 0)
            $chkAsk.AutoSize = $true
            $chkAsk.Checked = $true
            $form.Controls.Add($chkAsk)

            $btnAccept = New-Object System.Windows.Forms.Button
            $btnAccept.Location = New-Object System.Drawing.Point(10, 210)
            $btnAccept.Size = New-Object System.Drawing.Size(75, 23)
            $btnAccept.Text = "Update"
            $btnAccept.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.AcceptButton = $btnAccept
            $form.Controls.Add($btnAccept)

            $btnCancel = New-Object System.Windows.Forms.Button
            $btnCancel.Location = New-Object System.Drawing.Point(190, 210)
            $btnCancel.Size = New-Object System.Drawing.Size(75, 23)
            $btnCancel.Text = "Cancel"
            $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $form.CancelButton = $btnCancel
            $form.Controls.Add($btnCancel)
            $lblUpdate = New-Object System.Windows.Forms.Label
            $lblUpdate.Location = New-Object System.Drawing.Point(10, 10)
            $lblUpdate.MaximumSize = New-Object System.Drawing.Size(270, 0)
            $lblUpdate.AutoSize = $true
            $lblUpdate.Text = "There is a new version available. Would you like to update?"
            
            $lblVersions = New-Object System.Windows.Forms.Label
            $lblVersions.Location = New-Object System.Drawing.Point(10, 40)
            $lblVersions.MaximumSize = New-Object System.Drawing.Size(270, 0)
            $lblVersions.AutoSize = $true
            $lblVersions.Text = "Current = $running_vers, Latest = $latest_vers"
            
            $lblTitle = New-Object System.Windows.Forms.Label
            $lblTitle.Location = New-Object System.Drawing.Point(10, 70)
            $lblTitle.MaximumSize = New-Object System.Drawing.Size(270, 0)
            $lblTitle.AutoSize = $true
            $lblTitle.Font = New-Object System.Drawing.Font([System.Windows.Forms.Label]::DefaultFont, [System.Drawing.FontStyle]::Bold)
            $lblTitle.Text = "$latest_title"
            
            $lblBody = New-Object System.Windows.Forms.TextBox
            $lblBody.Location = New-Object System.Drawing.Point(10, 90)
            $lblBody.Size = New-Object System.Drawing.Size(255, 85)
            $lblBody.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
            $lblBody.WordWrap = $true
            $lblBody.Multiline = $true
            $lblBody.ReadOnly = $true
            $lblBody.Text = "$latest_body"

            $form.Controls.Add($lblUpdate)
            $form.Controls.Add($lblVersions)
            $form.Controls.Add($lblTitle)
            $form.Controls.Add($lblBody)

            $form.Topmost = $true
            $result = $form.ShowDialog()

            $data.Settings.checkUpdates = $chkAsk.Checked
            Save-Settings -Data $data -File $File

            if ($result -eq [System.Windows.Forms.DialogResult]::OK)
            {
                Start-Process -FilePath powershell.exe -WorkingDirectory $(Get-Location).Path -ArgumentList "-WindowStyle Hidden -ExecutionPolicy ByPass -Command `"& {. .\update.ps1; Update-MEC -Current $running_vers -Latest $latest_vers -File $File }`""
                Exit 0
            }
        }
    } catch { }

    return $data
}
Function Save-Settings
{
    param([Hashtable]$Data, [string]$File)

    Set-Content -Path $File -Value $($Data | New-IniContent)
}

# https://gist.github.com/beruic/1be71ae570646bca40734280ea357e3c
function Get-IniFile 
{
    param(
        [parameter(Mandatory = $true)] [string] $filePath,
        [string] $anonymous = 'NoSection',
        [switch] $comments,
        [string] $commentsSectionsSuffix = '_',
        [string] $commentsKeyPrefix = 'Comment'
    )

    $ini = @{}
    switch -regex -file ($filePath) {
        "^\[(.+)\]$" {
            # Section
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
            if ($comments) {
                $commentsSection = $section + $commentsSectionsSuffix
                $ini[$commentsSection] = @{}
            }
            continue
        }

        "^(;.*)$" {
            # Comment
            if ($comments) {
                if (!($section)) {
                    $section = $anonymous
                    $ini[$section] = @{}
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = $commentsKeyPrefix + $CommentCount
                $commentsSection = $section + $commentsSectionsSuffix
                $ini[$commentsSection][$name] = $value
            }
            continue
        }

        "^([^=]+?)\s*=\s*(.*)$" {
            # Key
            if (!($section)) {
                $section = $anonymous
                $ini[$section] = @{}
            }
            $name, $value = $matches[1..2]
            $ini[$section][$name] = $value
            continue
        }
    }

    return $ini
}

function New-IniContent 
{
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline)] [hashtable] $data,
        [string] $anonymous = 'NoSection'
    )
    process {
        $iniData = $_

        if ($iniData.Contains($anonymous)) {
            $iniData[$anonymous].GetEnumerator() |  ForEach-Object {
                Write-Output "$($_.Name)=$($_.Value)"
            }
            Write-Output ''
        }

        $iniData.GetEnumerator() | ForEach-Object {
            $sectionData = $_
            if ($sectionData.Name -ne $anonymous) {
                Write-Output "[$($sectionData.Name)]"

                $iniData[$sectionData.Name].GetEnumerator() |  ForEach-Object {
                    Write-Output "$($_.Name)=$($_.Value)"
                }
            }
            Write-Output ''
        }
    }
}
