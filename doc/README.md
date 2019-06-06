# CHECKSYNC
Checks if two machines are synchronized (same files)
## Descrizione
Il programma verifica se due server sono sincronizzati (quindi se i file presenti su di essi sono uguali).
> Uguali significa che devono avere la stessa dimensione, la stessa data di ultima modifica e lo stesso checksum MD5

Per fare questo vengono utilizzati diversi script:
> I programmi sono descritti in ordine di esecuzione
* ```checksync.sh```: e' il programma principale, si occupa di copiare in remoto, di avviare e di far interagire gli altri script 
* ```utils/configs.sh``` : richiede un parametro obbligatorio ( da passare a checksync.sh ), il percorso valido di un file di configurazione. 
Questo script estrae le configurazioni e le gestisce 
* ```utils/logger.sh``` : si occupa di creare la cartella contenente i log e di scrivere i log
* ```utils/getfiles.sh``` : si occupa di recuperare tutti i percorsi di tutti i file e le cartelle, 
per poi filtrarli dando in output un file con solo i percorsi dei file, piu' la loro dimensione, la data di ultima modifica e il checksum MD5. 
Questo script viene eseguito due volte, in locale e in remoto, e dai due output ricavati viene ricavato un terzo file di output attraverso il comando cat
> L'output di cat viene prima ordinato in ordine alfabetico per avere i percorsi uguali vicini

> La data di ultima modifica e la dimensione vengono ottenuti con il comando stat

> Il checksum MD5 viene ricavato dal comando md5sum

> Il comando cat permette di unire il contenuto dei due file in un file unico 

* ```utils/printdiffs.sh``` : contiene funzione "printdiffs" che si occupa di visualizzare quali file sono presenti su un server, 
su l'altro o su entrambe mostrando anche le informazioni precedentemente ricavate (dimensione, data ultima modifica e checksum MD5). 
Questa funzione richiede in input il file di output del comando cat.

## Esecuzione script
Per eseguire lo script posizionarsi nella cartella bin e digitare
```
./checksync.sh <config file>
```

"config file" e' il percorso di un file di configurazione.
Esempio struttura file di configurazione:
```
[ANALIZZA]

/path/da/analizzare

[IGNORA]
/path/da/ignorare

[LOG]
path=/path/filedi.log

[MACCHINA 2]
ip=x.x.x.x
user=<user>
scppath=/path/remoto

[OUTPUT]
getfiles=/path/output/comando/find.csv
diffout=/path/output/comando/diff.csv

[NOTIFICHE]
email=<email>
```

Il file di configurazione e' diviso in 6 sezioni: (3 obbligatorie)
* sezione "[ANALIZZA]" : contiene percorsi da analizzare (uno per riga)
* sezione "[IGNORA]" (facoltativa) : contiene percorsi da ignorare (uno per riga)
* sezione "[LOG]" (facoltativa) : la proprieta' "path" viene usata per il percorso file di log
> Se la sezione non esiste verra' usato il percorso ```/var/log/checksync/checksync.log```
* sezione "[MACCHINA 2]": contiene 
 * la proprieta' "ip" : indirizzo ip macchina remota da analizzare
 * la proprieta' "user" : nome utente con cui connettersi alla macchina remota
 * la proprieta' "scppath" : percorso della macchina remota in cui copiare la cartella con tutti gli script 
> Questo e' necessario per poter analizzare la macchina remota
* sezione "[OUTPUT]" : contiene
 * la proprieta' "getfiles" : percorso file di output del comando find (per trovare i percorsi di file e cartelle)
 * la proprieta' "diffout" : percorso file di output del comando diff (per capire quali file sono diversi tra le due macchine e a quale macchina appartengono) 
* sezione "[NOTIFICHE]" (facoltativa) : contiene
 * la proprieta' "email" : indirizzo email a cui mandare l'output 
> La mail per essere inviata richiede di installare sendmail attraverso il comando ```sudo apt-get install sendmail```

> Se le email non vengono ricevute, provare a rieseguire lo script dopo aver 
riavviato il daemon di sendmail con il comando ```sudo sendmail -bd```

## Requisiti
* Sistema operativo Unix / Unix-like

## Changelog

**03_01 2019-06-06:** <br>
Fixes:
* Ora lo script puo' essere eseguito da qualsiasi percorso
> Prima il percorso veniva completato con la cartella del percorso attuale
> e non con la cartella in cui risiedeva lo script

* Non viene piu' usato il comando diff per distinguere da dove provengono
i file e quali sono unici perche' non dava il risultato aspettato,
questa operazione viene eseguita dal programma printdiffs.sh

Features:
* Lo script puo' mandare l'output di esecuzione anche via mail
> La mail per essere inviata richiede di installare sendmail attraverso il comando ```sudo apt-get install sendmail```
> e l'indirizzo email deve essere specificato nella configurazione

**02_01 2019-06-05:** <br>
Changes:
* Rimosso script in python utils/printdiffs.py 
(la visualizzazione adesso viene svolta dall'omonimo script bash)
* Il nuovo script di visualizzazione (utils/printdiffs.sh) non scrive piu' il suo output su file
* Il nuovo script di visualizzazione (utils/printdiffs.sh) non necessita' piu' di due file
in input distinti per ogni macchina 
* Rimosso script utils/analizediffs.sh, lo script di visualizzazione non necessita' piu' di due file

**01_01 2019-06-04:** <br>
Prima versione

# Autore
Zenaro Stefano	
