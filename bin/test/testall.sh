#!/bin/bash

#
# Questo script esegue tutti gli script di test con bats
#

# tutto non deve dare errore
set -e

# vado nella cartella degli script bats
SCRIPTPATH="$( cd "$(dirname "$0")" || exit ; pwd -P )"
cd "$SCRIPTPATH"

printf "\nInizio i test\n"

# eseguo test configs
printf "\nEseguo test configs.sh\n"
./test_configs.bats
printf "\nFine test configs.sh\n"

# eseguo test getfiles
printf "\nEseguo test getfiles.sh\n"
./test_getfiles.bats
printf "\nFine test getfiles.sh\n"

# eseguo test logger
printf "\nEseguo test logger.sh\n"
./test_logger.bats
printf "\nFine test logger.sh\n"

# eseguo test printdiffs
printf "\nEseguo test printdiffs.sh\n"
./test_printdiffs.bats
printf "\nFine test printdiffs.sh\n"

printf "\nFine di tutti i test\n\n"
