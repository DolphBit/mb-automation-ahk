#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; UI of application
class GuiMain
{
    bToggleEdit := false
    wasProcessing := false
    scrollWindow := ""

    old := { x: 0, y: 0, w: 0, h: 0 }

    __New() {
        this.Show()
    }

    __Delete() {
        this.events.Clear()
    }

    ; Show the UI
    Show(SelectedTab := 1) {

        if (this.events) {
            this.events.Clear()
        }

        Gui, Main:New, +hwndhGui +Resize +E0x08000000
        this.hwnd := hGui
        this.controls := {}
        this.controls.quick := { buchung: {}, splitt: {} }

        Gui, Main:Margin, 10, 10
        Gui, Main:Font, s8 normal, Segoe UI
        Gui, Main:Color, % G_STYLES.main.color
        Gui, Main:+LastFound

        ; -- Processing
        this.controls.processing := []
        txt := "`n`nAutomatisierung ist aktiv... bitte warten und nicht interagieren!`n"
        txt := txt . "(" . G_AUTOMATION.ProcessingTask . ")`n`n"

        Gui, Main:Add, Text, Center w450 hwndCtlText, % txt
        this.controls.processing.Push(CtlText)
        GuiControl, Main:Hide, % CtlText

        Gui, Main:Font, bold
        Gui, Main:Add, Text, cRed Center w450 hwndCtlText, % "Abbruch mit ESC Taste"
        this.controls.processing.Push(CtlText)
        GuiControl, Main:Hide, % CtlText
        Gui, Main:Font,

        this.wasProcessing := G_AUTOMATION.IsProcessing
        ; ~~ Processing

        editText := !this.bToggleEdit ? "Bearbeiten" : "Fertig"
        editStyle := !this.bToggleEdit ? G_STYLES.btn.info : G_STYLES.btn.success

        Gui, Main:Add, Button, xm+335 ym-5 w80 hwndBtn, %editText%
        ImageButton.Create(Btn, editStyle*)
        this.controls.btn_edit := Btn

        Gui, Main:Add, Tab3, xm ym AltSubmit Choose%SelectedTab% hwndTab, Buchung | Splittbuchung | Aktionen | Quick
        this.controls.tab := Tab
        Gui, Main:Tab, 1

        this.controls.buchung := []
        for index, value in G_BUCHUNGEN.Buchungen {
            this.controls.buchung.Push(this.GuiBuchungRow(index, value))
        }

        ; Neue Buchung Btn
        Gui, Main:Add, Button, xm+5 y+10 section w120 hwndBtn, Neue Buchung hinzufügen
        ImageButton.Create(Btn, G_STYLES.btn.info*)
        this.controls.btn_add_buchung := Btn

        ; ----

        Gui, Main:Tab, 2
        this.controls.splitt := []
        for i, value in G_BUCHUNGEN.Splitt {
            this.controls.splitt.Push(this.GuiSplittBuchungRow(i, value))
        }

        ; Neue Splitt Buchung fD
        Gui, Main:Add, Button, xm+5 y+10 section w120 hwndBtn, Neue Splittbuchung hinzufügen
        ImageButton.Create(Btn, G_STYLES.btn.info*)
        this.controls.btn_add_splittbuchung := Btn

        ; ----

        Gui, Main:Tab, 3
        ; Verwendung
        Gui, Main:Add, GroupBox, xm+10 y+5 w390 h70 section,
        Gui, Main:Add, Button, xs+5 ys+11 w160 hwndBtn, Verwendung [STRG+SHIFT+K]
        ImageButton.Create(Btn, G_STYLES.btn.main*)
        this.controls.btn_verwendung := Btn

        strVerwendungen := G_BUCHUNGEN.GetVerwendungString()
        Gui, Main:Add, DDL, xs+175 ys+12 w140 +Choose1 hwndInput, %strVerwendungen%
        this.controls.input_verwendung := Input

        Gui, Main:Add, CheckBox, xs+5 y+10 hwndCbox, Ist Splittbuchung? Bearbeite Eintrag No.:
        this.controls.cbox_verwendung_splitt := Cbox

        Gui, Main:Add, Edit, w40 x+3 y+-16 hwndCtrlId Disabled
        this.controls.input_verwendung_splitt := CtrlId
        Gui, Main:Add, UpDown, Range1-100 , 1

        ; Belegnummer
        Gui, Main:Add, GroupBox, xm+10 y+20 w390 h40 section,
        Gui, Main:Add, Button, xs+5 ys+11 w160 hwndBtn, Belegnummer
        ImageButton.Create(Btn, G_STYLES.btn.main*)
        this.controls.btn_belegnummer := Btn

        Gui, Main:Add, Edit, xs+175 ys+12 w140 r1 hwndInput,
        this.controls.input_belegnummer := Input

        ; Settings Button
        Gui, Main:Add, Button, xm+10 y+20 w80 section hwndBtn, Einstellungen
        ImageButton.Create(Btn, G_STYLES.btn.info*)
        this.controls.btn_settings := Btn

        Gui, Main:Add, Button, x+10 ys w90 hwndBtn, Verwendungen
        ImageButton.Create(Btn, G_STYLES.btn.info*)
        this.controls.btn_edit_verwendungen := Btn

        ; ------ Quick Buchung

        Gui, Main:Tab, 4

        ; --- row 1
        Gui, Main:Add, GroupBox, xm+10 y+5 w440 h120 section

        ; Buchung Btn
        Gui, Main:Add, Button, xs+5 ys+28 w120 hwndBtn, Buchung
        ImageButton.Create(Btn, G_STYLES.btn.main*)
        this.controls.quick.buchung.submit := Btn

        ; Verwendung
        Gui, Main:Font, bold
        Gui, Main:Add, Text, xs+135 ys+10 w140, Verwendung:
        Gui, Main:Font,
        strVerwendungen := G_BUCHUNGEN.GetVerwendungString()
        val := ArrIndexOf(G_BUCHUNGEN.Verwendungen, G_BUCHUNGEN.Quick.Buchung.verwendung, 1)
        Gui, Main:Add, DropDownList, xs+135 ys+28 wp hwndInput +Choose%val%, %strVerwendungen%
        this.controls.quick.buchung.verwendung := Input

        ; Belegnummer
        Gui, Main:Font, bold
        Gui, Main:Add, Text, xs+290 ys+10 w140, Belegnummer:
        Gui, Main:Font,
        Gui, Main:Add, Edit, xs+290 ys+28 wp hwndInput, % G_BUCHUNGEN.Quick.Buchung.beleg
        this.controls.quick.buchung.belegnummer := Input

        ; --- row 2

        ; Konto
        Gui, Main:Font, bold
        Gui, Main:Add, Text, xs+5 ys+65 w70 section, Konto:
        Gui, Main:Font,
        Gui, Main:Add, Edit, xs+5 ys+18 wp hwndInput, % G_BUCHUNGEN.Quick.Buchung.konto
        this.controls.quick.buchung.konto := Input

        ; Steuersatz
        Gui, Main:Font, bold
        Gui, Main:Add, Text, xs+85 ys w140, Steuersatz:
        Gui, Main:Font,
        val := G_BUCHUNGEN.Quick.Buchung.steuer
        Gui, Main:Add, DDL, xs+85 ys+18 wp hwndInput +AltSubmit +Choose%val%, %C_STEUERN%
        this.controls.quick.buchung.steuer := Input

        ; Quick Splittbuchung
        Gui, Main:Add, Text, xm+0 y+5, ; used to position the buchung row properlyV
        this.controls.quick.splitt := this.GuiSplittBuchungRow(-1, G_BUCHUNGEN.Quick.Splitt)

        Gui, Main:Tab

        ; Create ScrollGUI1 with both horizontal and vertical scrollbars and scrolling by mouse wheel
        this.scrollWindow := new ScrollGUI(this.hwnd, 480, 400, "+Resize", 3, 4)

        ; Restore old window size or center it on first start
        if (this.old.x == 0 && this.old.y == 0) {
            this.old.x := "center"
            this.old.y := "center"
            this.scrollWindow.AdjustToChild()
            this.StorePosition()
        } else {
            this.scrollWindow.Width := this.old.w
            this.scrollWindow.Height := this.old.h
        }

        mainTitle := "MB Automation - " . G_APP.version

        if (G_AUTOMATION.IsProcessing) {
            this.scrollWindow.Show(mainTitle, Format("x{1} y{2} NA NoActivate", this.old.x, this.old.y))
            Gui, Main:Show, NA NoActivate, % mainTitle
            FocusWindowMB()
        } else {
            this.scrollWindow.Show(mainTitle, Format("x{1} y{2}", this.old.x, this.old.y))
            Gui, Main:Show,, % mainTitle
        }

        Gui, Verwendung:Add, Button, x+40 hwndBtn, Speichern
        ImageButton.Create(Btn, G_STYLES.btn.success*)
        this.controls.btn_save := Btn

        this.events := new this.EventHook(this)
    }

