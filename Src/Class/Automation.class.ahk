#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; Handles Automation logic
Class Automation {

    Static IsProcessing := false
    Static ProcessingTask := "None"
    Static LastSelectedTab := 1

    ; Toggle Processing Mode
    SetProcessing(processing := true, info := "Please wait...") {
        if (processing == this.IsProcessing) {
            return
        }
        G_LOGGER.Info("Set Processing to " . processing . " (" . info . ")")

        if (processing) {
            this.LastSelectedTab := G_GUI_MAIN.GetSelectedTab()
        }

        this.IsProcessing := processing
        this.ProcessingTask := info
        G_GUI_MAIN.ShowProcessing(processing)

        ; wait some time before executing, to allow user leave the RDP screen, etc.
        Sleep (G_SETTINGS.automationDelay * 1000)
    }

    ; Automation for Buchung
    ExecuteBuchung(index) {
        if (IsZuordnungsAssistent() || !FocusWindowMB() || !HasFocusZahlung()) {
            return false
        }

        if (index == -1) {
            buchung := G_BUCHUNGEN.Quick.Buchung
        } else {
            if (G_BUCHUNGEN.Buchungen.Length() < index || index < 1) {
                ErrorMessage("Ungültige Buchung")
                return false
            }
            buchung := G_BUCHUNGEN.Buchungen[index]
        }

        G_Logger.Debug("ExecuteBuchung -> " . buchung.label)
        this.SetProcessing(true, "Führe Buchung (" . buchung.label . ") durch...")

        Send, {F11}
        G_LOGGER.Debug("BuchungDurchführen -> öffne Bearbeiten")
        if (!WaitForZahlungWindow()) {
            this.SetProcessing(false)
            return false
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        Send, {F2}
        G_LOGGER.Debug("BuchungDurchführen -> Weitere Konto Auswahl")
        if (!WaitForSteuerkategorieWindow()) {
            this.SetProcessing(false)
            return false
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        G_LOGGER.Debug("Enter Konto " . buchung.konto . " and use it...")
        Send, % buchung.konto
        Sleep, 200
        Send {F11}

        ; lets settle everything in
        Sleep, 1000

        ; check if Konto was successfull, by checking if Verwendung does exist:
        ControlGet, CtrlHwnd, Hwnd,, %C_CTRL_VERWENDUNG_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
        if (ErrorLevel || !CtrlHwnd) {
            ErrorMessage("Verwendung konnte nicht gefunden werden, vermutlich gab es ein Problem mit dem Konto. Existiert es und ist die Sichtbarkeit richtig eingestellt?")
            return false
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        Send, {Tab 1} ; Kosten-/ Erlösart

        Send, {Tab 2} ; Verwendung
        if (buchung.verwendung) {
            G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Setze Verwendung...")
            this.SendVerwendung(buchung.verwendung)
        }

        if (buchung.steuer) {
            G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Setze Steuersatz")
            Send, {Tab 2} ; Steuersatz
            this.SendSteuersatz(buchung.steuer)
            Sleep, 500
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        this.SendOk()
        this.SetProcessing(false)
    }

    ; Automation for Splittbuchung
    ExecuteSplittbuchung(index) {
        if (IsZuordnungsAssistent() || !FocusWindowMB() || !HasFocusZahlung()) {
            return false
        }

        if(index == -1) {
            splitt := G_BUCHUNGEN.Quick.Splitt
        } else {
            if (G_BUCHUNGEN.Splitt.Length() < index || index < 1) {
                ErrorMessage("Ungültige Buchung")
                return false
            }
            splitt := G_BUCHUNGEN.Splitt[index]
        }

        label := splitt.label

        this.SetProcessing(true, "Führe Splittbuchung (" . label . ") durch...")

        G_LOGGER.Debug("ExecuteSplittbuchung -> " . label . "(index:" . index . ")")
        if (!this.GoToSplittbuchung()) {
            this.SetProcessing(false)
            return false
        }

        for i, entry in splitt.buchungen {
            if (!this.SplittbuchungSteuerkategorie(entry.konto, cleanupAmount(entry.betrag), entry.steuer, entry.verwendung)) {

                this.SetProcessing(false)
                return false
            }

            Sleep 1000
        }

        this.SendOk()

        this.SetProcessing(false)
        return true
    }

    ; Goes to Splittbuchung within Zahlung window
    GoToSplittbuchung() {
        if (!FocusWindowMB() || !HasFocusZahlung()) {
            return false
        }

        Send, {F11}
        G_LOGGER.Debug("ExecuteSplittbuchungEntry -> öffne Barbeiten")
        if (!WaitForZahlungWindow()) {
            return false
        }

        ControlGet, CtrlZahlungVerwerfen, Hwnd,, %C_CTRL_ZAHLUNG_VERWERFEN_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
        if not ErrorLevel
        {
            ControlGet, CtrlZahlungVerwerfenEnabled, Enabled,, %C_CTRL_ZAHLUNG_VERWERFEN_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
            if (CtrlZahlungVerwerfenEnabled == 1)
            {
                ControlGetText, CtrlZahlungVerwerfenText,, ahk_id %CtrlZahlungVerwerfen%
                if (CtrlZahlungVerwerfenText != C_CTRL_ZAHLUNG_VERWERFEN_TEXT) {
                    ErrorMessage("Keine Zuordnung Button ist nicht gültig!")
                    return false
                }
                SetControlDelay -1
                ControlClick,, ahk_id %CtrlZahlungVerwerfen%
                SetControlDelay %G_DEFAULT_DELAY%
            }
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        G_LOGGER.Debug("Wait for Steuerkonto to be visible...")
        ; Wait for Steuerkonto to be visible
        waitCount := 0
        loop {
            ControlGet, state, enabled,, %C_CTRL_BTN_STEUERKONTO_TEXT%, ahk_class %C_WIN_ZAHLUNG_CLASS%
            Sleep 250
            waitCount += 1
        } until (state == true or waitCount >= G_APP.timeout.counter * 4)
        if (!state) {
            ErrorMessage(C_CTRL_BTN_STEUERKONTO_TEXT . " wurde nicht gefunden!")
            return false
        }

        G_LOGGER.Debug("Click on Splittbuchung")

        if (!this.CheckExeFocus()) {
            return false
        }

        ; ControlClick does not work, so we get the pos, move and click
        if (!MoveMouseAndClickOnControl(C_CTRL_BTN_SPLITTBUCHUNG_TEXT, C_WIN_ZAHLUNG_CLASS, true)) {
            return false
        }

        G_LOGGER.Debug("Wait for Neue Splittbuchung to be visible")
        ; Wait for Neue Splittbuchung to be visible
        waitCount := 0
        state := false
        loop {
            if (Mod(waitCount, 3) == 0) {
                ; try to click again every sec
                MoveMouseAndClickOnControl(C_CTRL_BTN_SPLITTBUCHUNG_TEXT, C_WIN_ZAHLUNG_CLASS)
            }

            ControlGet, state, enabled,, %C_CTRL_BTN_SPLITTBUCHUNG_NEU_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
            Sleep 250
            waitCount += 1
        } until (state == true or waitCount >= G_APP.timeout.counter * 4)

        if (!state) {
            ErrorMessage(C_CTRL_BTN_SPLITTBUCHUNG_NEU_TEXT . " wurde nicht gefunden!")
            return false
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        return true
    }

    ; Creates a new Splittbuchung entry
    SplittbuchungSteuerkategorie(Konto, Betrag, Steuersatz, Verwendung) {
        if (!Konto) { ; special case, no Konto means rest is privatentnahme
            if (G_SETTINGS.bSKR04) {
                Konto := C_KONTO_PRIVATENNAHMEN_SKR4
            } else {
                Konto := C_KONTO_PRIVATENNAHMEN_SKR3
            }
            Steuersatz := ""
        }

        G_LOGGER.Debug("Click on Neue Splittbuchung")
        ; Click on Neue Splittbuchung
        SetControlDelay -1
        ControlClick, %C_CTRL_BTN_SPLITTBUCHUNG_NEU_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
        SetControlDelay %G_DEFAULT_DELAY%
        if ErrorLevel {
            ErrorMessage("Neue Splittbuchung konnte nicht gedrückt werden!")
            return false
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        ; Start new "Steuerkategorie" (open dropdown and use "Steuerkategorie")
        Send, s

        G_LOGGER.Debug("SplittbuchungSteuerkategorie -> auswählen " . Konto . ", " . Betrag . ", " . Steuersatz)

        if(!WaitForWindowAndActivate(C_WIN_BUCHUNG_ZORDNUNG_CLASS, "Steuerkateogrie Fenster")) {
            return false
        }

        if (Betrag) {
            G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Betrag eingeben...")
            Send, %Betrag%
        }

        ; Open "weitere" to get all Kontos and search and use correct one
        Send, {F2}
        if (!WaitForSteuerkategorieWindow()) {
            return false
        }

        G_LOGGER.Debug("Enter Konto " . Konto . " and use it...")
        Send, %Konto%
        Sleep, 200
        Send {F11}

        ; lets settle everything in
        Sleep 1000

        ; check if Konto was successfull, by checking if Verwendung does exist:
        ControlGet, CtrlHwnd, Hwnd,, %C_CTRL_VERWENDUNG_CLASSNN%, ahk_class %C_WIN_BUCHUNG_ZORDNUNG_CLASS%
        if (ErrorLevel || !CtrlHwnd) {
            ErrorMessage("Verwendung konnte nicht gefunden werden, vermutlich gab es ein Problem mit dem Konto. Existiert es und ist die Sichtbarkeit richtig eingestellt?")
            return false
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        Send, {Tab 1} ; Kosten-/ Erlösart

        Send, {Tab 2} ; Verwendung
        if (Verwendung) {
            G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Setze Verwendung...")
            this.SendVerwendung(Verwendung)
        }

        if (Steuersatz) {
            G_LOGGER.Debug("SplittbuchungSteuerkategorie -> Setze Steuersatz")
            Send, {Tab 2} ; Steuersatz
            this.SendSteuersatz(Steuersatz)
        }

        ; lets settle everything in
        Sleep 1000

        if (!this.CheckExeFocus()) {
            return false
        }

        G_LOGGER.Debug("SplittbuchungSteuerkategorie -> send F11 / OK...")
        Send, {F11} ; OK

        return true
    }

    ; Send Steuersatz (requires focus of input field)
    SendSteuersatz(index) {
        G_LOGGER.Debug("SendSteuersatz -> index:" . index)

        if (!this.CheckExeFocus()) {
            return false
        }

        Send, % C_STEUERN_ARR[index]
        Sleep, 500
        Send, {enter}
        G_LOGGER.Debug("SendSteuersatz -> " . C_STEUERN_ARR[index] . " done")
    }

    ; Set a Verwendung for a Zahlung
    ExecuteVerwendung(Verwendung, SplittIndex := -1) {
        if (IsZuordnungsAssistent() || !FocusWindowMB() || !HasFocusZahlung() || !Verwendung) {
            return false
        }

        Send, {F11}
        G_LOGGER.Debug("VerwendungSetzen -> öffne Bearbeiten")
        if (!WaitForZahlungWindow()) {
            return false
        }

        VerwendungWinClassNN := C_WIN_ZAHLUNG_CLASS
        if (SplittIndex > -1) {
            VerwendungWinClassNN := C_WIN_BUCHUNG_ZORDNUNG_CLASS

            ; focus the first entry of Splittbuchungen
            if (!MoveMouseOffsetAndClickOnControlClass(C_CTRL_ZAHLUNG_SPLITTBUCHUNGEN_LABEL_TEXT, C_WIN_ZAHLUNG_CLASS, { x: 20, y: 100 }, true)) {
                return false
            }

            ; move now to the correct entry
            moveDown := SplittIndex - 1
            Send, {Down %moveDown%}

            ControlClick, %C_CTRL_ZAHLUNG_SPLITTBUCHUNGEN_BTN_BEARBEITEN%, ahk_class %C_WIN_ZAHLUNG_CLASS%

            if (!WaitForWindowAndActivate(C_WIN_BUCHUNG_ZORDNUNG_CLASS, "Steuerkateogrie Fenster")) {
                return false
            }
        }

        ; Try to focus VERWENDUNG
        ControlFocus, %C_CTRL_VERWENDUNG_CLASSNN%, ahk_class %VerwendungWinClassNN%
        ControlGetFocus, FocusControl, ahk_class %VerwendungWinClassNN%
        if (ErrorLevel or FocusControl != C_CTRL_VERWENDUNG_CLASSNN) {
            G_LOGGER.Debug(FocusControl . " != " . C_CTRL_VERWENDUNG_CLASSNN)
            ErrorMessage("Verwendung ist nicht fokusiert, bitte diesen Fehler reporten mit Details!")
            return false
        }

        this.SendVerwendung(Verwendung)
        this.SendOk()

        if (SplittIndex > -1) {
            ; If it's a Splittbuchung, we must close two windows
            if (!WaitForZahlungWindow()) {
                return false
            }
            Sleep, 1000
            this.SendOk()
        }
    }

    ; Send Verwendung (must be focused already)
    SendVerwendung(Verwendung) {
        G_Logger.Info("Send Verwendung: " . Verwendung)
        SetKeyDelay, 100
        Send, {BackSpace}

        if (Verwendung == "" || Verwendung == C_VERWENDUNGEN_KEINE_ANGABE) {
            Send, {Up} ; this will select the default one
        } else {
            Send, %Verwendung%
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        SetKeyDelay, %G_DEFAULT_DELAY%
        Send, {Enter}
        Sleep, 1000
    }

    ; Set a Belegnummer for a Zahlung
    ExecuteBelegnummer(Belegnummer) {
        G_LOGGER.Debug("BelegnummerSetzen...")
        if (IsZuordnungsAssistent() || !FocusWindowMB() || !HasFocusZahlung() || !Belegnummer ) {
            return false
        }

        Send, {F11}
        G_LOGGER.Debug("BelegnummerSetzen -> öffne Bearbeiten")
        if (!WaitForZahlungWindow()) {
            return false
        }

        ; Try to focus Belegnummer
        ControlFocus, %C_CTRL_BELEGNUMMER_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
        ControlGetFocus, FocusControl, ahk_class %C_WIN_ZAHLUNG_CLASS%
        if (ErrorLevel or FocusControl != C_CTRL_BELEGNUMMER_CLASSNN) {

            G_LOGGER.Debug(FocusControl . " != " . C_CTRL_BELEGNUMMER_CLASSNN)
            ErrorMessage("Belegnummer ist nicht fokusiert, bitte diesen Fehler reporten mit Details!")
            return false
        }

        if (!this.CheckExeFocus()) {
            return false
        }

        SetKeyDelay, 50
        Send, %Belegnummer%
        SetKeyDelay, %G_DEFAULT_DELAY%
        Send, {Enter}

        this.SendOk()
    }

    ; Send OK via F11 and optionally ignores the warning
    SendOk() {
        if (!this.CheckExeFocus()) {
            return false
        }

        G_LOGGER.Debug("SendOk...")
        Send, {F11} ; OK - Abschluss

        if (!this.CheckExeFocus()) {
            return false
        }

        if (G_SETTINGS.bIgnoreWarning) {
            Sleep, 500
            Send, j
        }

        G_LOGGER.Debug("SendOk... done")
    }

    ; Checks if MB is unfocused and abort automation
    CheckExeFocus() {
        ; do we have focus?
        if (HasExeFocus()) {
            return true
        }

        ; give it a sec to ensure it truly lost focus
        WinWaitActive, % "ahk_exe" C_EXE_MAIN,, 1
        if (!ErrorLevel) {
            return true
        }

        WarnMessage("MB war nicht mehr fokusiert. Automatisierung wurde abgebrochen!")
        this.SetProcessing(false)
        return false
    }
}
