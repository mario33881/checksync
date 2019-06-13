#!./libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'


@test "configs.sh senza parametri: status code 11" {
    # lo script viene avviato senza parametri    
    run "$BATS_TEST_DIRNAME/../utils/configs.sh"
    [ "$status" -eq 11 ]
    [ "$output" = "Parametro file di configurazione mancante" ]
}


@test "configs.sh configurazione che non esiste: status code 10" {
    # parametro punta a file non esistente
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/filenonesistente"
    [ "$status" -eq 10 ]
    [ "$output" = "File di configurazione non esiste" ]
}


@test "configs.sh configurazione vuota, no percorsi da analizzare: status code 12" {
    # file di configurazione esistente ma vuoto
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/emptyconfig.ini"
    [ "$status" -eq 12 ]
    [ "$output" = "Nessun percorso da analizzare" ]
}


@test "configs.sh configurazione sezione percorsi da analizzare vuota: status code 12" {
    # sezione [ANALIZZA] nelle configurazioni vuota
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/emptyanalyzesection.ini"
    [ "$status" -eq 12 ]
    [ "$output" = "Nessun percorso da analizzare" ]
}


@test "configs.sh configurazione sezione percorsi con percorsi inesistenti: status code 14" {
    # percorsi cartelle da analizzare non esistenti
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/notexistingpathtoanalyze.ini"
    [ "$status" -eq 14 ]
    [[ "$output" = "Cartella"*"inesistente" ]]
}


@test "configs.sh configurazione sezione percorsi con percorsi validi: status code 13" {
    # percorsi da analizzare presenti ma ip non presente
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/correctanalyzepaths.ini"
    [ "$status" -eq 13 ]
    [ "$output" = "Manca l'indirizzo IP della macchina a cui connettersi" ]
}


@test "configs.sh configurazione sezione macchina 2 vuota: status code 13" {
    # non e' stata compilata la parte "[MACCHINA 2]" nella configurazione
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/emptymacchina2section.ini"
    [ "$status" -eq 13 ]
    [ "$output" = "Manca l'indirizzo IP della macchina a cui connettersi" ]
}


@test "configs.sh configurazione sezione macchina ip vuoto/spazi: status code 13" {
    # il file di configurazione contiene proprieta' ip in questo modo "ip=    "
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/emptyip.ini"
    [ "$status" -eq 13 ]
    [ "$output" = "Manca l'indirizzo IP della macchina a cui connettersi" ]
}


@test "configs.sh configurazione sezione macchina ipv4 errato: status code 15" {
    # utilizzatore potrebbe usare indirizzo ipv4 non valido
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/wrongipv4.ini"
    [ "$status" -eq 15 ]
    [ "$output" = "Ip inserito non valido" ]
}


@test "configs.sh configurazione sezione macchina ipv6 errato: status code 15" {
    # Utilizzatore potrebbe usare indirizzo ipv6 non valido
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/wrongipv6.ini"
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

    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/correctipv4.ini" "batstesting-hostname" "--test"
    # ignoro status perche' potrebbe non trovare scp_path remoto
    [ "${lines[0]}" = "Analizza: '/etc/ /var /bin/.'" ]
    [ "${lines[1]}" = "Ignora: ''" ]
    [ "${lines[2]}" = "Log: 'checksync.log'" ]
    [ "${lines[3]}" = "User: '$(whoami)'" ]
    [ "${lines[4]}" = "Scp: '$( cd ../utils ; pwd )'" ]
    [ "${lines[5]}" = "Getfiles: '/var/tmp/checksync/getfilesout.csv'" ]
    [ "${lines[6]}" = "Diffout: '/var/tmp/checksync/diffout.csv'" ]
    [ "${lines[7]}" = "Email: ''" ]
    [ "${lines[8]}" = "Sendemail: 'false'" ]
}


@test "configs.sh ip macchina remota non raggiungibile: status code 17" {
    # macchina non raggiungibile
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/unreachableip.ini"
    [ "$status" -eq 17 ]
    [[ "$output" = *" non rangiungibile" ]]
}


@test "configs.sh cartella destinazione remota non esistente: status code 16" {
    # scp_path non esistente
    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/wrongscppath.ini"
    [ "$status" -eq 16 ]
    [ "$output" = "Cartella remota in cui copiare lo script non esiste" ]
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

    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/emailnone.ini" "batstesting-hostname" "--test"
    # ignoro status perche' potrebbe non trovare scp_path remoto
    [ "${lines[0]}" = "Analizza: '/etc/ /var /bin/.'" ]
    [ "${lines[1]}" = "Ignora: '/etc/default /etc/apt'" ]
    [ "${lines[2]}" = "Log: 'customlog.txt'" ]
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

    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/completeconfig.ini" "batstesting-hostname" "--test"
    # ignoro status perche' potrebbe non trovare scp_path remoto
    [ "${lines[0]}" = "Analizza: '/etc/ /var /bin/.'" ]
    [ "${lines[1]}" = "Ignora: '/etc/default /etc/apt'" ]
    [ "${lines[2]}" = "Log: 'customlog.txt'" ]
    [ "${lines[3]}" = "User: 'customuser'" ]
    [ "${lines[4]}" = "Scp: 'custompath'" ]
    [ "${lines[5]}" = "Getfiles: 'getfiles_output.csv'" ]
    [ "${lines[6]}" = "Diffout: 'outputdiff.csv'" ]
    [ "${lines[7]}" = "Email: 'random@email.com'" ]
    [ "${lines[8]}" = "Sendemail: 'true'" ]
}
