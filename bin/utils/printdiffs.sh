#!/bin/bash

if [ "$boold" = "" ] ; then
	boold=false
fi


function bytesToHuman() {
    # converte byte in multiplo ' piu' leggibile
    b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,P,E,Z,Y}iB)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    echo "$b$d ${S[$s]}"
}


function get_csvelement() {
	# recupera dalla riga in formato csv (elementi divisi da ";") passata come primo parametro
	# l'elemento nella posizione passata come secondo parametro
	line="$1"
	n_el="$2"
	el=$( echo "$line" | awk -F "\"*;\"*" "{print \$$n_el}" )
	echo "$el"
}


function header_filesections() {
	# apro sezione file
        echo "<div style='overflow-x:auto;background-color: white;border-radius: 10px 10px 10px 10px;'>"
}


function printtable(){
	# visualizza la tabella usando questi parametri:
	# $1 e' l'identificativo della macchina ( es. 'Server 1 (locale)' )
	# $2 e' la dimensione del file
	# $3 e' la data di ultima modifica
	# $4 e' il checksum MD5

	machine="$1"
	size="$2"
	last_mod="$3"
	md5="$4"

	# inline css righe	
	oddrow_style="background-color: white;"
	evenrow_style="background-color: #f2f2f2;"
	
	# inline css colonne
	td_styles="text-align: left; padding: 8px;"
	
	echo '<table cellspacing="0" cellpadding="0" style="width: 100%; word-break:break-word;">'
	
	# thead con identificativo macchina
        printf '<thead> \n'
        printf '<tr style="%s"> \n' "$oddrow_style"
        printf '<td style="%s"></td> \n' "$td_styles"
        printf '<td style="%s"> %s </td> \n' "$td_styles" "$machine"
        printf '</tr> \n'
	printf '</thead> \n'
	
	# riga dimensione file
	printf '<tr style="%s"> \n' "$evenrow_style"
        printf '<td style="%s">Dimensione file:</td> \n' "$td_styles"
        printf '<td style="%s"> %s </td>' "$td_styles" "$size"
     	printf '</tr> \n'
	
	# riga data ultima modifica
        printf '<tr style="%s"> \n' "$oddrow_style"
        printf '<td style="%s">Ultima modifica:</td> \n' "$td_styles"
      	printf '<td style="%s"> %s </td> \n' "$td_styles" "$last_mod"
        printf '</tr> \n'

	# riga checksum md5
        printf '<tr style="%s"> \n' "$evenrow_style"
        printf '<td style="%s">Checksum MD5:</td> \n' "$td_styles"
        printf '<td style="%s"> %s </td> \n' "$td_styles" "$md5"
        printf '</tr> \n'

        printf '</table> \n'
}


function divide_filesections() {
	# divisore tra sezioni file
	printf '<hr style="display: block; height: 1px; border: 0; border-top: 15px solid #FBBA00; margin: 1em 0; padding: 0;">'
}


