#!/bin/bash

boold=false
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )" # percorso questo script

# prende parametro file di configurazione ( $configfile ) e gestisce parametri
# variabili con parametri:
# analize_paths[@] : array con parametri da analizzare
# toignore_paths[@]: array con parametri da ignorare
# logpath          : percorso file di log
# ip               : ip macchina remota
# user             : username macchina remota
# pass             : password macchina remota
# scp_path         : percorso remoto a cui copiare script
# getfiles_path    : percorso file con informazioni files computer
# diffout_path     : percorso file con differenze delle informazioni files
source "$SCRIPTPATH/utils/configs.sh"

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
	
	DEBUG "Comando da eseguire: '${command[@]}'"
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

SCRIPTENTRY

# copio script sul server remoto
cmd=( scp -r "$SCRIPTPATH" "${user}@${ip}:${scp_path}" )
checksuccess 5 "Copia script su server remoto" "${cmd[@]}"

# salvo file di configurazione sul server remoto
cmd=( scp "$configfile" "${user}@${ip}:${scp_path}/${PWD##*/}" )
checksuccess 6 "Copia file di configurazione sul server remoto" "${cmd[@]}"

# ottengo lista file su questo pc e salvo percorso file output locale
cmd=( "$SCRIPTPATH/utils/getfiles.sh" "$configfile" )
checksuccess 7 "Operazione recupero lista file di questa macchina" "${cmd[@]}"

# ottengo lista file su server remoto e salvo percorso file output remoto
inifilename=$( basename "$configfile" )
cmd=( ssh "${user}@${ip}" "${scp_path}/${PWD##*/}/utils/getfiles.sh ${scp_path}/${PWD##*/}/${inifilename}" )
checksuccess 8 "Operazione lista file macchina remota" "${cmd[@]}"

# recupero log del computer remoto
cmd=( ssh "${user}@${ip}" "cat '$logpath'" )

while IFS= read -r line
# scorri log
do
	echo "$line" >> "$logpath"
done < <( checksuccess 16 "Recupero file log remoto" "${cmd[@]}" ) # comando con stdout

# rimuovo log incompleto remoto
cmd=( ssh "${user}@${ip}" "rm '$logpath'" )
checksuccess 17 "Rimuovo file log remoto perche' incompleto" "${cmd[@]}"

# eseguo diff tra i due output, ordinando l'output del diff in ordine alfabetico ("ignorando" < e >)
if [ "$boold" = true ] ; then
	echo -e "\nOperazione recupero output lista file e diff tra liste file locale e remota"
fi

ssh "${user}@${ip}" "cat $getfiles_path" | diff "$getfiles_path" -  | sort -k1.2 > "$diffout_path"
status_code="$?"

DEBUG "Comando da eseguire: 'ssh "${user}@${ip}" "cat $getfiles_path" | diff - "$getfiles_path" | sort -k1.2 > "$diffout_path"'"
DEBUG "Descrizione comando: 'Operazione recupero output lista file e diff tra liste file locale e remota'"
DEBUG "Codice errore in caso di fallimento esecuzione: '9'"

if [ "$status_code" -ne 0 ] ; then
	# se l'operazione NON ha avuto successo, esci con status code 9
	echo "Operazione recupero output lista file e diff tra liste file locale e remota FALLITA (status code $status_code )"
    exit 9
fi

# visualizza le informazioni ricavate
source "$SCRIPTPATH/utils/printdiffs.sh"
cmd=( printdiffs "$diffout_path" )
checksuccess 11 "Visualizzazione differenze tra le due macchine" "${cmd[@]}"

# manda mail se e' installato sendmail e se e' stata inserita una mail nel file di configurazione
sendmail_path=$( command -v sendmail )
if [ "$sendmail_path" != "" ] ; then
	if [ "$boold" = true ] ; then
		echo "Sendmail e' installato"
	fi
	
	data=$( date +"%F %T" )
	htmlmessage=$( printdiffs "$diffout_path" "html" )
	(
	echo "From: checksyncscript@bashscript.com";
	echo "To: <destination email>";
	echo "Subject:Checksinc report ${data}";
	echo "Content-Type: text/html";
	echo "MIME-Version: 1.0";
	echo "";
	echo "$htmlmessage";
	) | sendmail -t
	
fi

SCRIPTEXIT
