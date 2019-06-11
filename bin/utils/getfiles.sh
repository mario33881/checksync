#!/bin/bash

# ================================================= RECUPERO INFORMAZIONI =================================================
#
# Questo script si occupa di recuperare tutte le informazioni relative ai file sul computer.
#
# Per prima viene eseguita la funzione getfiles() che si occupa di eseguire prima la funzione findtree() e poi getstatnmd5()
#
# La funzione findtree() usa le informazioni ricavate dal file di configurazione per comporre il comando find
# da usare per trovare i percorsi di tutti i file presenti sulla macchina, 
# eventualmente ignorando con -prune alcuni file e/o percorsi
# Tutti i percorsi verranno scritti sul file "/var/tmp/checksync/find_output.csv"
#
# La funzione getstatnmd5() si occupa di scorrrere il file scritto dalla funzione findtree() e di
# scrivere sul file $getfiles_path il percorso dei file, dimensione in byte e timestamp dati dal comando stat,
# checksum MD5 ottenuto dal comando md5sum e l''hostname della macchina (passato al programma come secondo parametro)
#

SCRIPTPATH="$( cd "$(dirname "$0")" || exit ; pwd -P )"

machine="$2" # identificativo macchina

if [ "$boold" = "" ] ; then
	boold=false
fi

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
source "$SCRIPTPATH/configs.sh"

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
source "$SCRIPTPATH/logger.sh" # importo logger

fileoutfind_path="/var/tmp/checksync"           # percorso cartella file con tutti i percorsi di file e cartelle
mkdir -p "$fileoutfind_path"                    # creo il percorso se non esiste
fileoutfind="$fileoutfind_path/find_output.csv" # percorso completo cartella file con tutti i percorsi di file e cartelle


function findtree(){
	# La funzione si occupa di recuperare i percorsi di tutti i file e cartelle presenti sulla macchina
	# per fare questo la funzione:
	# * concatena tutti i percorsi da cercare nel comando find
	# * se sono presenti percorsi da ignorare nelle configurazioni queste verranno concatenate nel prune di find
	# Infine il comando verra' eseguito e l'output finira' nel file $fileoutfind

	ENTRY
	# variabile array che conterra il comando
	command=('find')

	# -- SEZIONE ESECUZIONE --
	if [ "$boold" = true ] ; then
		echo "Percorsi da analizzare: ${analize_paths[*]}"
		echo "Percorsi da ignorare: ${toignore_paths[*]}"
	fi

	DEBUG "Percorsi da analizzare: ${analize_paths[*]}"
	DEBUG "Percorsi da ignorare: ${toignore_paths[*]}"

	# concateno i percorsi da analizzare nel comando
	for path in "${analize_paths[@]}"
	do
		if [ "$boold" = true ] ; then
			echo "Concateno $path"
		fi
		DEBUG "Percorso da analizzare: '$path'"
		command+=("$(cd "${path}" || exit; pwd)")
	done

	if [ "$boold" = true ] ; then
		echo "Comando: '${command[*]}'"
	fi

	DEBUG "Comando percorsi NON ignorati: '${command[*]}'"

	# controllo quanti sono i percorsi da ignorare
	# se sono zero il comando find e' praticamente completo
	if [ "${#toignore_paths[@]}" -eq 0 ] ; then
		# se sono zero il comando find e' praticamente completo
		if [ "$boold" = true ] ; then
			echo "0 percorsi da ignorare"
		fi
		
		command+=( -type f ) # includi solo file
		DEBUG "Comando percorsi NON ignorati COMPLETO: '${command[*]}'"
	else
		# altrimenti bisogna aggiungere percorsi con cui fare prune
		if [ "$boold" = true ] ; then
			echo "ci cono percorsi da ignorare"
		fi
		
		# inizio a concatenare i percorsi per il prune
		command+=(\()
		for path in "${toignore_paths[@]}"
		do
			command+=("-path ${path}")
			DEBUG "Percorso da ignorare: '${path}'"
			# se path e' l'ultimo elemento del l'array di percorsi da ignorare
			# non concatenare -o (OR)
			if [ "$path" != "${toignore_paths[-1]}" ] ; then
				command+=("-o")
			fi
		done
		
		command+=(\) "-prune -o -type f -print")
		if [ "$boold" = true ] ; then
	        echo "Comando con prune: '${command[*]}'"
	    fi

		DEBUG "Comando COMPLETO: '${command[*]}'"
	fi

	# eseguo il comando e metto l'output nel file "fileoutfind"
	DEBUG "Eseguo il comando"
	sudo -n "${command[@]}" 2> /dev/null 1> "$fileoutfind"

	if [ "$?" -ne 0 ] ; then
        	INFO "Impossibile eseguire seguente find con sudo: '${command[*]}'"
		"${command[@]}" > "$fileoutfind"
	fi

	DEBUG "File '$fileoutfind' aggiornato"
	EXIT
}


function getstatnmd5(){
	# La funzione scorre il file $fileoutfind con tutti i percorsi
	# di file e cartelle, controlla se sono file o cartelle:
	# se sono file ottiene con il comando stat dimensione e ultima modifica
	# e con il comando md5sum ottiene l'hash MD5 del file.
	# Le informazioni ottenute verranno scritte sul file $getfiles_path

	ENTRY

	echo "size;last_mod;md5;macchina" > "${getfiles_path}"

	while read -r line; do
	    output=$( sudo -n stat "${line}" --format="%n;%Y;%s" 2> /dev/null )
		
		if [ "$?" -ne 0 ] ; then
            INFO "Impossibile eseguire il comando stat con sudo su: '$line'"
			output=$( stat "${line}" --format="%n;%Y;%s" )
		fi
	    
		IFS=';' read -ra ADDR <<< "$output"

	    path="${ADDR[0]}"
	    last_mod="${ADDR[1]}"
		size="${ADDR[2]}"

	    md5=$( sudo -n md5sum "$path" 2> /dev/null | awk '{ print $1 }' )
		
		if [ "$?" -ne 0 ] ; then
            		INFO "Impossibile eseguire il comando md5sum con sudo su: '$path'"
			md5=$( md5sum "$path" | awk '{ print $1 }' )
		fi

		DEBUG "Informazioni ricavate: ${path};${size};${last_mod};${md5};${machine}"
	    echo "${path};${size};${last_mod};${md5};${machine}" >> "${getfiles_path}"
	        
	done < ${fileoutfind}

	EXIT
}


function getfiles(){
	# Questa funzione si occupa di richiamare due funzioni:
	# findtree    : recupera lista di tutti i file e cartelle ignorando certi percorsi
	# getstatnmd5 : verifica quali percorsi puntano a file (non cartelle) e usa
	#		i comandi stat e md5sum per recuperare la data di ultima modifica, 
	#		la dimensione e l'hash MD5 dei file
	#

	ENTRY

	DEBUG "recupero tutti i file e le cartelle con funzione findtree"
	findtree
	DEBUG "dalla lista file e cartelle ricavo i file con dimensione, ultima modifica e md5"
	getstatnmd5
	
	EXIT
}


SCRIPTENTRY

getfiles # ottengo lista file diversi

SCRIPTEXIT
