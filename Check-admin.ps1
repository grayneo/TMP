Set-ExecutionPolicy unrestricted -Scope LocalMachine -Force #Disable running script policy

$user = "byrnes"  ### Please type the username you want to check if member of Administrator group or NOT

$Computer = gc env:computername
$suffix = -join("$Computer",".", "txt");  # join variable to use as file name
$local_file =  "C:\_tools\$suffix"
$server_file = "\\files\SHA1_SHA256\report\$Computer\"

#check name of local admin
$op = Get-Localgroup | where-Object Name -eq "Administratoren" | Measure
if ($op.Count -eq 0) {
    $group = "Administrators"
} else {
    $group = "Administratoren"
}

$groupObj =[ADSI]"WinNT://./$group,group" 
$membersObj = @($groupObj.psbase.Invoke("Members")) 
$members = ($membersObj | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)})
If ($members -contains $user) {
    Remove-LocalGroupMember -Group $group -Member $user                 #if the given username is a member of administrator group, then it will remove it
    $user, "Removed from Administrator group" | Out-File $local_file
 } Else {
    $user, "NOT exist in Administrator group" | Out-File $local_file    #if given username NOT a member of administrator group will report it into a file
}

#Check if IT_Admin already created and exist
$groupObj =[ADSI]"WinNT://./$group,group" 
$membersObj = @($groupObj.psbase.Invoke("Members")) 
$members = ($membersObj | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)})
If ($members -contains "IT_Admin") {
    Remove-LocalGroupMember -Group $group -Member $user                    
    "IT_Admin", "Exist in Administrator group" | Out-File $local_file -Append
 } Else {
    "IT_Admin", "NOT exist in $group group" | Out-File $local_file  -Append    
}

New-Item "$server_file" -type Directory  #create a direcrtory for given username

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