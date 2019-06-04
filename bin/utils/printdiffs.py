#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Stefano Zenaro"
__version__ = "01.01 2019-05-28"

import sys
import os
from tabulate import tabulate
from datetime import datetime
import configparser
import time

config = configparser.ConfigParser(allow_no_value=True)
boold = False


def alphabeticalfirst(t_string1, t_string2):

    """

    :param t_string1: stringa, stringa da confrontare
    :param t_string2: stringa, stringa da confrontare

    La funzione si occupa di verificare quale delle
    due stringhe passate come parametro viene prima in ordine alfabetico.

    Se la funzione non restituisce niente le due stringhe sono uguali,
    altrimenti viene restituita la stringa che viene prima in ordine alfabetico
    
    """

    if t_string1 != t_string2:
        # le stringhe sono diverse
        # guardo ordine alfabetico
        lenstr1 = len(t_string1)
        lenstr2 = len(t_string2)

        if lenstr1 > lenstr2:
            # se la stringa t_string1 e' piu' grande di t_string2
            for i in range(lenstr1):
                if t_string1[i] > t_string2[i]:
                    # t_string1 viene dopo in ordine alfabetico
                    # rispetto a t_string2
                    return t_string2
                elif t_string1[i] < t_string2[i]:
                    # t_string1 e' prima in ordine alfabetico
                    # rispetto a t_string2
                    return t_string1
                
            # i caratteri analizzati sono uguali
            # vuol dire che t_string2 e' prima di t_string1
            # perche' piu' corta
            return t_string2
        else:
            # se la stringa t_string2 e' piu' grande di t_string1
            for i in range(lenstr2):
                if t_string1[i] > t_string2[i]:
                    # t_string1 viene dopo in ordine alfabetico
                    # rispetto a t_string2
                    return t_string2
                elif t_string1[i] < t_string2[i]:
                    # t_string1 e' prima in ordine alfabetico
                    # rispetto a t_string2
                    return t_string1
                
            # i caratteri analizzati sono uguali
            # vuol dire che t_string1 e' prima di t_string2
            # perche' piu' corta
            return t_string1


def sizeof_fmt(num, suffix='B'):

    """

    :param num: numero, byte da visualizzare in una nuova unita' di misura
    :param suffix: stringa, suffisso unita' di misura

    La funzione restituisce il numero "num" di byte
    come stringa che ha come unita' di misura una unita' facilmente leggibile

    """
    
    for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
        if abs(num) < 1024.0:
            return "%3.1f %s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f %s%s" % (num, 'Yi', suffix)


if __name__ == "__main__":

    if boold:
        print("Inizio programma")
        print("-" * 50)

    if len(sys.argv) == 5:
	
        config.read(sys.argv[1])
        logfile = config["LOG"]["path"].strip()
        file1 = sys.argv[2]
        file2 = sys.argv[3]
        output = sys.argv[4]

        if os.path.exists(file1) and os.path.exists(file2):
            with open(output, "w") as fout, open(logfile, "a") as flog:
                with open(file1, "r") as f1, open(file2, "r") as f2:

                    fout.write("filepath;mostupdated\n")
                    
                    line1 = f1.readline().lstrip(">").lstrip("<").lstrip()
                    line2 = f2.readline().lstrip(">").lstrip("<").lstrip()

                    while line1 != "" and line2 != "":
                        # scorro entrambe i file
                        v_line1 = line1.strip().split(";")
                        v_line2 = line2.strip().split(";")
                        
                        if v_line1[0] == v_line2[0]:
                            # filepath presente su entrambe i file
                            flog.write(time.strftime("[%F %T]") + "'" + v_line1[0] + "' presente su entrambe le macchine\n")

                            print("Presente su entrambe i server:")
                            print(v_line1[0], "\n")

                            size1 = sizeof_fmt(int(v_line1[1]))
                            size2 = sizeof_fmt(int(v_line2[1]))
                            
                            last_mod1 = datetime.utcfromtimestamp(int(v_line1[2])).strftime('%Y-%m-%d %H:%M:%S')
                            last_mod2 = datetime.utcfromtimestamp(int(v_line2[2])).strftime('%Y-%m-%d %H:%M:%S')
                            
                            table = [["Dimensione file:", size1, size2],
                                     ["Ultima modifica:", last_mod1, last_mod2],
                                     ["Checksum MD5:", v_line1[3], v_line2[3]]]
                            
                            print(tabulate(table, headers=["", "Server 1 (locale)", "Server 2 (remoto)"]))

                            line1 = f1.readline().lstrip(">").lstrip("<").lstrip()
                            line2 = f2.readline().lstrip(">").lstrip("<").lstrip()
                        else:
                            # i filepath sono diversi
                            if alphabeticalfirst(v_line1[0], v_line2[0]) == v_line1[0]:
                                # filepath presente sono nel file1
                                flog.write(time.strftime("[%F %T]") + "'" + v_line1[0] + "' presente SOLO sul server 1\n")
                                if boold:
                                    print(v_line1[0], "presente solo in", file1)

                                size1 = sizeof_fmt(int(v_line1[1]))
                                last_mod1 = datetime.utcfromtimestamp(int(v_line1[2])).strftime('%Y-%m-%d %H:%M:%S')

                                print("Presente SOLO sul server 1 (locale):")
                                print(v_line1[0], "\n")
                                table = [["Dimensione file:", size1],
                                         ["Ultima modifica:", last_mod1],
                                         ["Checksum MD5:", v_line1[3]]]

                                print(tabulate(table, headers=["", "Server 1 (locale)"]))
                                fout.write("'" + v_line1[0] + "';'" + file1 + "'\n")
                                line1 = f1.readline().lstrip(">").lstrip("<").lstrip()
                            elif alphabeticalfirst(v_line1[0], v_line2[0]) == v_line2[0]:
                                # filepath presente sono nel file2
                                flog.write(time.strftime("[%F %T]") + "'" + v_line1[0] + "' presente SOLO sul server 2\n")
                                if boold:
                                    print(v_line2[0], "presente solo in", file2)

                                size2 = sizeof_fmt(int(v_line1[1]))
                                last_mod2 = datetime.utcfromtimestamp(int(v_line1[2])).strftime('%Y-%m-%d %H:%M:%S')

                                print("Presente SOLO sul server 2 (remoto):")
                                print(v_line2[0], "\n")
                                table = [["Dimensione file:", size2],
                                         ["Ultima modifica:", last_mod2],
                                         ["Checksum MD5:", v_line2[3]]]

                                print(tabulate(table, headers=["", "Server 2 (remoto)"]))
                                
                                fout.write("'" + v_line2[0] + "';'" + file2 + "'\n")
                                line2 = f2.readline().lstrip(">").lstrip("<").lstrip()
                        print("\n" + "=" * 100 + "\n")
        else:
            print("File in input non esistenti")
            sys.exit(17)
    else:
        print("Numero parametri errato")
        print("python analizediffs.py <file1> <file2> <output>")
        print("<file1> : primo file csv in input da analizzare")
        print("<file2> : secondo file csv in input da analizzare")
        print("<output> : file csv in output, risultato tra confronto di file1 e file2")
        sys.exit(16)

    if boold:
        print("-" * 50)
        print("Fine programma")