    ; Shows a processing info text instead of Main GUI
    ShowProcessing(hide := true) {
        GuiControl, % "Main:" . (hide ? "Hide" : "Show"), % this.controls.tab
        GuiControl, % "Main:" . (hide ? "Hide" : "Show"), % this.controls.btn_edit

        for i, ctrl in this.controls.processing {
            GuiControl, % "Main:" . (!hide ? "Hide" : "Show"), % ctrl
        }

        Gui, % this.scrollWindow.HWND ":Hide"

        w := hide ? 450 : this.old.w
        h := hide ? 200 :this.old.h

        ; idk why but we must increment by one and later remove 1 to make it resize properly
        this.scrollWindow.Width := w+1
        this.scrollWindow.Height := h+1
        this.scrollWindow.Show("MB Automation - " . G_APP.version, Format("x{1} y{2}", this.old.x, this.old.y))
        this.scrollWindow.AdjustToChild()
        this.scrollWindow.Size(w, h)
    }

    ; Store window position and size
    StorePosition() {
        WinGetPos, oldX, oldY, oldWidth, oldHeight
        this.old.x := oldX
        this.old.y := oldY
        this.old.w := oldWidth
        this.old.h := oldHeight
    }

    ; Get the selected tab index
    GetSelectedTab() {
        GuiControlGet, TabIndex, , % this.controls.tab
        return TabIndex
    }

