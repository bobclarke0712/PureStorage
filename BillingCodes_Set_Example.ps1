# Written by Bob Clarke 
# Date: 4/8/2025
# GitHub link:    https://github.com/bobclarke0712/PureStorage
# Ver 1.0
# Script to create volumes, attach them to host Windows1 and set billing codes on them


# ------------------------*** SETUP ***-------------------------------
# 1. Run this script
# 2. Format volume with Disk Mgmt
# 3. Copy Files to new drives to show space used
# 4. Run collection script


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
# $cred = Get-Credential -Message "Enter credentials for Pure Storage Array:" # interactive MORE SECURE
$cred = New-Object System.Management.Automation.PSCredential ($username, $password) # non-interactive LESS SECURE - must be used with the two lines above where comments end in " - use get-credential instead"
Connect-Pfa2Array -Endpoint $endpoint -Credential $cred -IgnoreCertificateError

# wait for array connection before continuing
Start-Sleep (5)

# Functions
Function ConvertToGiB($size){
    $size/1024/1024/1024
}
Function ConvertToTiB($size){
     $size/1024/1024/1024/1024
}
# ---------------------------------------------------------------------------------------------


$volumes = "vol1", "vol2", "vol3", "vol4", "vol5"
$size = 10995116277760 # 10TB (Int64 in bytes)
# $size = 10737418240    # 10GB (Int64 in bytes) 
foreach ($volume in $volumes){
    $volume = new-Pfa2Volume -name $volume -Provisioned $size
}
Start-Sleep (5)

foreach ($volume in $volumes){
    New-Pfa2Connection -HostName "Windows1" -VolumeName $volume
}

Set-Pfa2VolumeTagBatch -ResourceName "vol1", "vol2", "vol3", "vol4", "vol5" -TagKey "BillingCode" -TagValue "IDOT-3465"

