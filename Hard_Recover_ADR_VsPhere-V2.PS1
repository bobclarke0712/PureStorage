#####
# **********************************************************Disclaimer****************************************************************************************
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This script is based on the API V1 script and has been updated to work with the Purity V2 API.
# Link to V1 script can be found here: https://github.com/PureStorage-OpenConnect/VMware-Scripts/blob/master/HardRecoverActiveDRPodVsphere.ps1
# Work in progress
# Ned's repo: https://github.com/nedegan/PureStorage
# Author Ned Egan negan@purestorage.com) -/5/1/2024-
# Co-Author Bob Clarke (bclarke@purestorage.com)
#####

$vcenter  = "VC1.ne-lab.local"
$vcuser   = "administrator@puremagic.local"
$vcpass   = "P@ssword1"
$endpoint = "nelab-flasharray2.ne-lab.local"
$podname  = "DRPod-Target"
$clusterName  = "Prod"

# Below $dsname needs to be the source vcenter's datastore name
$dsname   = "Source-VolA"
$cred = Get-Credential -Message "Enter credentials for Pure Array"
# imports
Import-Module PureStoragePowerShellSDK2
Import-Module vmware.powercli
# Connect to vCenter
Connect-VIserver -Force $vcenter -user $vcuser -password $vcpass
# Promote the DR Site Pod

# From Jase: connect to target pod and promote it
Connect-Pfa2Array -IgnoreCertificateError -Endpoint $endpoint -Credential $cred
$ADRPOD = Get-Pfa2Pod -Name $podname
Update-Pfa2Pod -Name $ADRPOD.Name -RequestedPromotionState "promoted" #promote the pod
#
# Wait for the DR Site Pod to be promoted
$podstatus = "purepod list $podname"
do {
    Write-Host "Waiting for Pod Promotion"
    Start-Sleep -Milliseconds 500
    $test = Invoke-Pfa2CLICommand -EndPoint $endpoint -CommandText $podstatus -Credential $cred
} while ($test | select-string -pattern "promoting")
$VMHost = Get-VMhost | Select-Object -First 1
$EsxCli = Get-EsxCli -VMHost $VMhost -V2
# Get the cluster
$Cluster = Get-Cluster -name $clusterName
# Rescan storage on all hosts in the cluster
$Cluster | Get-VMHost | ForEach-Object {
    $_ | Get-VMHostStorage -RescanAllHba
}
# Added to allow rescan to complete, test and adjust based on your cluster's response time
Write-Host "Waiting for rescan"
Start-Sleep -Milliseconds 5000

$Snaps = $esxcli.storage.vmfs.snapshot.list.invoke()
if ($Snaps.Count -gt 0) {
    Foreach ($Snap in $Snaps) {
        Write-Host "Snapshot Found: $($Snap.VolumeName)"
        $esxcli.storage.vmfs.snapshot.resignature.invoke(@{volumelabel=$($Snap.VolumeName)})
    }
} else {
    Write-Host "No Snapshot volumes found"
    
}
# Added because rename did not take effect right away ##
Write-Host "Waiting for snapshots to animate"
Start-Sleep -Milliseconds 3000
# convert the short $dsname from above to the long "snap.name"
$Datastore = Get-Datastore
foreach($Datastore in $Datastore) {
    if ((Get-Datastore -name $Datastore) -like "*$dsname*"){$dsname = $Datastore.name}
}
$VMFolder  = Get-Folder -Type VM -Name "Discovered virtual machine"
foreach($Datastore in $Datastore) {
    # Searches for .VMX Files in datastore variable
    $ds = Get-Datastore -Name $Datastore | %{Get-View $_.Id}
    $SearchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
    $SearchSpec.matchpattern = "*.vmx"
    $dsBrowser = Get-View $ds.browser
    $DatastorePath = "[" + $ds.Summary.Name + "]"
    # Find all .VMX file paths in Datastore variable and filters out .snapshot
    $SearchResults = $dsBrowser.SearchDatastoreSubFolders($DatastorePath,$SearchSpec) | Where-Object {$_.FolderPath -notmatch ".snapshot"} | %{$_.FolderPath + $_.File.Path}
    # Register all .VMX files with vCenter
    foreach($SearchResult in $SearchResults) {
    New-VM -VMFilePath $SearchResult -VMHost $VMHost -Location $VMFolder -RunAsync -ErrorAction SilentlyContinue
   }
}

