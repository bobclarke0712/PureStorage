# Written by Bob Clarke 
# Date: 10-12-2023
# Ver1
# Added several commonly used code snippets that can be put together to more easily write your own automations


# ------------------------*** SETUP ***-------------------------------

# Set up default variables if required
$username = "pureuser" # not recomended unless script MUST be non interactive - use get-credential instead
$pass = "pureuser" # not recomended unless script MUST be non interactive - use get-credential instead
$password = ConvertTo-SecureString $pass -AsPlainText -Force # not recomended unless script MUST be non interactive - use get-credential instead
$endpoint = "flasharray.testdrive.local"


# connect to array - always required. Use ONE of the next two lines based on your needs
$Cred = New-Object System.Management.Automation.PSCredential ($username, $password) # non-interactive LESS SECURE - must be used with the two lines above where comments end in " - use get-credential instead"
$cred = Get-Credential -Message "Enter credentials for Pure Storage Array:" # interactive MORE SECURE
Connect-Pfa2Array -Endpoint $endpoint -Credential $cred -IgnoreCertificateError


# Check to see if Pure Storage SDK is installed, if not, install it. - good to include this code
if(-not (Get-Module PureStoragePowerShellSDK2 -ListAvailable)){
    Install-Module PureStoragePowerShellSDK2 -Scope CurrentUser -Force
    }


# Import the Pure Storage PowerShellSDK2 - always required
Import-Module PureStoragePowerShellSDK2

# ------------------------*** EXAMPLES ***-------------------------------


