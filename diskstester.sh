#!/bin/bash
#Author: Damian Golał | Data Space

#Przygotowanie katalogu i początkowych zmiennych
#_____________________________________________________________
mkdir /tmp/diskdoctor/
mkdir /tmp/diskdoctor/tmp/
mkdir /tmp/diskdoctor/smart/
touch /tmp/diskdoctor/results
main_dir=/tmp/diskdoctor
trash=/tmp/diskdoctor/tmp
smart_dir=/tmp/diskdoctor/smart
results=/tmp/diskdoctor/results
start=$(time)

#Lista dysków
#_____________________________________________________________
lsblk | grep disk >> $trash/known_disks
sed 's/\s.*$//' $trash/known_disks >> $main_dir/known_disks
sed -i '$ d' $main_dir/known_disks
disks=$(cat $main_dir/known_disks)
num=$(wc -l $main_dir/known_disks)
number=$(echo $num | sed 's/[^0-9]*//g' )
echo "Data rozpoczęcia testu:" $time >> $results
echo "Data zakończenia testu: in_progress" >> $results
echo "Liczba sprawdzonych dysków:" $number >> $results
echo     "__________________________________________________" >> $results

#FUNKCJE
#_____________________________________________________________

#Pobranie numeru seryjnego aktualnie używanego dysku
function GREP_SN {

    sn=$(smartctl -a /dev/${x} |grep 'Serial Number')
    sn2=$(echo $sn |sed -r 's/^Serial Number://')
    sn3=$(echo $sn2 |sed 's/ //g')

}

function GREP_LIFETIME {

    lt=$(smartctl -a /dev/${x} |grep 'Power_On_Hours')
    lifetime=$(echo $lt |sed 's/.* //')

}

function GREP_CYCLE {

    pc=$(smartctl -a /dev/${x} |grep 'Power_Cycle_Count')
    powercycle=$(echo $pc |sed 's/.* //')

}

function GREP_UNSAFE_SH {

    us=$(smartctl -a /dev/${x} |grep 'Unsafe_Shutdown_Count')
    unsafeshutdown=$(echo $us |sed 's/.* //')

}

function GREP_REALLOCATED {

    rs=$(smartctl -a /dev/${x} |grep 'Reallocated_Sector_Ct')
    reallocated=$(echo $rs |sed 's/.* //')

}

#Przeprowadzenie testów S.M.A.R.T.
#_____________________________________________________________
for x in $disks
do
    smartctl -t long /dev/${x}
done

#Test BadBlocks
#_____________________________________________________________
for x in $disks
do
    GREP_SN
    nohup badblocks -wsv -o /tmp/diskdoctor/$sn3 /dev/${x} &
done

pgrep badblocks

while [ $? == 0 ]
do
    echo "Test nadal trwa"
    sleep 1
    pgrep badblocks
done

#Zapis wyników S.M.A.R.T.
#_____________________________________________________________
for x in $disks
do
    GREP_SN
    smartctl -a /dev/${x} >> $smart_dir/"$sn3".txt &
done

#Weryfikacja czasu działania dysków
#_____________________________________________________________
for x in $disks
do
    value=$(smartctl -a /dev/${x} |grep Power_On_Hours)
    GREP_SN
    value2=$(echo $value |sed 's|.*-||')
    value3=$(echo $value2 |sed 's/ //g')
    while [[ $value3 -gt 30000 ]]
    do
        echo $sn3 >> $main_dir/over30kh
        break
    done
done

echo "Dyski z czasem pracy powyżej 30.000 godzin:" >> $results
cat $main_dir/over30kh >> $results
echo     "__________________________________________________" >> $results

#Interpretacja wyników S.M.A.R.T.
#_____________________________________________________________
echo "Skrócone wyniki S.M.A.R.T." >> $results
for x in $disks
do
    echo "--------------------------------------------------" >> $results

    GREP_SN
    echo "Statystyki dla dysku" $sn3 >> $results

    GREP_LIFETIME
    echo "Łączny czas pracy dysku wynosi:" $lifetime >> $results

    GREP_REALLOCATED
    echo "Ilość przeniesionych sektorów:" $reallocated >> $results

    GREP_CYCLE
    echo "Ilość cykli wynosi:" $powercycle >> $results

    GREP_UNSAFE_SH
    echo "Liczba niepoprawnych wyłączeń wynosi:" $unsafeshutdown >> $results

done

#Interpretacja wyników BadBlocks
#_____________________________________________________________
echo     "__________________________________________________" >> $results
echo "Wyniki testu BadBlocks:" >> $results
for x in $disks
do
    GREP_SN
    if [ -f $main_dir/"$sn3" ]
    then
        if [ -s $main_dir/"$sn3" ]
        then
            echo "Dysk" $sn3 "posiada uszkodzone sektory" >> $results
        else
            echo "Dysk" $sn3 "jest sprawny" >> $results
        fi
    else
        echo "Nie udało się odczytać dysku" $sn3 >> $results
    fi
done

stop=$(date)
sed -i -r "s/in_progress/$stop/g" $results

#Czyszczenie
#_____________________________________________________________
rm -rf /tmp/diskdoctor/
