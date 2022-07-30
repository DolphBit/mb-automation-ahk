#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; UI for Splittbuchung
class GuiEditSplitt
{
    __Delete() {
        try Gui, % this.hwnd . ":Destroy"
        this.events.Clear()
    }

    ; Show the UI for the given {index} Splittbuchung
    Show(index)
    {
        if (this.events) {
            this.events.Clear()
        }

        Gui, Main:+OwnDialogs +Disabled
        Gui, Edit:New, +hwndhGui
        this.hwnd := hGui
        this.controls := {}

        Gui, Edit:+OwnerMain
        Gui, Edit:Margin, 10, 10
        Gui, Edit:Font, s8 normal, Segoe UI
        Gui, Edit:Color, % G_STYLES.main.color

        this.index := index

        if (index == -1)
            this.splitt := G_BUCHUNGEN.Quick.Splitt
        else
            this.splitt := G_BUCHUNGEN.Splitt[index]

        if (!this.originalData) {
            this.originalData := DeepClone(this.splitt)
        }

        ; --- row 1
        Gui, Edit:Add, GroupBox, xm yp+20 w560 h60 section,

        ; Name
        if (index != -1)
        {
            labelValue := this.splitt.label
            if (this.modifiedData) {
                labelValue := this.modifiedData.label
            }

            Gui, Edit:Font, bold
            Gui, Edit:Add, Text, xs+5 ys+10 w160, Name:
            Gui, Edit:Font,
            Gui, Edit:Add, Edit, xs+5 ys+28 wp hwndControl, % labelValue
            this.controls.label := Control
        }

        strVerwendungen := G_BUCHUNGEN.GetVerwendungString()

        this.controls.rows := []
        if (this.splitt.buchungen) {
            For j, buchung in this.splitt.buchungen
            {
                if (this.modifiedData) {
                    buchung := this.modifiedData.buchungen[j]
                }

                ctrls := {}
                ; --- row 2
                Gui, Edit:Add, GroupBox, xm ys+35 yp+30 w560 h60 section,

                ; Konto
                Gui, Edit:Font, bold
                Gui, Edit:Add, Text, xs+5 ys+10 w70, Konto:
                Gui, Edit:Font,
                Gui, Edit:Add, Edit, xs+5 ys+28 wp hwndCtrlId, % buchung.konto
                ctrls.konto := CtrlId

                ; Betrag
                Gui, Edit:Font, bold
                Gui, Edit:Add, Text, xs+85 ys+10 w70, Betrag:
                Gui, Edit:Font,
                Gui, Edit:Add, Edit, xs+85 ys+28 wp hwndCtrlId, % buchung.betrag
                ctrls.betrag := CtrlId

                ; Steuersatz
                val := buchung.steuer
                Gui, Edit:Font, bold
                Gui, Edit:Add, Text, xs+165 ys+10 w150, Steuersatz:
                Gui, Edit:Font,
                Gui, Edit:Add, DDL, xs+165 ys+28 wp hwndCtrlId +AltSubmit +Choose%val%, %C_STEUERN%
                ctrls.steuer := CtrlId

                ; Verwendung
                val := ArrIndexOf(G_BUCHUNGEN.Verwendungen, buchung.verwendung, 1)
                Gui, Edit:Font, bold
                Gui, Edit:Add, Text, xs+325 ys+10 w160, Verwendung:
                Gui, Edit:Font,
                Gui, Edit:Add, DropDownList, xs+325 ys+28 wp hwndCtrlId +Choose%val%, %strVerwendungen%
                ctrls.verwendung := CtrlId

                bShowMoveUp := j > 1
                xsOffset := 490
                if (bShowMoveUp) {
                    Gui, Edit:Add, Button, xs+%xsOffset% ys+8 w25 hwndCtrlId, /\
                    ImageButton.Create(CtrlId, G_STYLES.btn.secondary*)
                    ctrls.btn_move_up := CtrlId
                }

                bShowMoveDown := j != this.splitt.buchungen.Length()
                if (bShowMoveDown) {
                    Gui, Edit:Add, Button, xs+%xsOffset% ys+34 w25 hwndCtrlId, \/
                    ImageButton.Create(CtrlId, G_STYLES.btn.secondary*)
                    ctrls.btn_move_down := CtrlId
                }

                xsOffset += 30
                ysOffset := 28

                Gui, Edit:Add, Button, xs+%xsOffset% ys+%ysOffset% w25 section hwndCtrlId, X
                ImageButton.Create(CtrlId, G_STYLES.btn.danger_round*)
                ctrls.btn_remove := CtrlId

                this.controls.rows.Push(ctrls)
            }
        }

        if (!this.unmodifiedData) {
            this.unmodifiedData := this.FetchAllData()
        }
        this.StoreModifiedData()

        Gui, Edit:Add, Edit, xm section w40
        Gui, Edit:Add, UpDown, Range1-10 hwndCtrlId, 1
        this.controls.input_range := CtrlId

        ; Buttons
        Gui, Edit:Add, Button, xs+45 ys-1 hwndCtrlId, x Splitt Einträge hinzufügen
        this.controls.btn_add := CtrlId

        Gui, Edit:Add, Button, xs+200 section hwndCtrlId, Abbrechen
        this.controls.btn_cancel := CtrlId

        Gui, Edit:Add, Button, xs+100 ys hwndCtrlId, Speichern
        this.controls.btn_save := CtrlId

        ; Show UI
        Gui, Edit:Show,, % "Bearbeite " . this.splitt.label

        this.events := new this.EventHook(this)
    }

