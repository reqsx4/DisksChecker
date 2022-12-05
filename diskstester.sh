#!/bin/bash

#Zmienne
#_____________________________________________________________
main_dir=/tmp/DSDISK/
list_unformatted=/tmp/DSDISKS/disks_list_unformatted
list=/tmp/DSDISKS/disks_list_formatted
disks=0

#Sprawdzenie czy zainstalowane są odpowiednie narzędzia
#_____________________________________________________________
systemctl --no-pager status smartmontools
if [ $? != 0 ]; then

apt update && apt install --assume-yes smartmontools
systemctl start smartmontools

fi

dpkg -l e2fsprogs
if [ $? != 0 ]; then

apt install --assume-yes e2fsprogs
systemctl start e2fsprogs

fi

#Przygotowanie katalogu dla tymczasowych plików
#_____________________________________________________________
mkdir /tmp/DSDISKS/

#Przygotowanie listy dysków
#_____________________________________________________________
lsblk | grep disk >> $list_unformatted

sed 's/\s.*$//' /tmp/DSDISKS/disks_list_unformatted >> $list

#Testy smart
#_____________________________________________________________
#xargs -I{} smartctl -t short /dev/"{}" < $list

#Testy badblocks
#_____________________________________________________________
#xargs -I{} badblocks -wsv /dev/"{}" < $list > /etc/testy

#Weryfikacja czasu działania dysków
#_____________________________________________________________
disks=$(cat /tmp/DSDISKS2/disks_list_formatted)
mkdir /tmp/RESULTS2
touch /tmp/over30k.txt

for x in $disks
do
    value=$(smartctl -a /dev/${x} |grep Power_On_Hours)
    sn=$(smartctl -a /dev/${x} |grep 'Serial Number')
    sn2=$(echo $sn |sed -r 's/^Serial Number://')
    sn3=$(echo $sn2 |sed 's/ //g')
    value2=$(echo $value |sed 's|.*-||')
    value3=$(echo $value2 |sed 's/ //g')
    while [[ $value3 -gt 30000 ]]
    do
        echo $sn3 >> /tmp/over30k.txt
        break
    done
done

#Zebranie informacji z testu S.M.A.R.T (tylko uszkodzonych!)

for x in $disks
do
    sn=$(smartctl -a /dev/${x} |grep 'Serial Number')
    sn2=$(echo $sn |sed -r 's/^Serial Number://')
    sn3=$(echo $sn2 |sed 's/ //g')
    smartctl -a /dev/${x} |grep "Completed without error"
    while [ $? != 0 ]
    do
        echo $sn3 >> /tmp/smarterrors.txt
        smartctl -a /dev/${x} >> /tmp/$sn3.txt
        break
    done
done

# Czyszczenie dysków

for x in $disk
do
type=$(smartctl -a /dev/${x} |grep 'Rotation Rate:    Solid State Device')
    if [ $? == 0 ]; then
        dd if=/dev/zero of=/dev/${x}
    else
        dd if=/dev/urandom of=/dev/${x} && dd if=/dev/zero of=/dev/${x}
done


# Pakowanie wyników testów w .zip

#Klasyfikacja dysków i zestawienie

#Wysyłka maila do @TECH

#Usunięcie katalogu tymczasowego
#_____________________________________________________________
rm -rf /tmp/DSDISKS/
rm -rf /tmp/RESULTS/
rm -rf /tmp/over30k.txt
