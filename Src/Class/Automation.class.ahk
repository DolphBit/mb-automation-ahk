#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; Handles Automation logic
Class Automation {
    ; Automation for Buchung
    ExecuteBuchung(index) {
        if (!FocusWindowMB() || !HasFocusZahlung()) {
            return False
        }

        if (index == -1) {
            buchung := G_QUICK_BUCHUNG
        } else {
            if (G_BUCHUNGEN.Buchungen.Length() < index || index < 1) {
                ErrorMessage("Ungültige Buchung")
                return False
            }
            buchung := G_BUCHUNGEN.Buchungen[index]
        }

        G_Logger.Debug("ExecuteBuchung -> " . buchung.label)
        G_BUCHUNGEN.SetProcessing(True, "Führe Buchung (" . buchung.label . ") durch...")

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

        this.SendOk()
        G_BUCHUNGEN.SetProcessing(False)
    }

    ; Automation for Splittbuchung
    ExecuteSplittbuchung(index) {
        if (!FocusWindowMB() || !HasFocusZahlung()) {
            return False
        }

        if(index == -1) {
            splitt := G_QUICK_SPLIT
        } else {
            if (G_BUCHUNGEN.Splitt.Length() < index || index < 1) {
                ErrorMessage("Ungültige Buchung")
                return False
            }
            splitt := G_BUCHUNGEN.Splitt[index]
        }

        label := splitt.label

        G_BUCHUNGEN.SetProcessing(True, "Führe Splittbuchung (" . label . ") durch...")

        G_LOGGER.Debug("ExecuteSplittbuchung -> " . label . "(index:" . index . ")")
        if (!this.GoToSplittbuchung()) {
            G_BUCHUNGEN.SetProcessing(False)
            return False
        }

        for i, entry in splitt.buchungen {
            if (!this.SplittbuchungSteuerkategorie(entry.konto, cleanupAmount(entry.betrag), entry.steuer, entry.verwendung)) {

                G_BUCHUNGEN.SetProcessing(False)
                return False
            }

            Sleep 1000
        }

        this.SendOk()

        G_BUCHUNGEN.SetProcessing(False)
        return True
    }

    ; Goes to Splittbuchung within Zahlung window
    GoToSplittbuchung() {
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
            if (Mod(waitCount, 3) == 0) {
                ; try to click again every sec
                MoveMouseAndClickOnControl(C_CTRL_BTN_SPLITTBUCHUNG_TEXT, C_WIN_ZAHLUNG_CLASS)
            }

            ControlGet, state, enabled,, %C_CTRL_BTN_SPLITTBUCHUNG_NEU_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
            Sleep 250
            waitCount += 1
        } until (state == True or waitCount >= G_WAIT_TIMEOUT_COUNTER * 4)

        if (!state) {
            ErrorMessage(C_CTRL_BTN_SPLITTBUCHUNG_NEU_TEXT . " wurde nicht gefunden!")
            return False
        }
        return True
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

        ; check if Konto was successfull, by checking if Verwendung does exist:
        ControlGet, CtrlHwnd, Hwnd,, %C_CTRL_VERWENDUNG_CLASSNN%, ahk_class %C_WIN_BUCHUNG_ZORDNUNG_CLASS%
        if (ErrorLevel || !CtrlHwnd) {
            ErrorMessage("Verwendung konnte nicht gefunden werden, vermutlich gab es ein Problem mit dem Konto. Existiert es und ist die Sichtbarkeit richtig eingestellt?")
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

        G_LOGGER.Debug("SplittbuchungSteuerkategorie -> send F11 / OK...")
        Send, {F11} ; OK

        return true
    }

    ; Send Steuersatz (requires focus of input field)
    SendSteuersatz(index) {
        G_LOGGER.Debug("SendSteuersatz -> index:" . index)

        Send, % C_STEUERN_ARR[index]
        Sleep, 500
        Send, {enter}
        G_LOGGER.Debug("SendSteuersatz -> " . C_STEUERN_ARR[index] . " done")
    }

    ; Set a Verwendung for a Zahlung
    ExecuteVerwendung(Verwendung, SplittIndex := -1) {
        if (!FocusWindowMB() || !HasFocusZahlung() || !Verwendung) {
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

        SetKeyDelay, G_DEFAULT_DELAY
        Send, {Enter}
        Sleep, 1000
    }

    ; Set a Belegnummer for a Zahlung
    ExecuteBelegnummer(Belegnummer) {
        G_LOGGER.Debug("BelegnummerSetzen...")
        if (!FocusWindowMB() || !HasFocusZahlung() || !Belegnummer) {
            return False
        }

        Send, {F11}
        G_LOGGER.Debug("BelegnummerSetzen -> öffne Bearbeiten")
        if (!WaitForZahlungWindow()) {
            return False
        }

        ; Try to focus Belegnummer
        ControlFocus, %C_CTRL_BELEGNUMMER_CLASSNN%, ahk_class %C_WIN_ZAHLUNG_CLASS%
        ControlGetFocus, FocusControl, ahk_class %C_WIN_ZAHLUNG_CLASS%
        if (ErrorLevel or FocusControl != C_CTRL_BELEGNUMMER_CLASSNN) {

            G_LOGGER.Debug(FocusControl . " != " . C_CTRL_BELEGNUMMER_CLASSNN)
            ErrorMessage("Belegnummer ist nicht fokusiert, bitte diesen Fehler reporten mit Details!")
            return false
        }

        SetKeyDelay, 50
        Send, %Belegnummer%
        SetKeyDelay, G_DEFAULT_DELAY
        Send, {Enter}

        this.SendOk()
    }

    ; Send OK via F11 and optionally ignores the warning
    SendOk() {
        G_LOGGER.Debug("SendOk...")
        Send, {F11} ; OK - Abschluss

        if (G_SETTINGS.bIgnoreWarning) {
            Sleep, 500
            Send, j
        }

        G_LOGGER.Debug("SendOk... done")
    }
}
