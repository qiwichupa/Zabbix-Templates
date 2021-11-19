Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010

$dir = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')
$outfile = $dir + '\exchange_dbplussrv_discovery.txt'

$jsonhead = '{"data":['
$jsontail = ']}'
$jsonbody=""

$statusbody = ""
    
Get-MailboxDatabaseCopyStatus -Identity * |select Name | ForEach-Object {
    $Name = $_.Name -replace "\\", "/"
    $jsonbody += '{ "{#EDBONSRVNAME}":"' + $Name + '"},'
}

$jsonbody=($jsonbody -replace ',$')
$json = $jsonhead +  $jsonbody + $jsontail
$json | Out-File  -Encoding "Default" $outfile