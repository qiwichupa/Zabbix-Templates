Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010

$dir = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')
$outfile_exchange_db_counters = $dir + '\exchange_db_counters.csv'

# Инициализация переменных
$EDBs_total_EDBSize = $null
$EDBs_total_EDBFreeSpace = $null
$EDBs_total_EDBUsersCount = $null

# Создаем таблицу (объект) для хранения информации о базе
$EDBTable = New-Object system.Data.DataTable
[void]$EDBTable.Columns.Add('Name',[string]::empty.GetType() )
[void]$EDBTable.Columns.Add('EDBUsersCount',[string]::empty.GetType() )
[void]$EDBTable.Columns.Add('EDBSize',[string]::empty.GetType() )
[void]$EDBTable.Columns.Add('EDBFreeSpace',[string]::empty.GetType() )



# Получение списка баз
$DataBasesArray = (Get-MailboxDatabase |  Sort-Object Name)


# Подсчет места, количества логов и юзеров по базам
$DataBasesArray | foreach {$DBName = $_
                           $DB = Get-MailboxDatabase $DBName -Status
                           $DatabaseUsersCount = (Get-Mailbox -resultsize unlimited -Database $DBName).Count
                                                          
                           $DatabaseSize = $DB.DatabaseSize
                           $DatabaseFreeSpace = $DB.AvailableNewMailboxSpace
                           
                           # Добавление информации о базе в таблицу
                           $newRow = $EDBTable.NewRow()
                           $newRow.Name = $DBName
                           $newRow.EDBUsersCount = $DatabaseUsersCount
                           $newRow.EDBSize = $DatabaseSize.ToBytes()
                           $newRow.EDBFreeSpace = $DatabaseFreeSpace.ToBytes()
                           [void]$EDBTable.Rows.Add( $newRow )
                           
                           # Подсчет итоговых показателей
                           $EDBs_total_EDBSize += $DatabaseSize.ToBytes()
                           $EDBs_total_EDBFreeSpace += $DatabaseFreeSpace.ToBytes()
                           $EDBs_total_EDBUsersCount += $DatabaseUsersCount
                          }

# Добавление итоговых показателей в таблицу
$newRow = $EDBTable.NewRow()
$newRow.Name = 'EDBTotalCounts'
$newRow.EDBUsersCount = $EDBs_total_EDBUsersCount
$newRow.EDBSize = $EDBs_total_EDBSize
$newRow.EDBFreeSpace = $EDBs_total_EDBFreeSpace
[void]$EDBTable.Rows.Add( $newRow )

                          
# Output
$EDBTable | ConvertTo-Csv | Out-File $outfile_exchange_db_counters
#[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::WriteLine( $($d=[System.Environment]::GetEnvironmentVariable('TEMP','Machine');  $f=$d+'\exchange_db_counters.csv'; (Get-Content $f) | ConvertFrom-Csv | Where-Object {$_.Name -eq 'mdb5'}).EDBUsersCount )

 
