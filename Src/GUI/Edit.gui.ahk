#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

class GuiEdit
{
    __New() {
    }

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

        this.events := new this.EventHook(this)
    }

    __Delete() {
        try Gui, % this.hwnd . ":Destroy"
        this.events.Clear()
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

            this.OnSysCommand := ObjBindMethod(this, "WM_SYSCOMMAND")
            OnMessage(0x112, this.OnSysCommand)
        }

        OnButtonSave() {
            Gui, % this.gui.hwnd ":Submit", NoHide

            index := this.gui.index
            G_BUCHUNGEN.Buchungen[index] = {}

            GuiControlGet, val,, % this.gui.controls.label
            G_BUCHUNGEN.Buchungen[index].label := val

            GuiControlGet, val,, % this.gui.controls.verwendung
            G_BUCHUNGEN.Buchungen[index].verwendung := val

            GuiControlGet, val,, % this.gui.controls.steuer
            G_BUCHUNGEN.Buchungen[index].steuer := val

            GuiControlGet, val,, % this.gui.controls.konto
            G_BUCHUNGEN.Buchungen[index].konto := val

            G_BUCHUNGEN.WriteJSON()
            UpdateGUI()

            this.Clear()
        }

        OnButtonCancel() {
            Gui, % this.gui.hwnd ":Hide"
            this.Clear()
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
