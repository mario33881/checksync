#!./libs/bats-core/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

SCRIPT_PATH="$BATS_TEST_DIRNAME/../utils/"
SCRIPT_PATH="$( cd $SCRIPT_PATH ; pwd )/printdiffs.sh"

TEST_FOLDER="$BATS_TEST_DIRNAME/printdiffs_testing"

function gettimezone(){
    # ottieni timezone
    # https://unix.stackexchange.com/a/451925
    if filename=$(readlink /etc/localtime); then
        # /etc/localtime is a symlink as expected
        timezone=${filename#*zoneinfo/}
        if [[ $timezone = "$filename" || ! $timezone =~ ^[^/]+/[^/]+$ ]]; then
            # not pointing to expected location or not Region/City
	    >&2 echo "$filename points to an unexpected location"
            exit 1
        fi
        echo "$timezone"
    else  # compare files by contents
        # https://stackoverflow.com/questions/12521114/getting-the-canonical-time-zone-name-in-shell-script#comment88637393_12523283
        find /usr/share/zoneinfo -type f ! -regex ".*/Etc/.*" -exec \
            cmp -s {} /etc/localtime \; -print | sed -e 's@.*/zoneinfo/@@' | head -n1
    fi
}


@test "printdiffs.sh source" {
    # faccio il source del file
    run source "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}


@test "printdiffs.sh test bytesToHuman con cifre 'standard'" {
    # richiamo funzione con valori validi
    load "$SCRIPT_PATH"
    
    # 1 e' un byte
    [ "$( bytesToHuman 1 )" = "1 Bytes" ]
   
    # 0 sono zero byte
    [ "$( bytesToHuman 0 )" = "0 Bytes" ]

    # 1025 byte sono poco piu' di un Kibibyte (1024 byte) 
    [ "$( bytesToHuman 1025 )" = "1.00 KiB" ]

    # 1049600 byte sono circa un Mebibyte
    [ "$( bytesToHuman 1049600 )" = "1.00 MiB" ]
    
    # 1074800000 byte sono circa un Gibibyte
    [ "$( bytesToHuman 1074800000 )" = "1.00 GiB" ]

    # 1108000000000 byte sono circa un Tebibyte
    [ "$( bytesToHuman 1108000000000 )" = "1.00 TiB" ]

    # 1126999500000000 byte sono circa un Pebibyte
    [ "$( bytesToHuman 1126999500000000 )" = "1.00 PiB" ]
} 


@test "printdiffs.sh test bytesToHuman con cifre negative, float e lettere: status code 42" {
    # tutti i valori testati non sono validi
    load "$SCRIPT_PATH"
    
    # numero negativo "piccolo"
    run bytesToHuman -100
    [ "$status" -eq 42 ]    
    [ "$output" = "Il parametro passato non e' un numero o non e' valido ( >= 0 )" ]
    
    # numero negativo molto grande
    run bytesToHuman -100000000000000000000000000000000000
    [ "$status" -eq 42 ]
    [ "$output" = "Il parametro passato non e' un numero o non e' valido ( >= 0 )" ]

    # numero float
    run bytesToHuman 0.0
    [ "$status" -eq 42 ]
    [ "$output" = "Il parametro passato non e' un numero o non e' valido ( >= 0 )" ]

    # stringa al posto di un numero
    run bytesToHuman randomstring
    [ "$status" -eq 42 ]
    [ "$output" = "Il parametro passato non e' un numero o non e' valido ( >= 0 )" ]

    # stringa contentente spazi
    run bytesToHuman "random string with spaces "
    [ "$status" -eq 42 ]
    [ "$output" = "Il parametro passato non e' un numero o non e' valido ( >= 0 )" ]

    # senza parametri
    run bytesToHuman
    [ "$status" -eq 42 ]
    [ "$output" = "Il parametro passato non e' un numero o non e' valido ( >= 0 )" ]

    # parametro stringa vuota
    run bytesToHuman ""
    [ "$status" -eq 42 ]
    [ "$output" = "Il parametro passato non e' un numero o non e' valido ( >= 0 )" ]
}


@test "printdiffs.sh test get_csvelement con valori validi" {
    load "$SCRIPT_PATH"
    
    run get_csvelement  "random;csv;string" 1
    [ "$output" = "random" ]

    run get_csvelement  "random;csv;string" 2
    [ "$output" = "csv" ]

    run get_csvelement  "random;csv;string" 3
    [ "$output" = "string" ]

    run get_csvelement  "nextelement;isempty;" 3
    [ "$output" = "" ]
}


@test "printdiffs.sh test get_csvelement con valori non validi: status codes 43-46" {
    load "$SCRIPT_PATH"

    # eseguo funzione senza parametri
    run get_csvelement
    [ "$status" = 44 ]
    [ "$output" = "Primo parametro stringa in formato csv vuoto" ]

    # eseguo funzione con parametro stringa vuoto
    run get_csvelement ""
    [ "$status" = 44 ]
    [ "$output" = "Primo parametro stringa in formato csv vuoto" ]

    # eseguo funzione con parametro stringa con spazio
    run get_csvelement " "
    [ "$status" = 43 ]
    [ "$output" = "Il parametro index passato non e' un numero o non e' valido ( > 0 )" ]

    # eseguo funzione con parametro index troppo grande
    run get_csvelement  "random;csv;string" 20
    [ "$status" = 45 ]
    [ "$output" = "Parametro index troppo grande" ]

    # eseguo funzione con parametro index 0
    run get_csvelement  "random;csv;string" 0
    [ "$status" = 46 ]
    [ "$output" = "Il primo parametro non contiene delimitatori o parametro index 0" ]

    # eseguo funzione con parametro index lettera
    run get_csvelement  "random;csv;string" c
    [ "$status" = 43 ]
    [ "$output" = "Il parametro index passato non e' un numero o non e' valido ( > 0 )" ]
}


@test "printdiffs.sh test header_filesections" {
    # test funzione che apre div principale contentente le tabelle
    load "$SCRIPT_PATH"
    run header_filesections
    [ "$output" = "<div style='overflow-x:auto;background-color: white;border-radius: 10px 10px 10px 10px;'>" ]
}


@test "printdiffs.sh test printtable" {
    # test funzione che crea le tabelle delle email
    load "$SCRIPT_PATH"
    run printtable "bats-testrandomhostname" "99999 MiB" "data" "209fu80ie2hgf20ehfg82"

    # inizia tabella
    [ "${lines[0]}" = '<table cellspacing="0" cellpadding="0" style="width: 100%; word-break:break-word;">' ]
    
    # inizia tracciato record
    [ "${lines[1]}" = '<thead> ' ]
    [ "${lines[2]}" = '<tr style="background-color: white;"> ' ]
    [ "${lines[3]}" = '<td style="text-align: left; padding: 8px;"></td> ' ]
    [ "${lines[4]}" = '<td style="text-align: left; padding: 8px;"> bats-testrandomhostname </td> ' ]
    [ "${lines[5]}" = '</tr> ' ]
    [ "${lines[6]}" = '</thead> ' ]
    # fine tracciato record

    # inizio prima riga con dimensione file
    [ "${lines[7]}" = '<tr style="background-color: #f2f2f2;"> ' ]
    [ "${lines[8]}" = '<td style="text-align: left; padding: 8px;">Dimensione file:</td> ' ]
    [ "${lines[9]}" = '<td style="text-align: left; padding: 8px;"> 99999 MiB </td> ' ]
    [ "${lines[10]}" = '</tr> ' ]
    # fine prima riga con dimensione file

    # inizio seconda riga con la data di ultima modifica
    [ "${lines[11]}" = '<tr style="background-color: white;"> ' ]
    [ "${lines[12]}" = '<td style="text-align: left; padding: 8px;">Ultima modifica:</td> ' ]
    [ "${lines[13]}" = '<td style="text-align: left; padding: 8px;"> data </td> ' ]
    [ "${lines[14]}" = '</tr> ' ]
    # fine seconda riga con la data di ultima modifica

    # inizio terza/ultima riga con il checksum MD5
    [ "${lines[15]}" = '<tr style="background-color: #f2f2f2;"> ' ]
    [ "${lines[16]}" = '<td style="text-align: left; padding: 8px;">Checksum MD5:</td> ' ]
    [ "${lines[17]}" = '<td style="text-align: left; padding: 8px;"> 209fu80ie2hgf20ehfg82 </td> ' ]
    [ "${lines[18]}" = '</tr> ' ]
    # fine terza/ultima riga con il checksum MD5

    [ "${lines[19]}" = '</table> ' ]
    # fine tabella
}


@test "printdiffs.sh test divide_filesections" {
    # funzione che crea hr per dividere le tabelle nelle email
    load "$SCRIPT_PATH"
    run divide_filesections
    [ "$output" = '<hr style="display: block; height: 1px; border: 0; border-top: 15px solid #FBBA00; margin: 1em 0; padding: 0;">' ]
}


@test "printdiffs.sh test echo_stats" {
    # funzione che visualizza statistiche sul terminale
    load "$SCRIPT_PATH"
    run echo_stats "bats-test-randomhostname" 99999999 33333333 "another-hostname" "( 33 % uguali )"
    [ "$output" = "Sul server bats-test-randomhostname sono stati analizzati 99999999 file di cui 33333333 sono presenti sul server another-hostname ( 33 % uguali )" ]
}


@test "printdiffs.sh test printdiffs senza parametri: status code 41" {
    # test esecuzione senza parametri
    load "$SCRIPT_PATH"
    run printdiffs
    [ "$status" -eq 41 ]
    [ "${lines[0]}" = "Numero parametri errato" ]
    [ "${lines[1]}" = "printdiffs.sh <filepath> [<output format>]" ]
}


@test "printdiffs.sh test printdiffs percorso file inesistente: status code 40" {
    # test esecuzione senza parametri
    load "$SCRIPT_PATH"
    run printdiffs "percorso/sicuramente/non/esistente.csv"
    [ "$status" -eq 40 ]
    [ "$output" = "File in input non esistenti" ]
}


@test "printdiffs.sh test printdiffs percorso file vuoto: status code 41" {
    # test esecuzione parametro vuoto
    load "$SCRIPT_PATH"
    run printdiffs ""
    [ "$status" -eq 41 ]
    [ "${lines[0]}" = "Numero parametri errato" ]
    [ "${lines[1]}" = "printdiffs.sh <filepath> [<output format>]" ]
}


@test "printdiffs.sh test printdiffs con file esistente" {
    # test finale di funzionamento
    load "$SCRIPT_PATH"
    
    # ottieni timezone attuale
    timezone=$( gettimezone )
    
    # imposta timezone 
    export TZ=Europe/Rome

    # crea cartella dei test
    mkdir -p "/var/tmp/checksync/bats-test"

    # esegui printdiffs per ottenere output
    run printdiffs ${TEST_FOLDER}/diffout.csv 
    echo "$output" | head -n -2 > "/var/tmp/checksync/bats-test/printdiffs_out.tmp"
    
    echo "$output" >&3
    echo "" >&3

    # reimposta il vecchio timezone
    export TZ="$timezone"
 
    # verifica che output esistente sia uguale all'output del comando
    run diff '/var/tmp/checksync/bats-test/printdiffs_out.tmp' "$TEST_FOLDER/output.txt" 
    echo "$output" >&3
    [ "$status" -eq 0 ]

    # cancella cartella dei test
    rm -r "/var/tmp/checksync/bats-test"
}


@test "printdiffs.sh test html_stats" {
    # prova statistiche html per email
    load "$SCRIPT_PATH"

    run html_stats "param1" "2param" "3 param" "param 4" "qualcosa"
    [ "$output" = "<h4 style='padding: 8px;color: white; text-align:center;'> Sul server param1 sono stati analizzati 2param file di cui 3 param sono presenti sul server param 4 qualcosa </h4>" ]
}


@test "printdiffs.sh test printdiffs output html" {
    # test finale di funzionamento
    load "$SCRIPT_PATH"

    # ottieni timezone attuale
    timezone=$( gettimezone )

    # imposta timezone
    export TZ=Europe/Rome

    # crea cartella dei test
    mkdir -p "/var/tmp/checksync/bats-test"

    # esegui printdiffs per ottenere output
    run printdiffs ${TEST_FOLDER}/diffout.csv "html"
    echo "$output" > "/var/tmp/checksync/bats-test/printdiffs_out.tmp"

    echo "$output" >&3
    echo "" >&3

    # reimposta il vecchio timezone
    export TZ="$timezone"

    # verifica che output esistente sia uguale all'output del comando
    # > i due sed servono per ignorare il tag contenente data e ora 
    # > ( perche' variano ad ogni esecuzione )
    run diff <( sed "/<h2 style='margin-top: 0px;'> /,/ <\/h2> /d" '/var/tmp/checksync/bats-test/printdiffs_out.tmp' ) <( sed "/<h2 style='margin-top: 0px;'> /,/ <\/h2> /d" "$TEST_FOLDER/outputhtml.html" )
    echo "$output" >&3
    [ "$status" -eq 0 ]

    # cancella cartella dei test
    rm -r "/var/tmp/checksync/bats-test"
}
