#!/bin/bash

# ============================================== VISUALIZZAZIONE INFORMAZIONI ===============================================
#
# Questo script si occupa della visualizzazione delle informazioni ricavate dagli altri script.
# La funzione principale, "printdiffs", richiede come parametro il percorso del file output del comando cat
# che contiene tutte le informazioni dei file sia del server remoto, sia del server locale.
#
# Il file viene letto riga per riga, confrontando la riga letta con la riga precedente:
# * se il percorso del file della riga precedente e' uguale al percorso del file sulla riga attuale
#   allora i file sono presenti su entrambe le macchine e verranno visualizzate le informazioni di entrambe.
#   ( se dimensioni e checksum MD5 sono diversi )
#
#   > non ha senso quindi confrontare la riga attuale con la riga successiva perche' sappiamo gia' 
#     che i file sono presenti su entrambe le macchine, la riga successiva dovra' essere confrontata con la sua riga successiva 
#
# * se i percorsi sono diversi significa che la riga precedente appartiene ad un solo server
#   > le informazioni del file sono identificate dall'hostname della macchina
#
# > Per leggere i singoli elementi del file csv viene usata la funzione get_csvelement()
#
# Per visualizzare le informazioni printdiffs() usera' le funzioni:
# * bytesToHuman() per rendere la dimensione in byte facilmente leggibili
# * header_filesections(), printtable() e divide_filesections() per comporre l'html da mandare via email
#

if [ "$boold" = "" ] ; then
    boold=false
fi


function bytesToHuman() {
    # converte parametro byte in multiplo piu' leggibile  ( se il parametro e' numero e >= 0 )
    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]] ; then
        echo "Il parametro passato non e' un numero o non e' valido ( >= 0 )"
        return 42
    fi

    b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,P,E,Z,Y}iB)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        (( s++ ))
    done
    echo "$b$d ${S[$s]}"
}


function get_csvelement() {
    # recupera dalla riga in formato csv (elementi divisi da ";") passata come primo parametro
    # l'elemento nella posizione passata come secondo parametro
    line="$1"
    n_el="$2"
    re='^[0-9]+$'

    # conto quanti separatori sono presenti nella stringa
    char=";"
    n_dels=$( awk -F"${char}" '{print NF-1}' <<< "${line}" )

    # controllo dei parametri
    if [ "$line" = "" ] ; then
        # se la stringa e' vuota esci con status code 44
        echo "Primo parametro stringa in formato csv vuoto"
        return 44

    elif ! [[ "$n_el" =~ $re ]] ; then
        # se il parametro indice non e' un numero esci con status code 43
        echo "Il parametro index passato non e' un numero o non e' valido ( > 0 )"
        return 43
    fi

    el=$( echo "$line" | awk -F "\"*;\"*" "{print \$$n_el}" )

    if [ "$n_el" -gt "$(( $n_dels+1 ))" ] ; then
        # se l'indice e' maggiore del numero dei delimitatori + 1, ho "out of range"
        echo "Parametro index troppo grande"
        return 45

    elif [ "$el" = "$line" ] ; then
        echo "Il primo parametro non contiene delimitatori o parametro index 0"
        return 46
    fi

    echo "$el"
}


function header_filesections() {
    # apro sezione file
        echo "<div style='overflow-x:auto;background-color: white;border-radius: 10px 10px 10px 10px;'>"
}


