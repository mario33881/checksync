# CHECKSYNC

## Descrizione
Il programma verifica se due server sono sincronizzati (quindi se i file presenti su di essi sono uguali).
> Uguali significa che devono avere la stessa dimensione, la stessa data di ultima modifica e lo stesso checksum MD5

Per fare questo vengono utilizzati diversi script:
> I programmi sono descritti in ordine di esecuzione
* ```checksync.sh```: e' il programma principale, si occupa di copiare in remoto, di avviare e di far interagire gli altri script 
* ```utils/configs.sh``` : richiede un parametro obbligatorio, il percorso valido di un file di configurazione. Questo script estrae le configurazioni e le gestisce 
* ```utils/logger.sh``` : si occupa di creare la cartella contenente i log e di scrivere i log
* ```utils/getfiles.sh``` : si occupa di recuperare tutti i percorsi di tutti i file e le cartelle, per poi filtrarli dando in output un file con solo i percorsi dei file, piu' la loro dimensione, la data di ultima modifica e il checksum MD5. Questo script viene eseguito due volte, in locale e in remoto,
e dai due output ricavati viene ricavato un terzo file di output attraverso il comando diff
> La data di ultima modifica e la dimensione vengono ottenuti con il comando stat

> Il checksum MD5 viene ricavato dal comando md5sum

> Il comando diff permette di vedere quali righe dei file sono diverse

* ```utils/analizediffout.sh``` : richiede 3 parametri, il percorso del file output del comando diff e due percorsi di output.
Il programma si occupa di dividere in due file l'output del comando diff per permettere la loro analisi
* ```utils/printdiffs.py``` : script python che richiede in input il file di configurazione (per accedere al percorso del file di log), i due percorsi dei file in output di analizediffout.sh e il percorso del suo file in output. Visualizza quali file sono presenti su un server, su l'altro o su entrambe mostrando anche le informazioni precedentemente ricavate (dimensione, data ultima modifica e checksum MD5)
> Per visualizzare le informazioni lo script usa la libreria [tabulate](https://bitbucket.org/astanin/python-tabulate/src/master/)
installabile con il comando ```pip install tabulate```

## Requisiti
* Sistema operativo Unix / Unix-like
* Python3 per visualizzazione informazioni ricavate
* libreria [tabulate](https://bitbucket.org/astanin/python-tabulate/src/master/)
> installabile con il comando ```pip install tabulate```

## Changelog

**01_01 2019-06-04:** <br>
Prima versione

# Autore
Zenaro Stefano	

