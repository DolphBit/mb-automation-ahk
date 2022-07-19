#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Verwendung GUI
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ShowVerwendungGUI()
{
    Global G_STYLES

    Gui, Main:+OwnDialogs +Disabled

    Gui, Verwendung:Destroy
    Gui, Verwendung:New,, mainTitle
    Gui, Verwendung:Font, s8 normal, Segoe UI
    Gui, Verwendung:+OwnerMain
    Gui, Verwendung:Margin, 10, 10

    Gui, Verwendung:Add, Text,, Verwendungen

    global InputVerwendungen := []
    For i, label in G_BUCHUNGEN.Verwendungen {
        if (i == 1) {
            continue
        }

        Gui, Verwendung:Add, Edit, xm w200 hwndCtrlId, %label%
        InputVerwendungen[i] := CtrlId

        if (i > 2) {
            Gui, Verwendung:Add, Button, x+5 hwndBtn, /\
            ImageButton.Create(Btn, G_STYLES.btn.info*)
            fn := Func("GuiMoveVerwendung").Bind(i, i-1)
            GuiControl +g, % Btn, % fn
        } else {
            Gui, Verwendung:Add, Text, w22 x+5,
        }

        if (i != G_BUCHUNGEN.Verwendungen.Length()) {
            Gui, Verwendung:Add, Button, x+5 hwndBtn, \/
            ImageButton.Create(Btn, G_STYLES.btn.info*)
            fn := Func("GuiMoveVerwendung").Bind(i, i+1)
            GuiControl +g, % Btn, % fn
        } else {
            Gui, Verwendung:Add, Text, w22 x+5,
        }

        Gui, Verwendung:Add, Button, x+5 hwndBtn, X
        ImageButton.Create(Btn, G_STYLES.btn.danger_round*)
        fn := Func("GuiRemoveVerwendung").Bind(i)
        GuiControl +g, % Btn, % fn
    }

    Gui, Verwendung:Add, Button, xm hwndBtn gGuiVerwendungenCancel, Abbrechen
    ImageButton.Create(Btn, G_STYLES.btn.danger*)

    Gui, Verwendung:Add, Button, x+100 hwndBtn gGuiVerwendungenAdd, Neu
    ImageButton.Create(Btn, G_STYLES.btn.main*)

    Gui, Verwendung:Add, Button, x+40 hwndBtn gGuiVerwendungenSave, Speichern
    ImageButton.Create(Btn, G_STYLES.btn.success*)

    Gui, Verwendung:Show,,Verwendungen
}

VerwendungGuiClose() {
    Gui, Main:-Disabled
    Gui, Verwendung:Hide
    Gui, Verwendung:Destroy
}

GuiVerwendungenSave()
{
    global InputVerwendungen
    Gui, Verwendung:Submit, NoHide

    For i, value in InputVerwendungen {
        GuiControlGet, ValueInput, , % value
        G_BUCHUNGEN.Verwendungen[i] := ValueInput
    }

    G_BUCHUNGEN.WriteJSON()

    VerwendungGuiClose()
}

GuiVerwendungenCancel()
{
    VerwendungGuiClose()
}

GuiVerwendungenAdd()
{
    G_BUCHUNGEN.AddVerwendung()
    ShowVerwendungGUI()
}

GuiMoveVerwendung(index, newIndex)
{
    G_BUCHUNGEN.MoveVerwendung(index, newIndex)
    ShowVerwendungGUI()
}

GuiRemoveVerwendung(index)
{
    G_BUCHUNGEN.RemoveVerwendung(index)
    ShowVerwendungGUI()
}
