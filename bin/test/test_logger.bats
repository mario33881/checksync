#!./libs/bats-core/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

SCRIPT_PATH="$BATS_TEST_DIRNAME/../utils/"
SCRIPT_PATH="$( cd $SCRIPT_PATH ; pwd )/logger.sh"

LOG_PATH=/var/tmp/checksync/bats-test/
LOG_NAME=testing-logs.log
SCRIPT_LOG="$LOG_PATH/$LOG_NAME"


setup(){
    # crea cartella test in cui mettere i log
    mkdir -p "$LOG_PATH"
}


teardown(){
    # cancella cartella test con tutto il contenuto
    rm -r "$LOG_PATH"
}


@test "logger.sh senza parametri: status code 30" {
    # lo script viene avviato senza parametri
    bkSCRIPT_LOG="$SCRIPT_LOG"
    SCRIPT_LOG=""
    run source "$SCRIPT_PATH"
    [ "$status" -eq 30 ]
    [ "$output" = "Output log non definito ( variabile SCRIPT_LOG )" ]
    SCRIPT_LOG="$bkSCRIPT_LOG"
}


@test "logger.sh crea file di log" {
    # viene fatto source dello script e questo fa "touch" del file log
    run source "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [ -f "$SCRIPT_LOG" ]
}


# Test relativi alle funzioni contenute in logger.sh
#
# SCRIPTENTRY : avvio script
# SCRIPTEXIT  : termine script
# ENTRY       : avvio funzione
# EXIT        : termine funzione
# INFO        : messaggio informazione
# DEBUG       : messaggio debug
# ERROR       : messaggio errore


@test "logger.sh richiama funzione SCRIPTENTRY" {
    # viene fatto load dello script e viene eseguita la funzione SCRIPTEXIT
    
    load "$SCRIPT_PATH"
    
    run SCRIPTENTRY
    [ "$status" -eq 0 ]

    content=$( cat "$SCRIPT_LOG" )
    [[ "$content" = "["*"] [DEBUG]  > bats-exec-test SCRIPTENTRY" ]]
}


@test "logger.sh richiama funzione SCRIPTEXIT" {
    # viene fatto source dello script e viene eseguita la funzione SCRIPTEXIT

    load "$SCRIPT_PATH"

    run SCRIPTEXIT
    [ "$status" -eq 0 ]

    content=$( cat "$SCRIPT_LOG" )
    [[ "$content" = "["*"] [DEBUG]  < bats-exec-test SCRIPTEXIT" ]]
}


@test "logger.sh richiama funzione ENTRY" {
    # viene fatto source dello script e viene eseguita la funzione ENTRY

    load "$SCRIPT_PATH"

    run ENTRY
    [ "$status" -eq 0 ]

    content=$( cat "$SCRIPT_LOG" )
    [[ "$content" = "["*"] [DEBUG]  > run ENTRY" ]]
}


@test "logger.sh richiama funzione EXIT" {
    # viene fatto source dello script e viene eseguita la funzione EXIT

    load "$SCRIPT_PATH"

    run EXIT
    [ "$status" -eq 0 ]

    content=$( cat "$SCRIPT_LOG" )
    [[ "$content" = "["*"] [DEBUG]  < run EXIT" ]]
}


@test "logger.sh richiama funzione INFO" {
    # viene fatto source dello script e viene eseguita la funzione INFO
    # con il messaggio "questo e' un messaggio informativo"

    load "$SCRIPT_PATH"

    run INFO "questo e' un messaggio informativo"
    [ "$status" -eq 0 ]

    content=$( cat "$SCRIPT_LOG" )
    [[ "$content" = "["*"] [INFO]  questo e' un messaggio informativo" ]]
}


@test "logger.sh richiama funzione DEBUG" {
    # viene fatto source dello script e viene eseguita la funzione DEBUG
    # con il messaggio "questo e' un messaggio di debug"

    load "$SCRIPT_PATH"

    run DEBUG "questo e' un messaggio di debug"
    [ "$status" -eq 0 ]

    content=$( cat "$SCRIPT_LOG" )
    [[ "$content" = "["*"] [DEBUG]  questo e' un messaggio di debug" ]]
}


@test "logger.sh richiama funzione ERROR" {
    # viene fatto source dello script e viene eseguita la funzione ERROR
    # con il messaggio "questo e' un messaggio di errore"

    load "$SCRIPT_PATH"

    run ERROR "questo e' un messaggio di errore"
    [ "$status" -eq 0 ]

    content=$( cat "$SCRIPT_LOG" )
    [[ "$content" = "["*"] [ERROR]  questo e' un messaggio di errore" ]]
}
