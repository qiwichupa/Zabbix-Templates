Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010

$dir = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')
$outfile_exchange_db_counters = $dir + '\exchange_db_status.csv'


# ������� ������� (������) ��� �������� ���������� � ����
$EDBTable = New-Object system.Data.DataTable
[void]$EDBTable.Columns.Add('Name',[string]::empty.GetType() )
[void]$EDBTable.Columns.Add('Status',[string]::empty.GetType() )




# ��������� ������ ���
Get-MailboxDatabaseCopyStatus -Identity * |  Sort-Object Name | ForEach-Object {
                           $Name = $_.Name -replace "\\", "/"
                           
                           # ���������� ���������� � ���� � �������
                           $newRow = $EDBTable.NewRow()
                           $newRow.Name = $Name
                           $newRow.Status = $_.Status.value__
                           [void]$EDBTable.Rows.Add( $newRow )
}

                         
# Output
$EDBTable | ConvertTo-Csv | Out-File $outfile_exchange_db_counters

 
