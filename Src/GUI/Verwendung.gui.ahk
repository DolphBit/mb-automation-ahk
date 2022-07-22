#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; UI for Verwendung
class GuiVerwendungen
{
    __New() {
    }

    ; Show the UI
    Show()
    {
        if (this.events) {
            this.events.Clear()
        }

        Gui, Main:+OwnDialogs +Disabled

        Gui, Verwendung:New, +hwndhGui
        this.hwnd := hGui
        this.controls := {}

        if (!this.originalData) {
            this.originalData := G_BUCHUNGEN.Verwendungen.Clone()
        }

        Gui, Verwendung:+OwnerMain
        Gui, Verwendung:Margin, 10, 10
        Gui, Verwendung:Font, s8 normal, Segoe UI
        Gui, Verwendung:Color, % G_STYLES.main.color

        this.controls.rows := []
        For i, label in G_BUCHUNGEN.Verwendungen {
            if (i == 1) {
                Gui, Verwendung:Add, Text,, % label
                continue ; 1 is the default one, skip it
            }

            row := {}

            Gui, Verwendung:Add, Edit, xm w200 hwndCtrlId, % label
            row.input := CtrlId

            if (i > 2) {
                Gui, Verwendung:Add, Button, x+5 hwndBtn, /\
                ImageButton.Create(Btn, G_STYLES.btn.info*)
                row.btn_move_up := Btn
            } else {
                Gui, Verwendung:Add, Text, w22 x+5,
            }

            if (i != G_BUCHUNGEN.Verwendungen.Length()) {
                Gui, Verwendung:Add, Button, x+5 hwndBtn, \/
                ImageButton.Create(Btn, G_STYLES.btn.info*)
                row.btn_move_down := Btn
            } else {
                Gui, Verwendung:Add, Text, w22 x+5,
            }

            Gui, Verwendung:Add, Button, x+5 hwndBtn, X
            ImageButton.Create(Btn, G_STYLES.btn.danger_round*)
            row.btn_remove := Btn

            this.controls.rows.Push(row)
        }

        if (!this.unmodifiedData) {
            this.unmodifiedData := this.GetInputValues()
        }
        this.modifiedData := this.GetInputValues()

        Gui, Verwendung:Add, Button, xm hwndBtn, Abbrechen
        ImageButton.Create(Btn, G_STYLES.btn.danger*)
        this.controls.btn_cancel := Btn

        Gui, Verwendung:Add, Button, x+100 hwndBtn, Neu
        ImageButton.Create(Btn, G_STYLES.btn.main*)
        this.controls.btn_add := Btn

        Gui, Verwendung:Add, Button, x+40 hwndBtn, Speichern
        ImageButton.Create(Btn, G_STYLES.btn.success*)
        this.controls.btn_save := Btn

        Gui, Verwendung:Show,, Verwendungen

        this.events := new this.EventHook(this)
    }

    __Delete() {
        this.events.Clear()
    }

    ; Get all values (= Verwendung) from input fields
    GetInputValues() {
        values := []
        For i, row in this.controls.rows {
            GuiControlGet, ValueInput, , % row.input
            values.Push(ValueInput)
        }
        return values
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

            fn := ObjBindMethod(this, "OnButtonAdd")
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

        ; Called on Move Up / Down buttons and changes array position
        OnButtonMoveEntry(from, to) {
            this.ui.modifiedData := MoveArrayEntry(this.GetInputValues(), from, to)
            G_BUCHUNGEN.MoveVerwendung(from, to)
            this.ui.Show()
        }

        ; Called on add button click and adds a new entry
        OnButtonAdd() {
            this.ui.modifiedData := this.GetInputValues()
            G_BUCHUNGEN.AddVerwendung()
            this.ui.Show()
        }

        ; Called on remove button click and removes the given {index} entry
        OnButtonRemoveEntry(index) {
            G_BUCHUNGEN.RemoveVerwendung(index)
            this.ui.Show()
        }

        ; Called on save button click and saves the current Verwendungen and closes UI
        OnButtonSave() {
            Gui, % this.ui.hwnd ":Submit", NoHide

            G_BUCHUNGEN.SetVerwendungen(this.ui.GetInputValues())
            G_BUCHUNGEN.WriteJSON()

            UpdateGUI(3)

            this.CloseGui(true)
        }

        ; Called when the UI should be closed
        ; If {save} is false, the user will be warned if he loses saved data (if changed)
        CloseGui(save = false) {
            if(!save) {
                ; compare if input values differ
                if (!ArrayEquals(this.ui.unmodifiedData, this.ui.GetInputValues())) {
                    MsgBox, 4, % " ", Schließen ohne zu speichern?
                    IfMsgBox No, return false
                }

                ; reapply the original data, because we eventually applied some modifications (add/remove)
                G_BUCHUNGEN.Verwendungen := this.ui.originalData
                G_BUCHUNGEN.WriteJSON()
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

            if (wParam = C_SC_CLOSE) {
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
