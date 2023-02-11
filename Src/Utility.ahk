#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Utility
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; cleanup amount value by removing disallowed common value characters
; (apparently MB is not smart enough)
cleanupAmount(amount)
{
    return RegExReplace(amount, "m)[^0-9,-]", "")
}

; Checks if application is focused
HasExeFocus()
{
    return WinActive("ahk_exe" C_EXE_MAIN)
}

; Focus the application window - will alert if not found
FocusWindowMB()
{
    def := A_TitleMatchMode

    windowTitle := False
    if (WinExist(C_WINDOW_MAIN_TITLE_22)) {
        windowTitle := C_WINDOW_MAIN_TITLE_22
    } else if (WinExist(C_WINDOW_MAIN_TITLE_23)) {
        windowTitle := C_WINDOW_MAIN_TITLE_23
    }

    if (windowTitle) {
        WinActivate, %windowTitle%,,,
    }

    if (!windowTitle || !WinActive(windowTitle)) {
        ErrorMessage("MB konnte nicht gefunden werden!")
        return false
    }

    return true
}

; Check if a "Zahlung" is focused
HasFocusZahlung()
{
    ControlGetPos, posX, posY,,, % C_ZAHLUNG_TITLE, ahk_class %C_WIN_MAIN_CLASS%
    if ErrorLevel {
        ErrorMessage("Keine Zahlung ausgewählt!")
        return false
    }

    G_LOGGER.Info(Format("getpos x{1} y{2}", posX, posY))
    posY += 160

    MouseMove, posX, posY, 0

    Sleep, 100

    MouseGetPos,,,, MostLikelyControlZahlungen

    ControlGetFocus, CurrentControlFocus

    G_LOGGER.Info(Format("x{1} y{2}", posX, posY))
    G_LOGGER.Info(MostLikelyControlZahlungen . "==" . CurrentControlFocus)
    if (ErrorLevel || MostLikelyControlZahlungen != CurrentControlFocus) {
        ErrorMessage("Keine Zahlung ausgewählt!")
        return false
    }

    return true
}

IsZuordnungsAssistent()
{
    if(WinExist("ahk_class" CONST.zuordnung_assist.win_class_zuordnung_assist)) {
        ErrorMessage("Zuordnungs Assistent wird (noch) nicht unterstützt. Bitte erst schließen und Zahlung auswählen.")
        return true
    }

    return false
}

; Wait for Zahlung Details
WaitForZahlungWindow()
{
    return WaitForWindowAndActivate(C_WIN_ZAHLUNG_CLASS, "Zahlungsfenster")
}

; Wait for Steuerkategorie Auswahl
WaitForSteuerkategorieWindow()
{
    return WaitForWindowAndActivate(C_WIN_FIBU_KATEGORIE_AUSWAHL_CLASS, "Steuerkateogrie Fenster (Weitere)")
}

; Wait for a window, activates it then and check if its actually active
WaitForWindowAndActivate(WinClass, FensterName := "Fenster", showError := true)
{
    try {
        WinWait, ahk_class %WinClass%,, % G_APP.timeout.sec
    } catch _e {
        if (showError) {
            ErrorMessage(FensterName . " '" . WinClass . "' wurde nicht gefunden!")
        }
        return false
    }

    Sleep, 200

    try {
        WinActivate, ahk_class %WinClass%
        Sleep, 200
        WinWaitActive, ahk_class %WinClass%,, 3
    } catch _e {
        if (showError) {
            ErrorMessage(FensterName . " " . WinClass . "' ist nicht aktiv!")
        }
        return false
    }

    if (!G_AUTOMATION.CheckExeFocus()) {
        return false
    }

    return true
}

; Moves the mouse to the control and executes a click
; {controlText} text of control
; {winClass} CLASSNN of window to look for
; {showError} if true (default: false) an error will be shown if ctrl can't be found
MoveMouseAndClickOnControl(controlText, winClass, showError := false)
{
    return MoveMouseOffsetAndClickOnControl(controlText, winClass, { x: 10, y: 10 }, showError)
}

; Moves the mouse to the control and executes a click
; {controlText} text of control
; {winClass} CLASSNN of window to look for
; {object.x,object.y} offset (object) of x,y to click at
; {showError} if true (default: false) an error will be shown if ctrl can't be found
MoveMouseOffsetAndClickOnControl(controlText, winClass, offset := "", showError := false)
{
    ControlGetPos, posX, posY,,, % controlText, ahk_class %winClass%
    if (ErrorLevel || !posX || !posY) {
        if (showError) {
            ErrorMessage(controlText . " konnte nicht gedrückt werden!")
        }
        return false
    }

    if (offset.x) {
        posX += offset.x
    }
    if (offset.y) {
        posY += offset.y
    }

    if (!G_AUTOMATION.CheckExeFocus()) {
        return false
    }

    MouseMove, posX, posY, 0
    Click, posX posY

    if (!G_AUTOMATION.CheckExeFocus()) {
        return false
    }

    return true
}

