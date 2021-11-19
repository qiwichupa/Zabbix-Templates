Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010

$dir = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')
$outfile = $dir + '\exchange_db_discovery.txt'

$jsonhead = '{"data":['
$jsontail = ']}'
$jsonbody=""

$statusbody = ""

Get-MailboxDatabase | select Name | foreach {
           $base = $_.Name
           $jsonbody  += '{ "{#EDBNAME}":"' + $base + '"},'
}

$jsonbody=($jsonbody -replace ',$')
$json = $jsonhead +  $jsonbody + $jsontail

$json | Out-File  -Encoding "Default" $outfile