    ; Store the modifiedData
    StoreModifiedData() {
        this.modifiedData := this.FetchAllData()
    }

    ; Get all control values
    FetchAllData() {
        data := {}

        index := this.ui.index
        if (index != -1) {
            GuiControlGet, Val,, % this.controls.label
            data.label := Val
        }

        data.buchungen := []
        For i in this.controls.rows
        {
            entry := {}
            GuiControlGet, Val,, % this.controls.rows[i].betrag
            entry.betrag := Val

            GuiControlGet, Val,, % this.controls.rows[i].verwendung
            entry.verwendung := Val

            GuiControlGet, Val,, % this.controls.rows[i].steuer
            entry.steuer := Val

            GuiControlGet, Val,, % this.controls.rows[i].konto
            entry.konto := Val

            data.buchungen.Push(entry)
        }

        return data
    }

    ; Sub Class to handle events properly
    class EventHook
    {
        __New(ui) {
            this.ui := ui

            fn := ObjBindMethod(this, "OnButtonSave")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_save, % fn

            fn := ObjBindMethod(this, "CloseGui")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_cancel, % fn

            fn := ObjBindMethod(this, "OnButtonAddEntries")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_add, % fn

            For i in this.ui.controls.rows
            {
                fn := ObjBindMethod(this, "OnButtonRemoveEntry", i)
                GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.rows[i].btn_remove, % fn

                if (this.ui.controls.rows[i].btn_move_up) {
                    fn := ObjBindMethod(this, "OnButtonMoveEntry", i, i-1)
                    GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.rows[i].btn_move_up, % fn
                }

                if (this.ui.controls.rows[i].btn_move_down) {
                    fn := ObjBindMethod(this, "OnButtonMoveEntry", i, i+1)
                    GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.rows[i].btn_move_down, % fn
                }
            }

            this.OnSysCommand := ObjBindMethod(this, "WM_SYSCOMMAND")
            OnMessage(0x112, this.OnSysCommand)
        }

        ; Called on button click and will save the Splittbuchung
        OnButtonSave() {
            Gui, % this.ui.hwnd ":Submit", NoHide

            index := this.ui.index

            if (index != -1) {
                GuiControlGet, ValueLabel,, % this.ui.controls.label
                G_BUCHUNGEN.Splitt[index].label := ValueLabel
            }

            data := this.ui.FetchAllData()

            if (index != -1) {
                G_BUCHUNGEN.Splitt[index].label := data.label
                G_BUCHUNGEN.Splitt[index].buchungen := data.buchungen
            } else {
                G_BUCHUNGEN.Quick.Splitt.buchungen := data.buchungen
            }

            if (index == -1) {
                G_GUI_MAIN.Show(4)
            } else {
                G_BUCHUNGEN.WriteJSON()
                G_GUI_MAIN.Show(2)
            }

            this.CloseGui(true)
        }

        OnButtonMoveEntry(from, to) {
            this.ui.StoreModifiedData()
            this.ui.modifiedData.buchungen := MoveArrayEntry(this.ui.modifiedData.buchungen, from, to)

            G_BUCHUNGEN.MoveEntry("splitt-entry", from, to, this.ui.index)
        }

        ; Called on button click and adds x new entries, where x is received from the numeric input
        OnButtonAddEntries() {
            this.ui.StoreModifiedData()

            GuiControlGet, AddSplitAmount, , % this.ui.controls.input_range
            G_BUCHUNGEN.AddSplittbuchungEntry(this.ui.index, AddSplitAmount)

            this.ui.Show(this.ui.index)
        }

        OnButtonRemoveEntry(index) {
            splittIndex := this.ui.index
            this.ui.StoreModifiedData()
            this.ui.modifiedData.buchungen.RemoveAt(index)
            G_BUCHUNGEN.RemoveSplittEntry(index, splittIndex)
        }

        ; Called when the UI should be closed
        ; If {save} is false, the user will be warned if he loses saved data (if changed)
        CloseGui(save := false) {
            if (!save) {
                ; compare if input values differ
                if (!ObjectEquals(this.ui.unmodifiedData, this.ui.FetchAllData())) {
                    MsgBox, 4, % " ", Schließen ohne zu speichern?
                    IfMsgBox No, return false

                    ; reapply the original data, because we eventually applied some modifications (add/remove)
                    if (this.ui.index == -1) {
                        G_BUCHUNGEN.Quick.Splitt := this.ui.originalData
                    } else {
                        G_BUCHUNGEN.Splitt[this.ui.index] := this.ui.originalData
                        G_BUCHUNGEN.WriteJSON()
                    }
                }
            }

            this.ui.unmodifiedData := ""
            this.ui.modifiedData := ""
            this.ui.originalData := ""

            this.CloseGui := ""
            this.Clear()
            return true
        }

        ; Windows Events
        WM_SYSCOMMAND(wParam, lParam, msg, hwnd) {
            if (hwnd != this.ui.hwnd) {
                return
            }

            if (wParam == C_SC_CLOSE) {
                if (!this.CloseGui()) {
                    return 1
                }
                this.Clear()
                return
            }
        }

        ; Called to clear the event hooks and does cleanup + destroy ui
        Clear() {
            Gui, Main:-Disabled
            try Gui, %A_Gui%:Destroy

            ; Cleanup
            OnMessage(0x112, this.OnSysCommand, 0)
            this.OnSysCommand := ""
            this.Clear := ""
        }
    }
}