    ; Creates a new Splittbuchung row
    GuiBuchungRow(i, buchung) {
        controls := {}
        controls.index := i

        Gui, Add, GroupBox, xm y+5 w400 h40 section,
        Gui, Add, Button, xs+3 ys+10 w150 hwndBtn, % buchung.label
        ImageButton.Create(Btn, G_STYLES.btn.main*)
        controls.submit := Btn

        Gui, Add, Text, xs+160 ys+10 w180, % C_STEUERN_ARR[buchung.steuer]
        Gui, Add, Text, xs+160 ys+22 w180, % buchung.konto . " [" . buchung.verwendung . "]"

        controls.btns := this.GuiBuchungRowButtons(i, "buchung", buchung.label)

        return controls
    }

    ; Creates buttons for Buchung / Splittbuchung
    GuiBuchungRowButtons(i, type, label) {
        btns := {}

        entries := []
        if (type == "buchung") {
            entries := G_BUCHUNGEN.Buchungen
        } else if (type == "splitt") {
            entries := G_BUCHUNGEN.Splitt
        }

        btnSpace := 30
        xsOffset := 310
        ysOffset := 11

        if (!this.bToggleEdit) {
            xsOffset += 60
            Gui, Add, Button, xs+%xsOffset% ys+%ysOffset% w25 section hwndBtn, E
            ImageButton.Create(Btn, G_STYLES.btn.info*)
            btns.edit := Btn

            xsOffset := btnSpace
            ysOffset := 0
        } else {
            ; Show move up if not at top
            if (i > 1) {
                Gui, Add, Button, xs+%xsOffset% ys+%ysOffset% w25 section hwndBtn, /\
                ImageButton.Create(Btn, G_STYLES.btn.secondary*)
                btns.move_up := Btn

                xsOffset := btnSpace
                ysOffset := 0
            } else {
                xsOffset += btnSpace
            }

            ; Show move down if not at bottom
            if (i != entries.Length()) {
                Gui, Add, Button, xs+%xsOffset% ys+%ysOffset% w25 section hwndBtn, \/
                ImageButton.Create(Btn, G_STYLES.btn.secondary*)
                btns.move_down := Btn

                xsOffset := btnSpace
                ysOffset := 0
            } else {
                xsOffset += btnSpace
            }

            Gui, Add, Button, xs+%xsOffset% ys+%ysOffset% w25 section hwndBtn, X
            ImageButton.Create(Btn, G_STYLES.btn.danger_round*)
            btns.remove := Btn

        }

        return btns
    }