######################################## Volumes #################################################
# Create 10 volumes
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9"
$size = 10995116277760 # 10TB (Int64 in bytes)
$size = 10737418240    # 10GB (Int64 in bytes) 
foreach ($volume in $volumes){
    new-Pfa2Volume -name $volume -Provisioned $size
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
######################################## SnapShots #################################################
# Create a snapshot
$volume = "BobVol"
New-Pfa2VolumeSnapshot -SourceName $volume -Suffix "FromScript"

# Destroy Snapshot
$volume = $volume + ".FromScript"
Update-Pfa2VolumeSnapshot -Name $volume  -Destroyed:$true

# Eradicate Snapshot
$volume = $volume + ".FromScript"
Remove-Pfa2VolumeSnapshot -Name $volume -Eradicate -Confirm:$false

# Create a snapshot on multiple volumes
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9" 
foreach ($volume in $volumes){
    New-Pfa2VolumeSnapshot -SourceName $volume -Suffix "FromScript"
}

# Destroy SnapShots on multiple volumes
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9" 
foreach ($volume in $volumes){
    $volumename = $volume + ".FromScript"
    Update-Pfa2VolumeSnapshot -Name $volumename  -Destroyed:$True 
}

# Eradicate SnapShots on multiple volumes
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9" 
foreach ($volume in $volumes){
    $volumename = $volume + ".FromScript"
    Remove-Pfa2VolumeSnapshot -Name $volumename  -Eradicate -Confirm:$false 
}

########################################## Pods ###############################################
# Create 10 pods
$pods = "pod0","pod1", "pod2", "pod3", "pod4", "pod5", "pod6", "pod7", "pod8", "pod9"
foreach ($pod in $pods){
    new-Pfa2pod -name $pod
}

# Destroy 10 pods
$pods = "pod0","pod1", "pod2", "pod3", "pod4", "pod5", "pod6", "pod7", "pod8", "pod9"
foreach ($pod in $pods){
    Update-Pfa2Pod -name $pod -DestroyContents $True -Destroyed $True
}

# Eradicate the pods
foreach ($pod in $pods){
Remove-Pfa2pod -name $pod -Eradicate -eradicateContents:$true -confirm:$false
}

# Promote a pod
$pod = "pod1"
Update-Pfa2Pod -Name $pod -RequestedPromotionState "promoted"
Get-Pfa2Pod -Name $pod
do {
    Write-Host "Waiting for $Pod Promotion"
    Start-Sleep -Milliseconds 500
    $test = Get-Pfa2Pod -Name $pod
} while ($test.PromotionStatus -ne "promoted")

# Demote a pod
$pod = "pod1"
Update-Pfa2Pod -Name $pod -RequestedPromotionState "demoted"
Get-Pfa2Pod -Name $pod
do {
    Write-Host "Waiting for " $pod " Demotion"
    Start-Sleep -Milliseconds 500
    $test = Get-Pfa2Pod -Name $pod
} while ($test.PromotionStatus -ne "demoted")

# Flip promoted status (if promoted-demote, if demoted-promote)
$pod = "pod1"
if (((Get-Pfa2Pod -Name $pod).PromotionStatus) -eq "promoted"){
    Update-Pfa2Pod -Name $pod -RequestedPromotionState "demoted"
    do {
        Write-Host "Waiting for " $pod " Demotion"
        Start-Sleep -Milliseconds 500
        $test = Get-Pfa2Pod -Name $pod
    } while ($test.PromotionStatus -ne "demoted")
}else{
    Update-Pfa2Pod -Name $pod -RequestedPromotionState "promoted"
        do {
            Write-Host "Waiting for $Pod Promotion"
            Start-Sleep -Milliseconds 500
            $test = Get-Pfa2Pod -Name $pod
        } while ($test.PromotionStatus -ne "promoted")
    }

########################################## Protection Groups ###############################################
# Create 10 protection groups
$pgs = "pg0","pg1", "pg2", "pg3", "pg4", "pg5", "pg6", "pg7", "pg8", "pg9"
foreach ($pg in $pgs){
    New-Pfa2ProtectionGroup -name $pg
}

# Destroy 10 protection groups
$pgs = "pg0","pg1", "pg2", "pg3", "pg4", "pg5", "pg6", "pg7", "pg8", "pg9"
foreach ($pg in $pgs){
    Update-Pfa2ProtectionGroup -name $pg -Destroyed:$True
}

# Eradicate 10 protection groups
$pgs = "pg0","pg1", "pg2", "pg3", "pg4", "pg5", "pg6", "pg7", "pg8", "pg9"
foreach ($pg in $pgs){
    Remove-Pfa2ProtectionGroup -name $pg -Eradicate -Confirm:$false
}

# Add 10 existing volumes into a new ProtectionGroup
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9" # These volumes must exist, use the code above to create them if they don't.
New-Pfa2ProtectionGroup -name "PG-Example" # to add existing volumes to an existing Protection Group simply use the command Get-Pfa2ProtectionGroup in this line instead. 
foreach ($volume in $volumes){
    New-Pfa2ProtectionGroupVolume -GroupName "PG-Example" -MemberName $volume
}

# Remove 10 existing volumes from a ProtectionGroup
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9" # These volumes must exist, use the code above to create them if they don't.
foreach ($volume in $volumes){
    Remove-Pfa2ProtectionGroupVolume -GroupName "PG-Example" -MemberName $volume
}

######################################## Hosts #################################################
# Create 10 hosts
$PureHosts = "host0","host1", "host2", "host3", "host4", "host5", "host6", "host7", "host8", "host9"
foreach ($PureHost in $PureHosts){
    New-Pfa2Host -name $PureHost -Personality "esxi" -ChapHostUser "pureuser" -ChapHostPassword "pureuser"
}

# Delete 10 hosts -  Destroy and Eradicate functionality doesn't exist on hosts
$PureHosts = "host0","host1", "host2", "host3", "host4", "host5", "host6", "host7", "host8", "host9"
foreach ($PureHost in $PureHosts){
    Remove-Pfa2Host -name $PureHost 
}

######################################## SafeMode #################################################
# Check to see if SafeMode is enabled
# For PG based SafeMode
(Get-Pfa2ProtectionGroup -name "pgroup-auto").retentionlock
# Returns "ratcheted" or "unlocked"
# For array wide Safemode
# TBD

########################################## Find Commands###############################################
get-command -module PureStoragePowerShellSDK2 | select-string -pattern "pod"   # Useful for finding commands relating to certain objects on the array