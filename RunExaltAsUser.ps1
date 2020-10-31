
Function RunExaltAsUser
{
    param(
        $Username,
        $Password
    )

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
        $encoded_password = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))))
            
    } catch {
        [System.Windows.MessageBox]::Show("There was an issue converting your credentials.`n$_", "Credential Conversion Error", "OK", "Error")
        return
    }

    $exalt_args="data:{platform:Deca,password:$encoded_password,guid:$encoded_username,env:4}"

    & "$env:USERPROFILE\Documents\RealmOfTheMadGod\Production\RotMG Exalt.exe" $exalt_args
}

