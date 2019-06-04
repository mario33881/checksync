#!/bin/bash

# ============================= DIVIDI OUTPUT DIFF IN DUE (MACCHINA LOCALE E MACCHINA REMOTA) =============================
#
# Questo script si occupa di dividere l'output di diff (primo parametro, $filein = $1) in due file separati
# (secondo parametro, $fileout1 = $2 e terzo parametro $fileout2 = $3).
#
# Questo serve per permettere allo script python di analizzare contemporaneamente i due file
# per capire quali file sono presenti in entrambe le macchine, solo nella macchina locale o solo nella macchina remota
#
# > I percorsi appartengono a file gia' diversi ( verificato precedentemente dal comando diff )
# 
# > Se non vengono passati tutti i parametri lo script uscira' con status code 12
#
# > Se il primo parametro non punta ad un file in input esistente lo script uscira' con status code 13
#

SCRIPTENTRY

function analizediffs(){

	filein="$1"   # file in input, output del comando diff
	fileout1="$2" # file in output, percorsi file macchina 1 diversi rispetto ai percorsi macchina 2
	fileout2="$3" # file in output, percorsi file macchina 2 diversi rispetto ai percorsi macchina 1

	if [[ "$filein" != "" && "$fileout1" != "" && "$fileout2" != "" ]] ; then
		# sono stati passati tutti e tre i parametri
		DEBUG "Sono stati passati tutti e tre i parametri richiesti:"
		DEBUG "File in input: '$filein'"
		DEBUG "File output macchina 1 (locale): '$fileout1'"
		DEBUG "File output macchina 2 (remota): '$fileout2'"

		if [[ -f "$filein" ]]; then
			# il file in input esiste

			printf "" > "$fileout1" # mi assicuro che il file output macchina 1 sia vuoto
			printf "" > "$fileout2" # mi assicuro che il file output macchina 2 sia vuoto
			
			# scorro file in input
			DEBUG "Inizio lettura file"
			while IFS= read -r line; do
				if [[ "${line:0:1}" = ">" ]] ; then
					# se la riga comincia con > il file appartiene alla macchina 1 (locale)
					echo "$( echo ${line} | awk '{print $2}' )" >> "$fileout1"
					DEBUG "macchina1 (locale) : $line"

				elif [[ "${line:0:1}" = "<" ]] ; then
					# se la riga comincia con < il file appartiene alla macchina 2 (remota)
					echo "$( echo ${line} | awk '{print $2}' )" >> "$fileout2"
					DEBUG "macchina2 (remota) : $line"
				fi

			done < "$filein" # scorro questo file (file in input)
			DEBUG "Fine lettura file"
		else
			# il percorso non corrisponde a quello di nessun file esistente
			echo "Il file in input non esiste"
			ERROR "Il file in input non esiste"
			exit 13
		fi
	else
		# non sono stati passati tutti i parametri
		echo "Non sono stati passati tutti i parametri:"
		echo "analizeout.sh <filein> <fileout1> <fileout2>"
		echo "<filein>   : file in input, output del comando diff"
		echo "<fileout1> : file in output, conterra' righe primo file passato a diff"
		echo "<fileout2> : file in output, conterra' righe secondo file passato a diff"
		ERROR "Non sono stati passati tutti i parametri"

		exit 12
	fi
}

SCRIPTEXIT