    ; Creates a new Splittbuchung row
    GuiSplittBuchungRow(i, splitt) {
        controls := {}
        controls.index := i
        boxHeight := 40 + splitt.buchungen.Length() * 16

        Gui, Add, GroupBox, xm+10 y+5 w400 h%boxHeight% section,
        Gui, Add, Button, xs+3 ys+10 w150 hwndBtn, % splitt.label
        ImageButton.Create(Btn, G_STYLES.btn.main*)
        controls.submit := Btn

        controls.btns := this.GuiBuchungRowButtons(i, "splitt", splitt.label)

        For j, buchung in splitt.buchungen {
            steuer := C_STEUERN_ARR[buchung.steuer]
            if (!steuer) {
                steuer := "N/A %"
            }
            verwendung := buchung.verwendung
            if (verwendung) {
                verwendung := "[" . verwendung . "]"
            }

            yPos := 10 + 16 * j
            isLast := j == splitt.buchungen.Length()

            if (isLast && !buchung.betrag) {
                if (!buchung.konto) {
                    privatKonto := C_KONTO_PRIVATENNAHMEN_SKR3
                    if (G_SETTINGS.bSKR04) {
                        privatKonto := C_KONTO_PRIVATENNAHMEN_SKR4
                    }
                    Gui, Add, Text, xm+15 ys+%yPos%, % Format("> Restlich Privatentnahme (0 %) | Konto {:s} {:s}", privatKonto, verwendung)
                } else {
                    Gui, Add, Text, xm+15 ys+%yPos%, % Format("> Restlich ({:s}) | Konto {:s} {:s}", buchung.konto, steuer, verwendung)
                }
            } else {
                Gui, Add, Text, xm+15 ys+%yPos%, % Format("> {:s} € ({:s}) | Konto: {:s} {:s}", buchung.betrag, steuer, buchung.konto, verwendung)
            }
        }

        return controls
    }

