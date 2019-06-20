#!./libs/bats-core/bin/bats

SCRIPTPATH="$BATS_TEST_DIRNAME/../bin/utils/configs.sh"

@test "configs.sh senza parametri: status code 11" {
    # lo script viene avviato senza parametri    
    run "$SCRIPTPATH"
    [ "$status" -eq 11 ]
    [ "$output" = "Parametro file di configurazione mancante" ]
}


@test "configs.sh configurazione che non esiste: status code 10" {
    # parametro punta a file non esistente
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/filenonesistente"
    [ "$status" -eq 10 ]
    [ "$output" = "File di configurazione non esiste" ]
}


@test "configs.sh configurazione vuota, no percorsi da analizzare: status code 12" {
    # file di configurazione esistente ma vuoto
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/emptyconfig.ini"
    [ "$status" -eq 12 ]
    [ "$output" = "Nessun percorso da analizzare" ]
}


@test "configs.sh configurazione sezione percorsi da analizzare vuota: status code 12" {
    # sezione [ANALIZZA] nelle configurazioni vuota
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/emptyanalyzesection.ini"
    [ "$status" -eq 12 ]
    [ "$output" = "Nessun percorso da analizzare" ]
}


@test "configs.sh configurazione sezione percorsi con percorsi inesistenti: status code 14" {
    # percorsi cartelle da analizzare non esistenti
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/notexistingpathtoanalyze.ini"
    [ "$status" -eq 14 ]
    [[ "$output" = "Cartella"*"inesistente" ]]
}


@test "configs.sh configurazione sezione percorsi con percorsi validi: status code 13" {
    # percorsi da analizzare presenti ma ip non presente
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/correctanalyzepaths.ini"
    [ "$status" -eq 13 ]
    [ "$output" = "Manca l'indirizzo IP della macchina a cui connettersi" ]
}


@test "configs.sh configurazione sezione macchina 2 vuota: status code 13" {
    # non e' stata compilata la parte "[MACCHINA 2]" nella configurazione
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/emptymacchina2section.ini"
    [ "$status" -eq 13 ]
    [ "$output" = "Manca l'indirizzo IP della macchina a cui connettersi" ]
}


@test "configs.sh configurazione sezione macchina ip vuoto/spazi: status code 13" {
    # il file di configurazione contiene proprieta' ip in questo modo "ip=    "
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/emptyip.ini"
    [ "$status" -eq 13 ]
    [ "$output" = "Manca l'indirizzo IP della macchina a cui connettersi" ]
}


@test "configs.sh configurazione sezione macchina ipv4 errato: status code 15" {
    # utilizzatore potrebbe usare indirizzo ipv4 non valido
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/wrongipv4.ini"
    [ "$status" -eq 15 ]
    [ "$output" = "Ip inserito non valido" ]
}


@test "configs.sh configurazione sezione macchina ipv6 errato: status code 15" {
    # Utilizzatore potrebbe usare indirizzo ipv6 non valido
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/wrongipv6.ini"
    [ "$status" -eq 15 ]
    [ "$output" = "Ip inserito non valido" ]
}


@test "configs.sh configurazione minima corretta" {
    #Analizza: '/etc/ /var /bin/.'                  ; definito nella configurazione
    #Ignora: ''                                     ; configurazione non ne specifica
    #Log: 'checksync.log'                           ; default perche' non definito
    #User: ''                                       ; di default e' username attuale
    #Scp: ''                                        ; default percorso in cui si trova lo script in locale
    #Getfiles: '/var/tmp/checksync/getfilesout.csv' ; percorso di destinazione di default
    #Diffout: '/var/tmp/checksync/diffout.csv'      ; percorso di destinazione di default
    #Email: ''                                      ; non definita nel file di configurazione
    #Sendemail: 'false'                             ; false perche' email non definita

    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/correctipv4.ini" "batstesting-hostname" "--test"
    # ignoro status perche' potrebbe non trovare scp_path remoto
    [ "${lines[0]}" = "Analizza: '/etc/ /var /bin/.'" ]
    [ "${lines[1]}" = "Ignora: ''" ]
    [ "${lines[2]}" = "Log: 'checksync.log'" ]
    [ "${lines[3]}" = "User: '$(whoami)'" ]
    [ "${lines[4]}" = "Scp: '$( cd ../bin/utils ; pwd )'" ]
    [ "${lines[5]}" = "Getfiles: '/var/tmp/checksync/getfilesout.csv'" ]
    [ "${lines[6]}" = "Diffout: '/var/tmp/checksync/diffout.csv'" ]
    [ "${lines[7]}" = "Email: ''" ]
    [ "${lines[8]}" = "Sendemail: 'false'" ]
}


