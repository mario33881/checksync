#!./libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

get_csvelement() {
    # recupera dalla riga in formato csv (elementi divisi da ";") passata come primo parametro
    # l'elemento nella posizione passata come secondo parametro
    line="$1"
    n_el="$2"
    el=$( echo "$line" | awk -F "\"*;\"*" "{print \$$n_el}" )
    echo "$el"
}


extract_pathnhostname(){
    # dall'output di getfiles recupero solo path e hostname, ignoro il resto per i test
    printf "" > /var/tmp/checksync/bats-tests/getfiles.tmp
    while IFS= read -r line
    do
        path=$( get_csvelement "$line" 1 )
        hostname=$( get_csvelement "$line" 5 )
	echo "$path;$hostname" >> /var/tmp/checksync/bats-tests/getfiles.tmp
    done < /var/tmp/checksync/bats-tests/getfiles_output.csv
    
}


setup(){
    mkdir -p "/var/tmp/checksync/bats-tests/"
}


teardown(){
    rm -r "/var/tmp/checksync/bats-tests/"
}


@test "getfiles.sh file configurazione senza percorsi da ignorare" {
    # vengono rilevati tutti i file in getfiles_testing/
    run "$BATS_TEST_DIRNAME/../utils/getfiles.sh" "$BATS_TEST_DIRNAME/getfiles_testing/configs/confignoinora.ini" "batstesting-hostname" "--skip-conn-test"
    [ "$status" -eq 0 ]
    
    extract_pathnhostname

    run cat /var/tmp/checksync/bats-tests/getfiles.tmp  
    
    echo "# $output" >&3
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" = "path;macchina" ]]
    [[ "${lines[1]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder1/root1_folder1_file1.txt;batstesting-hostname" ]]
    [[ "${lines[2]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder1/root1_folder1_file2.txt;batstesting-hostname" ]]
    [[ "${lines[3]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder1/root1_folder1_file3.txt;batstesting-hostname" ]]
    [[ "${lines[4]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder2/eq_file1;batstesting-hostname" ]]
    [[ "${lines[5]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder2/eq_file2;batstesting-hostname" ]]
    [[ "${lines[6]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root1_folder2/eq_file1;batstesting-hostname" ]]
    [[ "${lines[7]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root1_folder2/eq_file2;batstesting-hostname" ]]
    [[ "${lines[8]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root2_folder1/root2_folder1_file3.txt;batstesting-hostname" ]]
    [[ "${lines[9]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root3/file.txt;batstesting-hostname" ]]
}


@test "getfiles.sh file configurazione con due percorsi da analizzare, zero da ignorare" {
    # vengono rilevati i file in getfiles_testing/root1 e getfiles_testing/root2
    run "$BATS_TEST_DIRNAME/../utils/getfiles.sh" "$BATS_TEST_DIRNAME/getfiles_testing/configs/configtwopaths.ini" "batstesting-hostname" "--skip-conn-test"
    [ "$status" -eq 0 ]
    
    extract_pathnhostname

    run cat /var/tmp/checksync/bats-tests/getfiles.tmp
    echo "# $output" >&3
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" = "path;macchina" ]]
    [[ "${lines[1]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder1/root1_folder1_file1.txt;batstesting-hostname" ]]
    [[ "${lines[2]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder1/root1_folder1_file2.txt;batstesting-hostname" ]]
    [[ "${lines[3]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder1/root1_folder1_file3.txt;batstesting-hostname" ]]
    [[ "${lines[4]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder2/eq_file1;batstesting-hostname" ]]
    [[ "${lines[5]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder2/eq_file2;batstesting-hostname" ]]
    [[ "${lines[6]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root1_folder2/eq_file1;batstesting-hostname" ]]
    [[ "${lines[7]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root1_folder2/eq_file2;batstesting-hostname" ]]
    [[ "${lines[8]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root2_folder1/root2_folder1_file3.txt;batstesting-hostname" ]]
}


