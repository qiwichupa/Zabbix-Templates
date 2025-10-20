#!/bin/bash
# Скрипт для сбора информации о PV/VG/Thinpool LVM и отправки данных в Zabbix.
# Он выполняет автоматическое обнаружение PV/VG/Thinpool и собирает данные о них, такие как количество физических
# и логических томов, размер, свободное и использованное пространство.
#
# Использование с zabbix_sender:
# ./script.sh                       - отправляет все данные в Zabbix.
#
# Использование с агентом:
# ./script.sh vg_discovery          - выполняет только обнаружение VG.
# ./script.sh vg_info <VG_NAME>     - получает информацию о конкретной VG.
#
# ./script.sh pv_discovery          - выполняет только обнаружение PV.
# ./script.sh pv_info <PV_NAME>     - получает информацию о конкретном PV.
#
# ./script.sh tp_discovery          - выполняет только обнаружение Thinpool.
# ./script.sh tp_info <TP_NAME>     - получает информацию о конкретном Thinpool.
#


# Конфигурация для отсылки через zabbix_sender
ZBX_SERVER="192.168.1.70"
ZBX_HOST="nas" #"${HOSTNAME}"

# item-префикс (при смене - также менять в темплейте)
ZBX_ITEM_PREFIX="lvm.info"

trim() {
    local var="$1"
    printf "%s" "$var" | awk '{$1=$1};1'
}

# Секция Thinpoll
send_tp_discovery() {
    local tp_output="$1"

    local discovery_data='{"data":[ '

    while IFS=: read -r lv_attr lv_name lv_size data_percent metadata_percent vg_name
    do
        local TP=$(trim "$lv_name")
        local VG=$(trim "$vg_name")

        discovery_data+='{"{#TP}":"'"$TP"'", "{#VG}":"'"$VG"'"},'
    done <<< "$tp_output"

    # Remove last ',' in JSON
    discovery_data="${discovery_data%,} ]}"

    if [ "$MODE" = "SENDER" ]
    then
        zabbix_sender -z "$ZBX_SERVER" -s "$ZBX_HOST" -k "${ZBX_ITEM_PREFIX}.tp.discovery" -o "$discovery_data"
    else
        echo "$discovery_data"
    fi

}

send_tp_info() {
    local tp_output="$1"

    while IFS=: read -r lv_attr lv_name lv_size data_percent metadata_percent vg_name
    do
        local TP=$(trim "$lv_name")
        local LSize=$(trim "$lv_size")
        local LDataPercent=$(trim "$data_percent")
        local LMetadataPercent=$(trim "$metadata_percent")

        local items_data='{"data":[ '
        items_data+="{ \"tp_name\": \"$TP\", \"values\": {"
        items_data+="\"size\": $LSize,"
        items_data+="\"datapersentused\": $LDataPercent,"
        items_data+="\"metadatapercentused\": $LMetadataPercent"
        items_data+="} }"
        items_data+=" ]}"

        if [ "$MODE" = "SENDER" ]
        then
            zabbix_sender -z "$ZBX_SERVER" -s "$ZBX_HOST" -k "${ZBX_ITEM_PREFIX}.tp.raw[$TP]" -o "$items_data"
        else
            echo "$items_data"
        fi


    done <<< "$tp_output"

}
# Секция PV
send_pv_discovery() {
    local pvs_output="$1"
    local discovery_data='{"data":[ '

    while IFS=: read -r pv_uuid pv_name vg_name pv_size pv_free pv_used
    do
        # помимо ID передаем в discovery дополнительно информацию
        # об имени устройства и расположенной на нем VG - для тегирования
        local PVID=$(trim "$pv_uuid")
        local PV=$(trim "$pv_name")
        local VG=$(trim "$vg_name")

        # если на PV не расположено VG
        if [ "$VG" = "" ]
        then
            local VG="[empty]"
        fi

        discovery_data+='{"{#PVID}":"'"$PVID"'", "{#PV}":"'"$PV"'", "{#VG}":"'"$VG"'"},'
    done <<< "$pvs_output"

    # Remove last ',' in JSON
    discovery_data="${discovery_data%,} ]}"

    if [ "$MODE" = "SENDER" ]
    then
        zabbix_sender -z "$ZBX_SERVER" -s "$ZBX_HOST" -k "${ZBX_ITEM_PREFIX}.pv.discovery" -o "$discovery_data"
    else
        echo "$discovery_data"
    fi
}

