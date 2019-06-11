#!/bin/bash

if [ "$boold" = "" ] ; then
	boold=false # variabile debug
fi

configfile=$1 # percorso file configurazione
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )" # percorso questo script

# ============================================ GESTIONE FILE DI CONFIGURAZIONE ============================================
#
# Questa parte di programma controlla se e' stato passato il parametro con il percorso del file di configurazione 
# e se questo file esiste, se non e' stato passato il parametro il programma uscira' con status 2, 
# se il percorso non punta ad un file esistente il programma uscira' con status 1, 
# altrimenti il programma continuera' la sua esecuzione

if [ "$configfile" != "" ] ; then
	if [ -f "$configfile" ] ; then
		# ogni 	riga di configurazione deve avere la sua sezione
		configcmd=( awk -F= '/\[/{prefix=$0; next} $1{$1=$1; print prefix $0}' OFS=' = ' "$configfile" )

		analize_paths=()  # contiene percorsi da analizzare
		toignore_paths=() # contiene percorsi da ignorare

		# leggi riga per riga di stdout del comando configcmd
		while IFS= read -r line
		do
			if [[ "$line" = "[ANALIZZA]"* ]] ; then
				# se la configurazione e' nella sezione analizza...
				path=$( echo "${line:10}" | sed -e 's/^[[:space:]]*//' ) # rimuovi eventuali spazi prima e dopo il percorso
				analize_paths+=("${path}") # aggiungi percorso al vettore

			elif [[ "$line" = "[IGNORA]"* ]] ; then
				# se la configurazione e' nella sezione ignora...
				path=$( echo "${line:8}" | sed -e 's/^[[:space:]]*//' ) # rimuovi eventuali spazi prima e dopo il percorso
               			toignore_paths+=("${path}") # aggiungi percorso al vettore
	
			elif [[ "$line" = "[LOG]path = "* ]] ; then
				# se la configurazione e' nella sezione log, proprieta' path
				logpath="${line:12}" # salva percorso del file di log
	
			elif [[ "$line" = "[MACCHINA 2]ip = "* ]] ; then
				# se la configurazione e' nella sezione macchina 2, proprieta' ip
				ip="${line:17}" # salva indirizzo ip

			elif [[ "$line" = "[MACCHINA 2]user = "* ]] ; then
                		# se la configurazione e' nella sezione macchina 2, proprieta' user
                		user="${line:19}" # salva username
	
			elif [[ "$line" = "[MACCHINA 2]scppath = "* ]] ; then
                		# se la configurazione e' nella sezione macchina 2, proprieta' scppath
                		scp_path="${line:22}" # salva scp path
			
			elif [[ "$line" = "[OUTPUT]getfiles = "* ]] ; then
                		# se la configurazione e' nella sezione output, proprieta' getfiles
                		getfiles_path="${line:19}" # salva percorso output getfiles
	
			elif [[ "$line" = "[OUTPUT]diffout = "* ]] ; then
                		# se la configurazione e' nella sezione output, proprieta' diffout
                		diffout_path="${line:18}" # salva percorso output diffout
			
			elif [[ "$line" = "[NOTIFICHE]email = "* ]] ; then
                                # se la configurazione e' nella sezione notifiche, proprieta' email
                                email="${line:19}" # salva indirizzo email
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
		exit 2
	fi
	
else
	echo "Parametro file di configurazione mancante"
	exit 1
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
	echo -e "\n${analize_paths[@]}"
	echo "Nessun percorso da analizzare"
	exit 3
fi

if [ "${logpath}" = "" ] ; then
	if [ "$boold" = true ] ; then
        	echo "Verra' usato percorso log di default"
	fi
	logpath=/var/log/checksync/checksync.log
fi

if [ "${ip}" = "" ] ; then
        echo "Manca l'indirizzo IP della macchina a cui connettersi"
        exit 4
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

if [ -f "$SCRIPTPATH/utils/logger.sh" ] ; then
	source "$SCRIPTPATH/utils/logger.sh"
else
	source "$SCRIPTPATH/logger.sh"
fi

DEBUG "Ho letto le configurazioni"
DEBUG "Parametri da analizzare: '${analize_paths[@]}'"
DEBUG "Parametri da ignorare: '${toignore_paths[@]}'"
DEBUG "Percorso file di log: '$logpath'"
DEBUG "Ip macchina remota: '$ip'"
DEBUG "Username macchina remota: '$user'"
DEBUG "Percorso remoto in cui copiare script: '$scp_path'"
DEBUG "Percorso output lista file: '$getfiles_path'"
DEBUG "Percorso output lista con file diversi tra le due macchine: '$diffout_path'"
DEBUG "Indirizzo email: '$email'"