@test "getfiles.sh file configurazione con due percorsi da analizzare, cartelle da ignorare" {
    # vengono rilevati i file in getfiles_testing/root1 e getfiles_testing/root2, ignorando contenuto cartella 
    # getfiles_testing/mainroot/root1/root1_folder1
    
    # recupero il percorso assoluto della cartella da ignorare
    toignore="./getfiles_testing/mainroot/root1/root1_folder1"
    toignore_abs=$( cd "$toignore" ; pwd )

    # salvo configurazione nuova in un file temporaneo
    #sed -e 's/${toignore}/${toignore_abs}/g' "$BATS_TEST_DIRNAME/getfiles_testing/configs/configtwopathsnignora.ini" > /var/tmp/checksync/bats-tests/config.tmp
    sed -e "s|${toignore}|${toignore_abs}|g" "$BATS_TEST_DIRNAME/getfiles_testing/configs/configtwopathsnignora.ini" > /var/tmp/checksync/bats-tests/config.tmp

    run "$BATS_TEST_DIRNAME/../utils/getfiles.sh" "/var/tmp/checksync/bats-tests/config.tmp" "batstesting-hostname" "--skip-conn-test"
    [ "$status" -eq 0 ]
    
    extract_pathnhostname

    run cat /var/tmp/checksync/bats-tests/getfiles.tmp

    [ "$status" -eq 0 ]
    [[ "${lines[0]}" = "path;macchina" ]]
    [[ "${lines[1]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder2/eq_file1;batstesting-hostname" ]]
    [[ "${lines[2]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder2/eq_file2;batstesting-hostname" ]]
    [[ "${lines[3]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root1_folder2/eq_file1;batstesting-hostname" ]]
    [[ "${lines[4]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root1_folder2/eq_file2;batstesting-hostname" ]]
    [[ "${lines[5]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root2_folder1/root2_folder1_file3.txt;batstesting-hostname" ]]
}


@test "getfiles.sh file configurazione con due percorsi da analizzare, file e cartelle da ignorare" {
    # vengono rilevati i file in getfiles_testing/root1 e getfiles_testing/root2, ignorando contenuto cartella
    # getfiles_testing/mainroot/root1/root1_folder1 e il file getfiles_testing/mainroot/root1/root1_folder2/eq_file1

    # recupero il percorso assoluto della cartella da ignorare
    toignore="./getfiles_testing/mainroot/root1/root1_folder1"
    toignore_abs=$( cd "$toignore" ; pwd )

    # salvo configurazione nuova in un file temporaneo
    sed -e "s|${toignore}|${toignore_abs}|g" "$BATS_TEST_DIRNAME/getfiles_testing/configs/configtwopathsnignorafiles.ini" > /var/tmp/checksync/bats-tests/config.tmp

    # recupero il percorso assoluto del file da ignorare
    toignore="./getfiles_testing/mainroot/root1/root1_folder2"
    toignore_abs=$( cd "$toignore" ; pwd )

    # salvo configurazione nuova sul file temporaneo
    sed -i -e "s|${toignore}/eq_file1|${toignore_abs}/eq_file1|g" "/var/tmp/checksync/bats-tests/config.tmp"

    run "$BATS_TEST_DIRNAME/../utils/getfiles.sh" "/var/tmp/checksync/bats-tests/config.tmp" "batstesting-hostname" "--skip-conn-test"
    [ "$status" -eq 0 ]

    extract_pathnhostname

    run cat /var/tmp/checksync/bats-tests/getfiles.tmp

    [ "$status" -eq 0 ]
    [[ "${lines[0]}" = "path;macchina" ]]
    [[ "${lines[1]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root1/root1_folder2/eq_file2;batstesting-hostname" ]]
    [[ "${lines[2]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root1_folder2/eq_file1;batstesting-hostname" ]]
    [[ "${lines[3]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root1_folder2/eq_file2;batstesting-hostname" ]]
    [[ "${lines[4]}" = *"/checksync/bin/test/getfiles_testing/mainroot/root2/root2_folder1/root2_folder1_file3.txt;batstesting-hostname" ]]
}
