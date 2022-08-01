#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.
#SingleInstance, force
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

; Add third party dependencies
#Include <JSON>
#Include <Class_ImageButton>
#Include <UseGDIP>
#Include <Class_ScrollGUI>

#Include Src/Globals.ahk
#Include Src/Constants.ahk
#Include Src/Styles.ahk
#Include Src/Utility.ahk

;@Ahk2Exe-IgnoreBegin
EnvGet, envDebug, ahk-mb-automation-debug
if (envDebug) {
    G_APP.debug := true
}
;@Ahk2Exe-IgnoreEnd

; Handle arguments
logLevel := 2
for argIndex in A_Args
{
    if (A_Args[argIndex] == "--debug") {
        logLevel := 3
        G_APP.debug := true
    }

    if (A_Args[argIndex] == "--loglevel" && (argIndex + 1 <= A_Args.MaxIndex())) {
        logLevel := A_Args[argIndex + 1]
    }
}

; Init logger
#Include Src/Class/Logger.class.ahk
G_LOGGER := new Logger(G_APP.program_folder . "logs\", "log", logLevel, G_APP.debug)

; Logic Class & GUI
#Include Src/Class/Automation.class.ahk
#Include Src/Class/Buchungen.class.ahk
#Include Src/Class/Settings.class.ahk
#Include Src/GUI/Main.gui.ahk
#Include Src/GUI/Edit.gui.ahk
#Include Src/GUI/EditSplitt.gui.ahk
#Include Src/GUI/Settings.gui.ahk
#Include Src/GUI/Verwendung.gui.ahk

; Main
global G_SETTINGS = new Settings()
global G_BUCHUNGEN = new Buchungen()
global G_AUTOMATION = new Automation()
global G_GUI_EDIT = new GuiEdit()
global G_GUI_EDIT_SPLITT = new GuiEditSplitt()
global G_GUI_VERWENDUNGEN = new GuiVerwendungen()
global G_GUI_MAIN = new GuiMain()

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; HOTKEYS
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; `CTRL+SHIFT+V`
; Inserts value but cleaned up to support paste from calc / excel
^+V::
    if (!HasExeFocus()) {
        return
    }
    clipboard2 := cleanupAmount(clipboard)
    SendRaw % clipboard2
return

; `CTRL+SHIFT+K`
; Hotkey to set selected Buchung with the given Verwendung
^+K::
    if (!HasExeFocus()) {
        return
    }
    G_GUI_MAIN.events.OnButtonExecuteVerwendung()
return

; Reload app if `ESC` is pressed, to stop any automation, etc
Esc::
    if (!G_AUTOMATION.IsProcessing) {
        return ; only reload if we are actually processing
    }
    Reload
return

; Exit App with `SHIFT+ESC`
+Esc::
ExitApp
