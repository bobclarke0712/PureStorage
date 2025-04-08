# Written by Bob Clarke 
# Date: 4/8/2025
# GitHub link:    https://github.com/bobclarke0712/PureStorage
# Ver 1.0
# Use to read in tags and volume sizes that were set in the BillingCode_Set_Examples.ps1 script to feed into a reporting or billing system.



# ------------------------*** SETUP ***-------------------------------
# 1. Prerequsite: Run BillingCode_Set_Examples.ps1 script to create volumes, connect to Windows1, and set billing codes. 
# 2. Run this script to report on billing codes and usage


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

# wait for array connection before continuing, if connection takes longer than 5 seconds re-run code from here to the bottom. 
Start-Sleep (5)

# Functions
Function ConvertToGiB($size){
    $size/1024/1024/1024
}
Function ConvertToTiB($size){
     $size/1024/1024/1024/1024
}
# ---------------------------------------------------------------------------------------------

# create custom volumeBilling object
$volumeBilling = New-Object -TypeName PSObject
$volumeBilling | Add-Member -MemberType NoteProperty -Name name -Value null
$volumeBilling | Add-Member -MemberType NoteProperty -Name billingCode -Value null
$volumeBilling | Add-Member -MemberType NoteProperty -Name provisionedSpaceGiB -Value null
$volumeBilling | Add-Member -MemberType NoteProperty -Name usedSpaceGiB -Value null


Foreach ($volume in get-pfa2volume){
    $volumeBilling.name = $volume.name
    $billcode = Get-Pfa2VolumeTag -ResourceName $volume.name
    $volumeBilling.billingCode = $billcode.value
    $volumeBilling.usedSpaceGib = ConvertToGiB($volume.space.virtual)
    $volumeBilling.provisionedSpaceGiB = ConvertToGiB($Volume.Provisioned)
    $volumeBilling
}

# Optionally use an export-csv cmdlet to format the output for upload to your internal billing system. 