; Moves the mouse to the control and executes a click
; {controlClass} CLASSNN of control
; {winClass} CLASSNN of window to look for
; {object.x,object.y} offset (object) of x,y to click at
; {showError} if true (default: false) an error will be shown if ctrl can't be found
MoveMouseOffsetAndClickOnControlClass(controlClass, winClass, offset := "", showError := false)
{
    ControlGetPos, posX, posY,,, %controlClass%, ahk_class %winClass%
    if (ErrorLevel || !posX || !posY) {
        if (showError) {
            ErrorMessage(controlClass . " position nicht auffindbar!")
        }
        return false
    }

    if (offset.x) {
        posX += offset.x
    }
    if (offset.y) {
        posY += offset.y
    }

    G_LOGGER.info("Move to " . posX . "x" . posY . " and click...")

    if (!G_AUTOMATION.CheckExeFocus()) {
        return false
    }

    MouseMove, posX, posY, 0
    Click, posX posY

    if (!G_AUTOMATION.CheckExeFocus()) {
        return false
    }

    return true
}

; Shows a generic error message box
ErrorMessage(message, title:= "Fehler")
{
    if (G_Logger) {
        G_Logger.Error("{ErrorMessage:" . title . "} " . message)
    }
    MsgBox, 0x2010, %title%, %message%
}

; Shows a generic warn message box
WarnMessage(message, title:= "Warning")
{
    if (G_Logger) {
        G_Logger.Warn("{WarnMessage:" . title . "} " . message)
    }
    MsgBox, 0x2030, %title%, %message%
}

; Return index of array item or notFoundValue (default -1) if not found
ArrIndexOf(haystack, needle, notFoundValue:=-1)
{
    if !(IsObject(haystack) || haystack.Length() == 0) {
        return notFoundValue
    }

    For i, val in haystack {
        if (val == needle)
            return i
    }
    return notFoundValue
}

; Checks if haystack is array in does include needle
ArrIncludes(haystack, needle)
{
    return ArrIndexOf(haystack, needle) > -1
}

; Join an array with seperator
ArrJoin(Sep, Arr)
{
    str := ""
    For i, v in Arr
        str .= Sep . v

    return SubStr(str, 1+StrLen(Sep))
}

; Moves an array element {from} index {to} index.
; The modified array will be returned.
; If out of bounds, the array won't be modified.
MoveArrayEntry(array, from, to)
{
    if (from == to || array.Length() < 1 || from < 1 || to < 1 || from > array.Length() || to > array.Length()) {
        return array
    }

    entry := array[from]
    array.RemoveAt(from)
    array.Insert(to, entry)

    return array
}

; Check if {arrOrObj} is an array
IsArray(arrOrObj) ; https://www.autohotkey.com/boards/viewtopic.php?f=76&t=64332 + added IsObject check
{
    return IsObject(arrOrObj) && !ObjCount(arrOrObj) || ObjMinIndex(arrOrObj) == 1 && ObjMaxIndex(arrOrObj) == ObjCount(arrOrObj) && arrOrObj.Clone().Delete(1, arrOrObj.MaxIndex()) == ObjCount(arrOrObj)
}

; Checks if array {a} equals aray {b}
ArrayEquals(a, b)
{
    if (!IsArray(b) || a.Length() != b.Length()) {
        return false
    }

    For i, aVal in a {
        bVal := b[i]

        ; we need a copy here, because AHK converts eventually aVal to number and I can't figure out why
        aValCopy := aVal
        bValCopy := bVal

        if (IsArray(aVal)) {
            if (!ArrayEquals(aVal, bVal)) {
                return false
            }
        } else if (IsObject(aVal)) {
            if (!ObjectEquals(aVal, bVal)) {
                return false
            }
        } else if (!NumberStringEquals(aValCopy, bValCopy)) {
            return false
        }
    }

    return true
}

; Checks if object {a} equals object {b}
ObjectEquals(a, b)
{
    if (!IsObject(b)) {
        return false
    }

    if (a.Count() != b.Count()) {
        return false
    }

    For k, aVal in a {
        if (!b.HasKey(k)) {
            return false
        }
        bVal := b[k]

        ; we need a copy here, because AHK converts eventually aVal to number and I can't figure out why
        aValCopy := aVal
        bValCopy := bVal

        if (!aVal && (aVal != bVal)) { ; null | undefined | empty | false check
            return false
        } else if (IsObject(aVal)) {

            if (!IsObject(bVal)) {
                return false
            }

            if (IsArray(aVal)) {
                if (!ArrayEquals(aVal, bVal)) {
                    return false
                }
            } else if (!ObjectEquals(aVal, bVal)) {
                return false
            }
        } else if(!NumberStringEquals(aValCopy, bValCopy)) {
            return false
        }
    }

    return true
}

; Check if aVal & bVal are the same and avoids that "1" == 1 => true (type check of string / number)
NumberStringEquals(aVal, bVal)
{
    if (IsNumber(aVal) != IsNumber(bVal) || aVal != bVal) {
        return false
    }

    return true
}

; Checks if val is a number type
IsNumber(val)
{
    return ObjGetCapacity([val], 1) == ""
}

; Creats a deep clone of an object
DeepClone(obj)
{
    clone := {}
    For k, val in obj {

        ; we need a copy here, because AHK converts eventually val to number and I can't figure out why
        valCopy := val

        if (val && IsObject(val)) {
            clone[k] := DeepClone(val)
        } else if (IsNumber(valCopy)) {
            clone[k] := valCopy
        } else {
            clone[k] := val
        }
    }
    return clone
}

; Ensures the falue is true or false
Truthy(val) {
    if (!val) {
        return false
    }

    return true
}
