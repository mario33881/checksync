#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

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

fileoutfind_path="/var/tmp/bashsincserver"      # percorso cartella file con tutti i percorsi di file e cartelle
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
		echo "Percorsi da analizzare: ${analize_paths[@]}"
		echo "Percorsi da ignorare: ${toignore_paths[@]}"
	fi

	DEBUG "Percorsi da analizzare: ${analize_paths[@]}"
	DEBUG "Percorsi da ignorare: ${toignore_paths[@]}"

	# concateno i percorsi da analizzare nel comando
	for path in "${analize_paths[@]}"
	do
		if [ "$boold" = true ] ; then
			echo "Concateno $path"
		fi
		INFO "Percorso da analizzare: '$path'"
		command+=("$(cd ${path}; pwd)")
	done

	if [ "$boold" = true ] ; then
		echo "Comando: '${command[@]}'"
	fi

	DEBUG "Comando percorsi NON ignorati: '${command[@]}'"

	# controllo quanti sono i percorsi da ignorare
	# se sono zero il comando find e' praticamente completo
	if [ "${#toignore_paths[@]}" -eq 0 ] ; then
		# se sono zero il comando find e' praticamente completo
		if [ "$boold" = true ] ; then
			echo "0 percorsi da ignorare"
		fi
		
		INFO "Comando percorsi NON ignorati COMPLETO: '${command[@]}'"
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
		
		command+=(\) "-prune -o -print")
		if [ "$boold" = true ] ; then
	                echo "Comando con prune: '${command[@]}'"
	        fi

		INFO "Comando COMPLETO: '${command[@]}'"
	fi

	# eseguo il comando e metto l'output nel file "fileoutfind"
	DEBUG "Eseguo il comando"
	
	${command[@]} > $fileoutfind
	INFO "File '$fileoutfind' aggiornato"
	EXIT
}


function getstatnmd5(){
	# La funzione scorre il file $fileoutfind con tutti i percorsi
	# di file e cartelle, controlla se sono file o cartelle:
	# se sono file ottiene con il comando stat dimensione e ultima modifica
	# e con il comando md5sum ottiene l'hash MD5 del file.
	# Le informazioni ottenute verranno scritte sul file $getfiles_path

	ENTRY

	echo "path;size;last_mod;md5" > ${getfiles_path}

	while read line; do
	        output=$( stat "${line}" --format="%F;%n;%Y;%s" )

	        if [[ $output = 'regular file;'* ]] ; then

	                IFS=';' read -ra ADDR <<< "$output"

	                path="${ADDR[1]}"
	                size="${ADDR[3]}"
	                last_mod="${ADDR[2]}"
	                md5=$( md5sum "$path" | awk '{ print $1 }' )
			
			DEBUG "Informazioni ricavate: ${path};${size};${last_mod};${md5}"
	                echo "${path};${size};${last_mod};${md5}" >> ${getfiles_path}
	        fi
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

	DEBUG "recupero tutti i file e le cartelle con findtree()"
	findtree
	DEBUG "dalla lista file e cartelle ricavo i file con dimensione, ultima modifica e md5"
	getstatnmd5
	
	EXIT
}


SCRIPTENTRY

getfiles # ottengo lista file diversi

SCRIPTEXIT