function printdiffs(){
	# funzione che si occupa della visualizzazione delle informazioni
	#
	# il primo parametro punta al file in cui e' stato inserito il contenuto 
	# ordinato delle due liste file delle macchine.
	# il secondo parametro indica come visualizzare l'output:
	# * echo (default) : visualizza tabelle con le informazioni
	# * html : restituisce html pronto per essere usato come body di una mail
	#
	# Per verificare se un file e' presente in entrambe le macchine
	# viene controllato se il percorso e' uguale al percorso della riga precedente:
	# * se i percorsi sono uguali, vengono confrontati md5, dimensione file e data di ultima modifica,
	#   se anche questi sono uguali allora i file sono uguali, se una sola delle proprieta' 
	#   e' diversa i file sono diversi
	#
	# * se i percorsi sono diversi significa che il percorso del file precedente e' unico:
	#   il file e' presente su una sola delle due macchine: viene usata l'ultima proprieta' : 
	#   la locazione del file per capire su quale macchina e' presente il file

	diffile="$1"
	outformat="$2"
	
	if [ "$outformat" = "" ] ; then
		outformat="echo"
	fi
	skip=true
	oldpath=""
	oldline=""
	
	if [ "$outformat" = "html" ] ; then
		printf '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n'
		printf '<html xmlns="http://www.w3.org/1999/xhtml">\n'
		printf "<head> \n <meta http-equiv='Content-Type' content='text/html; charset=UTF-8' /> \n" 
		printf "<title>%s</title> \n"  "checksync report"
		printf "<meta name='viewport' content='width=device-width, initial-scale=1.0'/> \n </head>"
		echo "<body style='width:100%; height: 100%; margin:0;font-family: "Segoe UI", Roboto'>"
		
		# apertura div principale (sfondo arancio/giallo, larghezza massima, altezza minima 100%)
		echo '<div style="position: absolute; background-color: #FBBA00; min-height: 100%; width:100%">'
		
		# apertura sezione titolo, testo bianco e centrato
		echo "<div style='color:white; text-align: center;'>"
		echo "<h1 style='margin-bottom: 0px;'>Checksync report</h1> "
		data=$( date +'%F %T' )
		echo "<h2 style='margin-top: 0px;'> ${data} </h2> "
		printf '</div> \n'
		# chiusura sezione titolo
	fi

	if [ "$diffile" != "" ] ; then
		if [[ -f "$diffile" ]] ; then
			
			while IFS= read -r line
			do
				col1=$( echo "$line" | awk -F "\"*;\"*" '{print $1}' )

	                        path="${col1}"
				
				if [ "${line:0:1}" = "/" ] ; then
				
					if ! "$skip" ; then

						if [ "$oldpath" = "$path" ] ; then
							if [ "$boold" = true ] ; then
								echo "Percorso gia' visto: $oldpath ($path)"
							fi
							skip=true # salto prossima riga per trovare nuove eventuali ricorrenze
							
							# ottengo dimensione file macchina fisica ( < )
							el2f1=$( get_csvelement "$oldline" 2 )
							size1=$( bytesToHuman "$el2f1" )
							
							# ottengo dimensione file macchina remota ( > )
							el2f2=$( get_csvelement "$line" 2 )
	                                                size2=$( bytesToHuman "$el2f2" )
						
							# ottengo ultima modifica file macchina fisica ( < )
							last_mod1ts=$( get_csvelement "$oldline" 3 )

							if [[ "$last_mod1ts" =~ ^[0-9]+$ ]] ; then
								last_mod1=$( date -d @"$last_mod1ts" +"%F %T" )
							fi

							# ottengo ultima modifica file macchina remota ( > )
	                                                last_mod2ts=$( get_csvelement "$line" 3 )
  							if [[ "$last_mod2ts" =~ ^[0-9]+$ ]] ; then
                                                                last_mod2=$( date -d @"$last_mod2ts" +"%F %T" )
                                                        fi							

							# checksum MD5 file macchina fisica ( < )
							md51=$( get_csvelement "$oldline" 4 )

							# checksum MD5 file macchina remota ( > )
	                                                md52=$( get_csvelement "$line" 4 )
        						#echo "Dimensione file macchina fisica: $size1"
                                                        #echo "Dimensione file macchina remota: $size2"
                                                        #echo "Data ultima modifica file macchina fisica: $last_mod1"
                                                        #echo "Data ultima modifica file macchina remota: $last_mod2"
                                                        #echo "Checksum MD5 file macchina fisica: $md51"
                                                        #echo "Checksum MD5 file macchina remota: $md52"

							if [ "$el2f1" = "$el2f2" ] && [ "$md51" = "$md52" ] ; then
								: # file uguali, non fare niente
							else
								if [ "$outformat" = "html" ] ; then

									# titolo sezione e percorso file
									#printf "<h3>File presente su entrambe le macchine (locale e remota)</h3><p>%s</p>\n" "$path"
									
									# header sezione con tutti i file
                							header_filesections
									printf "<h3>File presente su entrambe le macchine (locale e remota)</h3><p>%s</p>\n" "$path"
									# tabelle
									printtable "Server 1 (locale)" "$size1" "$last_mod1" "$md51"
									printtable "Server 2 (remoto)" "$size2" "$last_mod2" "$md52"
									echo "</div>"
									divide_filesections
								
								else
									printf "File presente su entrambe le macchine (locale e remota)\n$path\n\n"
								
									printf "%34s %34s %34s \n" "" "Server 1 (locale)" "Server 2 (remoto)"
									printf "%s\n" "---------------------------------- ---------------------------------- ----------------------------------"
									printf "%34s %34s %34s \n" "Dimensione file:" "$size1" "$size2"
									printf "%34s %34s %34s \n" "Ultima modifica:" "$last_mod1" "$last_mod2"
									printf "%34s %34s %34s \n" "Checksum MD5:" "$md51" "$md52"
                                    			                printf "\n==========================================================================================================\n\n"
									
								fi
							fi
						else
							if [ "$boold" = true ] ; then
								echo "Percorso mai visto $oldpath"
							fi
							
							machine=$( get_csvelement "$oldline" 5 )
							if [ "${machine}" = "Server 1" ] ; then
								if [ "$boold" = true ] ; then
									echo "Appartiene macchina 1"
								fi

								# ottengo dimensione file macchina fisica ( < )
	                                                	el2f1=$( get_csvelement "$oldline" 2 )
	                                                	size1=$( bytesToHuman "$el2f1" )
							
								# ottengo ultima modifica file macchina fisica ( < )
								last_mod1ts=$( get_csvelement "$oldline" 3 )

	                                                        if [[ "$last_mod1ts" =~ ^[0-9]+$ ]] ; then
	                                                                last_mod1=$( date -d @"$last_mod1ts" +"%F %T" )
	                                                        fi		                                                
								
								# checksum MD5 file macchina fisica ( < )
		                                                md51=$( get_csvelement "$oldline" 4 )
									
								#echo "Dimensione file macchina fisica: $size1"
								#echo "Data ultima modifica file macchina fisica: $last_mod1"
								#echo "Checksum MD5 file macchina fisica: $md51"

								if [ "$outformat" = "html" ] ; then
									# header sezione con tutti i file
                                                                        header_filesections
	                                                                printf "<h3>File presente SOLO sulla macchina 1 (locale)</h3><p>%s</p>\n" "$oldpath"
	                                                                printtable "Server 1 (locale)" "$size1" "$last_mod1" "$md51"
									echo "</div>"
									divide_filesections
	                                                        else
									printf "File presente SOLO sulla macchina 1 (locale)\n$oldpath\n\n"

			                                                printf "%34s %34s \n" "" "Server 1 (locale)"
			                                                printf "%s\n" "---------------------------------- ----------------------------------"
			                                                printf "%34s %34s \n" "Dimensione file:" "$size1"
			                                                printf "%34s %34s \n" "Ultima modifica:" "$last_mod1"
			                                                printf "%34s %34s \n" "Checksum MD5:" "$md51"
								fi
							else
								if [ "$boold" = true ] ; then
									echo "Appartiene macchina 2"
								fi

								# ottengo dimensione file macchina remota ( > )
	                                                        el2f2=$( get_csvelement "$oldline" 2 )
	                                                        size2=$( bytesToHuman "$el2f2" )

	                                                        # ottengo ultima modifica file macchina remota ( > )
								last_mod2ts=$( get_csvelement "$oldline" 3 )
	                                                        if [[ "$last_mod2ts" =~ ^[0-9]+$ ]] ; then
	                                                                last_mod2=$( date -d @"$last_mod2ts" +"%F %T" )
	                                                        fi

	                                                        # checksum MD5 file macchina remota ( > )
	                                                        md52=$( get_csvelement "$oldline" 4 )

	                                                        #echo "Dimensione file macchina fisica: $size2"
	                                                        #echo "Data ultima modifica file macchina fisica: $last_mod2"
	                                                        #echo "Checksum MD5 file macchina fisica: $md52"
								if [ "$outformat" = "html" ] ; then
									# header sezione con tutti i file
                                                                        header_filesections
                                                                        printf "<h3>File presente SOLO sulla macchina 2 (remota)</h3><p>%s</p>\n" "$oldpath"
                                                                        printtable "Server 2 (remoto)" "$size2" "$last_mod2" "$md52"
									echo "</div>"
									divide_filesections
                                                                else
									printf "File presente SOLO sulla macchina 2 (remota)\n$oldpath\n\n"

		                                                        printf "%34s %34s \n" "" "Server 2 (remoto)"
		                                                        printf "%s\n" "---------------------------------- ----------------------------------"
		                                                        printf "%34s %34s \n" "Dimensione file:" "$size2"
		                                                        printf "%34s %34s \n" "Ultima modifica:" "$last_mod2"
		                                                        printf "%34s %34s \n" "Checksum MD5:" "$md52"
								fi
							fi

							if [ "$outformat" = "echo" ] ; then
                                                        	printf "\n==========================================================================================================\n\n"
                                                	fi
						fi
					else
						skip=false
					fi
					oldpath="$path"
					oldline="$line"
				fi
			done < "$diffile"

			if [ "$outformat" = "html" ] ; then
				printf "</div> \n </body> \n </html>"
			fi
		else
			echo "File in input non esistenti"
			exit 17
		fi
	else
		echo "Numero parametri errato"
	        echo "printdiffs.sh <filepath> [<output format>]"
		exit 16
	fi
}
