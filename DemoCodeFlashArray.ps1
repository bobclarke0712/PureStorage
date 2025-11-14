# Written by Bob Clarke 
# Date: 10-12-2023
# GitHub link:    https://github.com/bobclarke0712/PureStorage
# Ver 1.2
# Added several commonly used code snippets that can be put together to more easily write your own automations
# Added volume tagging examples
# Link to using Fusion with PowerShell: https://github.com/PureStorage-OpenConnect/fusion-example-code/blob/main/powershell/Connect-FAApi.ps1
# ------------------------*** SETUP ***-------------------------------


# Check to see if Pure Storage SDK is installed, if not, install it. - good to include this code to be sure.
if(-not (Get-Module PureStoragePowerShellSDK2 -ListAvailable)){
    Install-Module PureStoragePowerShellSDK2 -Scope CurrentUser -Force
    }


# Import the Pure Storage PowerShellSDK2 - always required
Import-Module PureStoragePowerShellSDK2


# Set up default variables if required

$username = "pureuser" # not recomended unless script MUST be non interactive - use get-credential instead
$pass = "pureuser" # not recomended unless script MUST be non interactive - use get-credential instead
$password = ConvertTo-SecureString $pass -AsPlainText -Force # not recomended unless script MUST be non interactive - use get-credential instead
$endpoint = "flasharray1.testdrive.local"


# connect to array - always required. Use ONE of the next two lines based on your needs
$cred = Get-Credential -Message "Enter credentials for Pure Storage Array:" # interactive MORE SECURE
$cred = New-Object System.Management.Automation.PSCredential ($username, $password) # non-interactive LESS SECURE - must be used with the two lines above where comments end in " - use get-credential instead"

Connect-Pfa2Array -Endpoint $endpoint -Credential $cred -IgnoreCertificateError


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

######################################## Hosts #################################################
# Create 10 hosts
$PureHosts = "host0","host1", "host2", "host3", "host4", "host5", "host6", "host7", "host8", "host9"
foreach ($PureHost in $PureHosts){
    New-Pfa2Host -name $PureHost -Personality "esxi" # you can use embedded credentials by adding: -ChapHostUser "pureuser" -ChapHostPassword "pureuser"
}

# Delete 10 hosts -  Destroy and Eradicate functionality don't exist on hosts
$PureHosts = "host0","host1", "host2", "host3", "host4", "host5", "host6", "host7", "host8", "host9"
foreach ($PureHost in $PureHosts){
    Remove-Pfa2Host -name $PureHost 
}

######################################## Host-Volume associations ##################################

# See associations
Get-Pfa2Connection 

# connect volume to host
New-Pfa2Connection -VolumeNames 'vol0' -HostNames 'host0'

# Connect volume to host and set LUN ID
New-Pfa2Connection -VolumeName "YourVolumeName" -HostNames "YourHostName" -Lun 10

# Remove volume from host
Remove-Pfa2Connection -Array $FlashArray -VolumeNames 'vol0' -HostNames 'host0'



######################################## SnapShots #################################################
# Create a snapshot
$volume = "WindowsVol1"
$suffix = ("FromScript-" + (get-date -format yy-MM-dd))
New-Pfa2VolumeSnapshot -SourceName $volume -Suffix $suffix

# Destroy Snapshot
$DestroyVolume = $volume + "." + $suffix 
Update-Pfa2VolumeSnapshot -Name $DestroyVolume  -Destroyed:$true

# Eradicate Snapshot
$EradicateVolume = $volume + "." + $suffix 
Remove-Pfa2VolumeSnapshot -Name $EradicateVolume -Eradicate -Confirm:$false

# Create a snapshot on multiple volumes
$volumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9" 
$suffix = ("FromScript-" + (get-date -format yy-MM-dd))
foreach ($volume in $volumes){
    New-Pfa2VolumeSnapshot -SourceName $volume -Suffix $suffix
}

# Destroy SnapShots on multiple volumes
$DestroyVolumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9" 
$suffix = ("FromScript-" + (get-date -format yy-MM-dd))
foreach ($volume in $DestroyVolumes){
    $volumename = $volume + "." + $suffix 
    Update-Pfa2VolumeSnapshot -Name $volumename  -Destroyed:$True 
}

# Eradicate SnapShots on multiple volumes
$EradicateVolumes = "vol0","vol1", "vol2", "vol3", "vol4", "vol5", "vol6", "vol7", "vol8", "vol9" 
$suffix = ("FromScript-" + (get-date -format yy-MM-dd))
foreach ($volume in $EradicateVolumes){
    $volumename = $volume + "." + $suffix 
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
$pods = "pod0","pod1", "pod2", "pod3", "pod4", "pod5", "pod6", "pod7", "pod8", "pod9"
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

# Tagging Volumes
# Set tags on a single volume
Set-Pfa2VolumeTagBatch -ResourceName "VMwareVol1" -TagKey "BillingCode" -TagValue "IDOT-3465"

# Set tags on multiple volumes
Set-Pfa2VolumeTagBatch -ResourceName "VMwareVol1", "WindowsVol1" -TagKey "BillingCode" -TagValue "IDOT-3465"

# Set multiple tags on multiple volumes
Set-Pfa2VolumeTagBatch -ResourceName "VMwareVol1", "WindowsVol1" -TagKey "BillingCode", "Department" -TagValue "IDOT-3465", "Road Department"


# Retrieve tag from volume by name
Get-Pfa2VolumeTag -ResourceName "VMwareVol1"
# or to just display a single code
$VolTags = Get-Pfa2VolumeTag -ResourceName "VMwareVol1"
$VolTags.value
# Display keys and values of all tags
foreach ($obj in $voltags) {
    write-output ($obj.key + " = " + $obj.value)
}


######################################## SafeMode #################################################
# Check to see if SafeMode is enabled
# For PG based SafeMode

# Ensure pgroup-auto exists before running this code

$pg = Get-Pfa2ProtectionGroup -name "pgroup-auto"
If ($pg.RetentionLock -eq "ratcheted"){
    Write-Host $pg.name  "is ratcheted"
} Else{
    Write-Host $pg.name  "is NOT ratcheted"
}



# ######################################## Array Wide Safemode ########################################
# TBD
# Returns "ratcheted", "unlocked"

########################################## Find Commands###############################################
get-command -module PureStoragePowerShellSDK2 | select-string -pattern "pod"   # Useful for finding commands relating to certain objects on the array