This template automatically detects Windows domains (AD web services required) and counts computers (Win servers, Win workstations, Linux stations).

## setup

Edit Get_LivePC.ps1 and add it to the task scheduler - it will create a list of domain computers.

Place Get_LivePC_ZabbixCounter.ps1 according to the path from domain_disc.conf.

Add the contents of domain_disc.conf to the Zabbix Agent configuration.
