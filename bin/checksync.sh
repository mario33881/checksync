#!/bin/bash

#
# Nome programma    : checksync
# Versione          : 04_01
# Autore            : Zenaro Stefano
# Github repository : https://github.com/mario33881/checksync
#
# ======================================================= CHECKSYNC =======================================================
#
# Script principale: esegue gli altri script, copia gli script sulla macchina remota e poi lo esegue da remoto
# 
# I passaggi che fa sono i seguenti:
# 1.  Fa source dello script "logger.sh" che si occupera' del file di log
# 2.  Fa source dello script "configs.sh" che gestisce il file di configurazione passato come primo parametro
# 3.  copia script sul server remoto (specificato sul file di configurazione)
# 4.  salva file di configurazione sul server remoto
# 5.  ottiene lista file su questo pc con lo script "getfiles.sh", identificandoli con l'hostname della macchina locale
# 6.  ottiene lista file su server remoto con lo script "getfiles.sh", identificandoli con l'hostname della macchina remota
# 7.  recupera log di getfiles.sh del computer remoto
# 8.  cancella file log del computer remoto
# 9.  esegue il cat tra i due output dei "getfiles.sh", ordinando l'output del cat in ordine alfabetico ( con sort -V )
# 10. visualizza/manda via mail le informazioni ricavate con lo script "printdiffs.sh"
#
# > Per assicurarsi che non si siano errori durante l'esecuzione i comandi vengono eseguiti attraverso
# > la funzione checksuccess()
#

boold=false
SCRIPTPATH="$( cd "$( dirname "$0" )" || exit ; pwd -P )"  # percorso questo script
SCRIPTDIR=$( basename "$SCRIPTPATH" )                    # nome cartella in cui risiede questo script

output_flag="$2" # flag di output ( -e = echo , -em o -me = mail e echo, -m = mail )

# prende parametro file di configurazione ( $configfile ) e gestisce parametri
# variabili con parametri:
# analize_paths[@] : array con parametri da analizzare
# toignore_paths[@]: array con parametri da ignorare
# logpath          : percorso file di log
# ip               : ip macchina remota
# user             : username macchina remota
# scp_path         : percorso remoto a cui copiare script
# getfiles_path    : percorso file con informazioni files computer
# diffout_path     : percorso file con differenze delle informazioni files
# send_email       : booleano che indica se inviare l'output via mail
# email            : indirizzo email a cui mandare l'output ( se send_email=true )
source "$SCRIPTPATH/utils/configs.sh"
configs "$1" "$2" "$3"

# prendi percorso dove salvare i log dalle configurazioni e importa il logger 
# ( che scrivera' sul file $SCRIPT_LOG )
# logger fornisce queste funzioni:
# SCRIPTENTRY : avvio script
# SCRIPTEXIT  : termine script
# ENTRY       : avvio funzione
# EXIT        : termine funzione
# INFO        : messaggio informazione
# DEBUG       : messaggio debug
# ERROR       : messaggio errore
SCRIPT_LOG="$logpath"
source "$SCRIPTPATH/utils/logger.sh"

# script per visualizzazione informazioni
source "$SCRIPTPATH/utils/printdiffs.sh"


function checksuccess(){
    # questa funzione si occupa di eseguire comandi e
    # di verificarne il successo
    #
    # il primo parametro e' il status code con cui far uscire lo script
    # in caso di errore, il secondo parametro e' la descrizione di cio'
    # che fa il comando (utile con boold=true per debug e in caso di errore)
    # e gli altri parametri compongono il comando da eseguire
    
    ENTRY

    params=("$@") # array di tutti i parametri
    
    command=("${params[@]:2}") # comando da eseguire
    desc="${params[1]}"        # cosa fa il comando
    exitcode="${params[0]}"    # codice da dare in caso fallimento
    
    DEBUG "Comando da eseguire: '${command[*]}'"
    DEBUG "Descrizione comando: '$desc'"
    DEBUG "Codice errore in caso di fallimento esecuzione: '$exitcode'"
    
    if [ "$boold" = true ] ; then
        # se in debug
        echo -e "\n$desc" # visualizzo descrizione comando
    fi
    
    out=$( "${command[@]}" ) # eseguo il comando salvando l'output
    status_code="$?"         # e salvo il status code dell'esecuzione
    
    if [ "$out" != "" ] ; then
        # se c'e' l'output questo viene visualizzato
        echo "$out"
    fi
    
    if [ "$status_code" -ne 0 ] ; then
        # se l'operazione NON ha avuto successo, esci con status code $exitcode
        echo "$desc FALLITA (status code $status_code )"
        ERROR "$desc FALLITA (status code $status_code )"
        exit "$exitcode"
    fi

    EXIT
}


