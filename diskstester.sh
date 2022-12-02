#!/bin/bash

#Zmienne
#_____________________________________________________________
list_unformatted=/tmp/DSDISKS/disks_list_unformatted
list=/tmp/DSDISKS/disks_list_formatted

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
xargs -I{} smartctl -t short /dev/"{}" < $list

#Testy badblocks
#_____________________________________________________________
xargs -I{} badblocks -svn /dev/"{}" < $list > /etc/testy

#Weryfikacja czasu działania dysków
#_____________________________________________________________
xargs -I{} smartctl -a /dev/"{}" |grep Power_On_Hours < $list > /etc/timers

#Zebranie informacji z testu S.M.A.R.T

# Czyszczenie dysków

# Pakowanie wyników testów w .zip

#Klasyfikacja dysków i zestawienie

#Wysyłka maila do @TECH

#Usunięcie katalogu tymczasowego
#_____________________________________________________________
rm -rf /tmp/DSDISKS/
