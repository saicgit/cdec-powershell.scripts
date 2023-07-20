# Create your credentials with these commands
#$credential = Get-Credential;
#$credential | Export-CliXml -Path 'C:\Tools\cred.xml';

# Configure your Source Domain configuration
$sourceDomainNetBIOS       = 'cdhs';
$sourceDomainFQDN          = 'cdhs.state.co.us';
$sourceDomainDN            = 'DC=cdhs,DC=state,DC=co,DC=us';
$sourceDomainCredential    = Import-CliXml -Path 'C:\Tools\ADMTSyncFiles\CDHS-Cred.xml';

# Configure your Target Domain configuration
$targetDomainNetBIOS       = 'cdec';
$targetDomainFQDN          = 'cdec.colorado.lcl';
$targetDomainDN            = 'DC=cdec,DC=colorado,DC=lcl';
$targetDomainCredential    = Import-CliXml -Path 'C:\Tools\ADMTSyncFiles\CDEC-Cred.xml';
#$syncGroup                 = 'CDEC_HumanResources';# Get Source Domain hashes


# Get Source Domain hashes
$hashes = Get-ADReplAccount -All -NamingContext $sourceDomainDN -Server $sourceDomainFQDN -Credential $sourceDomainCredential;

# The group of users to sync passwords for
$users = Get-ADUser -Filter * -Properties * -SearchBase 'OU=CDEC,DC=cdec,DC=colorado,DC=lcl' -server $targetDomainFQDN -Credential $targetDomainCredential;

# Loop through these users
foreach ($user in $users)
{
    # Get the hash of the user in the hashes collection
    $currentUserHash = $hashes | ? {$_.saMAccountName -eq $user.SamAccountName};
    
    # Convert hash to string
    $NTHash = ([System.BitConverter]::ToString($currentUserHash.NTHash) -replace '-','').ToLower();
    
    # Set target domain password to the source domain hash
    Write-Host "Updating password for"$user.SamAccountName
    Set-SamAccountPasswordHash -SamAccountName $user.SamAccountName -Domain $targetDomainNetBIOS -NTHash $NTHash -Server $targetDomainFQDN -Credential $targetDomainCredential;
}