function printtable(){
    # visualizza la tabella html usando questi parametri:
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
        printf '<td style="%s"> %s </td> \n' "$td_styles" "$size"
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


function echo_stats(){
    printf "Sul server %s sono stati analizzati %s file di cui %s sono presenti sul server %s %s\n" "$1" "$2" "$3" "$4" "$5"
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
    curr_hostname=$( hostname )
    
    n_files1=0
    n_files2=0
    n_eqfiles1=0
    n_eqfiles2=0

    #declare -F

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
                # leggo primo campo con il percorso del flie
                col1=$( echo "$line" | awk -F "\"*;\"*" '{print $1}' )
                            path="${col1}"
                
                if [ "${line:0:1}" = "/" ] ; then
                    # verifico che la riga cominci con "/" (quindi che sia un percorso assoluto)
                    if ! "$skip" ; then
                        # non devo saltare la riga 
                        # (la riga deve essere saltata se sono stati trovati due percorsi uguale)
                        if [ "$oldpath" = "$path" ] ; then
                            # il percorso della riga precedente e' uguale a quello attuale:	
                            # i file sono presenti su entrambe le macchine

                            if [ "$boold" = true ] ; then
                                echo "Percorso gia' visto: $oldpath ($path)"
                            fi

                            skip=true # salto prossima riga per trovare nuove eventuali ricorrenze
                            
                            # ottengo dimensione file macchina locale
                            el2f1=$( get_csvelement "$oldline" 2 )
                            size1=$( bytesToHuman "$el2f1" )
                            
                            # ottengo dimensione file macchina remota 
                            el2f2=$( get_csvelement "$line" 2 )
                                                    size2=$( bytesToHuman "$el2f2" )
                        
                            # ottengo ultima modifica file macchina locale
                            last_mod1ts=$( get_csvelement "$oldline" 3 )

                            if [[ "$last_mod1ts" =~ ^[0-9]+$ ]] ; then
                                last_mod1=$( date -d @"$last_mod1ts" +"%F %T" )
                            fi

                            # ottengo ultima modifica file macchina remota
                                                    last_mod2ts=$( get_csvelement "$line" 3 )
                              if [[ "$last_mod2ts" =~ ^[0-9]+$ ]] ; then
                                                                last_mod2=$( date -d @"$last_mod2ts" +"%F %T" )
                                                        fi

                            # checksum MD5 file macchina locale
                            md51=$( get_csvelement "$oldline" 4 )

                            # checksum MD5 file macchina remota
                                                    md52=$( get_csvelement "$line" 4 )

                            # hostname macchina locale
                            hostname1=$( get_csvelement "$oldline" 5 )

                            # hostname macchina remota
                                                        hostname2=$( get_csvelement "$line" 5 )
                            
                            if declare -f "DEBUG" > /dev/null ; then
                                DEBUG "Informazioni ricavate del file: $$oldpath"
                                DEBUG "Dimensione file macchina locale: $size1"
                                DEBUG "Dimensione file macchina remota: $size2"
                                DEBUG "Data ultima modifica file macchina locale: $last_mod1"
                                DEBUG "Data ultima modifica file macchina remota: $last_mod2"
                                DEBUG "Checksum MD5 file macchina locale: $md51"
                                DEBUG "Checksum MD5 file macchina remota: $md52"
                                DEBUG "Hostname macchina locale: $hostname1"
                                DEBUG "Hostname macchina remota: $hostname2"
                            fi

                            (( n_files1++ ))
                            (( n_files2++ ))

                            if [ "$el2f1" = "$el2f2" ] && [ "$md51" = "$md52" ] ; then
                                # file uguali, non fare niente
                                (( n_eqfiles1++ ))
                                                                (( n_eqfiles2++ ))
                            else
                                # file diversi, visualizza le informazioni
                                if [ "$outformat" = "html" ] ; then
                                    # header sezione con tutti i file
                                            header_filesections

                                    # titolo sezione e percorso file
                                    printf "<h3>File presente su entrambe le macchine (%s e %s)</h3><p>%s</p>\n" "$hostname1" "$hostname2" "$path"

                                    # tabelle
                                    printtable "$hostname1" "$size1" "$last_mod1" "$md51"
                                    printtable "$hostname2" "$size2" "$last_mod2" "$md52"
                                    echo "</div>"

                                    divide_filesections
                                
                                else
                                    printf "File presente su entrambe le macchine (%s e %s)\n%s\n\n" "$hostname1" "$hostname2" "$path"
                                
                                    printf "%34s %34s %34s \n" "" "$hostname1" "$hostname2"
                                    printf "%s\n" "---------------------------------- ---------------------------------- ----------------------------------"
                                    printf "%34s %34s %34s \n" "Dimensione file:" "$size1" "$size2"
                                    printf "%34s %34s %34s \n" "Ultima modifica:" "$last_mod1" "$last_mod2"
                                    printf "%34s %34s %34s \n" "Checksum MD5:" "$md51" "$md52"
                                                                printf "\n==========================================================================================================\n\n"
                                    
                                fi
                            fi
                        else
                            # Il percorso precedente e' diverso dal percorso attuale:
                            # il percorso precedente e' presente in una sola macchina

                            if [ "$boold" = true ] ; then
                                echo "Percorso mai visto $oldpath"
                            fi
                            
                            machine=$( get_csvelement "$oldline" 5 ) # macchina contente il file
                            
                            if declare -f "DEBUG" > /dev/null ; then
                                DEBUG "Informazioni ricavate del file: $oldpath"
                            fi

                            if [ "${machine}" = "$curr_hostname" ] ; then
                                # se la macchina corrisponde alla macchina locale...
                                (( n_files1++ ))

                                if [ "$boold" = true ] ; then
                                    echo "Appartiene macchina 1"
                                fi

                                # ottengo dimensione file macchina locale
                                                        el2f1=$( get_csvelement "$oldline" 2 )
                                                        size1=$( bytesToHuman "$el2f1" )
                            
                                # ottengo ultima modifica file macchina locale
                                last_mod1ts=$( get_csvelement "$oldline" 3 )

                                                            if [[ "$last_mod1ts" =~ ^[0-9]+$ ]] ; then
                                                                    last_mod1=$( date -d @"$last_mod1ts" +"%F %T" )
                                                            fi		                                                
                                
                                # checksum MD5 file macchina locale
                                                        md51=$( get_csvelement "$oldline" 4 )
                                
                                # hostname macchina locale
                                                               hostname1=$( get_csvelement "$oldline" 5 )
                                if declare -f "DEBUG" > /dev/null ; then
                                    DEBUG "Dimensione file macchina locale: $size1"
                                    DEBUG "Data ultima modifica file macchina locale: $last_mod1"
                                    DEBUG "Checksum MD5 file macchina locale: $md51"
                                    DEBUG "Hostname macchina locale: $hostname1"
                                fi

                                if [ "$outformat" = "html" ] ; then
                                    # header sezione con tutti i file
                                                                        header_filesections
                                                                    printf "<h3>File presente SOLO su %s</h3><p>%s</p>\n" "$hostname1" "$oldpath"
                                                                    printtable "$hostname1" "$size1" "$last_mod1" "$md51"
                                    echo "</div>"
                                    divide_filesections
                                                            else
                                    printf "File presente SOLO su %s\n%s\n\n" "$hostname1" "$oldpath"

                                                            printf "%34s %34s \n" "" "$hostname1"
                                                            printf "%s\n" "---------------------------------- ----------------------------------"
                                                            printf "%34s %34s \n" "Dimensione file:" "$size1"
                                                            printf "%34s %34s \n" "Ultima modifica:" "$last_mod1"
                                                            printf "%34s %34s \n" "Checksum MD5:" "$md51"
                                fi
                            else
                                # il file risiede sulla macchina remota
                                (( n_files2++ ))
                                if [ "$boold" = true ] ; then
                                    echo "Appartiene macchina 2"
                                fi

                                # ottengo dimensione file macchina remota
                                                            el2f2=$( get_csvelement "$oldline" 2 )
                                                            size2=$( bytesToHuman "$el2f2" )

                                                            # ottengo ultima modifica file macchina remota
                                last_mod2ts=$( get_csvelement "$oldline" 3 )
                                                            if [[ "$last_mod2ts" =~ ^[0-9]+$ ]] ; then
                                                                    last_mod2=$( date -d @"$last_mod2ts" +"%F %T" )
                                                            fi

                                                            # checksum MD5 file macchina remota
                                                            md52=$( get_csvelement "$oldline" 4 )
                                
                                # hostname macchina remota
                                                                hostname2=$( get_csvelement "$oldline" 5 )

                                if declare -f "DEBUG" > /dev/null ; then
                                    DEBUG "Dimensione file macchina fisica: $size2"
                                    DEBUG "Data ultima modifica file macchina fisica: $last_mod2"
                                    DEBUG "Checksum MD5 file macchina fisica: $md52"
                                    DEBUG "Hostname macchina remota: $hostname2"
                                fi

                                if [ "$outformat" = "html" ] ; then
                                    # header sezione con tutti i file
                                                                        header_filesections
                                                                        printf "<h3>File presente SOLO su %s</h3><p>%s</p>\n" "$hostname2" "$oldpath"
                                                                        printtable "$hostname2" "$size2" "$last_mod2" "$md52"
                                    echo "</div>"
                                    divide_filesections
                                                                else
                                    printf "File presente SOLO su %s\n%s\n\n" "$hostname2" "$oldpath"

                                                                printf "%34s %34s \n" "" "$hostname2"
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
                        skip=false # la prossima riga non deve essere saltata
                    fi

                    oldpath="$path" # salvo percorso file precedente
                    oldline="$line" # salvo riga precedente
                fi

            done < "$diffile" # file da leggere (output comando cat)

            if [ "$outformat" = "html" ] ; then
                printf "</div> \n </body> \n </html>"
            else
                if [ "$hostname1" = "$curr_hostname" ] ; then
                    echo_stats "$hostname1" "$n_files1" "$n_eqfiles1" "$hostname2" "( $(( $n_eqfiles1 * 100 / $n_files1 )) % uguali )"
                             echo_stats "$hostname2" "$n_files2" "$n_eqfiles2" "$hostname1" "( $(( $n_eqfiles2 * 100 / $n_files2 )) % uguali )"
                else
                                        echo_stats "$hostname2" "$n_files1" "$n_eqfiles1" "$hostname1" "( $(( $n_eqfiles1 * 100 / $n_files1 )) % uguali )"
                                        echo_stats "$hostname1" "$n_files2" "$n_eqfiles2" "$hostname2" "( $(( $n_eqfiles2 * 100 / $n_files2 )) % uguali )"
                fi
                       fi
        else
            echo "File in input non esistenti"
            exit 40
        fi
    else
        echo "Numero parametri errato"
            echo "printdiffs.sh <filepath> [<output format>]"
        exit 41
    fi
}