function email_sender(){
    # manda mail se e' installato sendmail e se e' stata inserita una mail nel file di configurazione
    
    sendmail_path=$( command -v sendmail ) # verifico se sendmail e' installato ( se != "" )
    if [ "$sendmail_path" != "" ] && "$send_email" ; then
        if [ "$boold" = true ] ; then
            echo "Sendmail e' installato ed e' stata specificata email di destinazione"
        fi

        data=$( date +"%F %T" ) # data "yyyy/mm/dd hh:mm:ss"

        htmlmessage=$( printdiffs "$diffout_path" "html" ) # ottieni html con tutte le informazioni
        (
        echo "From: checksyncscript@bashscript.com"; # mail mittente
        echo "To: ${email}";                         # mail destinatario ( da file di configurazione )
        echo "Subject:Checksinc report ${data}";     # oggetto della mail
        echo "Content-Type: text/html";              # il contenuto mail e' tipo html
        echo "MIME-Version: 1.0";
        echo "";
        echo "$htmlmessage"; # messaggio (html)
        ) | sendmail -t      # usa sendmail per mandare la mail

    fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPTENTRY

    # copio script sul server remoto
    cmd=( scp -r "$SCRIPTPATH" "${user}@${ip}:${scp_path}" )
    checksuccess 20 "Copia script su server remoto" "${cmd[@]}"

    # salvo file di configurazione sul server remoto
    cmd=( scp "$configfile" "${user}@${ip}:${scp_path}/" )
    checksuccess 21 "Copia file di configurazione sul server remoto" "${cmd[@]}"

    # ottengo lista file su questo pc, identificandoli con l'hostname della macchina locale
    curr_hostname=$( hostname )
    cmd=( "$SCRIPTPATH/utils/getfiles.sh" "$configfile" "$curr_hostname" )
    checksuccess 22 "Operazione recupero lista file di questa macchina" "${cmd[@]}"

    # ottengo lista file su server remoto, identificandoli con l'hostname della macchina remota
    inifilename=$( basename "$configfile" ) # recupero nome file di configurazione
    cmd=( ssh "${user}@${ip}" "rem_hostname=\$( hostname ) ; ${scp_path}/${SCRIPTDIR}/utils/getfiles.sh ${scp_path}/${inifilename}" '"$rem_hostname"' )

    checksuccess 23 "Operazione lista file macchina remota" "${cmd[@]}"

    # recupero log del computer remoto
    cmd=( ssh "${user}@${ip}" "cat '$logpath'" )

    while IFS= read -r line
    # scorri log
    do
        echo "$line" >> "$logpath" # inserisco nel file di log le righe del file di log remoto
    done < <( checksuccess 24 "Recupero file log remoto" "${cmd[@]}" ) # comando con stdout

    # rimuovo log incompleto remoto
    cmd=( ssh "${user}@${ip}" "rm '$logpath'" )
    checksuccess 25 "Rimuovo file log remoto perche' incompleto" "${cmd[@]}"

    # eseguo cat tra i due output, ordinando l'output del cat in ordine alfabetico
    if [ "$boold" = true ] ; then
        echo -e "\nOperazione recupero output lista file e cat tra liste file locale e remota"
    fi

    ssh "${user}@${ip}" "cat $getfiles_path" | cat "$getfiles_path" -  | sort -V > "$diffout_path" # -V risolve problemi con file con "-" nel nome
    status_code="$?"

    DEBUG "Comando da eseguire: 'ssh ""${user}"@"${ip}"" "cat "$getfiles_path"" | cat ""$getfiles_path"" -  | sort -V > ""$diffout_path""'"
    DEBUG "Descrizione comando: 'Operazione recupero output lista file e cat tra liste file locale e remota'"
    DEBUG "Codice errore in caso di fallimento esecuzione: '9'"

    if [ "$status_code" -ne 0 ] ; then
        # se l'operazione NON ha avuto successo, esci con status code 9
        echo "Operazione recupero output lista file e cat tra liste file locale e remota FALLITA (status code $status_code )"
        exit 26
    fi

    # visualizza le informazioni ricavate

    if [ "$output_flag" = "-m" ] ; then
        # manda solo la mail con le informazioni
        cmd=( email_sender )

    elif [ "$output_flag" = "-me" ] || [ "$output_flag" = "-em" ] ; then
        # manda mail e visualizza le informazioni su terminale
        cmd=( printdiffs "$diffout_path" )
        "${cmd[@]}"
        cmd=( email_sender )
    else
        # visualizza le informazioni su terminale
        cmd=( printdiffs "$diffout_path" )
    fi

    checksuccess 27 "Visualizzazione differenze tra le due macchine" "${cmd[@]}"

    SCRIPTEXIT
fi
