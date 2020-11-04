# Multiple Exalt Clients
 Run multiple RotMG Exalt games at the same time

# How to Use
There are many ways you can run this:

- **RunExalt.cmd** is a one-time click, it will ask for your credentials each time you want to log in.

- **RunExaltAM.cmd** will display a GUI for adding/editing/removing accounts to pre-select to log in with. Simply select an account in the list and click Confirm to log in. Multi-select is enabled for Login and Remove.

- Create a shortcut and add `-Username YOUR_USER -Password YOUR_PASS` to the end of the Target in the shortcut properies (right-click the shortcut and click properties).

	- If you don't want to have your password in the shortcut, you can omit the password and keep your username in there; the credential popup will show with your username already filled in.
	- You can look at Shortcut Example to see how it should be setup.
	
- You can also run it from PowerShell by importing RunExaltAsUser.ps1 and running the function `RunExalt([optional]$Username,[optional]$Password,[optional]$B64P,[optional]$File)`. `$File` overrides all other arguments and expects an ini.

- **You may get a Windows SmartScreen popup the first time this has been ran. Simply click More Info in the top left, then click Run Anyway to begin.**

All documents are free to edit and distribute and are provided as-is.
