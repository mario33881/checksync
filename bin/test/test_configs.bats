#!./libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'


@test "configs.sh senza parametri: status code 11" {
    
    run "$BATS_TEST_DIRNAME/../utils/configs.sh"
    [ "$status" -eq 11 ]
    [ "$output" = "Parametro file di configurazione mancante" ]
}


@test "configs.sh configurazione che non esiste: status code 10" {

    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/filenonesistente"
    [ "$status" -eq 10 ]
    [ "$output" = "File di configurazione non esiste" ]
}


@test "configs.sh configurazione vuota, no percorsi da analizzare: status code 12" {

    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/emptyconfig.ini"
    [ "$status" -eq 12 ]
    [ "$output" = "Nessun percorso da analizzare" ]
}


@test "configs.sh configurazione sezione percorsi da analizzare vuota: status code 12" {

    run "$BATS_TEST_DIRNAME/../utils/configs.sh" "$BATS_TEST_DIRNAME/configfiles/emptyanalyzesection.ini"
    [ "$status" -eq 12 ]
    [ "$output" = "Nessun percorso da analizzare" ]
}

