#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.
#SingleInstance, force
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

; Add third party dependencies
#Include <JSON>
#Include <Class_ImageButton>
#Include <UseGDIP>
#Include <Class_ScrollGUI>

#Include Src/Constants.ahk
#Include Src/Globals.ahk
#Include Src/Styles.ahk
#Include Src/Utility.ahk

EnvGet, envDebug, ahk-mb-automation-debug
if (envDebug) {
    G_DEBUG_MODE := True
}

; Handle arguments
loglevel := 3
for argIndex in A_Args
{
    if (A_Args[argIndex] == "--debug") {
        logLevel := 4
        G_DEBUG_MODE := True
    }

    if (A_Args[argIndex] == "--loglevel" && (argIndex + 1 <= A_Args.MaxIndex())) {
        logLevel := A_Args[argIndex + 1]
    }
}

; Init logger
#Include Src/Class/Logger.class.ahk
G_LOGGER := new Logger(G_PROGRAMM_FOLDER "logs\", "log", logLevel, G_DEBUG_MODE)

; Logic Class & GUI
#Include Src/Class/Buchungen.class.ahk
#Include Src/Class/Settings.class.ahk
#Include Src/GUI/Main.gui.ahk
#Include Src/GUI/Edit.gui.ahk
#Include Src/GUI/EditSplitt.gui.ahk
#Include Src/GUI/Settings.gui.ahk
#Include Src/GUI/Verwendung.gui.ahk

; Main

global G_SETTINGS = new Settings()
global G_BUCHUNGEN = new Buchungen()
global G_GUI_EDIT = new GuiEdit()
global G_GUI_EDIT_SPLITT = new GuiEditSplitt()
global G_GUI_VERWENDUNGEN = new GuiVerwendungen()

UpdateGUI()

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; HOTKEYS
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; CTRL + SHIFT + V
; Inserts value but cleaned up to support paste from calc / excel
^+V::
    if (!HasExeFocus()) {
        return
    }
    clipboard2 := cleanupAmount(clipboard)
    SendRaw % clipboard2
return

; CTRL + SHIFT + K
; Hotkey to set selected Buchung with the given Verwendung
^+K::
    if (!HasExeFocus()) {
        return
    }
    GuiButtonVerwendung()
return

; CTRL + O
^O::
    DebugFocusControl()
return

DebugFocusControl() {
    global G_DEBUG_MODE

    if (!G_DEBUG_MODE) {
        return
    }
    ControlGetFocus, FocusVar, A

    G_LOGGER.Debug("=== DEBUG CONTROL ===")
    G_LOGGER.Debug(FocusVar)

    ControlGet, OutputList, List,, %FocusVar%, A
    G_LOGGER.Debug(OutputList)

    ControlGet, OutputList, Choice,, %FocusVar%, A
    G_LOGGER.Debug(OutputList)

    ControlGet, OutputList, LineCount,, %FocusVar%, A
    G_LOGGER.Debug(OutputList)

    ControlGet, OutputList, CurrentLine,, %FocusVar%, A
    G_LOGGER.Debug(OutputList)

    ControlGet, OutputList, Line, 2, %FocusVar%, A
    G_LOGGER.Debug(OutputList)

    ControlGet, OutputList, Selected,, %FocusVar%, A
    G_LOGGER.Debug(OutputList)

    ControlGetText, OutputList, %FocusVar%, A
    G_LOGGER.Debug(OutputList)

    ControlGet, Items, List,, %FocusVar%, A
    Loop, Parse, Items, `n
        G_LOGGER.Debug("Item number" . A_Index . "is" . A_LoopField)

    SendMessage, 0x014F, 1, , %FocusVar% , ; CB_SHOWDROPDOWN = 0x014F

    G_LOGGER.Debug("=== ~~~~~~~ ===")
}

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Automation Logic
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; Send Ok via F11 and optionally ignores the warning
SendOk()
{
    G_LOGGER.Debug("SendOk...")
    Send, {F11} ; OK - Abschluss

    if (G_SETTINGS.bIgnoreWarning) {
        Send, j ; OPTIONAL - Bestätige potentielle Warnung
    }

    G_LOGGER.Debug("SendOk... done")
}

; Setzt eine VORHANDENE Verwendung und speichert
VerwendungSetzen(Verwendung)
{
    if (!FocusWindowMB() || !HasFocusZahlung() || !Verwendung) {
        return False
    }

    Send, {F11}
    G_LOGGER.Debug("VerwendungSetzen -> öffne Bearbeiten")
    if (!WaitForZahlungWindow()) {
        return False
    }

    ; TODO how to handle SplittBuchung and implement?!

    Send, {Tab 4}
    ; Verwendung should be focused now
    ControlGet, CtrlHwnd, Hwnd,, %C_CTRL_BELEGNUMMER_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
    if (ErrorLevel || !CtrlHwnd)
    {
        ErrorMessage("Belegnummer ist nicht fokusiert, bitte diesen Fehler reporten mit Details!")
        return False
    }

    SendVerwendung(Verwendung)

    SendOk()
}

SendVerwendung(Verwendung) {
    SetKeyDelay, 100
    Send, {BackSpace}

    if (Verwendung == "" || Verwendung == C_VERWENDUNGEN_KEINE_ANGABE) {
        Send, {Up} ; this will select the default one
    } else {
        Send, %Verwendung%
    }

    SetKeyDelay, G_DEFAULT_DELAY
    Send, {Enter}
}

; Setze eine VORHANDNE Belegnummer und speichert
BelegnummerSetzen(Belegnummer)
{
    G_LOGGER.Debug("BelegnummerSetzen...")
    if (!FocusWindowMB() || !HasFocusZahlung() || !Belegnummer) {
        return False
    }

    Send, {F11}
    G_LOGGER.Debug("BelegnummerSetzen -> öffne Bearbeiten")
    if (!WaitForZahlungWindow()) {
        return False
    }

    ; Belegnummer should be focused automatically
    ControlGet, CtrlHwnd, Hwnd,, %C_CTRL_BELEGNUMMER_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
    if (ErrorLevel || !CtrlHwnd)
    {
        ErrorMessage("Belegnummer ist nicht fokusiert, bitte diesen Fehler reporten mit Details!")
        return False
    }

    SetKeyDelay, 50
    Send, %Belegnummer%
    SetKeyDelay, G_DEFAULT_DELAY
    Send, {Enter}

    SendOk()
}

WaitForZahlungWindow()
{
    WinWaitActive, ahk_class %C_WIN_ZAHLUNG_CLASS%,, %G_WAIT_TIMEOUT_SEC%
    if ErrorLevel
    {
        ErrorMessage("Zahlungsfenster (" . C_WIN_ZAHLUNG_CLASS . ") nicht offen!")
        return False
    }

return True
}

WaitForSteuerkategorieWindow()
{
    WinWaitActive, ahk_class %C_WIN_FIBU_KATEGORIE_AUSWAHL_CLASS%,, %G_WAIT_TIMEOUT_SEC%
    if ErrorLevel
    {
        ErrorMessage("Steuerkateogrie Fenster (Weitere) (" . C_WIN_FIBU_KATEGORIE_AUSWAHL_CLASS . ") nicht offen!")
        return False
    }

return True
}

; Führt eine Buchung durch, optional mit Verwendung
BuchungDurchführen(Label, Konto, Steuersatz, Verwendung)
{
    if (!FocusWindowMB() || !HasFocusZahlung()) {
        return False
    }

    G_BUCHUNGEN.SetProcessing(True, "Führe Buchung (" . Label . ") durch...")

    Send, {F11}
    G_LOGGER.Debug("BuchungDurchführen -> öffne Bearbeiten")
    if (!WaitForZahlungWindow()) {
        G_BUCHUNGEN.SetProcessing(False)
        return False
    }

    Send, {F2}
    G_LOGGER.Debug("BuchungDurchführen -> Weitere Konto Auswahl")
    if (!WaitForSteuerkategorieWindow()) {
        G_BUCHUNGEN.SetProcessing(False)
        return False
    }

    G_LOGGER.Debug("Enter Konto " . Konto . " and use it...")
    Send, %Konto%
    Sleep, 200
    Send {F11}

    ; lets settle everything in
    Sleep, 1000

    Send, {Tab 1} ; Kosten-/ Erlösart

    Send, {Tab 2} ; Verwendung
    if (Verwendung) {
        G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Setze Verwendung...")
        SendVerwendung(Verwendung)
    }

    if (Steuersatz) {
        G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Setze Steuersatz")
        Send, {Tab 2} ; Steuersatz
        SendSteuersatz(Steuersatz)
        Sleep, 500
    }

    SendOk()
    G_BUCHUNGEN.SetProcessing(False)
}

ExecuteSplittbuchung(index)
{
    if (G_BUCHUNGEN.Splitt.Length() < index || index < 1) {
        ErrorMessage("Ungültige Buchung")
        return False
    }

    if (!FocusWindowMB() || !HasFocusZahlung()) {
        return False
    }

    splitt := G_BUCHUNGEN.Splitt[index]

    label := splitt.label

    G_BUCHUNGEN.SetProcessing(True, "Führe Splittbuchung (" . label . ") durch...")

    G_LOGGER.Debug("ExecuteSplittbuchung -> " . label . "(index:" . index . ")")
    if (!GoToSplittbuchung()) {
        G_BUCHUNGEN.SetProcessing(False)
        return False
    }

    for i, entry in splitt.buchungen {
        if (!SplittbuchungSteuerkategorie(entry.konto, cleanupAmount(entry.betrag), entry.steuer, entry.verwendung)) {

            G_BUCHUNGEN.SetProcessing(False)
            return False
        }
        Sleep 1000
    }

    SendOk()

    G_BUCHUNGEN.SetProcessing(False)
return True
}

; Führt eine Splittbuchung durch
GoToSplittbuchung()
{
    if (!FocusWindowMB() || !HasFocusZahlung()) {
        return False
    }

    Send, {F11}
    G_LOGGER.Debug("ExecuteSplittbuchungEntry -> öffne Barbeiten")
    if (!WaitForZahlungWindow()) {
        return False
    }

    ControlGet, CtrlZahlungVerwerfen, Hwnd,, %C_CTRL_ZAHLUNG_VERWERFEN_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
    if not ErrorLevel
    {
        ControlGet, CtrlZahlungVerwerfenEnabled, Enabled,, %C_CTRL_ZAHLUNG_VERWERFEN_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
        if (CtrlZahlungVerwerfenEnabled == 1)
        {
            ControlGetText, CtrlZahlungVerwerfenText,, ahk_id %CtrlZahlungVerwerfen%
            if (CtrlZahlungVerwerfenText != C_CTRL_ZAHLUNG_VERWERFEN_TEXT)
            {
                ErrorMessage("Keine Zuordnung Button ist nicht gültig!")
                return False
            }
            SetControlDelay -1
            ControlClick,, ahk_id %CtrlZahlungVerwerfen%
            SetControlDelay %G_DEFAULT_DELAY%
        }
    }

    G_LOGGER.Debug("Wait for Steuerkonto to be visible...")
    ; Wait for Steuerkonto to be visible
    waitCount := 0
    loop {
        ControlGet, state, enabled,, %C_CTRL_BTN_STEUERKONTO_TEXT%, ahk_class %C_WIN_ZAHLUNG_CLASS%
        Sleep 250
        waitCount += 1
    } until (state == True or waitCount >= G_WAIT_TIMEOUT_COUNTER * 4)
    if (!state) {
        ErrorMessage(C_CTRL_BTN_STEUERKONTO_TEXT . " wurde nicht gefunden!")
        return False
    }

    G_LOGGER.Debug("Click on Splittbuchung")

    ; ControlClick does not work, so we get the pos, move and click
    if (!MoveMouseAndClickOnControl(C_CTRL_BTN_SPLITTBUCHUNG_TEXT, C_WIN_ZAHLUNG_CLASS, true)) {
        return False
    }

    G_LOGGER.Debug("Wait for Neue Splittbuchung to be visible")
    ; Wait for Neue Splittbuchung to be visible
    waitCount := 0
    state := False
    loop {
        ControlGet, state, enabled,, %C_CTRL_BTN_SPLITTBUCHUNG_NEU_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
        Sleep 250
        waitCount += 1

        if (Mod(waitCount, 4) == 0) {
            ; try to click again every sec
            if (MoveMouseAndClickOnControl(C_CTRL_BTN_SPLITTBUCHUNG_TEXT, C_WIN_ZAHLUNG_CLASS)) {
                return False
            }
        }

    } until (state == True or waitCount >= G_WAIT_TIMEOUT_COUNTER * 4)
    if (!state) {
        ErrorMessage(C_CTRL_BTN_SPLITTBUCHUNG_NEU_TEXT . " wurde nicht gefunden!")
        return False
    }
return True
}

; Fügt eine neue Splittbuchung hinzu, der Fokus muss auf dem "Neue Splittbuchung" Button mittels Tab sein!
SplittbuchungSteuerkategorie(Konto, Betrag, Steuersatz, Verwendung)
{
    if (!Konto) {
        ; TODO C_KONTO_PRIVATENNAHMEN_SKR4
        Konto := C_KONTO_PRIVATENNAHMEN_SKR3
        Steuersatz = ""
    }

    G_LOGGER.Debug("Click on Neue Splittbuchung")
    ; Click on Neue Splittbuchung
    SetControlDelay -1
    ControlClick, %C_CTRL_BTN_SPLITTBUCHUNG_NEU_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
    SetControlDelay %G_DEFAULT_DELAY%
    if ErrorLevel {
        ErrorMessage("Neue Splittbuchung konnte nicht gedrückt werden!")
        return False
    }

    ; Start new "Steuerkategorie" (open dropdown and use "Steuerkategorie")
    Send, s

    G_LOGGER.Debug("SplittbuchungSteuerkategorie -> auswählen " . Konto . ", " . Betrag . ", " . Steuersatz)

    WinWaitActive, ahk_class %C_WIN_BUCHUNG_ZORDNUNG_CLASS%,, %G_WAIT_TIMEOUT_SEC%
    if ErrorLevel
    {
        ErrorMessage("Steuerkateogrie Fenster (" . C_WIN_BUCHUNG_ZORDNUNG_CLASS . ") nicht offen!")
        return False
    }

    if (Betrag) {
        G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Betrag eingeben...")
        Send, %Betrag%
    }

    ; Open "weitere" to get all Kontos and search and use correct one
    Send, {F2}
    if (!WaitForSteuerkategorieWindow()) {
        return False
    }

    G_LOGGER.Debug("Enter Konto " . Konto . " and use it...")
    Send, %Konto%
    Sleep, 200
    Send {F11}

    ; lets settle everything in
    Sleep 1000

    Send, {Tab 1} ; Kosten-/ Erlösart

    Send, {Tab 2} ; Verwendung
    if (Verwendung) {
        G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Setze Verwendung...")
        SendVerwendung(Verwendung)
    }

    if (Steuersatz) {
        G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Setze Steuersatz")
        Send, {Tab 2} ; Steuersatz
        SendSteuersatz(Steuersatz)
    }

    ; lets settle everything in
    Sleep 1000

    G_LOGGER.Debug("SplittbuchungSteuerkategorie -> send F11 / OK...")
    Send, {F11} ; OK

return True
}

SendSteuersatz(index)
{
    G_LOGGER.Debug("SendSteuersatz -> index:" . index)

    Send, % C_STEUERN_ARR[index]
    Sleep, 500
    Send, {enter}
    G_LOGGER.Debug("SendSteuersatz -> " . C_STEUERN_ARR[index] . " done")
}

; Exit app if no GUI or ESC is pressed
GuiClose:
Esc::
ExitApp ; Exit script with Escape key

; -----------------------------------------------------------------

/*
    GuiControlGet, WertMiete
    SplittbuchungDurchführen("4288", WertMiete, "")

    GuiControlGet, WertStrom
    GuiControlGet, SteuerWertStrom
    SplittbuchungDurchführen("4288", WertStrom, SteuerWertStrom)
    SplittbuchungDurchführen("4920", WertTeleData, SteuerWertTeleData)
    SplittbuchungDurchführen("4920", WertVodafone, SteuerWertVodafone)
    SplittbuchungDurchführen("4288", WertRundfunk, "")
    SplittbuchungDurchführen("4288", WertHomeOffice, SteuerWertHomeOffice)
    BuchungDurchführen("3125", SteuerWertAuslandBuchung, VerwendungWertAuslandBuchung)
    BuchungDurchführen("3123", SteuerWertEuropaBuchung, VerwendungWertEuropaBuchung)
*/
