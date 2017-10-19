#!/bin/bash
   
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
   
set +u
set -e
#set -x

#echo -e "$0 Paramter: $*"

declare ROT_BEG="\\033[01;33m\e[31m"
declare MAG_BEG="\\033[01;33m\e[35m"
declare GREEN_BEG="\\033[01;33m\e[32m"
declare BLUE_BEG="\\033[01;33m\e[34m"
declare TUERK_BEG="\\033[01;33m\e[34m"
declare COL_END="\\033[;0m"

declare ARG_OPTION=$1

set -u

runterladen() {             #lädt die Software herunter und entpackt sie, falls nötig
    Info_trace "Lade gerade die Software herunter"
    if ! wget $LINK; then
        error_trace "Eventuell ist die URL nicht verfügbar oder abgelaufen"
        help
        exit
    fi
    Info_trace "Versuche die Heruntergeladene Datei zu entpacken"
    if ! gunzip  $LINK >/dev/null 2>/dev/null; then
        entpacken_text
    fi
}

entpacken() {               #entpackt die Software
    Info_trace "Entpacke die Datei"
    if ! gunzip $FILENAME >/dev/null 2>/dev/null; then
        entpacken_text
        exit
    fi
}

entpacken_text() {      #gibt ein text zum entpacken aus
    echo -e "Entpacken ist nicht notwendig"
}

help() {                    #gibt ein Hilfetext aus
    echo -e "Ungültiges Kommando"
    echo -e "Aufruf: ./image_to_device.sh [-d, --download, -g, --gunzip] [Downloadlink, Datei zum entpacken]"
    echo -e "Beispiel: ./image_to_device.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256"
    exit 
}

