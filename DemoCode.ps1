# Written by Bob Clarke 
# Date: 10-12-2023
# Ver1
# Added several commonly used code snippets that can be put together to more easily write your own automations


# Set up default variables if required
$username = "pureuser" # not recomended unless script MUST be non interactive - use get-credential instead
$password = ConvertTo-SecureString "pureuser" -AsPlainText -Force # not recomended unless script MUST be non interactive - use get-credential instead
$endpoint = "flasharray.testdrive.local"


# connect to array - always required. Use one of the next two lines based on your needs
$Cred = New-Object System.Management.Automation.PSCredential ($username, $password) # non-interactive LESS SECURE
$cred = Get-Credential -Message "Enter credentials for Pure Storage Array:" # interactive MORE SECURE
Connect-Pfa2Array -Endpoint $endpoint -Credential $cred


# Check to see if Pure Storage SDK is installed, if not install it.
if(-not (Get-Module PureStoragePowerShellSDK2 -ListAvailable)){
    Install-Module PureStoragePowerShellSDK2 -Scope CurrentUser -Force
    }
# Import the Pure Storage PowerShellSDK2 - always required
Import-Module PureStoragePowerShellSDK2



# Create 10 volumes
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9"
$size = 10995116277760 # 10TB (Int64 in bytes)
foreach ($volume in $volumes){
    new-Pfa2Volume -name $volume -Provisioned $size
}


# Create 10 pods
$pods = "pod0","pod1", "pod2", "pod3", "pod4", "pod5", "pod6", "pod7", "pod8", "pod9"
foreach ($pod in $pods){
    new-Pfa2pod -name $pod
}



# destroy 10 volumes
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9"
foreach ($volume in $volumes){
    Update-Pfa2Volume  -Destroyed $True -Name $volume
}

# Eradicate 10 volumes
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9"
foreach ($volume in $volumes){
    Remove-Pfa2Volume -Name $volume -Eradicate -Confirm:$false
}

# Destroy 10 pods
$pods = "pod0","pod1", "pod2", "pod3", "pod4", "pod5", "pod6", "pod7", "pod8", "pod9"

# Check to see if SafeMode is enabled
#TODO

# Destroy the pods
foreach ($pod in $pods){
    Update-Pfa2Pod -name $pod -DestroyContents $True -Destroyed $True
}


# Eradicate the pods
foreach ($pod in $pods){
Remove-Pfa2pod -name $pod -Eradicate -eradicateContents:$true -confirm:$false
}

get-command -module PureStoragePowerShellSDK2 | select-string -pattern "pod"   # Useful for finding commands relating to certain objects on the array