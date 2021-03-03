Set-ExecutionPolicy unrestricted -Scope LocalMachine -Force #Disable running script policy

#check name of local admin
$op = Get-Localgroup | where-Object Name -eq "Administratoren" | Measure
if ($op.Count -eq 0) {
    $group = "Administrators"
} else {
    $group = "Administratoren"
}

$CurrentUserName = $env:username.split("0")[0]

Remove-LocalGroupMember -Group $group -Member $CurrentUserName

Set-ExecutionPolicy restricted -Scope LocalMachine -Force #Enable running script policy