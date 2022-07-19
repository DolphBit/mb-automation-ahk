#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

global WasProcessing := False
global oldX := 0
global oldY := 0
global oldWidth := 0
global oldHeight := 0

UpdateGUI(SelectedTab := 1)
{
    Global G_STYLES, MainGUI, bToggleEdit

    mainTitle := "MB Automation - "
    mainTitle = %mainTitle%%G_VERSION%

    Gui,Main:+LastFound
    if (!WasProcessing)
        WinGetPos, oldX, oldY, oldWidth, oldHeight

    if (MainGUI) MainGUI.Destroy()

    Gui, Main:Destroy
    Gui, Main:New,, mainTitle
    Gui, Main:Font, s8 normal, Segoe UI
    Gui, Main:Color, % G_STYLES.main.color
    Gui, Main:+hwndHGUI +Resize
    Gui, Main:Margin, 10, 10

    if (G_BUCHUNGEN.IsProcessing) {
        WasProcessing := True
        Gui, Main:Add, Text,, Automatisierung ist aktiv... bitte warten und nicht interagieren!
        Gui, Main:Add, Text,,
        Gui, Main:Add, Text,, % "(" . G_BUCHUNGEN.ProcessingTask . ")"
        Gui, Main:Add, Text,,
        Gui, Main:Add, Text,, Abbruch mit ESC Taste
    } else {
        WasProcessing := False

        ; ----

        editText := "Bearbeiten"
        editStyle := G_STYLES.btn.info
        if (bToggleEdit) {
            editText := "Fertig"
            editStyle := G_STYLES.btn.success
        }

        Gui, Main:Add, Button, xm+335 ym-5 w80 hwndBtn, %editText%
        ImageButton.Create(Btn, editStyle*)
        fn := Func("GuiToggleEditMode")
        GuiControl +g, % Btn, % fn

        Gui, Main:Add, Tab3, xm ym Choose%SelectedTab%, Buchung | Splittbuchung | Aktionen | Quick
        Gui, Main:Tab, 1

        For index, value in G_BUCHUNGEN.Buchungen
            GuiBuchungRow(index, value)

        ; Neue Buchung Btn
        Gui, Main:Add, Button, xm+5 y+10 section gGuiAddBuchung w120 hwndBtn, Neue Buchung hinzufügen
        ImageButton.Create(Btn, G_STYLES.btn.info*)

        ; ----

        Gui, Main:Tab, 2
        For i, value in G_BUCHUNGEN.Splitt
            GuiSplittBuchungRow(i, value)

        ; Neue Splitt Buchung Btn
        Gui, Main:Add, Button, xm+5 y+10 section gGuiAddSplittbuchung w120 hwndBtn, Neue Splittbuchung hinzufügen
        ImageButton.Create(Btn, G_STYLES.btn.info*)

        ; ----

        Gui, Main:Tab, 3
        ; Verwendung
        Gui, Main:Add, GroupBox, xm y+5 w390 h40 section,
        Gui, Main:Add, Button, xs+5 ys+11 w160 hwndBtn, Verwendung [STRG+SHIFT+K]
        ImageButton.Create(Btn, G_STYLES.btn.main*)
        strVerwendungen := G_BUCHUNGEN.GetVerwendungString()
        fn := Func("GuiButtonVerwendung")
        GuiControl +g, % Btn, % fn
        Gui, Main:Add, DDL, xs+175 ys+12 w140 +Choose1 vWertVerwendung, %strVerwendungen%

        ; Belegnummer
        Gui, Main:Add, GroupBox, xm yp+20 w390 h40 section,
        Gui, Main:Add, Button, xs+5 ys+11 w160 hwndBtn, Belegnummer
        ImageButton.Create(Btn, G_STYLES.btn.main*)
        fn := Func("GuiButtonBelegnummer")
        GuiControl +g, % Btn, % fn
        Gui, Main:Add, Edit, xs+175 ys+12 w140 r1 vWertBelegnummer,

        ; Settings Button
        Gui, Main:Add, Button, xm+10 y+20 w80 section hwndBtn, Einstellungen
        ImageButton.Create(Btn, G_STYLES.btn.info*)
        fn := Func("GuiButtonShowSettings")
        GuiControl, Main:+g, % Btn, % fn

        Gui, Settings:Add, Button, hwndBtn, Programm Ordner öffnen

        Gui, Main:Add, Button, x+10 ys w90 hwndBtn, Verwendungen
        ImageButton.Create(Btn, G_STYLES.btn.info*)
        fn := Func("GuiVerwendungen")
        GuiControl +g, % Btn, % fn

        ; ------

        Gui, Main:Tab, 4

        ; Quick Buchung
        Global InputBetrag = ""
        Global InputVerwendung := 1
        Global InputSteuer = ""
        Global InputKonto = ""
        Global InputBelegnummer = ""

        ; --- row 1
        Gui, Main:Add, GroupBox, xm+10 y+5 w440 h120 section

        ; Buchung Btn
        Gui, Main:Add, Button, xs+5 ys+28 w120 hwndBtn, Buchung
        ImageButton.Create(Btn, G_STYLES.btn.main*)
        fn := Func("GuiQuickBuchung")
        GuiControl +g, % Btn, % fn

        ; Verwendung
        Gui, Main:Font, bold
        Gui, Main:Add, Text, xs+135 ys+10 w140, Verwendung:
        Gui, Main:Font,
        strVerwendungen := G_BUCHUNGEN.GetVerwendungString()
        Gui, Main:Add, DropDownList, xs+135 ys+28 wp vInputVerwendung +Choose%InputVerwendung%, %strVerwendungen%

        ; Belegnummer
        Gui, Main:Font, bold
        Gui, Main:Add, Text, xs+290 ys+10 w140, Belegnummer:
        Gui, Main:Font,
        Gui, Main:Add, Edit, xs+290 ys+28 wp vInputBelegnummer

        ; --- row 2

        ; Konto
        Gui, Main:Font, bold
        Gui, Main:Add, Text, xs+5 ys+65 w70 section, Konto:
        Gui, Main:Font,
        Gui, Main:Add, Edit, xs+5 ys+18 wp vInputKonto, %InputKonto%

        ; Steuersatz
        Gui, Main:Font, bold
        Gui, Main:Add, Text, xs+85 ys w140, Steuersatz:
        Gui, Main:Font,
        Gui, Main:Add, DDL, xs+85 ys+18 wp vInputSteuer +AltSubmit +Choose%InputSteuer%, %C_STEUERN%

        ; Quick Splittbuchung

        Gui, Main:Add, Text, xm+0 y+5, ; used to position the buchung row properly
        GuiSplittBuchungRow(-1, G_QUICK_SPLIT)

        Gui, Main:Tab
    }

    ; Create ScrollGUI1 with both horizontal and vertical scrollbars and scrolling by mouse wheel
    MainGUI := New ScrollGUI(HGUI, 480, 400, "+Resize", 3, 4)

    ; Restore old window size or center it on first start
    if (oldX == 0 && oldY == 0) {
        oldX := "center"
        oldY := "center"
    } else {
        oldX := oldX - 10
        oldY := oldY - 10
        MainGUI.Width := oldWidth
        MainGUI.Height := oldHeight
    }

    MainGUI.Show(mainTitle, Format("x{1} y{2}", oldX, oldY))

    if (G_BUCHUNGEN.IsProcessing) {
        Gui, Show, NA
        FocusWindowMB()
    } else {
        Gui, Show
    }
}

