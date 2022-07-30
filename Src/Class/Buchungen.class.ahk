#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; Handles saved Buchungen & Splittbuchungen
Class Buchungen {
    Static Buchungen := []
    Static Splitt := []
    Static Verwendungen := []

    Static EntriesFilePath := ""

    Static Quick := { Splitt: {}, Buchung: {} }

    __New() {
        this.EntriesFilePath := G_APP.program_folder . "entries.json"
        this.DefaultSplittEntry := { label: "Splittbuchung", betrag: 0, konto: 0, steuer: 0, verwendung: C_VERWENDUNGEN_KEINE_ANGABE }
        this.Quick.Buchung := { label: "Quick Buchung", betrag: 0, konto: 0, steuer: 0, beleg: "", verwendung: C_VERWENDUNGEN_KEINE_ANGABE }
        this.Quick.Splitt := { label: "Quick Splittbuchung", buchungen: []}
        this.Quick.Splitt.buchungen.Push(this.DefaultSplittEntry)

        this.ReadJSON()
    }

    ; Read JSON entries and stores them
    ReadJSON() {
        this.Buchungen := []
        this.Splitt := []
        this.Verwendungen := [C_VERWENDUNGEN_KEINE_ANGABE]

        FileRead, JsonContent, % this.EntriesFilePath
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

    ; Write entries to JSON file
    WriteJSON() {
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
        FileAppend, %JsonContent%, % this.EntriesFilePath . ".new"
        if not ErrorLevel
        {
            FileMove, % this.EntriesFilePath . ".new", % this.EntriesFilePath, true
            if ErrorLevel
            {
                ErrorMessage("Überschreiben / Erstellen der Buchungen nicht möglich: " . this.EntriesFilePath)
            }
        } else {
            ErrorMessage("Erstellen der Buchungen nicht möglich: " . this.EntriesFilePath)
        }
    }

    ; Add a new Splittbuchung
    AddSplittbuchung() {
        this.Splitt.Push({ label: "Neue Splittbuchung", buchungen: [] })
        this.WriteJSON()

        G_GUI_MAIN.Show(2)
    }

    ; Add a new Splittbuchung entry
    AddSplittbuchungEntry(index, amount) {
        if (index == -1) {
            Loop %amount%
                G_BUCHUNGEN.Quick.Splitt.buchungen.Push(this.DefaultSplittEntry)
            return
        }

        Loop %amount%
            this.Splitt[index].buchungen.Push(this.DefaultSplittEntry)

        this.WriteJSON()
    }

    ; Add a new Buchung
    AddBuchung() {
        this.Buchungen.Push({ label: "Neue Buchung", konto: 0, steuer: 0, verwendung: C_VERWENDUNGEN_KEINE_ANGABE })
        this.WriteJSON()

        G_GUI_MAIN.Show()
    }

    ; Returns Verwendungen as string
    GetVerwendungString() {
        return ArrJoin("|", this.Verwendungen)
    }

    ; Set Verwendungen
    SetVerwendungen(verwendungen) {
        this.Verwendungen := verwendungen
        this.Verwendungen.InsertAt(1, C_VERWENDUNGEN_KEINE_ANGABE)
    }

    ; Add new Verwendung
    AddVerwendung() {
        this.Verwendungen.Push("Neue Verwendung")
        this.WriteJSON()
    }

    ; Remove Verwendung at {index}
    RemoveVerwendung(index) {
        index += 1 ; we must add +1 because the first index is the default one and must stay
        this.Verwendungen.RemoveAt(index)
        this.WriteJSON()
    }

    ; Move Verwendung entry in array from {index} to {newIndex}
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

    ; Remove the given {index} Buchung / Splittbuchung entry depending on {type}
    RemoveEntry(type, index) {
        label := ""
        if (type == "buchung") {
            label := this.Buchungen[index].label
        } else if (type == "splitt") {
            label := this.Splitt[index].label
        }

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
            G_GUI_MAIN.Show()
        }
        else
            return
    }

    ; Remove the entry at {index} of the given Splittbuchung {splittIndex}
    RemoveSplittEntry(index, splittIndex) {
        MsgBox, 4,, Splitt-Eintrag löschen?
        IfMsgBox Yes
        {
            if (splittIndex == -1) {
                G_BUCHUNGEN.Quick.Splitt.buchungen.RemoveAt(index)
            } else {
                this.Splitt[splittIndex].buchungen.RemoveAt(index)
            }

            G_GUI_EDIT_SPLITT.Show(splittIndex)
        }
        else
            return
    }

    ; Move Splittbuchung, Splittbuchgung Entry or Buchung depending on {type} from {index} to {newIndex}
    MoveEntry(type, index, newIndex, splittIndex=1) {
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
                G_BUCHUNGEN.Quick.Splitt.buchungen := MoveArrayEntry(G_BUCHUNGEN.Quick.Splitt.buchungen, index, newIndex)
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
            G_GUI_MAIN.Show()
        }
    }

}
