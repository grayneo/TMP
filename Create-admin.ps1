Set-ExecutionPolicy unrestricted -Scope LocalMachine -Force #Disable running script policy

$path = "C:\_tools"   #create the path for running script if not exist please change the C:\_tools if you want to save the script somewhere else
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}

Function New-SecurePassword {
    $Password = "!@0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".tochararray()
    ($Password | Get-Random -Count 8) -Join ''
    } #generate new random password from the Password array

$Password = New-SecurePassword 
$Username = "IT_Admin"

#check the name of local admin for German and English language
$op = Get-Localgroup | where-Object Name -eq "Administratoren" | Measure
if ($op.Count -eq 0) {
    $group = "Administrators"
} else {
    $group = "Administratoren"
}

#create a new admin username if already exist then set the password
$adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
$existing = $adsi.Children | where {$_.SchemaClassName -eq 'user' -and $_.Name -eq $Username }

if ($existing -eq $null) {

    Write-Host "Creating new local user $Username."
    & NET USER $Username $Password /add /y /expires:never
    
    Write-Host "Adding local user $Username to $group."
    & NET LOCALGROUP $group $Username /add

}
else {
    Write-Host "Setting password for existing local user $Username."
    $existing.SetPassword($Password)
}

Write-Host "Ensuring password for $Username never expires."
& WMIC USERACCOUNT WHERE "Name='$Username'" SET PasswordExpires=FALSE

# save serial number of system
$Serial = (gwmi win32_bios).SerialNumber

#save computer name
$Computer = gc env:computername

$suffix = -join("$Computer", "_", "$Serial",".", "txt");  # join two variable to use as file name

# Set the variable to the first string before the "0" character
#$CurrentUserName = $env:username.split("0")[0]
$CurrentUserName = $Computer

$local_file =  "C:\_tools\$suffix"    ### Edit if necessary to change local or server path to another location
$server_file = "\\files\SHA1_SHA256\psswd\$CurrentUserName\"

# write Password,  Computer name and serial number of system into a file
"$Computer , $Serial , $Password " | Out-File $local_file

New-Item "$server_file" -type Directory  #create a direcrtory for each machine name (username)

Copy-Item -Path "$local_file" -Destination "$server_file" -Force -PassThru  # transfer local file to file server

if(Test-Path -Path $server_file)  #remove local password file if the file already copied to the file server
{
    Remove-Item $local_file
}

#Disable inherited permission
$acl = Get-Acl $server_file
$acl.SetAccessRuleProtection($true,$true)
$acl | Set-Acl $server_file

# Remove Everyone share file access for German and English language
icacls  $server_file  /remove everyone 
icacls  $server_file  /remove jeder 

Set-ExecutionPolicy restricted -Scope LocalMachine -Force #Enable running script policy