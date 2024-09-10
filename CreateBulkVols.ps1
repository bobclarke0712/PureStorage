# Author Bob Clarke 
# 09/10/24
# V1
# Author is not responisible for any damages caused from the use of this script. It is provided for educational 
#    purposes only.

# A script to create volumes, hosts and connect them while setting the LUN ID from an input file

# set up defaults (set to Windows '\' or Linux|Mac '/' )
$path = "./inputfile.csv"

# Read in input file
$data = Import-Csv -Delimiter ","  -Path $path
# set variables from input file


# Create volumes
foreach ($volume in $data){
    $size = $volume.SizeGB + "GB"
    # convert to Int64
    $size = ($size / $size) * $size
    new-Pfa2Volume -name $volume.Volume -Provisioned $size
}

# Create hosts
foreach ($hostName in $data){
    New-Pfa2Host -name $hostName.Host -Personality "esxi"
}

# Associate Volumes to Hosts and set LUN ID
foreach ($assoc in $data){
    New-Pfa2Connection -VolumeName  $assoc.Volume -HostName $assoc.Host -Lun $assoc.LUNID
}








