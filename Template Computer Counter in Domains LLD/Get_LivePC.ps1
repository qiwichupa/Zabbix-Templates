Import-Module ActiveDirectory

$tempfile   = 'c:\temp\comp.csv.temp'
$resultfile = 'c:\temp\comp.csv'
 
$domains='my.domain.local'`
             ,'my.second.domain.loc'`


function DoDomain($dc)
    {
    $lastCheckDays = 30 # Max days after password update
    $filter =  (get-date).AddDays(-$lastCheckDays).ToString("dd/MM/yyyy")

    $error.clear()
    try {Get-ADDomain -server "$dc" | Out-Null } # checking dc connection
    catch {"[Connection Error] $dc" }
    if (!$error){ # if dc available...
        # Get alive computers, 
        # export to temp file without headers
        get-adcomputer `
                    -filter "Passwordlastset -gt '$filter'" `
                    -server "$dc"`
                    -properties name,CanonicalName,passwordlastset,OperatingSystem `
                    | Select name,CanonicalName,passwordlastset,OperatingSystem  `
                    | ConvertTo-Csv -NoTypeInformation `
                    | Select-Object -Skip 1 `
                    | Out-File "$tempfile" 

        #import temp file with alt headers 
        $tmp = Import-Csv -Header Name,Domain,Date,OS $tempfile

        # remove OU, leave only domain
        $tmp | ForEach-Object {$_.Domain = [regex]::replace($_.Domain,'/.*','') }

        # addig header before first domain and skip for others
        if (Test-Path "$resultfile") {
            $tmp | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Out-File "$tempfile" 
            } else {
            $tmp | ConvertTo-Csv -NoTypeInformation |  Out-File "$tempfile" 
            }

        # Append temp file to result file
        [System.IO.File]::ReadAllText("$tempfile") | Out-File "$resultfile" -Append 
        
        # remove empty lines from result file
        [System.IO.File]::ReadAllText("$resultfile")  -replace '\s+\r\n+', "`r`n" |  Out-File "$resultfile"
        Remove-Item "$tempfile"
        }
    }





Remove-Item "$resultfile" 
foreach ($domain in $domains)
{
    Write-Host "${domain}: searching for DC with AD Web Services role"
    $error.clear()
    try {
        $dc=(Get-ADDomainController -DomainName $domain -Discover -Service ADWS -NextClosestSite).HostName
    }
    catch {"[Error] ${domain}: DC not found"}
    if (!$error)
    {
        Write-Host "${domain}: DC found (${dc}). Testing connection..."
        $error.clear()
        try {Get-ADDomain -server "$dc" | Out-Null } # checking dc connection
        catch {"[Error] ${domain}: connection error." }
        if (!$error)
        {
            Write-Host "${domain}: DC $dc available. Running export function..."
            DoDomain($dc)
            Write-Host "done"
            Write-Host
        }
    }
    
}