#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; MB window Identifiers
global C_WINDOW_MAIN_TITLE := "Mein Büro"
global C_EXE_MAIN := "MB.exe"

; Window Zahlung Fenster
global C_WIN_ZAHLUNG_TITLE := "Zahlung"
global C_WIN_ZAHLUNG_CLASS := "TFO_Zahlung"
global C_CTRL_ZAHLUNG_ROW_CLASSNN := ["TcxGridSite2", "TcxGridSite3"] ; Changes randomly, great...

; Window
global C_WIN_BUCHUNG_ZORDNUNG_CLASS := "TFO_BuchungsZuordnungSubKonto"
global C_WIN_FIBU_KATEGORIE_AUSWAHL_CLASS := "TFO_FibuKategorieAuswahl"

; Ads :/
global C_WIN_AD_CLASS := "TFO_AdView"
global C_CTRL_AD_CLOSE_CLASSNN := "TcxLabel1"
global C_CTRL_AD_CLOSE_TEXT := "Fenster schliessen"

; --
;global C_CTRL_BTN_STEUERKONTO_CLASSNN := "TcxImage5" ; <-- always changes ... :(
global C_CTRL_BTN_STEUERKONTO_TEXT := "Steuerkategorie"
;global C_CTRL_BTN_SPLITTBUCHUNG_CLASSNN := "TcxImage3" ; <-- always changes ... :(
global C_CTRL_BTN_SPLITTBUCHUNG_TEXT := "Splittbuchung"

global C_CTRL_BTN_SPLITTBUCHUNG_NEU_CLASSNN := "TDeltraCxButton12"
global C_CTRL_BTN_SPLITTBUCHUNG_NEU_TEXT := "Neue Splittbuchung"

global C_CTRL_ZAHLUNG_VERWERFEN_CLASSNN := "TDeltraCxButton10"
global C_CTRL_ZAHLUNG_VERWERFEN_TEXT := "Vorschlag verwerfen"

global C_CTRL_KEINE_ZUORDNUNG_CLASSNN := "TDeltraCxButton9"
global C_CTRL_KEINE_ZUORDNUNG_TEXT := "Keine Zuordnung"

global C_CTRL_BELEGNUMMER_CLASSNN := "TcxCustomInnerTextEdit5"
global C_CTRL_BELEGNUMMER_TEXT := "Beleg-Nr. (opt.)"

; Dokumente Fenster
global C_WIN_DOKUMENTE_TITLE := "Dokumente"

; Dokumente Open
global C_WIN_OPENFILE_TITLE := "Open"
global C_WIN_OPENFILE_ADDRESS_CLASSNN := "Edit2"

; Settings Variables
global C_VERWENDUNGEN_KEINE_ANGABE := "(keine Angabe)"

; STEUERN
global C_STEUERN := ("5,00 `% Umsatzsteuer|7,00 `% Umsatzsteuer|16,00 `% Umsatzsteuer|19,00 `% Umsatzsteuer
    |---|5,00 `% Vorsteuer|5,50 `% Vorsteuer|7,00 `% Vorsteuer|9,00 `% Vorsteuer
    |9,50 `% Vorsteuer|10,70 `% Vorsteuer|16,00 `% Vorsteuer|19,00 `% Vorsteuer
|0,00 `%|5,00 `%|5,50 `%|7,00 `%|9,00 `%|9,50 `%|10,70 `%|16,00 `%|19,00 `%")

global C_STEUERN_ARR := StrSplit(C_STEUERN, "|")

; KONTO
global C_KONTO_PRIVATENNAHMEN_SKR3 := 1800
global C_KONTO_PRIVATENNAHMEN_SKR4 := 2100

; === Defaults
global G_NEW_SPLITENTRY := { label: "Splittbuchung", betrag: 0, konto: 0, steuer: 0, verwendung: C_VERWENDUNGEN_KEINE_ANGABE }

; Codes
global C_SC_CLOSE := 0xF060