@test "configs.sh ip macchina remota non raggiungibile: status code 17" {
    # macchina non raggiungibile
    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/unreachableip.ini"
    [ "$status" -eq 17 ]
    [[ "$output" = *" non rangiungibile" ]]

    rm "$BATS_TEST_DIRNAME/checksync.log"
}


@test "configs.sh configurazione completa con email=none" {
    #Analizza: '/etc/ /var /bin/.'   ; definito nella configurazione
    #Ignora: '/etc/default /etc/apt' ; definito nella configurazione
    #Log: 'customlog.txt'            ; definito nella configurazione
    #User: 'customuser'              ; definito nella configurazione
    #Scp: 'custompath'               ; definito nella configurazione
    #Getfiles: 'getfiles_output.csv' ; definito nella configurazione
    #Diffout: 'outputdiff.csv'       ; definito nella configurazione
    #Email: 'none'                   ; definito nella configurazione
    #Sendemail: 'false'              ; false perche' email = none

    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/emailnone.ini" "batstesting-hostname" "--test"
    # ignoro status perche' potrebbe non trovare scp_path remoto
    [ "${lines[0]}" = "Analizza: '/etc/ /var /bin/.'" ]
    [ "${lines[1]}" = "Ignora: '/etc/default /etc/apt'" ]
    [ "${lines[2]}" = "Log: '/var/tmp/checksync/bats-test/customlog.txt'" ]
    [ "${lines[3]}" = "User: 'customuser'" ]
    [ "${lines[4]}" = "Scp: 'custompath'" ]
    [ "${lines[5]}" = "Getfiles: 'getfiles_output.csv'" ]
    [ "${lines[6]}" = "Diffout: 'outputdiff.csv'" ]
    [ "${lines[7]}" = "Email: 'none'" ]
    [ "${lines[8]}" = "Sendemail: 'false'" ]
}


@test "configs.sh configurazione completa" {
    #Analizza: '/etc/ /var /bin/.'   ; definito nella configurazione
    #Ignora: '/etc/default /etc/apt' ; definito nella configurazione
    #Log: 'customlog.txt'            ; definito nella configurazione
    #User: 'customuser'              ; definito nella configurazione
    #Scp: 'custompath'               ; definito nella configurazione
    #Getfiles: 'getfiles_output.csv' ; definito nella configurazione
    #Diffout: 'outputdiff.csv'       ; definito nella configurazione
    #Email: 'random@email.com'       ; definito nella configurazione
    #Sendemail: 'false'              ; true perche' email definita

    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/completeconfig.ini" "batstesting-hostname" "--test"
    # ignoro status perche' potrebbe non trovare scp_path remoto
    [ "${lines[0]}" = "Analizza: '/etc/ /var /bin/.'" ]
    [ "${lines[1]}" = "Ignora: '/etc/default /etc/apt'" ]
    [ "${lines[2]}" = "Log: '/var/tmp/checksync/bats-test/customlog.txt'" ]
    [ "${lines[3]}" = "User: 'customuser'" ]
    [ "${lines[4]}" = "Scp: 'custompath'" ]
    [ "${lines[5]}" = "Getfiles: 'getfiles_output.csv'" ]
    [ "${lines[6]}" = "Diffout: 'outputdiff.csv'" ]
    [ "${lines[7]}" = "Email: 'random@email.com'" ]
    [ "${lines[8]}" = "Sendemail: 'true'" ]
}


@test "configs.sh prova funzione stripspaces()" {
    # prova funzione stripspaces() che si occupa di 
    # rimuovere gli spazi a inizio e fine stringa

    source "$SCRIPTPATH"

    run stripspaces "      stringa casualedi test  "

    [ "$status" -eq 0 ]
    [ "$output" = "stringa casualedi test" ]

    run stripspaces "altra stringa conspazio a destra           "

    [ "$status" -eq 0 ]
    [ "$output" = "altra stringa conspazio a destra" ]


    run stripspaces "   e ora stringa conspazio a sinistra"

    [ "$status" -eq 0 ]
    [ "$output" = "e ora stringa conspazio a sinistra" ]
}


@test "configs.sh prova funzione valid_ipv6(): indirizzi validi" {
    # prova funzione valid_ipv6() che si occupa di verificare
    # la validita' di un indirizzo ipv6
 
    source "$SCRIPTPATH"

    valid_ipv6 "0:0:0:0:0:0:0:1"
    valid_ipv6 "::1"
    valid_ipv6 "2001:DB8:0:0:8:800:200C:417A"
    valid_ipv6 "1200:0000:AB00:1234:0000:2552:7777:1313"
    valid_ipv6 "21DA:D3:0:2F3B:2AA:FF:FE28:9C5A"
}


