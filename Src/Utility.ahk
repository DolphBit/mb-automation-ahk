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
    WinActivate, %C_WINDOW_MAIN_TITLE%,,,
    if !(WinActive(C_WINDOW_MAIN_TITLE)) {
        ErrorMessage("MB konnte nicht gefunden werden!")
        return False
    }
    return True
}

; Check if a "Zahlung" is focused
HasFocusZahlung()
{
    ControlGetFocus, OutputVar, %C_WINDOW_MAIN_TITLE%
    if ErrorLevel or (!ArrIncludes(C_CTRL_ZAHLUNG_ROW_CLASSNN, OutputVar)) {
        ErrorMessage("Keine Zahlung ausgewählt!")
        return False
    }

    return True
}

MoveMouseAndClickOnControl(controlText, winClass, showError := false)
{
    ControlGetPos, posX, posY,,, % controlText, ahk_class %winClass%
    if (ErrorLevel || !posX || !posY) {
        if (showError) {
            ErrorMessage(controlText . " konnte nicht gedrückt werden!")
        }
        return False
    }
    posX += 10
    posY += 10

    MouseMove, posX, posY, 0
    Click, posX posY

    return True
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
