# CHECKSYNC
![](https://i.imgur.com/rTSjWyR.png)

This script **checks if two machines are synchronized** (they have the same files)

Questo script **controlla se due macchine sono sincronizzate** (hanno gli stessi file)

## Sezioni pagina ![](https://i.imgur.com/5ACc398.png)
* <a href="#descrizione-breve-">Descrizione breve</a>
* <a href="#descrizione-dettagliata-">Descrizione dettagliata</a>
* <a href="#esecuzione-script">Esecuzione script</a>
* <a href="#status-code">Status code</a>
* <a href="#contenuto-archivio-">Contenuto archivio</a>
* <a href="#changelog-">Changelog</a>
* <a href="#autore-">Autore</a>

## Descrizione breve ![](https://i.imgur.com/wMdaLI0.png)
Il programma verifica se **due server sono sincronizzati** (quindi se i file presenti su di essi sono uguali).
> Uguali significa che devono avere la **stessa dimensione** e lo **stesso checksum MD5**

Per fare questo vengono utilizzati **diversi script**:
> I programmi sono descritti in **ordine di esecuzione**
* ```checksync.sh```: e' il **programma principale**, si occupa di **copiare in remoto**, di **avviare** e di **far interagire gli altri script**
* ```utils/configs.sh``` : richiede un **parametro obbligatorio** ( passato attraverso checksync.sh ), il percorso valido di un **file di configurazione**.
Questo script **estrae le configurazioni e le gestisce**
* ```utils/logger.sh``` : si occupa di **creare la cartella contenente i log** e di **scrivere i log**
* ```utils/getfiles.sh``` : si occupa di **recuperare tutti i percorsi di tutti i file**,
dando in **output un file** con solo i **percorsi dei file**, piu' la loro **dimensione**, la **data di ultima modifica**, il **checksum MD5** e l'**hostname** della loro macchina.
Questo script **viene eseguito due volte, in locale e in remoto**, e dai due output ricavati **viene ricavato un terzo file** di output attraverso il comando cat
    > L'output di cat viene prima **ordinato in ordine alfabetico** per avere i percorsi ( / file ) uguali vicini

    > La data di **ultima modifica** e la **dimensione** vengono ottenuti con il **comando stat**

    > Il **checksum MD5** viene ricavato dal comando **md5sum**

    > Il **comando cat** permette di **unire il contenuto** dei due file in un file unico

* ```utils/printdiffs.sh``` : contiene la funzione "printdiffs" che **si occupa di visualizzare** quali file sono presenti su un server,
su l'altro o su entrambe mostrando anche le informazioni precedentemente ricavate (dimensione, data ultima modifica e checksum MD5).
Questa funzione **richiede in input il file di output del comando cat**.

> Questo script contiene anche la funzione ```bytesToHuman()``` per rendere la **dimensione in byte facilmente leggibile**
e ```header_filesections()```, ```printtable()``` e ```divide_filesections()``` per **comporre l'html** da mandare via email.
Inoltre sono presenti le funzioni ```echo_stats()``` e ```html_stats()``` per visualizzare, rispettivamente su terminale e su email, le statistiche

<a href="#sezioni-pagina-">Torna a sezioni pagina</a>

## Descrizione dettagliata ![](https://i.imgur.com/wMdaLI0.png)

Lo script checksync.sh **si occupa di**:
1. Fare **source dello script "configs.sh" che gestisce il file di configurazione** passato come primo parametro.
Sul file di configurazione viene eseguito il **comando awk** il cui stdout viene letto riga per riga.
Questo comando permette di avere la **sezione di ogni configurazione su tutte le righe**, rendendo piu' facile
la loro interpretazione.

    Le informazioni ricavate dal file sono memorizzate nelle seguenti variabili:
    * **analize_paths[@]** : array con parametri da analizzare
    * **toignore_paths[@]**: array con parametri da ignorare
    * **logpath**          : percorso file di log
    * **ip**               : ip macchina remota
    * **user**             : username macchina remota
    * **scp_path**         : percorso remoto a cui copiare script
    * **getfiles_path**    : percorso file con informazioni files computer
    * **diffout_path**     : percorso file con differenze delle informazioni files
    * **email**            : indirizzo email a cui mandare l'output ( se send_email=true )

    Se i **parametri obbligatori non sono specificati** lo script uscira' con un **messaggio di errore**,
    altri parametri non sono necessari o hanno un valore di default
    > Nota: e' possibile leggere piu' **informazioni relative al file di configurazione nella sezione**
    di questa documentazione **"Esecuzione script"**

    Durante la sua esecuzione lo script **verifica** che tutti i **percorsi da analizzare siano esistenti**,
    che la **macchina remota sia raggiungibile** attraverso il comando **ping** e che la **destinazione
    dello script** sulla macchina remota sia effettivamente **presente** sul computer remoto.

2. Poi checksync.sh si occupa di fare il **source dello script logger.sh**
La prima informazione del file di configurazione che viene usata e' il percorso del file di log,
utilizzato per **creare le cartelle e il file di log**.

    Lo script logger.sh fornisce queste funzioni:
    * ```SCRIPTENTRY()``` : specifica quando avviene **avvio script**
    * ```SCRIPTEXIT()```  : specifica quando **termina lo script**
    * ```ENTRY()```       : specifica quando si **entra in una funzione**
    * ```EXIT()```        : specifica quando **termina una funzione**
    * ```INFO()```        : richiede stringa da visualizzare come **messaggio di informazione**
    * ```DEBUG()```       : richiede stringa da visualizzare come **messaggio di messaggio debug**
    * ```ERROR()```       : richiede stringa da visualizzare come **messaggio di messaggio errore**

3. Lo script checksync.sh **copia gli script sul server remoto** (specificato sul file di configurazione) attraverso il protocollo scp

4. **salva il file di configurazione sul server remoto** con il protocollo scp

5. **ottiene lista file su questo pc con lo script "getfiles.sh"**, identificandoli con l'hostname della macchina locale (output comando "hostname")
Per prima viene eseguita la funzione ```getfiles()``` che **si occupa di eseguire** prima la funzione ```findtree()``` e poi ```getstatnmd5()```

            findtree()

    La funzione ```findtree()``` **usa le informazioni ricavate dal file di configurazione** per comporre il **comando find**
    da usare per trovare i **percorsi di tutti i file** presenti sulla macchina,
    eventualmente **ignorando con -prune alcuni file/percorsi**
    > Tutti i percorsi verranno **scritti sul file** ```/var/tmp/checksync/find_output.csv```

            getstatnmd5()

    La funzione ```getstatnmd5()``` si occupa di **scorrrere il file** scritto dalla funzione ```findtree()``` e di
    **scrivere sul file $getfiles_path il percorso dei file**, **dimensione** in byte e **timestamp di ultima modifica** dati dal **comando stat**,
    **checksum MD5** ottenuto dal **comando md5sum** e l'**hostname della macchina** (passato al programma come secondo parametro)

    > **find, stat e md5sum** verranno **eseguiti** con ```sudo -n``` (modalita' **non interattiva**) perche' altrimenti
    i comandi porteranno ad un **"Permission Denied"**, se il comando da errore perche' il **sudo richiede la password**
    i comandi verranno **rieseguiti senza sudo**. Questo permette la **continuita' dello script** senza interazione
    da parte dell'utente ma impedisce di verificare che alcuni file siano realmente uguali tra le due macchine

    > E' consigliato **impostare il file sudoers** per permettere ad un account creato solo per lo script
    di **eseguire find, stat e md5sum via sudo senza password**

    L'output di ```getstatnmd5()``` sara' un **file csv** il cui **percorso** e' specificato nel **file di configurazione**,
    sezione "[OUTPUT]" proprieta' "getfiles".
    Questo file **conterra' percorso del file, dimensione, timestamp di ultima modifica e l'hostname** della macchina

6. Lo script checksync.sh **ottiene lista file** su server remoto con lo **script "getfiles.sh"**, identificandoli con l'hostname della macchina remota.
Lo script **si connette via ssh** al server remoto e **avvia lo script** "getfiles.sh" copiato nel passaggio 3.
    > Le operazioni che esegue sono uguali a quelle descritte nel punto 5

7. Lo script checksync.sh **recupera log di getfiles.sh** del computer remoto attraverso il **comando "cat" via ssh**
e scorrendo il suo output scrive il contenuto riga per riga sul log locale

8. Il **file log del computer remoto viene cancellato** via ssh con il comando "rm"
    > **Non ha senso avere due file di log**, di cui **uno incompleto** perche' contiene solo la parte di esecuzione remota

9. Viene eseguito il **cat tra i due output** dei "getfiles.sh" via ssh, ordinando l'**output** del cat **in ordine alfabetico** con "sort -V".
L'output del comando viene scritto sul file il cui percorso e' specificato sul file di configurazione specificato nella sezione "[OUTPUT]", proprieta' "diffout"

10. **Visualizza/manda via mail le informazioni** ricavate con lo **script "printdiffs.sh"**.
Lo script checksync.sh fa il **source dello script** "printdiffs.sh" rendendo disponibile la sua funzione
principale, ```printdiffs()```

            printdiffs()

    La funzione **richiede come parametro il percorso del file output del comando cat**
    che contiene tutte le informazioni dei file sia del server remoto, sia del server locale.

    Il file viene **letto riga per riga**, confrontando la riga letta con la riga precedente:
    * se il **percorso del file della riga precedente** e' **uguale** al percorso del file sulla **riga attuale**
    allora **i file sono presenti su entrambe le macchine** e verranno **visualizzate le informazioni** di entrambe.
    ( se dimensioni e checksum MD5 sono diversi, altrimenti i file sono uguali )

        > non ha senso quindi confrontare la riga attuale con la riga successiva perche' sappiamo gia'
        che i file sono presenti su entrambe le macchine, la riga successiva dovra' essere confrontata con la sua riga successiva

    * **se i percorsi sono diversi** significa che **il file** descritto nella riga precedente **appartiene ad un solo server**
    > le informazioni del file sono **identificate dall'hostname** della macchina

    > Per leggere i **singoli elementi** del file csv viene usata la funzione ```get_csvelement()```

    **Per visualizzare le informazioni** ```printdiffs()``` usera' le funzioni:
    * ```bytesToHuman()``` per rendere la **dimensione in byte** facilmente **leggibile**
    * ```header_filesections()```, ```printtable()``` e ```divide_filesections()``` per **comporre l'html** da mandare via email
    * ```echo_stats()``` per visualizzare le statistiche su terminale e ```html_stats()``` per inserire le statistiche nell'email 
        > Le statistiche indicano il numero dei file rilevati su entrambe le macchine, quanti di questi sono presenti su entrambe
        le macchine e quanti sono effettivamente uguali (questo dato e' visualizzato anche in percentuale) 

Se al programma "checksync.sh" viene passata come **secondo parametro** la flag "**-m**", "**-me**" o "**-em**"
l'**output in formato html** verra' memorizzato in una variabile e **utilizzato dalla funzione**
```email_sender()``` per **mandare la mail** con tutte le informazioni.
> ```email_sender()``` per mandare la mail **ha bisogno di una mail** specificata nel **file di configurazione**
e di **sendmail installato** sulla macchina

Se al programma viene passata come **secondo parametro** la flag "**-e**". "**-me**", "**-em**" o **nessuna flag**
l'**output** del programma verra' **visualizzato sul terminale**.

> Per **assicurarsi che non si siano errori** durante l'esecuzione di checksync.sh i comandi vengono eseguiti attraverso
> la funzione ```checksuccess()```

    checksuccess()

questa funzione si occupa di **eseguire comandi** e
di verificarne il successo

il primo parametro e' il **status code** con cui far uscire lo script
in caso di errore, il secondo parametro e' la **descrizione** di cio'
che fa il comando (utile con boold=true per debug e in caso di errore)
e gli **altri parametri compongono il comando** da eseguire

<a href="#sezioni-pagina-">Torna a sezioni pagina</a>

## Esecuzione script
Per eseguire lo script **posizionarsi nella cartella** bin e digitare
```
./checksync.sh <config file> [<output dest>]
```

> Se necessario **renderlo eseguibile** con il comando ```chmod +x checksync.sh```

"\<config file>" e' il **percorso di un file di configurazione**

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

Il **file di configurazione** e' diviso in 6 sezioni:
* sezione "**[ANALIZZA]**" : contiene **percorsi da analizzare** assoluti (uno per riga)
* sezione "**[IGNORA]**" (facoltativa) : contiene **percorsi** assoluti di cartelle o file **da ignorare** (uno per riga)
* sezione "**[LOG]**" (facoltativa) : la proprieta' "path" viene usata per il **percorso file di log**
    > Se la sezione **non esiste** verra' usato il percorso ```/var/log/checksync/checksync.log```
* sezione "**[MACCHINA 2]**": contiene
    * la proprieta' "**ip**" : indirizzo **ip macchina remota** da analizzare
    * la proprieta' "**user**" (facoltativa) : **nome utente** con cui connettersi alla **macchina remota**, se non specificato verra' usato il nome utente corrente
    * la proprieta' "**scppath**" : **percorso** della macchina **remota** in cui **copiare la cartella** con tutti gli script
* sezione "**[OUTPUT]**" : contiene
    * la proprieta' "**getfiles**" : percorso **file di output dello script getfiles.sh** (per trovare i percorsi di file e cartelle)
    * la proprieta' "**diffout**" : percorso **file di output del comando cat** (contenente percorsi file delle due macchine)
* sezione "**[NOTIFICHE]**" (facoltativa) : contiene
    * la proprieta' "**email**" : **indirizzo email** a cui mandare l'output

"\<output dest>" e' la **destinazione dell'output**:
* "**-m**" = **email**
* "**-me**" o "**-em**" = **email** e **echo** sul terminale
* "**-e**" = **echo** sul terminale

Per poter mandare le **informazioni ottenute via email** e' necessario **installare sendmail**
attraverso il comando:

    sudo apt-get install sendmail

> Se le email **non vengono ricevute**, provare a rieseguire lo script dopo aver
**riavviato il daemon** di sendmail con il comando ```sudo sendmail -bd```.

<a href="#sezioni-pagina-">Torna a sezioni pagina</a>

## Status code
Tutti gli script hanno dei codici uscita in caso di errore

I codici:
* **1x** corrispondono allo script configs.sh
* **2x** corrispondono allo script checksync.sh
* **3x** corrispondono allo script logger.sh
* **4x** corrispondono allo script printdiffs.sh

In particolare:

| Status code | Descrizione                                                                   | Script        |
|-------------|-------------------------------------------------------------------------------|---------------|
| 10          | Il file di configurazione non esiste                                          | configs.sh    |
| 11          | Parametro file di configurazione non passato                                  | configs.sh    |
| 12          | Sezione con percorsi da analizzare ( [ANALIZZA] ) vuota                       | configs.sh    |
| 13          | Indirizzo IP macchina remota non specificato ( [MACCHINA 2]ip)                | configs.sh    |
| 14          | Percorso da analizzare non valido/inesistente                                 | configs.sh    |
| 15          | Indirizzo IP non valido                                                       | configs.sh    |
| 16          | Cartella remota ( [MACCHINA 2]scppath) non esistente                          | configs.sh    |
| 17          | Macchina remota non raggiungibile                                             | configs.sh    |
| 20          | Errore durante la copia degli script su server remoto                         | checksync.sh  |
| 21          | Errore durante copia file di configurazione su macchina remota                | checksync.sh  |
| 22          | Errore durante esecuzione di getfiles.sh in locale                            | checksync.sh  |
| 23          | Errore durante esecuzione di getfiles.sh su macchina remota                   | checksync.sh  |
| 24          | Errore durante copia del log su macchina remota                               | checksync.sh  |
| 25          | Errore durante eliminazione log su macchina remota                            | checksync.sh  |
| 26          | Errore durante il recupero output getfiles.sh remoto e creazione output "cat" | checksync.sh  |
| 27          | Errore durante l'esecuzione di printdiffs.sh                                  | checksync.sh  |
| 30          | Percorso file di log non esistente ($SCRIPT_LOG)                              | logger.sh     |
| 40          | File "cat" passato come parametro a printdiffs() non esistente                | printdiffs.sh |
| 41          | Nessun file "cat" passato come parametro a printdiffs()                       | printdiffs.sh |
| 42          | Parametro passato a bytesToHuman() non valido (deve essere intero >=0)        | printdiffs.sh |
| 43          | Parametro Index passato a get_csvelement() non valido (deve essere intero >0) | printdiffs.sh |
| 44          | Parametro Stringa passato a get_csvelement() vuoto                            | printdiffs.sh |
| 45          | Parametro Index passato a get_csvelement() troppo grande (out of range)       | printdiffs.sh |
| 46          | Parametro Stringa senza delimitatore o Index = 0 passati a get_csvelement()   | printdiffs.sh |

<a href="#sezioni-pagina-">Torna a sezioni pagina</a>

## Requisiti
* Sistema operativo **Unix / Unix-like**
* [ **sendmail** se si vuole ricevere l'output via email ]

<a href="#sezioni-pagina-">Torna a sezioni pagina</a>

### Contenuto archivio ![](https://i.imgur.com/FWdiWIM.png)
```
checksync-master/
├ bin/
│   ├ test/
│   │   ├ configfiles/
│   │   │   └ ...
│   │   ├ getfiles_testing/
│   │   │   └ ...
│   │   ├ libs/
│   │   │   └ ...
│   │   ├ printdiffs_testing/
│   │   │   └ ...
│   │   ├ test_configs.bats
│   │   ├ test_getfiles.bats
│   │   ├ test_logger.bats
│   │   └ test_printdiffs.bats
│   ├ utils/
│   │   ├ getfiles.sh
│   │   ├ logger.sh
│   │   ├ printdiffs.sh
│   │   └ configs.sh
│   ├ config.ini
│   └ checksync.sh
├ doc/
│   └ README.md
└ README.md
```

<a href="#sezioni-pagina-">Torna a sezioni pagina</a>

## Changelog ![](https://i.imgur.com/SDKHpak.png)

**04_01 2019-06-20:** <br>
Features:
* Tutti gli script hanno sezione main
    > Questo permette di testare anche quelle funzioni 
    che non venivano testate in precedenza
* Ora le configurazioni possono contenere spazi
    > ad esempio "ip = x.x.x.x" ora e' valido,
    prima era obbligatorio scrivere "ip=x.x.x.x"
* E' stata aggiunta una progress bar per 
tracciare l'esecuzione dello script
    > L'ultimo punto percentale ( 96% )
    scompare dopo un secondo per non intaccare
    in nessun modo l'output dello script

**03_05 2019-06-19:** <br>
Features:
* I percorsi da ignorare possono terminare con "/" e "/."
    > Prima "-prune" ignorava questi percorsi 

Modifiche:
* Per i test ora viene usato bats-core e non piu' bats

Fixes:
* Ora la funzione ismyip() in configs.sh indica effettivamente se l'ip
passato come parametro appartiene o no alla macchina
    > Questo evita di eseguire il test di ping e dell'esistenza
      della cartella remota in cui copiare gli script
      ( In quest'ultimo caso a causa della password ssh il test poteva fallire )
* Il test che verifica la presenza della cartella remota 
  viene effettuata con lo user (se specificato) della configurazione
    > Prima il test veniva eseguito con lo user attuale della macchina locale

**03_04 2019-06-17:** <br>
Features:
* Aggiunti script bats di test
* Aggiunti controlli IP, scppath e percorsi da analizzare
* Aggiunte statistiche su terminale e via email in fondo agli output

Modifiche:
* Status code modificati secondo lo schema nella sezione status code

**03_03 2019-06-10:** <br>
Features:
* Al posto di "Server 1" e "Server 2" vengono visualizzati gli hostname delle due macchine
* Aggiunta la possibilita' di dare allo script un secondo parametro per definire
la destinazione dell'output (email, echo su terminale o entrambe)

**03_02 2019-06-09:** <br>
Fixes:
* Ora il sort viene eseguito con la flag "-V" per non avere
problemi nel riconoscimento di file presenti su entrambe le macchine
a causa di caratteri come "-" nel nome
    > Questo avveniva ad esempio con i file ```/etc/shadow-``` e ```/etc/shadow```,
    dove questi apparivano in successione, facendo rappresentare al programma che i due file
    prima erano presenti solo su una macchina, poi solo sull'altra
    (invece di rappresentarli presenti su entrambe le macchine)

* I comandi find, stat e md5sum non bloccano piu' l'esecuzione del programma
a causa della password perche' vengono eseguiti da sudo con la flag "-n" (non interactive).
Questo significa che il programma cerchera' di eseguire i comandi con sudo,
se verra' chiesta la password il programma eseguira' i comandi normalmente
    > Questo significa che in quest'ultimo caso certi file non verranno verificati con precisione

* Il comando find e' stato modificato per includere direttamente solo i file,
senza dover verificare successivamente il tipo. Per fare questo si usava
il comando stat il cui output e' dipendente dalla lingua selezionata sulla macchina

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

Changes:
* I comandi find, stat e md5sum ora vengono eseguiti come root
perche' normalmente non hanno l'accesso a tutte le informazioni relative ai file

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

<a href="#sezioni-pagina-">Torna a sezioni pagina</a>

# Autore ![](https://i.imgur.com/ej4EVF6.png)
Zenaro Stefano ( [Github](https://github.com/mario33881) )