; Button Functions

GuiButtonShowSettings()
{
    Global G_SETTINGS_GUI
    G_SETTINGS_GUI := new GuiSettings()
}

GuiAddBuchung()
{
    G_BUCHUNGEN.AddBuchung()
}

GuiAddSplittbuchung()
{
    G_BUCHUNGEN.AddSplittbuchung()
}

GuiToggleEditMode()
{
    global bToggleEdit
    bToggleEdit := !bToggleEdit
    UpdateGUI()
}

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; GUI logic For main
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; Erstellt einen GUI Eintrag für eine Splittbuchng
GuiBuchungRow(i, buchung)
{
    global G_STYLES

    label := buchung.label
    konto := buchung.konto
    steuer := C_STEUERN_ARR[buchung.steuer]
    verwendung := buchung.verwendung

    Gui, Add, GroupBox, xm y+5 w400 h40 section,
    Gui, Add, Button, xs+3 ys+10 w150 hwndSubmitEntryBtn, %label%
    ImageButton.Create(SubmitEntryBtn, G_STYLES.btn.main*)
    fn := Func("GuiButtonSubmitBuchung").Bind(i)
    GuiControl +g, % SubmitEntryBtn, % fn

    Gui, Add, Text, xs+160 ys+10 w180, %steuer%
    Gui, Add, Text, xs+160 ys+22 w180, %konto% [%verwendung%]

    GuiBuchungRowButtons(i, "buchung", label)
}

