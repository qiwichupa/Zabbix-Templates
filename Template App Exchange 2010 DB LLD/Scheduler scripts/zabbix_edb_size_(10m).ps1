Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010

$dir = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')
$outfile_exchange_db_counters = $dir + '\exchange_db_counters.csv'

# ������������� ����������
$EDBs_total_EDBSize = $null
$EDBs_total_EDBFreeSpace = $null
$EDBs_total_EDBUsersCount = $null

# ������� ������� (������) ��� �������� ���������� � ����
$EDBTable = New-Object system.Data.DataTable
[void]$EDBTable.Columns.Add('Name',[string]::empty.GetType() )
[void]$EDBTable.Columns.Add('EDBUsersCount',[string]::empty.GetType() )
[void]$EDBTable.Columns.Add('EDBSize',[string]::empty.GetType() )
[void]$EDBTable.Columns.Add('EDBFreeSpace',[string]::empty.GetType() )



# ��������� ������ ���
$DataBasesArray = (Get-MailboxDatabase |  Sort-Object Name)


# ������� �����, ���������� ����� � ������ �� �����
$DataBasesArray | foreach {$DBName = $_
                           $DB = Get-MailboxDatabase $DBName -Status
                           $DatabaseUsersCount = (Get-Mailbox -resultsize unlimited -Database $DBName).Count
                                                          
                           $DatabaseSize = $DB.DatabaseSize
                           $DatabaseFreeSpace = $DB.AvailableNewMailboxSpace
                           
                           # ���������� ���������� � ���� � �������
                           $newRow = $EDBTable.NewRow()
                           $newRow.Name = $DBName
                           $newRow.EDBUsersCount = $DatabaseUsersCount
                           $newRow.EDBSize = $DatabaseSize.ToBytes()
                           $newRow.EDBFreeSpace = $DatabaseFreeSpace.ToBytes()
                           [void]$EDBTable.Rows.Add( $newRow )
                           
                           # ������� �������� �����������
                           $EDBs_total_EDBSize += $DatabaseSize.ToBytes()
                           $EDBs_total_EDBFreeSpace += $DatabaseFreeSpace.ToBytes()
                           $EDBs_total_EDBUsersCount += $DatabaseUsersCount
                          }

# ���������� �������� ����������� � �������
$newRow = $EDBTable.NewRow()
$newRow.Name = 'EDBTotalCounts'
$newRow.EDBUsersCount = $EDBs_total_EDBUsersCount
$newRow.EDBSize = $EDBs_total_EDBSize
$newRow.EDBFreeSpace = $EDBs_total_EDBFreeSpace
[void]$EDBTable.Rows.Add( $newRow )

                          
# Output
$EDBTable | ConvertTo-Csv | Out-File $outfile_exchange_db_counters
#[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::WriteLine( $($d=[System.Environment]::GetEnvironmentVariable('TEMP','Machine');  $f=$d+'\exchange_db_counters.csv'; (Get-Content $f) | ConvertFrom-Csv | Where-Object {$_.Name -eq 'mdb5'}).EDBUsersCount )

 
