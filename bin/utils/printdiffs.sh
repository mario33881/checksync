#!/bin/bash

if [ "$boold" = "" ] ; then
	boold=true
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


function printdiffs(){
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
		printf "<head> \n <meta http-equiv='Content-Type' content='text/html; charset=UTF-8' /> \n <title>%s</title> \n"  "checksync report"
		#printf "<style> table { border-collapse: collapse; width: 100%; }th, td { text-align: left; padding: 8px; }tr:nth-child(even) {background-color: #f2f2f2;} </style>\n"
  		echo '<style type="text/css"> table { border-collapse: collapse; width: 100%; }th, td { text-align: left; padding: 8px; }tr:nth-child(even) {background-color: #f2f2f2;} </style>'
		printf "<meta name='viewport' content='width=device-width, initial-scale=1.0'/> \n </head>"
		printf "<body> \n <div style='overflow-x:auto;'> \n"
	fi

	if [ "$diffile" != "" ] ; then
		if [[ -f "$diffile" ]] ; then
			
			while IFS= read -r line
			do
				col1=$( echo "$line" | awk -F "\"*;\"*" '{print $1}' )

	                        path="${col1:2}"
				
				if [[ "${line:0:1}" = "<" || "${line:0:1}" = ">" ]] ; then
				
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
							last_mod1=$( date -d @"$last_mod1ts" +"%F %T" )

							# ottengo ultima modifica file macchina remota ( > )
	                                                last_mod2ts=$( get_csvelement "$line" 3 )
							last_mod2=$( date -d @"$last_mod2ts" +"%F %T" )

							# checksum MD5 file macchina fisica ( < )
							md51=$( get_csvelement "$oldline" 4 )

							# checksum MD5 file macchina remota ( > )
	                                                md52=$( get_csvelement "$oldline" 4 )
							
							#echo "Dimensione file macchina fisica: $size1"
							#echo "Dimensione file macchina remota: $size2"
							#echo "Data ultima modifica file macchina fisica: $last_mod1"
							#echo "Data ultima modifica file macchina remota: $last_mod2"
							#echo "Checksum MD5 file macchina fisica: $md51"
							#echo "Checksum MD5 file macchina remota: $md52"
							
							if [ "$outformat" = "html" ] ; then
								printf "<h3>File presente su entrambe le macchine (locale e remota)</h3><p>%s</p>\n" "$path"
								echo "<table style='border-collapse: collapse; width: 100%;'>"
								printf "<thead><tr><td>%s</td><td>%s</td><td>%s</td></tr></thead> \n" "" "Server 1 (locale)" "Server 2 (remoto)"
								printf "<tr><td>%s</td><td>%s</td><td>%s</td></tr> \n" "Dimensione file:" "$size1" "$size2"
								printf "<tr><td>%s</td><td>%s</td><td>%s</td></tr> \n" "Ultima modifica:" "$last_mod1" "$last_mod2"
								printf "<tr><td>%s</td><td>%s</td><td>%s</td></tr> \n" "Checksum MD5:" "$md51" "$md52"
								printf "</table>\n"
							else
								printf "File presente su entrambe le macchine (locale e remota)\n$path\n\n"
							
								printf "%34s %34s %34s \n" "" "Server 1 (locale)" "Server 2 (remoto)"
								printf "%s\n" "---------------------------------- ---------------------------------- ----------------------------------"
								printf "%34s %34s %34s \n" "Dimensione file:" "$size1" "$size2"
								printf "%34s %34s %34s \n" "Ultima modifica:" "$last_mod1" "$last_mod2"
								printf "%34s %34s %34s \n" "Checksum MD5:" "$md51" "$md52"
								
							fi
						else
							if [ "$boold" = true ] ; then
								echo "Percorso mai visto $oldpath"
							fi

							if [ "${oldline:0:1}" = "<" ] ; then
								if [ "$boold" = true ] ; then
									echo "Appartiene macchina 1"
								fi

								# ottengo dimensione file macchina fisica ( < )
	                                                	el2f1=$( get_csvelement "$oldline" 2 )
	                                                	size1=$( bytesToHuman "$el2f1" )
							
								# ottengo ultima modifica file macchina fisica ( < )
		                                                last_mod1ts=$( get_csvelement "$oldline" 3 )
		                                                last_mod1=$( date -d @"$last_mod1ts" +"%F %T" )
					
								# checksum MD5 file macchina fisica ( < )
		                                                md51=$( get_csvelement "$oldline" 4 )
									
								#echo "Dimensione file macchina fisica: $size1"
								#echo "Data ultima modifica file macchina fisica: $last_mod1"
								#echo "Checksum MD5 file macchina fisica: $md51"
								if [ "$outformat" = "html" ] ; then
	                                                                printf "<h3>File presente SOLO sulla macchina 1 (locale)</h3><p>%s</p>\n" "$oldpath"
	                                                                echo "<table style='border-collapse: collapse; width: 100%;'>"
	                                                                printf "<thead><tr><td>%s</td><td>%s</td></tr></thead> \n" "" "Server 1 (locale)"
	                                                                printf "<tr><td>%s</td><td>%s</td></tr> \n" "Dimensione file:" "$size1"
	                                                                printf "<tr><td>%s</td><td>%s</td></tr> \n" "Ultima modifica:" "$last_mod1"
	                                                                printf "<tr><td>%s</td><td>%s</td></tr> \n" "Checksum MD5:" "$md51"
	                                                                printf "</table>\n"
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
	                                                        last_mod2=$( date -d @"$last_mod2ts" +"%F %T" )

	                                                        # checksum MD5 file macchina remota ( > )
	                                                        md52=$( get_csvelement "$oldline" 4 )

	                                                        #echo "Dimensione file macchina fisica: $size2"
	                                                        #echo "Data ultima modifica file macchina fisica: $last_mod2"
	                                                        #echo "Checksum MD5 file macchina fisica: $md52"
								if [ "$outformat" = "html" ] ; then
                                                                        printf "<h3>File presente SOLO sulla macchina 2 (remota)</h3><p>%s</p>\n" "$oldpath"
                                                                        echo "<table style='border-collapse: collapse; width: 100%;'>"
                                                                        printf "<thead><tr><td>%s</td><td>%s</td></tr></thead> \n" "" "Server 2 (remoto)"
                                                                        printf "<tr><td>%s</td><td>%s</td></tr> \n" "Dimensione file:" "$size2"
                                                                        printf "<tr><td>%s</td><td>%s</td></tr> \n" "Ultima modifica:" "$last_mod2"
                                                                        printf "<tr><td>%s</td><td>%s</td></tr> \n" "Checksum MD5:" "$md52"
                                                                        printf "</table>\n"
                                                                else
									printf "File presente SOLO sulla macchina 2 (remota)\n$oldpath\n\n"

		                                                        printf "%34s %34s \n" "" "Server 2 (remoto)"
		                                                        printf "%s\n" "---------------------------------- ----------------------------------"
		                                                        printf "%34s %34s \n" "Dimensione file:" "$size2"
		                                                        printf "%34s %34s \n" "Ultima modifica:" "$last_mod2"
		                                                        printf "%34s %34s \n" "Checksum MD5:" "$md52"
								fi
							fi
						fi

						if [ "$outformat" = "echo" ] ; then
							printf "\n==========================================================================================================\n\n"
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
	        echo "printdiffs.sh <configfile> <filediff1> <filediff2> <output>"
		exit 16
	fi
}