GuiBuchungRowButtons(i, type, label)
{
    global G_STYLES, bToggleEdit

    entries := []
    if (type == "buchung") {
        entries := G_BUCHUNGEN.Buchungen
    } else if (type == "splitt") {
        entries := G_BUCHUNGEN.Splitt
    }

    btnSpace := 30
    xsOffset := 310
    ysOffset := 11
    bShowMoveUp := bToggleEdit && i > 1
    bShowMoveDown := bToggleEdit && i != entries.Length()

    if (!bToggleEdit) {
        xsOffset += 60
        Gui, Add, Button, xs+%xsOffset% ys+%ysOffset% w25 section hwndEditEntryBtn, E
        ImageButton.Create(EditEntryBtn, G_STYLES.btn.info*)
        fn := Func("GuiButtonEdit").Bind(type, i)
        GuiControl +g, % EditEntryBtn, % fn
        xsOffset := btnSpace
        ysOffset := 0
    }

    if (bShowMoveUp) {
        Gui, Add, Button, xs+%xsOffset% ys+%ysOffset% w25 section hwndMoveEntryBtn, /\
        ImageButton.Create(MoveEntryBtn, G_STYLES.btn.secondary*)
        fn := Func("GuiMoveEntry").Bind(type, i, i-1)
        GuiControl +g, % MoveEntryBtn, % fn
        xsOffset := btnSpace
        ysOffset := 0
    } else {
        xsOffset += btnSpace
    }

    if (bShowMoveDown) {
        Gui, Add, Button, xs+%xsOffset% ys+%ysOffset% w25 section hwndMoveEntryBtn, \/
        ImageButton.Create(MoveEntryBtn, G_STYLES.btn.secondary*)
        fn := Func("GuiMoveEntry").Bind(type, i, i+1)
        GuiControl +g, % MoveEntryBtn, % fn
        xsOffset := btnSpace
        ysOffset := 0
    } else {
        xsOffset += btnSpace
    }

    if (bToggleEdit) {
        Gui, Add, Button, xs+%xsOffset% ys+%ysOffset% w25 section hwndRemoveEntryBtn, X
        ImageButton.Create(RemoveEntryBtn, G_STYLES.btn.danger_round*)
        fn := Func("GuiRemoveEntry").Bind(type, i, label)
        GuiControl +g, % RemoveEntryBtn, % fn
    }
}

GuiSplittBuchungRow(i, splitt)
{
    Global G_STYLES

    label := splitt.label

    boxHeight := 40 + splitt.buchungen.Length() * 16

    Gui, Add, GroupBox, xm+10 y+5 w400 h%boxHeight% section,
    Gui, Add, Button, xs+3 ys+10 w150 hwndSubmitEntryBtn, %label%
    fn := Func("ExecuteSplittbuchung").Bind(i)
    GuiControl +g, % SubmitEntryBtn, % fn

    ImageButton.Create(SubmitEntryBtn, G_STYLES.btn.main*)

    GuiBuchungRowButtons(i, "splitt", label)

    For j, buchung in splitt.buchungen {
        betrag := buchung.betrag
        konto := buchung.konto
        steuer := C_STEUERN_ARR[buchung.steuer]
        verwendung := buchung.verwendung
        if (verwendung) {
            verwendung = [%verwendung%]
        }

        yPos := 10 + 16 * j
        isLast = j == splitt.buchungen.Length()

        if (isLast && !betrag) {
            if (!konto)
                Gui, Add, Text, xm+15 ys+%yPos%, > Restlich Privatentnahme %verwendung%
            else
                Gui, Add, Text, xm+15 ys+%yPos%, > Restlich auf Konto %konto% %verwendung%
        } else {
            Gui, Add, Text, xm+15 ys+%yPos%, > %betrag% € (%steuer%) | Konto: %konto% %verwendung%
        }
    }
}

; -------------
; Function handling
; -------------

GuiButtonEdit(type, i)
{
    if (type == "buchung") {
        G_GUI_EDIT.Show(i)
    } else if (type == "splitt") {
        G_GUI_EDIT_SPLITT.Show(i)
    }
}

GuiMoveEntry(type, index, newIndex, splittIndex=1)
{
    G_BUCHUNGEN.MoveEntry(type, index, newIndex, splittIndex)
}

GuiRemoveEntry(type, i, label)
{
    G_BUCHUNGEN.RemoveEntry(type, i, label)
}

GuiVerwendungen()
{
    ShowVerwendungGUI()
}

GuiButtonVerwendung() {
    WertVerwendung := ""
    GuiControlGet, WertVerwendung
    VerwendungSetzen(WertVerwendung)
}

GuiButtonBelegnummer() {
    WertBelegnummer := ""
    GuiControlGet, WertBelegnummer
    BelegnummerSetzen(WertBelegnummer)
}

GuiButtonSubmitBuchung(index)
{
    buchung := G_BUCHUNGEN.Buchungen[index]
    G_Logger.Debug("SubmitBuchungEntry -> " . buchung.label)
    BuchungDurchführen(buchung.label, buchung.konto, buchung.steuer, buchung.verwendung)
}
