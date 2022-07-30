#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

global G_LOGGER := 0
global G_APP := {}

G_APP.version := "v2022.07.31_1"
G_APP.date := "2022-07-31"

G_APP.github_repo := "https://github.com/DolphBit/mb-automation-ahk"
G_APP.program_folder := A_AppData . "\MB Automation AHK\"
G_APP.debug := false

; Timing
G_APP.timeout := { counter: 20, sec: 30 }

global G_DEFAULT_DELAY := A_KeyDelay