@test "configs.sh prova funzione valid_ipv6(): indirizzi non validi" {
    # prova funzione valid_ipv6() che si occupa di verificare
    # la validita' di un indirizzo ipv6 (in questo caso nessuno e' valido)

    source "$SCRIPTPATH"

    ! valid_ipv6 ""
    ! valid_ipv6 "              "
    ! valid_ipv6 "1200::AB00:1234::2552:7777:1313"
    ! valid_ipv6 "1200:0000:AB00:1234:O000:2552:7777:1313"
}


@test "configs.sh prova funzione valid_ipv4(): indirizzi validi" {
    # prova funzione valid_ipv4() che si occupa di verificare
    # la validita' di un indirizzo ipv4

    source "$SCRIPTPATH"
    
    valid_ipv4 "4.2.2.2"
    valid_ipv4 "192.168.1.1"
    valid_ipv4 "0.0.0.0"
    valid_ipv4 "255.255.255.255"
    valid_ipv4 "192.168.0.1"
}


@test "configs.sh prova funzione valid_ipv4(): indirizzi non validi" {
    # prova funzione valid_ipv4() che si occupa di verificare
    # la validita' di un indirizzo ipv4 (in questo caso nessuno e' valido)

    source "$SCRIPTPATH"

    ! valid_ipv4 ""
    ! valid_ipv4 "         "
    ! valid_ipv4 "a.b.c.d"
    ! valid_ipv4 "255.255.255.256"
    ! valid_ipv4 "192.168.0"
    ! valid_ipv4 "1234.123.123.123"
}


@test "configs.sh prova funzione remove_slash()" {
    # prova funzione che rimuove "/" e "/." dai percorsi prune

    source "$SCRIPTPATH"

    run remove_slash ""
    [ "$output" = "" ]

    run remove_slash "/"
    [ "$output" = "" ]

    run remove_slash "/."
    [ "$output" = "" ]

    run remove_slash "questo/e'/un/percorso/casuale/."
    [ "$output" = "questo/e'/un/percorso/casuale" ]

    run remove_slash "questo/e'/un/percorso/casuale/"
    [ "$output" = "questo/e'/un/percorso/casuale" ]

    run remove_slash "questo/e'/un/percorso/casuale"
    [ "$output" = "questo/e'/un/percorso/casuale" ]

    run remove_slash "/questo/e'/un/percorso/casuale/assoluto/."
    [ "$output" = "/questo/e'/un/percorso/casuale/assoluto" ]

    run remove_slash "/questo/e'/un/percorso/casuale/assoluto/"
    [ "$output" = "/questo/e'/un/percorso/casuale/assoluto" ]

    run remove_slash "/questo/e'/un/percorso/casuale/assoluto"
    [ "$output" = "/questo/e'/un/percorso/casuale/assoluto" ]
}


@test "configs.sh prova funzione ismyip()" {
    # prova funzione che indica se l'ip passato
    # appartiene alla macchina

    source "$SCRIPTPATH"

    ismyip "$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')"
    ! ismyip "not.conf.ip."
}


@test "configs.sh prova funzione pingstat()" {
    # prova funzione che indica se la macchina e' raggiungibile

    source "$SCRIPTPATH"
    
    pingstat "127.0.0.1"
 
    ! pingstat "random.ip.0.0"
    
    ! pingstat "100::"
}


@test "configs.sh configurazione completa con spazi" {
    #Analizza: '/etc/ /var /bin/.'   ; definito nella configurazione
    #Ignora: '/etc/default /etc/apt' ; definito nella configurazione
    #Log: 'customlog.txt'            ; definito nella configurazione
    #User: 'customuser'              ; definito nella configurazione
    #Scp: 'custompath'               ; definito nella configurazione
    #Getfiles: 'getfiles_output.csv' ; definito nella configurazione
    #Diffout: 'outputdiff.csv'       ; definito nella configurazione
    #Email: 'random@email.com'       ; definito nella configurazione
    #Sendemail: 'false'              ; true perche' email definita

    run "$SCRIPTPATH" "$BATS_TEST_DIRNAME/configfiles/completeconfigwspaces.ini" "batstesting-hostname" "--test"
    # ignoro status perche' potrebbe non trovare scp_path remoto
    [ "${lines[0]}" = "Analizza: '/etc/ /var /bin/.'" ]
    [ "${lines[1]}" = "Ignora: '/etc/default /etc/apt'" ]
    [ "${lines[2]}" = "Log: '/var/tmp/checksync/bats-test/customlog.txt'" ]
    [ "${lines[3]}" = "User: 'customuser'" ]
    [ "${lines[4]}" = "Scp: 'custompath'" ]
    [ "${lines[5]}" = "Getfiles: 'getfiles_output.csv'" ]
    [ "${lines[6]}" = "Diffout: 'outputdiff.csv'" ]
    [ "${lines[7]}" = "Email: 'random@email.com'" ]
    [ "${lines[8]}" = "Sendemail: 'true'" ]
}
