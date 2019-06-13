#!/bin/bash

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
	echo "Output log non definito ( variabile SCRIPT_LOG )"
	exit 30
fi

touch "$SCRIPT_LOG" # crea file log se non esiste


SCRIPTENTRY(){
    # scrive data e ora, e indica che e' iniziato uno script (e indica quale)
    timeAndDate=$( date +"%F %T" )
    script_name=$( basename "$0" )
    script_name="${script_name%.*}"
    echo "[$timeAndDate] [DEBUG]  > $script_name ${FUNCNAME[0]}" >> "$SCRIPT_LOG"
}


SCRIPTEXIT(){
    # scrive data e ora, e indica che e' terminato lo script (e indica quale)
    script_name=$( basename "$0" )
    script_name="${script_name%.*}"
    timeAndDate=$( date +"%F %T" )
    echo "[$timeAndDate] [DEBUG]  < $script_name ${FUNCNAME[0]}" >> "$SCRIPT_LOG"
}


ENTRY(){
    # scrive data e ora, e indica che e' iniziata l'esecuzione di una funzione (indica nome)
    local cfn="${FUNCNAME[1]}"
    timeAndDate=$( date +"%F %T" )
    echo "[$timeAndDate] [DEBUG]  > $cfn ${FUNCNAME[0]}" >> "$SCRIPT_LOG"
}


EXIT(){
    # scrive data e ora, e indica che e' terminata l'esecuzione di una funzione (indica nome)
    local cfn="${FUNCNAME[1]}"
    timeAndDate=$( date +"%F %T" )
    echo "[$timeAndDate] [DEBUG]  < $cfn ${FUNCNAME[0]}" >> "$SCRIPT_LOG"
}


INFO(){
    # scrive data e ora e permette di indicare un messaggio di informazione
    local msg="$*"
    timeAndDate=$( date +"%F %T" )
    echo "[$timeAndDate] [INFO]  $msg" >> "$SCRIPT_LOG"
}


DEBUG(){
    # scrive data e ora, e permette di indicare un messaggio di debug
    local msg="$*"
    timeAndDate=$( date +"%F %T" )
    echo "[$timeAndDate] [DEBUG]  $msg" >> "$SCRIPT_LOG"
}


ERROR(){
    # scrive data e ora, e permette di indicare un messaggio di errore
    local msg="$*"
    timeAndDate=$( date +"%F %T" )
    echo "[$timeAndDate] [ERROR]  $msg" >> "$SCRIPT_LOG"
}