send_pv_info() {
    local pvs_output="$1"

    while IFS=: read -r  pv_uuid pv_name vg_name pv_size pv_free pv_used
    do
        local PVID=$(trim "$pv_uuid")
        local PSize=$(trim "$pv_size")
        local PFree=$(trim "$pv_free")
        local PUsed=$(trim "$pv_used")

        local items_data='{"data":[ '
        items_data+="{ \"pv_id\": \"$PVID\", \"values\": {"
        items_data+="\"size\": $PSize,"
        items_data+="\"free\": $PFree,"
        items_data+="\"used\": $PUsed"
        items_data+="} }"
        items_data+=" ]}"

        if [ "$MODE" = "SENDER" ]
        then
            zabbix_sender -z "$ZBX_SERVER" -s "$ZBX_HOST" -k "${ZBX_ITEM_PREFIX}.pv.raw[$PVID]" -o "$items_data"
        else
            echo "$items_data"
        fi
    done <<< "$pvs_output"
}
# Секция VG
send_vg_discovery() {
    local vgs_output="$1"
    local discovery_data='{"data":[ '

    while IFS=: read -r vg_name pv_count lv_count vg_size vg_free
    do
        local VG=$(trim "$vg_name")
        discovery_data+='{"{#VGNAME}":"'"$VG"'"},'
    done <<< "$vgs_output"

    # Remove last ',' in JSON
    local discovery_data="${discovery_data%,} ]}"

    if [ "$MODE" = "SENDER" ]
    then
        zabbix_sender -z "$ZBX_SERVER" -s "$ZBX_HOST" -k "${ZBX_ITEM_PREFIX}.vg.discovery" -o "$discovery_data"
    else
        echo "$discovery_data"
    fi
}

send_vg_info() {
    local vgs_output="$1"



    while IFS=: read -r vg_name pv_count lv_count vg_size vg_free
    do
        local VG=$(trim "$vg_name")
        local PV=$(trim "$pv_count")
        local LV=$(trim "$lv_count")
        local VSize=$(trim "$vg_size")
        local VFree=$(trim "$vg_free")
        local VUsed=$(( VSize - VFree ))

        local items_data='{"data":[ '
        items_data+="{ \"vg_name\": \"$VG\", \"values\": {"
        items_data+="\"pv_count\": $PV,"
        items_data+="\"lv_count\": $LV,"
        items_data+="\"size\": $VSize,"
        items_data+="\"free\": $VFree,"
        items_data+="\"used\": $VUsed"
        items_data+="} }"
        items_data+=" ]}"

        if [ "$MODE" = "SENDER"  ]
        then
            zabbix_sender -z "$ZBX_SERVER" -s "$ZBX_HOST" -k "${ZBX_ITEM_PREFIX}.vg.raw[$VG]" -o "$items_data"
        else
            echo "$items_data"
        fi
    done <<< "$vgs_output"
}

# проверяем если скрипт запустился без параметров - в этом случае все данные
# будут подготовлены и отправлены через zabbix_sender. В противном случае
# данные выводятся через echo для отправки через агента
if [ -z $1  ]
then
    MODE=SENDER
fi

# Опции для lvs/vgs/pvs
common_cmd_options="--noheadings --units B --nosuffix --separator :"
vgs_fields="vg_name,pv_count,lv_count,vg_size,vg_free"
pvs_fields="pv_uuid,pv_name,vg_name,pv_size,pv_free,pv_used"
lvs_tp_fields="lv_attr,lv_name,lv_size,data_percent,metadata_percent,vg_name" # для thinpool

# Готовим все данные и посылаем (будет использован zabbix_sender)
if [ "$MODE" = "SENDER"  ]
then
    vgs_output=$(vgs $common_cmd_options -o $vgs_fields)
    pvs_output=$(pvs $common_cmd_options -o $pvs_fields)
    tp_output=$(lvs $common_cmd_options -o $lvs_tp_fields | grep '^\s*t')
    send_vg_discovery "$vgs_output"
    send_pv_discovery "$pvs_output"
    send_tp_discovery "$tp_output"
    send_vg_info "$vgs_output"
    send_pv_info "$pvs_output"
    send_tp_info "$tp_output"

fi

# Ниже все данные отправляются по запросу через агента.
# VGS
if [ "$1" = "vg_discovery"  ]
then
    vgs_output=$(vgs $common_cmd_options -o $vgs_fields)
    send_vg_discovery "$vgs_output"
fi

if [[ "$1" = "vg_info" &&  -n $2 ]]
then
    vg_name=$2
    vgs_output=$(vgs $common_cmd_options -o $vgs_fields | grep "^\s.$vg_name:")
    send_vg_info "$vgs_output"
fi

# PVS
if [ "$1" = "pv_discovery"  ]
then
    pvs_output=$(pvs $common_cmd_options -o $pvs_fields)
    send_pv_discovery "$pvs_output"
fi

if [[ "$1" = "pv_info" &&  -n $2 ]]
then
    pvid=$2
    pvs_output=$(pvs $common_cmd_options -o $pvs_fields | grep "^\s.$pvid:")
    send_pv_info "$pvs_output"
fi

# LVS (thinpool)
if [ "$1" = "tp_discovery"  ]
then
    tp_output=$(lvs $common_cmd_options -o $lvs_tp_fields | grep '^\s*t')
    send_tp_discovery "$tp_output"
fi

if [[ "$1" = "tp_info" &&  -n $2 ]]
then
    tp=$2
    tp_output=$(lvs $common_cmd_options -o $lvs_tp_fields | grep '^\s*t' | grep ":$tp:")
    send_tp_info "$tp_output"
fi

