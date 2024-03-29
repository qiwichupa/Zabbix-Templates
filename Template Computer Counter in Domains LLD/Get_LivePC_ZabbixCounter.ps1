# .\Get_LivePC_ZabbixCounter.ps1 -domain my.domain.local -- for workstations count
# .\Get_LivePC_ZabbixCounter.ps1 -lld $True" -- for domain-LLD
# .\Get_LivePC_ZabbixCounter.ps1 -allDomains $True" -- for workstations count in all domains

#######
Param(
    [string]$winwrkst,
    [string]$winsrv,
    [string]$lin,
    [string]$otheros,
    [string]$domain,
    [string]$allDomains,
    [string]$lld
    )
#######

$pcfile = 'c:\temp\comp.csv'

$pclist = Import-Csv $pcfile


#$srwList = $pclist | where  {$_.OS -like "*Сервер*" -or $_.OS -like "*Server*" }

if($lld)
{
    $domains = $pclist |   select Domain | where {$_.Domain -ne $null } |   Get-Unique -asstring
    Write-Host "{"
    Write-Host "`"data`":[`n"
    $counter = 1
    $domains |  ForEach-Object {
            $CurrentDomain = $_.Domain
            if ($counter -lt $domains.Count){
                    $line = "{`"{#DOMAIN}`" : `"" + $CurrentDomain + "`"},"
            } else {
                    $line = "{`"{#DOMAIN}`" : `"" + $CurrentDomain + "`"}"
                }    

            Write-Host $line
            $counter++
            }
    Write-Host " ]"
    Write-Host "}"
}

if ($domain) 
{
    $domains = $pclist |   select Domain | where {$_.Domain -ne $null } |   Get-Unique -asstring
    if ($winwrkst) {$pclistfiltered = $pclist | where  {$_.OS -notlike "*Сервер*" -and $_.OS -notlike "*Server*" -and $_.OS -like "*windows*"}}
    if ($winsrv)   {$pclistfiltered = $pclist | where  {$_.OS -like "*Сервер*" -or $_.OS -like "*Server*"}}
    if ($lin)      {$pclistfiltered = $pclist | where  {$_.OS -like "*linux*"}}
    if ($otheros)  {$pclistfiltered = $pclist | where  {$_.OS -notlike "*windows*" -and $_.OS -notlike "*linux*"}}
    $domains | where {$_.Domain -eq $domain} |  ForEach-Object {
            $CurrentDomain = $_.Domain
            $pcsInDomain = ($pclistfiltered  | where { $_.Domain -eq $CurrentDomain }  |  Measure-Object).Count
            Write-Host $pcsInDomain
            }
    
}

if ($allDomains) 
{
    $domains = $pclist |   select Domain | where {$_.Domain -ne $null } |   Get-Unique -asstring
    if ($winwrkst) {$pclistfiltered = $pclist | where  {$_.OS -notlike "*Сервер*" -and $_.OS -notlike "*Server*" -and $_.OS -like "*windows*"}}
    if ($winsrv)   {$pclistfiltered = $pclist | where  {$_.OS -like "*Сервер*" -or $_.OS -like "*Server*"}}
    if ($lin)      {$pclistfiltered = $pclist | where  {$_.OS -like "*linux*"}}
    if ($otheros)  {$pclistfiltered = $pclist | where  {$_.OS -notlike "*windows*" -and $_.OS -notlike "*linux*"}}
    $pcsInDomain = 0
    
    $domains | ForEach-Object {
            $CurrentDomain = $_.Domain
            $pcsInDomain +=  ($pclistfiltered  | where { $_.Domain -eq $CurrentDomain }  |  Measure-Object).Count
            }

    Write-Host $pcsInDomain
}