    ; Sub Class to handle events properly
    class EventHook
    {
        __New(ui) {
            this.ui := ui

            fn := ObjBindMethod(this, "OnButtonToggleEditMode")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_edit, % fn

            fn := ObjBindMethod(this, "OnButtonAddBuchung", "buchung")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_add_buchung, % fn

            fn := ObjBindMethod(this, "OnButtonAddBuchung", "splitt")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_add_splittbuchung, % fn

            ; Buchungen
            for i in this.ui.controls.buchung
            {
                fn := ObjBindMethod(this, "OnButtonExecuteBuchung", "buchung", i)
                GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.buchung[i].submit, % fn

                fn := ObjBindMethod(this, "OnButtonEditBuchung", "buchung", i)
                GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.buchung[i].btns.edit, % fn

                if (this.ui.controls.buchung[i].btns.move_up) {
                    fn := ObjBindMethod(this, "OnButtonMoveBuchung", "buchung", i, i - 1)
                    GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.buchung[i].btns.move_up, % fn
                }

                if (this.ui.controls.buchung[i].btns.move_down) {
                    fn := ObjBindMethod(this, "OnButtonMoveBuchung", "buchung", i, i + 1)
                    GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.buchung[i].btns.move_down, % fn
                }

                fn := ObjBindMethod(this, "OnButtonRemoveBuchung", "buchung", i)
                GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.buchung[i].btns.remove, % fn
            }

            for i in this.ui.controls.splitt
            {
                fn := ObjBindMethod(this, "OnButtonExecuteBuchung", "splitt", i)
                GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.splitt[i].submit, % fn

                fn := ObjBindMethod(this, "OnButtonEditBuchung", "splitt", i)
                GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.splitt[i].btns.edit, % fn

                if (this.ui.controls.splitt[i].btns.move_up) {
                    fn := ObjBindMethod(this, "OnButtonMoveBuchung", "splitt", i, i - 1)
                    GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.splitt[i].btns.move_up, % fn
                }

                if (this.ui.controls.splitt[i].btns.move_down) {
                    fn := ObjBindMethod(this, "OnButtonMoveBuchung", "splitt", i, i + 1)
                    GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.splitt[i].btns.move_down, % fn
                }

                fn := ObjBindMethod(this, "OnButtonRemoveBuchung", "splitt", i)
                GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.splitt[i].btns.remove, % fn
            }

            ; Quick
            fn := ObjBindMethod(this, "OnButtonExecuteBuchung", "buchung", -1)
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.quick.buchung.submit, % fn

            fn := ObjBindMethod(this, "OnButtonExecuteBuchung", "splitt", -1)
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.quick.splitt.submit, % fn

            fn := ObjBindMethod(this, "OnButtonEditBuchung", "splitt", -1)
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.quick.splitt.btns.edit, % fn

            ; Aktionen
            fn := ObjBindMethod(this, "OnButtonExecuteVerwendung")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_verwendung, % fn

            fn := ObjBindMethod(this, "OnCheckboxIsSplitt")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.cbox_verwendung_splitt, % fn

            fn := ObjBindMethod(this, "OnButtonExecuteBelegnummer")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_belegnummer, % fn

            fn := ObjBindMethod(this, "OnButtonShowSettings")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_settings, % fn

            fn := ObjBindMethod(this, "OnButtonEditVerwendungen")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_edit_verwendungen, % fn

            ; Events
            this.OnSysCommand := ObjBindMethod(this, "WM_SYSCOMMAND")
            OnMessage(0x112, this.OnSysCommand)

            this.OnMsgMonitor := ObjBindMethod(this, "MsgMonitor")
            OnMessage(0x03, this.OnMsgMonitor)
        }

        ; Called on button click to add a new buchung
        OnButtonAddBuchung(type) {
            if (type == "buchung") {
                G_BUCHUNGEN.AddBuchung()
            } else if (type == "splitt") {
                G_BUCHUNGEN.AddSplittbuchung()
            }
        }

        ; Called on button click to toggle edit mode (move / delete)
        OnButtonToggleEditMode() {
            this.ui.bToggleEdit := !this.ui.bToggleEdit
            this.ui.Show(this.ui.GetSelectedTab())
        }

        ; Called on button click to edit the given Buchung
        OnButtonEditBuchung(type, index) {
            if (type == "buchung") {
                G_GUI_EDIT.Show(index)
            } else if (type == "splitt") {
                G_GUI_EDIT_SPLITT.Show(index)
            }
        }

