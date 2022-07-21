#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; APP
global G_VERSION := "v2022.07.18_0"
global G_DATE := "2022-07-18"
global G_GITHUB_REPO := "https://github.com/DolphBit/mb-automation-ahk"
global G_PROGRAMM_FOLDER := A_AppData "\MB Automation AHK\"

; Predefined
global G_LOGGER := 0
global G_DEBUG_MODE := False
global MainGUI = 0
global bToggleEdit = False
global WertVerwendung := ""
global WertBelegnummer := ""

; States
global G_IS_PROCESSING := False
global G_PROCESSING_TASK := "None"

; Timing
global G_DEFAULT_DELAY := A_KeyDelay
global G_WAIT_TIMEOUT_COUNTER := 20
global G_WAIT_TIMEOUT_SEC := 30

; Settings
global G_SETTINGS_FILE := G_PROGRAMM_FOLDER "settings.ini"
global G_ENTRIES_FILE := G_PROGRAMM_FOLDER "entries.json"

; === Defaults
global G_NEW_SPLITENTRY := { label: "Splittbuchung", betrag: 0, konto: 0, steuer: 0, verwendung: C_VERWENDUNGEN_KEINE_ANGABE }

; Quick
global G_QUICK_SPLIT := { label: "Quick Splittbuchung", buchungen: []}
G_QUICK_SPLIT.buchungen.Push(G_NEW_SPLITENTRY)
