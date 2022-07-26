#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; UI for Buchung
class GuiEdit
{
    __New() {
    }

    ; Show the UI for the given {index} Buchung
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

        this.buchung := G_BUCHUNGEN.Buchungen[index]
        this.index := index

        ; --- row 1
        Gui, Edit:Add, GroupBox, xm yp+20 w480 h60 section,

        ; Name
        Gui, Edit:Font, bold
        Gui, Edit:Add, Text, xs+5 ys+10 w160, Name:
        Gui, Edit:Font,
        Gui, Edit:Add, Edit, xs+5 ys+28 wp hwndControl, % this.buchung.label
        this.controls.label := Control

        ; Verwendung
        Gui, Edit:Font, bold
        Gui, Edit:Add, Text, xs+175 ys+10 w160, Verwendung:
        Gui, Edit:Font,
        strVerwendungen := G_BUCHUNGEN.GetVerwendungString()
        VerwendungValue := ArrIndexOf(G_BUCHUNGEN.Verwendungen, this.buchung.verwendung, 1)
        Gui, Edit:Add, DropDownList, xs+175 ys+28 wp hwndControl +Choose%VerwendungValue%, %strVerwendungen%
        this.controls.verwendung := Control

        ; --- row 2
        Gui, Edit:Add, GroupBox, xm ys+35 yp+30 w480 h60 section,

        ; Konto
        Gui, Edit:Font, bold
        Gui, Edit:Add, Text, xs+5 ys+10 w70, Konto:
        Gui, Edit:Font,
        Gui, Edit:Add, Edit, xs+5 ys+28 wp hwndControl, % this.buchung.konto
        this.controls.konto := Control

        ; Steuersatz
        Gui, Edit:Font, bold
        Gui, Edit:Add, Text, xs+85 ys+10 w150, Steuersatz:
        Gui, Edit:Font,
        SteuerValue := this.buchung.steuer
        Gui, Edit:Add, DDL, xs+85 ys+28 wp hwndControl +AltSubmit +Choose%SteuerValue%, %C_STEUERN%
        this.controls.steuer := Control

        ; Buttons
        Gui, Edit:Add, Button, xs+200 section hwndControl, Abbrechen
        this.controls.btn_cancel := Control

        Gui, Edit:Add, Button, xs+100 ys hwndControl, Speichern
        this.controls.btn_save := Control

        Gui, Edit:Show,, % "Bearbeite " . this.buchung.label

        if (!this.unmodifiedData) {
            this.unmodifiedData := this.FetchAllData()
        }

        this.events := new this.EventHook(this)
    }

    __Delete() {
        try Gui, % this.hwnd . ":Destroy"
        this.events.Clear()
    }

    ; Get all control values
    FetchAllData() {
        data := {}

        GuiControlGet, Val,, % this.controls.label
        data.label := Val

        GuiControlGet, Val,, % this.controls.verwendung
        data.verwendung := Val

        GuiControlGet, Val,, % this.controls.konto
        data.konto := Val

        GuiControlGet, Val,, % this.controls.steuer
        data.steuer := Val

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

            this.OnSysCommand := ObjBindMethod(this, "WM_SYSCOMMAND")
            OnMessage(0x112, this.OnSysCommand)
        }

        ; Called on button click and will save the Buchung
        OnButtonSave() {
            Gui, % this.ui.hwnd ":Submit", NoHide

            index := this.ui.index
            G_BUCHUNGEN.Buchungen[index] := this.ui.FetchAllData()

            G_BUCHUNGEN.WriteJSON()
            G_GUI_MAIN.Show()

            this.Clear()
        }

        ; Called when the UI should be closed
        ; If {save} is false, the user will be warned if he loses saved data (if changed)
        CloseGui(save := false) {
            if (!save) {
                ; compare if input values differ
                if (!ArrayEquals(this.ui.unmodifiedData, this.ui.FetchAllData())) {
                    MsgBox, 4, % " ", Schließen ohne zu speichern?
                    IfMsgBox No, return false
                }
            }

            this.ui.unmodifiedData := ""

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
            Gui, %A_Gui%:Destroy

            ; Cleanup
            OnMessage(0x112, this.OnSysCommand, 0)
            this.OnSysCommand := ""
            this.Clear := ""
        }
    }
}
