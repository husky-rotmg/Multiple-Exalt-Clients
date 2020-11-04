
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

    Write-Host "Username $Username"
    Write-Host "Password $Password"
    Write-Host "B64P $B64P"

    Add-Type -AssemblyName PresentationFramework

    #If a password was supplied, immediately convert to secure string
    If (-not([string]::IsNullOrWhiteSpace($Password)))
    {
        $Password = ConvertTo-SecureString $Password -AsPlainText -Force
    }
    Else
    {
        $credentials = Get-Credential -Message "Enter your RotMG Exalt credentials." -UserName $Username
        
        #If the username is empty or the password was truly empty, error out
        If ([string]::IsNullOrWhiteSpace($credentials.UserName) -or $credentials.Password.Length -eq 0)
        {
            [System.Windows.MessageBox]::Show('You require both a username and a password to log in.', 'Invalid Credentials', 'OK', 'Error')
            return
        }
        $Username = $credentials.UserName
        $Password = $credentials.Password
    }

    try {
        $encoded_username=[Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Username))
        #Convert secure string encoded password to base64 string
        $encoded_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
        If (-not($B64P)) {
            $encoded_password = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($encoded_password))
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

    Add-Type -AssemblyName System.Windows.Forms

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
            };
            Accounts = @{
            };
        }
        SaveSettings -Data $data -File $File
    }
    $base64 = $false

    if (-not($data.Settings -eq $null) -and -not($data.Settings.base64 -eq $null) -and $data.Settings.base64 -eq $true)
    {
        $base64 = $true
    }

    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Select an Account'
    $form.Size = New-Object System.Drawing.Size(300, 430)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $btnConfirm = New-Object System.Windows.Forms.Button
    $btnConfirm.Location = New-Object System.Drawing.Point(10, 350)
    $btnConfirm.Size = New-Object System.Drawing.Size(75, 23)
    $btnConfirm.Text = "Confirm"
    $btnConfirm.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $btnConfirm
    $form.Controls.Add($btnConfirm)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Location = New-Object System.Drawing.Point(195, 350)
    $btnCancel.Size = New-Object System.Drawing.Size(75, 23)
    $btnCancel.Text = 'Cancel'
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $btnCancel
    $form.Controls.Add($btnCancel)

    $btnAdd = New-Object System.Windows.Forms.Button
    $btnAdd.Location = New-Object System.Drawing.Point(10, 320)
    $btnAdd.Size = New-Object System.Drawing.Size(75, 23)
    $btnAdd.Text = 'Add'
    $btnAdd.Add_Click({
        try {
            $creds = PromptNewCredentials -base64 $base64
            $lbAccounts.Items.Add($creds.Username)
            $data.Accounts.Add($creds.Username, $creds.Password)
            SaveSettings -Data $data -File $File
        } catch { }
    })
    $form.Controls.Add($btnAdd)

    $btnRemove = New-Object System.Windows.Forms.Button
    $btnRemove.Location = New-Object System.Drawing.Point(195, 320)
    $btnRemove.Size = New-Object System.Drawing.Size(75, 23)
    $btnRemove.Text = 'Remove'
    $btnRemove.Add_Click({
        $selected = $lbAccounts.SelectedItem
        $lbAccounts.Items.Remove($selected)
        $data.Accounts.Remove($selected)
        SaveSettings -Data $data -File $File
    })
    $form.Controls.Add($btnRemove)

    $btnEdit = New-Object System.Windows.Forms.Button
    $btnEdit.Location = New-Object System.Drawing.Point(100, 320)
    $btnEdit.Size = New-Object System.Drawing.Size(75, 23)
    $btnEdit.Text = 'Edit'
    $btnEdit.Add_Click({
        $selected = $lbAccounts.SelectedItem
        if ($selected -eq $null) {
            return
        }
        try {
            $creds = PromptNewCredentials -Username $selected -base64 $base64
            $lbAccounts.Items.Remove($selected)
            $lbAccounts.Items.Add($creds.Username)
            $data.Accounts.Remove($selected)
            $data.Accounts.Add($creds.Username, $creds.Password)
            SaveSettings -Data $data -File $File
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
    $lbAccounts.Height = 280
    $lbAccounts.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended


    $lbAccounts.Items.AddRange($data.Accounts.Keys)

    $form.Controls.Add($lbAccounts)
    $form.Topmost = $true
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
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

Function SaveSettings
{
    param([Hashtable]$data, [string]$file)

    Set-Content -Path $file -Value ""
    foreach ($section in $data.Keys)
    {
        Add-Content -Path $file -Value "[$section]"
        $section = $data.Get_Item($section)
        foreach ($key in $section.Keys)
        {
            $value = $section.Get_Item($key)
            Add-Content -Path $file -Value "$key=$value"
        }
        Add-Content -Path $file -Value ""
    }
}

function Get-IniFile {
    <#
    .SYNOPSIS
    Read an ini file.
    
    .DESCRIPTION
    Reads an ini file into a hash table of sections with keys and values.
    
    .PARAMETER filePath
    The path to the INI file.
    
    .PARAMETER anonymous
    The section name to use for the anonymous section (keys that come before any section declaration).
    
    .PARAMETER comments
    Enables saving of comments to a comment section in the resulting hash table.
    The comments for each section will be stored in a section that has the same name as the section of its origin, but has the comment suffix appended.
    Comments will be keyed with the comment key prefix and a sequence number for the comment. The sequence number is reset for every section.
    
    .PARAMETER commentsSectionsSuffix
    The suffix for comment sections. The default value is an underscore ('_').
    .PARAMETER commentsKeyPrefix
    The prefix for comment keys. The default value is 'Comment'.
    
    .EXAMPLE
    Get-IniFile /path/to/my/inifile.ini
    
    .NOTES
    The resulting hash table has the form [sectionName->sectionContent], where sectionName is a string and sectionContent is a hash table of the form [key->value] where both are strings.
    This function is largely copied from https://stackoverflow.com/a/43697842/1031534. An improved version has since been pulished at https://gist.github.com/beruic/1be71ae570646bca40734280ea357e3c.
    #>
    
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

        "^(.+?)\s*=\s*(.*)$" {
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



function New-IniContent {
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