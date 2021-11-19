Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010

$dir = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')
$outfile_exchange_db_counters = $dir + '\exchange_db_status.csv'


# Создаем таблицу (объект) для хранения информации о базе
$EDBTable = New-Object system.Data.DataTable
[void]$EDBTable.Columns.Add('Name',[string]::empty.GetType() )
[void]$EDBTable.Columns.Add('Status',[string]::empty.GetType() )




# Получение списка баз
Get-MailboxDatabaseCopyStatus -Identity * |  Sort-Object Name | ForEach-Object {
                           $Name = $_.Name -replace "\\", "/"
                           
                           # Добавление информации о базе в таблицу
                           $newRow = $EDBTable.NewRow()
                           $newRow.Name = $Name
                           $newRow.Status = $_.Status.value__
                           [void]$EDBTable.Rows.Add( $newRow )
}

                         
# Output
$EDBTable | ConvertTo-Csv | Out-File $outfile_exchange_db_counters

 
