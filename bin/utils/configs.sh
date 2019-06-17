#!/bin/bash

if [ "$boold" = "" ] ; then
    boold=false # variabile debug
fi

configfile="$1"  # percorso file configurazione
testingflag="$3" # flag di test (--test per visualizzare contenuto configurazioni, 
                 # --skip-conn-test per saltare il test di connessione)

SCRIPTPATH="$( cd "$(dirname "$0")" || exit ; pwd -P )" # percorso questo script


function stripspaces(){
    # rimuove tutti spazi prima e dopo la stringa
    echo -e "${1}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}


function valid_ipv6(){
    # controlla se l'ipv6 passato come primo parametro e' valido
    regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'
    [[ $1 =~ $regex ]]
    return $?
}


function valid_ipv4(){
    # controlla se l'ipv4 passato come primo parametro e' valido
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


function remove_slash(){
    # questa funzione rimuove lo slash e 
    # il punto dal percorso passato come parametro

    path="$1"
    echo "$path" | sed -e 's|\.*$||' -e 's|/*$||'
}


function ismyip(){
    # restituisce vero se l'ip passato come parametro e' configurato sulla macchina,
    # altrimenti restituisce falso
    ip="$1"
    ips=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

    [ "$ips" = "$ip" ]
    return $?
}


function pingstat(){
    ip="$1"
    ping -c 1 "$ip" 2>/dev/null 1>/dev/null
    return $?
}

# ============================================ GESTIONE FILE DI CONFIGURAZIONE ============================================
#
# Questa parte di programma controlla se e' stato passato il parametro con il percorso del file di configurazione 
# e se questo file esiste, se non e' stato passato il parametro il programma uscira' con status 2, 
# se il percorso non punta ad un file esistente il programma uscira' con status 1, 
# altrimenti il programma continuera' la sua esecuzione

if [ "$configfile" != "" ] ; then
    if [ -f "$configfile" ] ; then
        # ogni 	riga di configurazione deve avere la sua sezione
        configcmd=( awk "-F=" '/\[/{prefix=$0; next} $1{$1=$1; print prefix $0}' "OFS="' = ' "$configfile" )

        analize_paths=()  # contiene percorsi da analizzare
        toignore_paths=() # contiene percorsi da ignorare

        # leggi riga per riga di stdout del comando configcmd
        while IFS= read -r line
        do
            if [[ "$line" = "[ANALIZZA]"* ]] ; then
                # se la configurazione e' nella sezione analizza...
                path="${line:10}"
                path="$( stripspaces "$path" )" # rimuovi eventuali spazi prima e dopo il percorso
                analize_paths+=("${path}") # aggiungi percorso al vettore

            elif [[ "$line" = "[IGNORA]"* ]] ; then
                # se la configurazione e' nella sezione ignora...
                path="${line:8}"
                path="$( stripspaces "$path" )"  # rimuovi eventuali spazi prima e dopo il percorso
                path="$( remove_slash "$path" )" # rimuovi "/" e "." dai percorsi
                toignore_paths+=("${path}") # aggiungi percorso al vettore
    
            elif [[ "$line" = "[LOG]path = "* ]] ; then
                # se la configurazione e' nella sezione log, proprieta' path
                logpath="${line:12}" # salva percorso del file di log
                logpath="$( stripspaces "$logpath" )" # rimuovi eventuali spazi prima e dopo
    
            elif [[ "$line" = "[MACCHINA 2]ip = "* ]] ; then
                # se la configurazione e' nella sezione macchina 2, proprieta' ip
                ip="${line:17}" # salva indirizzo ip
                ip="$( stripspaces "$ip" )" # rimuovi eventuali spazi prima e dopo

            elif [[ "$line" = "[MACCHINA 2]user = "* ]] ; then
                # se la configurazione e' nella sezione macchina 2, proprieta' user
                user="${line:19}" # salva username
                user="$( stripspaces "$user" )" # rimuovi eventuali spazi prima e dopo
    
            elif [[ "$line" = "[MACCHINA 2]scppath = "* ]] ; then
                # se la configurazione e' nella sezione macchina 2, proprieta' scppath
                scp_path="${line:22}" # salva scp path
                scp_path="$( stripspaces "$scp_path" )" # rimuovi eventuali spazi prima e dopo
            
            elif [[ "$line" = "[OUTPUT]getfiles = "* ]] ; then
                # se la configurazione e' nella sezione output, proprieta' getfiles
                getfiles_path="${line:19}" # salva percorso output getfiles
                getfiles_path="$( stripspaces "$getfiles_path" )" # rimuovi eventuali spazi prima e dopo

            elif [[ "$line" = "[OUTPUT]diffout = "* ]] ; then
                # se la configurazione e' nella sezione output, proprieta' diffout
                diffout_path="${line:18}" # salva percorso output diffout
                diffout_path="$( stripspaces "$diffout_path" )" # rimuovi eventuali spazi prima e dopo
            
            elif [[ "$line" = "[NOTIFICHE]email = "* ]] ; then
                # se la configurazione e' nella sezione notifiche, proprieta' email
                email="${line:19}" # salva indirizzo email
                email="$( stripspaces "$email" )" # rimuovi eventuali spazi prima e dopo
            fi
        
        done < <(stdbuf -oL "${configcmd[@]}") # l'output di questo comando e' letto riga per riga
        
        if [ "$boold" = true ] ; then
            echo "${analize_paths[@]}"
            echo "${toignore_paths[@]}"
            echo "$logpath"
            echo "$ip"
            echo "$user"
            echo "$scp_path"
            echo "$getfiles_path"
            echo "$diffout_path"
            echo "$email"
        fi
    
    else
        echo "File di configurazione non esiste"
        exit 10
    fi
    
else
    echo "Parametro file di configurazione mancante"
    exit 11
fi

# ================================================ GESTIONE CONFIGURAZIONI ================================================
#
# poi il programma verifica che ci sia almeno un percorso da analizzare (altrimenti il programma termina con status code 3),
# se manca il percorso del file log verra' usato il percorso di default:  /var/log/bashsincserver/bashsincserver.log
# se manca l'indirizzo ip della seconda macchina il programma terminera' con status code 4,
# se manca il nome utente con cui connettersi alla seconda macchina verra' usato il nome utente attuale,
# se manca il percorso remoto in cui copiare lo script verra' usato lo stesso percorso di questo programma 
# se mancano i percorsi in output del file contenente tutte le informazioni relative ai file sul computer
# e della differenza tra i due file (quello locale e quello remoto) verranno messi in /var/tmp/bashsincserver
# se nel file di configurazione e' presente un indirizzo email, l'output verra' mandato anche a quella mail, altrimenti
# verra' solo visualizzato

if [ "${#analize_paths[@]}" -eq 0 ] ; then
    echo "Nessun percorso da analizzare"
    exit 12

else
    for path in "${analize_paths[@]}"
    do
        if [ ! -d "$path" ] ; then
            echo "Cartella '$path' inesistente"
            exit 14
        fi
    done
fi

if [ "${logpath}" = "" ] ; then
    if [ "$boold" = true ] ; then
        echo "Verra' usato percorso log di default"
    fi
    
    logpath=checksync.log # se non ci sono altre possibilita' metti log nella cartella di esecuzione
    if [ ! -d "/var/log/checksync" ] ; then
        # se la directory in log non esiste cerca di crearla e eventualmente usala come destinazione log
        mkdir -p "/var/log/checksync" 2>/dev/null && logpath=/var/log/checksync/checksync.log
    else
        # se la directory esiste usala per i log
        logpath=/var/log/checksync/checksync.log
    fi
fi

if [ "${ip}" = "" ] ; then
    echo "Manca l'indirizzo IP della macchina a cui connettersi"
    exit 13

else
    if valid_ipv6 "$ip" || valid_ipv4 "$ip" ; then
        # ip valido
        :
    else
        echo "Ip inserito non valido"
        exit 15
    fi
fi

if [ "${user}" = "" ] ; then
    if [ "$boold" = true ] ; then
        echo "Verra' usato l'attuale nome utente per la connessione ssh"
    fi
    user=$(whoami)
fi

if [ "${scp_path}" = "" ] ; then
    if [ "$boold" = true ] ; then
        echo "Verra' usato l'attuale percorso per copiare lo script in remoto"
    fi
    scp_path="$SCRIPTPATH"
fi

if [ "${getfiles_path}" = "" ] ; then
    if [ "$boold" = true ] ; then
        echo "Verra' usato un percorso temporaneo per il file con tutte le informazioni relative ai file sul computer"
    fi
    getfiles_path="/var/tmp/checksync/getfilesout.csv"
fi

if [ "${diffout_path}" = "" ] ; then
    if [ "$boold" = true ] ; then
        echo "Verra' usato un percorso temporaneo per il file differenza tra i due getfiles"
    fi
    diffout_path="/var/tmp/checksync/diffout.csv"
fi

send_email=true
if [[ "$email" = "none" || "$email" = "" ]] ; then
    send_email=false
fi

SCRIPT_LOG="$logpath"

if [ "$testingflag" = "" ] ; then
    if [ -f "$SCRIPTPATH/utils/logger.sh" ] ; then
        source "$SCRIPTPATH/utils/logger.sh"
    else
        source "$SCRIPTPATH/logger.sh"
    fi

    DEBUG "Ho letto le configurazioni"
    DEBUG "Parametri da analizzare: '${analize_paths[*]}'"
    DEBUG "Parametri da ignorare: '${toignore_paths[*]}'"
    DEBUG "Percorso file di log: '$logpath'"
    DEBUG "Ip macchina remota: '$ip'"
    DEBUG "Username macchina remota: '$user'"
    DEBUG "Percorso remoto in cui copiare script: '$scp_path'"
    DEBUG "Percorso output lista file: '$getfiles_path'"
    DEBUG "Percorso output lista con file diversi tra le due macchine: '$diffout_path'"
    DEBUG "Indirizzo email: '$email'"

elif [ "$testingflag" = "--test" ] ; then
    echo "Analizza: '${analize_paths[*]}'"
    echo "Ignora: '${toignore_paths[*]}'"
    echo "Log: '$logpath'"
    echo "User: '$user'"
    echo "Scp: '$scp_path'"
    echo "Getfiles: '$getfiles_path'"
    echo "Diffout: '$diffout_path'"
    echo "Email: '$email'"
    echo "Sendemail: '$send_email'"
fi

if [ "$testingflag" != "--skip-conn-test" ] ; then
    # flag permette di evitare questo controllo
    if ! ismyip "$ip" ; then
        # il controllo fallo solo se sei sulla macchina locale
        if ! pingstat "$ip" ; then
            echo "$ip non rangiungibile"
            exit 17
        fi

        if ! ssh "$ip" "cd '${scp_path}'" 2> /dev/null ; then
            echo "Cartella remota in cui copiare lo script non esiste"
            exit 16
        fi
    fi
fi
