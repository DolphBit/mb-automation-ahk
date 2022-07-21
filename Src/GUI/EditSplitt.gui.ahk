#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

class GuiEditSplitt
{
    __New() {
    }

    Show(index)
    {
        global G_STYLES, G_QUICK_SPLIT

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
            this.splitt := G_QUICK_SPLIT
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

    __Delete() {
        try Gui, % this.hwnd . ":Destroy"
        this.events.Clear()
    }

    StoreModifiedData() {
        this.modifiedData := this.FetchAllData()
    }

    FetchAllData() {
        data := {}

        index := this.gui.index
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
        __New(gui) {
            hwnd := gui.hwnd
            this.gui := gui

            fn := ObjBindMethod(this, "OnButtonSave")
            GuiControl, %hwnd%:+g, % this.gui.controls.btn_save, % fn

            fn := ObjBindMethod(this, "OnButtonCancel")
            GuiControl, %hwnd%:+g, % this.gui.controls.btn_cancel, % fn

            fn := ObjBindMethod(this, "OnButtonAddEntries")
            GuiControl, %hwnd%:+g, % this.gui.controls.btn_add, % fn

            For i in this.gui.controls.rows
            {
                fn := ObjBindMethod(this, "OnButtonRemoveEntry", i)
                GuiControl, %hwnd%:+g, % this.gui.controls.rows[i].btn_remove, % fn

                if (this.gui.controls.rows[i].btn_move_up) {
                        fn := ObjBindMethod(this, "OnButtonMoveEntry", i, i-1)
                    GuiControl, %hwnd%:+g, % this.gui.controls.rows[i].btn_move_up, % fn
                }

                if (this.gui.controls.rows[i].btn_move_down) {
                        fn := ObjBindMethod(this, "OnButtonMoveEntry", i, i+1)
                    GuiControl, %hwnd%:+g, % this.gui.controls.rows[i].btn_move_down, % fn
                }
            }

            this.OnSysCommand := ObjBindMethod(this, "WM_SYSCOMMAND")
            OnMessage(0x112, this.OnSysCommand)
        }

        OnButtonSave() {
            Global G_QUICK_SPLIT
            Gui, % this.gui.hwnd ":Submit", NoHide

            index := this.gui.index

            if (index != -1) {
                GuiControlGet, ValueLabel,, % this.gui.controls.label
                G_BUCHUNGEN.Splitt[index].label := ValueLabel
            }

            data := this.gui.FetchAllData()

            if (index != -1) {
                G_BUCHUNGEN.Splitt[index].label := data.label
                G_BUCHUNGEN.Splitt[index].buchungen := data.buchungen
            } else {
                G_QUICK_SPLIT.buchungen := data.buchungen
            }

            if (index == -1) {
                UpdateGUI(4)
            } else {
                G_BUCHUNGEN.WriteJSON()
                UpdateGUI(2)
            }

            this.CloseGui()
        }

        OnButtonCancel() {
            Global G_QUICK_SPLIT

            ; compare if input values differ
            if (!ObjectEquals(this.gui.unmodifiedData, this.gui.FetchAllData())) {
                    MsgBox, 4, % " ", Schließen ohne zu speichern?
                IfMsgBox No, return 1

                ; reapply the original data, because we eventually applied some modifications (add/remove)
                if (this.gui.index == -1) {
                        G_QUICK_SPLIT := this.gui.originalData
                } else {
                    G_BUCHUNGEN.Splitt[this.gui.index] := this.gui.originalData
                    G_BUCHUNGEN.WriteJSON()
                }
            }
            this.CloseGui()
        }

        CloseGui() {
            this.gui.unmodifiedData := ""
            this.gui.modifiedData := ""
            this.gui.originalData := ""
            try Gui, % this.gui.hwnd ":Hide"
            this.Clear()
        }

        OnButtonMoveEntry(from, to) {
            index := this.gui.index

            this.gui.StoreModifiedData()
            this.gui.modifiedData.buchungen := MoveArrayEntry(this.gui.modifiedData.buchungen, from, to)

            G_BUCHUNGEN.MoveEntry("splitt-entry", from, to, index)
        }

        OnButtonAddEntries() {
            Global CtrlIdSplitAmount
            index := this.gui.index

            this.gui.StoreModifiedData()

            GuiControlGet, AddSplitAmount, , % this.gui.controls.input_range
            G_BUCHUNGEN.AddSplittbuchungEntry(index, AddSplitAmount)

            this.gui.Show(index)
        }

        OnButtonRemoveEntry(index) {
            splittIndex := this.gui.index
            this.gui.StoreModifiedData()
            this.gui.modifiedData.buchungen.RemoveAt(index)
            G_BUCHUNGEN.RemoveSplittEntry(index, splittIndex)
        }

        WM_SYSCOMMAND(wParam, lParam, msg, hwnd) {
            if (hwnd != this.gui.hwnd) {
                    return
            }

            if (wParam = C_SC_CLOSE) {
                this.Clear()
                return
            }
            return
        }

        Clear() {
            Gui, Main:-Disabled
            Gui, %A_Gui%:Destroy

            ; Cleanup
            OnMessage(0x112, this.OnSysCommand, 0)
            this.OnSysCommand := ""
            this.Clear := ""
        }
    }
}
