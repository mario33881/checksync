#!/bin/sh

# ================================================= GESTIONE FILE DI LOG =================================================
# Questo script server per definire le funzioni adatte al log:
# 
# SCRIPTENTRY : avvio script 
# SCRIPTEXIT  : termine script 
# ENTRY       : avvio funzione
# EXIT        : termine funzione
# INFO        : messaggio informazione
# DEBUG       : messaggio debug
# ERROR       : messaggio errore

if [ "$SCRIPT_LOG" = "" ] ; then
	# se il percorso del file di log non e' definito esci
	# con status code 14
	echo "Output log non definito"
	exit 14
fi

mkdir -p "$(dirname "$SCRIPT_LOG")" # crea cartelle per il log (se non esiste)
touch $SCRIPT_LOG # crea file log se non esiste


function SCRIPTENTRY(){
    # scrive data e ora, e indica che e' iniziato uno script (e indica quale)
    timeAndDate=`date +"%F %T"`
    script_name=`basename "$0"`
    script_name="${script_name%.*}"
    echo "[$timeAndDate] [DEBUG]  > $script_name $FUNCNAME" >> $SCRIPT_LOG
}


function SCRIPTEXIT(){
    # scrive data e ora, e indica che e' terminato lo script (e indica quale)
    script_name=`basename "$0"`
    script_name="${script_name%.*}"
    timeAndDate=`date +"%F %T"`
    echo "[$timeAndDate] [DEBUG]  < $script_name $FUNCNAME" >> $SCRIPT_LOG
}


function ENTRY(){
    # scrive data e ora, e indica che e' iniziata l'esecuzione di una funzione (indica nome)
    local cfn="${FUNCNAME[1]}"
    timeAndDate=`date +"%F %T"`
    echo "[$timeAndDate] [DEBUG]  > $cfn $FUNCNAME" >> $SCRIPT_LOG
}


function EXIT(){
    # scrive data e ora, e indica che e' terminata l'esecuzione di una funzione (indica nome)
    local cfn="${FUNCNAME[1]}"
    timeAndDate=`date +"%F %T"`
    echo "[$timeAndDate] [DEBUG]  < $cfn $FUNCNAME" >> $SCRIPT_LOG
}


function INFO(){
    # scrive data e ora e permette di indicare un messaggio di informazione
    local function_name="${FUNCNAME[1]}"
    local msg="$@"
    timeAndDate=`date +"%F %T"`
    echo "[$timeAndDate] [INFO]  $msg" >> $SCRIPT_LOG
}


function DEBUG(){
    # scrive data e ora, e permette di indicare un messaggio di debug
    local function_name="${FUNCNAME[1]}"
    local msg="$@"
    timeAndDate=`date +"%F %T"`
    echo "[$timeAndDate] [DEBUG]  $msg" >> $SCRIPT_LOG
}


function ERROR(){
    # scrive data e ora, e permette di indicare un messaggio di errore
    local function_name="${FUNCNAME[1]}"
    local msg="$@"
    timeAndDate=`date +"%F %T"`
    echo "[$timeAndDate] [ERROR]  $msg" >> $SCRIPT_LOG
}
