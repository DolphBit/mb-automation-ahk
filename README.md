# MB Automation
(_README language: German - most likely only German end users, everything else is in english_)

Dieses AutoHotkey Script erlaubt eine Teilautomatisierung von `WISO MeinBüro Desktop` (Splitt-)Buchungen und bietet ein paar weitere nützliche Features.

## Installation

Skript (`mb-automation.ahk`) manuell kompilieren bzw. ausführen oder die vorhandene `mb-automation-ahk.exe` unter [Releases](/releases) runterladen und ausführen.

Sollte MB nicht auf dem Rechner ausgeführt werden, sondern über Remote Desktop verwendet werden, muss das Skript / exe und auf dem Host System ausgeführt werden!

> Das Skript wurde für den Remote Desktop entwickelt. (MB läuft auf einer Synology VM und ist langsam / träge)

## Features

### Übersicht

* Buchungen & Splittbuchungen durchführen
* Splittbuchung Wizard: X-beliebige Anzahl an Splittbuchungen mit Betrag angabe, inklusive Restbetrag Funktion
* Erstellen und speichern von Favoriten / Templates (bsp. Internet Rechnung, Serverkosten, etc.)
* Kategorien (`STRG + SHIFT + K`) & Belegnummer ändern (Hotkey verfügbar)
* "Bitte Keine Werbung"-Modus (schließt automatisch das Werbung-Fenster - keine nervigen Werbung Fenster mehr)
* `STRG + SHIFT + V` zum einfügen von Werten mit Euro, Punkt und Leerzeichen (weil MB das in manchen Feldern nicht mag...)

### Limitierung

* Während der Automatisierung darf nichts anderes unternommen werden
  * schon ein Maus bewegen könnte am Anfang zu Fehlern führen 
* Das Skript führt Mausbewegungen und Tastenkombinationen aus, wenn währenddessen vom Benutzer eine Aktion gemacht wird, kann es zu Fehlern kommen
    * Im Fall der Fälle kann mittels `ESC`-Taste eine aktive Automatisierung gestoppt werden (reload)
    * Via `SHIFT + ESC` kann das Programm komplett beendet werden

### (Splitt-) Buchung durchführen
* Automatisiert aus Favoriten oder Quick, kann eine Zahlung schnell gebucht werden

### Einfügen aus Excel / Calc
> Wer kennt es nicht, "13.05€" einfügen nicht möglich

Via `STRG + SHIFT + V` wird der Betrag nun richtig eingefügt 🥳

### Keine super tolle mega Werbung
* Schließt automatisch die nervige Werbung popups
  * Mega nervig im remote desktop, vorallem da manchmal die Fenster sich im Hintergrund verstecken...

### Argumente

Die exe kann mit folgenden Argumenten gestartet werden

- `--debug` - Startet die Anwendung im Debug mode (loglevel 4) und zeigt ein Log Fenster an
- `--loglevel [0-4]` - Setzt das Loglevel auf (0: error, 1: warn, 2: info, 3: debug)
> 🚩 Debug Window  or higher log level will slow down automation. Debug Window significantly on a **slow** machine

## Unterstützte Versionen

Mit Version `23.01.02.002` (Stand Februar 2023) getestet.

Neuere Versionen *können* zu Fehlern führen (unwahrscheinlich) aber ggf. ändern sich Name oder Layout wodurch die Anwendung aktualisiert werden muss.
 
## Hilfe / Support

Siehe [Wiki Dokumentation](https://github.com/DolphBit/mb-automation-ahk/wiki) und [SUPPORT](/SUPPORT.md)

## Changelog

Siehe [CHANGELOG](/CHANGELOG.md)

## Credits / Third Party

Siehe [CREDITS](/CREDITS.md)

## Lizenz / Garantie

Open Source, siehe [LICENSE](/LICENSE)

Entwickelt mit AutoHotkey v1 (https://www.autohotkey.com/) unter der `GNU GENERAL PUBLIC LICENSE v2` (https://www.autohotkey.com/docs/license.htm)

## Contribution

Siehe [CONTRIBUTING](/CONTRIBUTING.md)

## Roadmap

Seiehe [ROADMAP](/ROADMAP.md)
