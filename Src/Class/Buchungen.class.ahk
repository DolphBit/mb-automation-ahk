#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

Class Buchungen {
    Static Buchungen := []
    Static Splitt := []
    Static Verwendungen := []

    Static IsProcessing := False
    Static ProcessingTask := "None"

    __New() {
        this.ReadJSON()
    }

    SetProcessing(processing = True, info = "Please wait...") {
        this.IsProcessing := processing
        this.ProcessingTask := info
        UpdateGUI()
    }

    ReadJSON()
    {
        this.Buchungen := []
        this.Splitt := []
        this.Verwendungen := [C_VERWENDUNGEN_KEINE_ANGABE]

        FileRead, JsonContent, %G_ENTRIES_FILE%
        if not ErrorLevel
        {
            entries := JSON.Load(JsonContent)
            if not ErrorLevel
            {
                if (entries.buchungen) {
                    this.Buchungen := entries.buchungen
                }
                if (entries.splitt) {
                    this.Splitt := entries.splitt
                }
                if (entries.verwendungen) {
                    this.SetVerwendungen(entries.verwendungen)
                }
            }
        }
    }

    WriteJSON()
    {
        entries := {}
        entries.buchungen := this.Buchungen
        entries.splitt := this.Splitt
        entries.verwendungen := []
        For i, val in this.Verwendungen {
            if (i == 1 || val == C_VERWENDUNGEN_KEINE_ANGABE) {
                continue
            }
            entries.verwendungen.Push(val)
        }

        JsonContent := JSON.Dump(entries)
        FileAppend, %JsonContent%, %G_ENTRIES_FILE%.new
        if not ErrorLevel
        {
            FileMove, %G_ENTRIES_FILE%.new, %G_ENTRIES_FILE%, true
            if ErrorLevel
            {
                ErrorMessage("Überschreiben / Erstellen der Buchungen nicht möglich: " . G_ENTRIES_FILE)
            }
        } else {
            ErrorMessage("Erstellen der Buchungen nicht möglich: " . G_ENTRIES_FILE)
        }
    }

    AddSplittbuchung()
    {
        this.Splitt.Push({ label: "Neue Splittbuchung", buchungen: [] })
        this.WriteJSON()

        UpdateGUI(2)
    }

    AddSplittbuchungEntry(index, amount)
    {
        global G_NEW_SPLITENTRY

        if (index == -1) {
            Loop %amount%
                G_QUICK_SPLIT.buchungen.Push(G_NEW_SPLITENTRY)
            return
        }

        Loop %amount%
            this.Splitt[index].buchungen.Push(G_NEW_SPLITENTRY)

        this.WriteJSON()
    }

    AddBuchung()
    {
        this.Buchungen.Push({ label: "Neue Buchung", konto: 0, steuer: 0, verwendung: C_VERWENDUNGEN_KEINE_ANGABE })
        this.WriteJSON()

        UpdateGUI()
    }

    GetVerwendungString()
    {
        return ArrJoin("|", this.Verwendungen)
    }

    SetVerwendungen(verwendungen)
    {
        this.Verwendungen := verwendungen
        this.Verwendungen.InsertAt(1, C_VERWENDUNGEN_KEINE_ANGABE)
    }

    AddVerwendung()
    {
        this.Verwendungen.Push("Neue Verwendung")
        this.WriteJSON()
    }

    RemoveVerwendung(index)
    {
        index += 1 ; we must add +1 because the first index is the default one and must stay
        this.Verwendungen.RemoveAt(index)
        this.WriteJSON()
    }

    MoveVerwendung(index, newIndex)
    {
        index += 1 ; we must add +1 because the first index is the default one and must stay
        newIndex += 1

        if (index < 1 || newIndex < 1 || index == newIndex) {
            return
        }
        if (index > this.Verwendungen.Length() || newIndex > this.Verwendungen.Length()) {
            return
        }

        this.Verwendungen := MoveArrayEntry(this.Verwendungen, index, newIndex)
        this.WriteJSON()
    }

    RemoveEntry(type, index, label)
    {
        MsgBox, 4,, Eintrag '%label%' wirklich löschen?
        IfMsgBox Yes
        {
            if (type == "buchung") {
                this.Buchungen.RemoveAt(index)
            } else if (type == "splitt") {
                this.Splitt.RemoveAt(index)
            }
            else return

            this.WriteJSON()
            UpdateGUI()
        }
        else
            return
    }

    RemoveSplittEntry(index, splittIndex)
    {
        MsgBox, 4,, Splitt-Eintrag löschen?
        IfMsgBox Yes
        {
            if (splittIndex == -1) {
                G_QUICK_SPLIT.buchungen.RemoveAt(index)
            } else {
                this.Splitt[splittIndex].buchungen.RemoveAt(index)
            }

            G_GUI_EDIT_SPLITT.Show(splittIndex)
        }
        else
            return
    }

    MoveEntry(type, index, newIndex, splittIndex=1)
    {
        G_Logger.Debug("MoveEntry -> " . type . "from" . index . "to new" . newIndex . "(splittIndex: " . splittIndex . ")")

        ; arrays start at 1 and .Length() is the last index x.x
        if (newIndex < 1 || splittIndex < 1 || index == newIndex) {
            return
        }

        if (type == "buchung") {
            this.Buchungen := MoveArrayEntry(this.Buchungen, index, newIndex)
        } else if (type == "splitt") {
            this.Splitt := MoveArrayEntry(this.Splitt, index, newIndex)
        } else if (type == "splitt-entry") {
            if (splittIndex == -1) {
                G_QUICK_SPLIT.buchungen := MoveArrayEntry(G_QUICK_SPLIT.buchungen, index, newIndex)
            } else {
                if (this.Splitt.Length() < 1 || splittIndex > this.Splitt.Length()) {
                    return
                }
                if (this.Splitt[splittIndex].buchungen.Length() < 1 || newIndex > this.Splitt[splittIndex].buchungen.Length()) {
                    return
                }

                this.Splitt[splittIndex].buchungen := MoveArrayEntry(this.Splitt[splittIndex].buchungen, index, newIndex)
            }
        }

        if (splittIndex != -1) {
            this.WriteJSON()
        }

        if (type == "splitt-entry") {
            G_GUI_EDIT_SPLITT.Show(splittIndex)
        } else {
            UpdateGUI()
        }
    }

}