        ; Called on button click and moves the given buchung
        OnButtonMoveBuchung(type, from, to) {
            G_BUCHUNGEN.MoveEntry(type, from, to)
        }

        ; Called on button click and removes the given buchung
        OnButtonRemoveBuchung(type, index) {
            G_BUCHUNGEN.RemoveEntry(type, index)
        }

        ; Called on button click and executes the given Buchung
        OnButtonExecuteBuchung(type, index) {
            if (type == "buchung") {
                if (index == -1) {
                    ; update the quick entry first
                    GuiControlGet, Val, , % this.ui.controls.quick.buchung.verwendung
                    G_BUCHUNGEN.Quick.Buchung.verwendung := Val

                    GuiControlGet, Val, , % this.ui.controls.quick.buchung.belegnummer
                    G_BUCHUNGEN.Quick.Buchung.belegnummer := Val

                    GuiControlGet, Val, , % this.ui.controls.quick.buchung.konto
                    G_BUCHUNGEN.Quick.Buchung.konto := Val

                    GuiControlGet, Val, , % this.ui.controls.quick.buchung.steuer
                    G_BUCHUNGEN.Quick.Buchung.steuer := Val
                }

                G_AUTOMATION.ExecuteBuchung(index)
            } else if (type == "splitt") {
                G_AUTOMATION.ExecuteSplittbuchung(index)
            }
        }

        ; Called on Checkbox click
        OnCheckboxIsSplitt() {
            GuiControlGet, IsSplitt,, % this.ui.controls.cbox_verwendung_splitt
            Control, % IsSplitt ? "Enable" : "Disable",,, % "ahk_id" this.ui.controls.input_verwendung_splitt
        }

        ; Called on button click and executes Verwendung automation
        OnButtonExecuteVerwendung() {
            GuiControlGet, Verwendung, , % this.ui.controls.input_verwendung
            GuiControlGet, IsSplitt, , % this.ui.controls.cbox_verwendung_splitt

            if (IsSplitt) {
                GuiControlGet, SplittIndex, , % this.ui.controls.input_verwendung_splitt
                G_AUTOMATION.ExecuteVerwendung(Verwendung, SplittIndex)
            } else {
                G_AUTOMATION.ExecuteVerwendung(Verwendung)
            }
        }

        ; Called on button click and executes Belegnummer automation
        OnButtonExecuteBelegnummer() {
            GuiControlGet, Belegnummer, , % this.ui.controls.input_belegnummer
            G_AUTOMATION.ExecuteBelegnummer(Belegnummer)
        }

        ; Called on button click and opens the settings window
        OnButtonShowSettings() {
            this.guiSettings := new GuiSettings()
        }

        ; Called on button click and opens the Verwendungen window
        OnButtonEditVerwendungen() {
            G_GUI_VERWENDUNGEN.Show()
        }

        ; Windows Events
        WM_SYSCOMMAND(wParam, lParam, msg, hwnd) {
            if (hwnd != this.ui.scrollWindow.HWND) {
                return
            }

            if (wParam == C_SC_CLOSE) {
                this.Clear()
                ExitApp
                return
            }
        }

        ; Monitor Events (handles window movement)
        MsgMonitor(wParam, lParam, msg, hwnd) {
            if (hwnd != this.ui.scrollWindow.HWND) {
                return
            }

            if (!G_AUTOMATION.IsProcessing && !this.ui.wasProcessing) {
                this.ui.StorePosition()
            }
        }

        ; Called to clear the event hooks and does cleanup + destroy ui
        Clear() {
            if (this.ui.scrollWindow) {
                this.ui.scrollWindow.Destroy()
            }

            try Gui, %A_Gui%:Destroy

            ; Cleanup
            OnMessage(0x112, this.OnSysCommand, 0)
            this.OnSysCommand := ""
            OnMessage(0x03, this.OnMsgMonitor, 0)

            this.OnMsgMonitor := ""
            this.Clear := ""
        }
    }
}