Parameter_show() {          #Überprüft ob mehr als 2 Paramter angegeben worden sind
    if [ $# -lt 2 ]; then   
        help_for_less_Paramter
    fi
}

help_for_less_Paramter () {     #Gibt ein längeren Hilfetext aus
    echo -e "Aufruf: ./image_to_device.sh [-d, --download, -g, --gunzip] [Downloadlink, Datei zum entpacken]"
    echo -e "./image_to_device.sh                    -g      --gunzip                            Datei zum entpacken"
    echo -e "./image_to_device.sh                    -d      --download                          Downloadlink"
    echo -e "Beispiel: ./image_to_device.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256"
    exit
}

SD_karte_ermitteln () {     #Überprüft ob die SD-Karte vorhanden ist
    Info_trace "Überprüfe ob die SD-Karte vorhanden ist"
    if ! [ -e /dev/mmcblk0 ]; then 
        error_trace "SD-Karte nicht erkannt"
        Help_trace "Biite stecken sie eine SD-Karte ein"
    fi
    while true; do 
        sleep 1
        declare SIZE=$(lsblk $SDKARTE_DEVICE 2>/dev/null | grep "mmcblk0 " | awk '{print $4}' )
    if [ -e /dev/mmcblk0 ]; then
        SIZE_trace "Die SD-Karte ist $SIZE groß"
        break
    fi
    done
}

Ueberpruefe_SD-Karte_und_DateiGroesse () {      #Überprüft die Größe der Datei und der SD-Karte miteinander
    Info_trace "Überprüfe die Größe der SD-Karte und der Image-Datei miteinander"
    if [ $SIZE_GANZ -lt $FILESIZE_GANZ ]; then
        error_trace "SD-Karte hat zu wenig Speicherplatz"
        Help_trace "Neue SD-Karte einlegen"
        Help_trace "Oder Speicherplatz beschaffen"
    elif [ $FILESIZE_GANZ -lt 2147485696 ]; then
        echo -e "Es werden mindestens 2 GB benötigt"
    elif [ $FILESIZE_GANZ -gt 2147485696 ]; then
        echo -e "Es werden mindestens 4 GB benötigt"
    elif [ $FILESIZE_GANZ -gt 4294967296 ]; then
        echo -e "Es werden mindestens 8 GB benötigt"
    fi
    while true; do
        sleep 1
    declare SIZE_GANZ=$(lsblk -b $SDKARTE_DEVICE 2>/dev/null | grep "mmcblk0 " | awk '{print $4}' )
    if [ $SIZE_GANZ -gt $FILESIZE_GANZ ] >/dev/null 2>/dev/null; then
        Correct_trace "SD-Karte ist größer als die Datei"
        break
    fi
    done 
}

KopierenSD () {             #Kopiert die Software auf die SD-Karte
    Info_trace "Kopiere die Image-Datei auf die SD-Karte"
    declare BLOCKS=8000000
    sudo dd if=$FILENAME of=$SDKARTE_DEVICE bs=$BLOCKS count=$((FILESIZE_GANZ))
    sync
}

Kopieren_back() {           #Kopiert die Software von der SD-Karte zurück in eine Datei
    Info_trace "Lese die Software von der SD-Karte in eine Datei zurück"
    declare -r BLOCKS_BACK=1000000
    sudo dd if=$SDKARTE_DEVICE of=verify.img bs=$BLOCKS_BACK count=$((FILESIZE_GANZ))
    sync
    Info_trace "Verkürze die zurückgeschriebenen Datei in die Größe der Originalen Datei"
    sudo truncate -r $FILENAME verify.img
}

Dateigroesse () {                       #Überprüft die Dateigröße
    Info_trace "Überprüfe die Dateigröße der Image-Datei"
    SIZE_trace "Dateigröße der Image-Datei: $FILESIZE" 
}

Dateigroesse_zurueckgeschrieben () {    #Überprüft die Dateigröße der zurückgeschriebenen Datei
    declare FILESIZE_BACK_GANZ=$(stat -c %s verify.img)
    declare FILESIZE_BACK=$(du -h verify.img | awk '{print $1}') 
    Info_trace "Überprüfe die Größe der zurückgeschriebenen Datei"
    SIZE_trace "Dateigröße der zurückgeschriebenen Datei: $FILESIZE_BACK"
}

Hashwerte_Vergleichen() {   #Vergleicht die Hashwerte von der Heruntergeladenen Datei und der zurückgeschriebenen Datei mit einander
    Info_trace "Vergleiche die Hashwerte der zurückgeschriebenen und der Originalen Datei miteinander"
    declare MD5SUM=$(md5sum $FILENAME | cut -d" " -f1)
    declare MD5SUM_BACK=$(md5sum verify.img | cut -d" " -f1)
    if [ $MD5SUM == $MD5SUM_BACK ]; then 
        Correct_trace "Die Hashwerte sind gleich"
        else 
        error_trace "Die Hashwerte sind nicht gleich, bitte versuchen sie es erneut"
    fi
}
declare SIZE_GANZ=
Zurueckgeschriebene_Datei_loeschen() {  #Die Zurueckgeschriebene Datei löschen
    rm -rf verify.img
}

Info_trace() {          #Markiert Lila
    echo -e "${MAG_BEG}$1${COL_END}"
}

Help_trace() {          #Markiert Rot
    echo -e "${ROT_BEG}$1${COL_END}"
}

error_trace() {         #Markiert Rot und fügt ein ERROR am Anfanh hinzu
    echo -e "\n${ROT_BEG}ERROR: $1${COL_END}"
}

Correct_trace() {       #Markiert Grün
    echo -e "${GREEN_BEG}$1${COL_END}"
}

SIZE_trace() {          #Markiert Blau
    echo -e "${BLUE_BEG}$1${COL_END}"
}

if [ $# -lt 2 ]; then   #Gibt es ein Fehler im Script, wird ein Hilfetext ausgegeben
    help_for_less_Paramter
    exit
fi

declare LINK=$2 
declare FILENAME="$(basename $2)"

trap Zurueckgeschriebene_Datei_loeschen exit
trap Zurueckgeschriebene_Datei_loeschen term 

case $ARG_OPTION in  
    "-d") 
        runterladen
        ;;

    "--download")
        runterladen
        ;;

    "-g")
        entpacken
        ;;

    "--gunzip")
        entpacken
        ;;
    "--help") 
        help_for_less_Paramter
        ;;
    "*")
        help
        exit
        ;;
esac

declare FILESIZE_GANZ=$(stat -c %s $FILENAME)
declare FILESIZE=$(du -h $FILENAME | awk '{print $1}') 
declare SDKARTE_DEVICE=/dev/mmcblk0
declare SIZE=""
declare SIZE_GANZ=""

SD_karte_ermitteln

declare SIZE_GANZ=$(lsblk -b $SDKARTE_DEVICE | grep "mmcblk0 " | awk '{print $4}' )

Ueberpruefe_SD-Karte_und_DateiGroesse

Dateigroesse

KopierenSD  

Kopieren_back

Dateigroesse_zurueckgeschrieben

Hashwerte_Vergleichen

Info_trace "Die zurückgeschriebene Datei löschen"

Zurueckgeschriebene_Datei_loeschen

Correct_trace "Sie können die SD-Karte entfernen"
