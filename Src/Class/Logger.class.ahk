#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; Application Logger
Class Logger {

    ; How many log files should be kept max
    static MAX_LOG_FILES := 3

    ; Maps numeric type to label
    static MAP_TYPES := Object(0, "Error", 1, "Warn", 2, "Info", 3, "Debug")
    static MAP_TYPES_SHORT := Object(0, "E", 1, "W", 2, "I", 3, "D")

    static EditText := ""

    ; Init Logger
    ; logPath (string) absolute path to log directory
    ; logName (string) filename of log file w/o/ extension
    ; logLevel (int) 0-3 [0: error, 1: warn, 2: info, 3: debug], default is 2, which includes error, warn, info
    ; debugWindow (boolean) shows a very basic debug info with all messages
    __New(logPath, logName, logLevel := 2, debugWindow := False) {
        this.logPath := logPath
        this.logFilepath := logPath logName ".txt"
        this.logLevel := logLevel
        this.debugWindow := debugWindow

        if (logLevel < 0 || logLevel > 3) {
            logLevel := 2
            WarnMessage("Invalid log level, must be between [0-4], using default (2)")
        }

        if (this.events) {
            this.events.Clear()
        }

        if (debugWindow) {
            Gui, Logger:New, +hwndhGui
            this.hwnd := hGui
            this.controls := {}

            Gui, Logger:Add, Edit, Readonly x10 y10 w400 h300 hwndInput
            this.controls.input := Input

            Gui, Logger:Add, Button, w80 hwndBtn, Clear
            ImageButton.Create(Btn, G_STYLES.btn.info*)
            this.controls.btn_clear := Btn

            Gui, Logger:Show, w420 h350, Debug Logger
            Gui, Logger:Add, Text, x+8 yp+4, % "(Debug Window will slow down automation on weak machines)"
        }

        this.EnsureLogFolderExists()
        if (FileExist(this.logFilepath)) {
            FileMove, % this.logFilepath, % logPath logName "-" A_Now ".txt"
        }
        level := this.MAP_TYPES[logLevel]

        this.Info("Logger initialized (loglevel: " . level . ")")

        this.PruneOlderLogFiles()

        this.events := new this.EventHook(this)
    }

    ; Log an error message
    Error(text) {
        this.Log(0, text)
    }

    ; Log a warn message
    Warn(text) {
        this.Log(1, text)
    }

    ; Log an info message
    Info(text) {
        this.Log(2, text)
    }

    ; Log a debug message
    Debug(text) {
        this.Log(3, text)
    }

    ; Generic log message, which will write to terminal and file; {type} 0-3 (error: 0, warn: 1, info: 2, debug: 3); {text} message to log
    Log(type, text) {
        if (this.logLevel < type) {
            return
        }

        debugOutput := "[" . this.MAP_TYPES[type] . "]: " . text
        ;@Ahk2Exe-IgnoreBegin
        OutputDebug, % debugOutput
        ;@Ahk2Exe-IgnoreEnd

        FileAppend, % A_Now "[" . this.MAP_TYPES_SHORT[type] . "]: " text "`n", % this.logFilepath

        if (this.debugWindow) {
            GuiControlGet, DebugLoggerEdit,, % this.controls.input
            GuiControl,, % this.controls.input, %debugOutput%`r`n%DebugLoggerEdit%
        }
    }

    ; Open the settings folder of the script
    OpenLogsFolder() {
        Run, % this.logPath
    }

    ; Deletes older log files
    PruneOlderLogFiles() {
        FileList := ""
        Loop, Files, % this.logPath "\*.txt", F
            FileList .= A_LoopFileTimeCreated "`t" A_LoopFileName "`n"
        Sort, FileList ; Sort by date.

        StrReplace(FileList, "`n", "`n", fileCount)

        if (fileCount <= this.MAX_LOG_FILES)
            return

        this.Info("Prune old log files...")

        Loop, Parse, FileList, `n
        {
            if (fileCount <= this.MAX_LOG_FILES)
                break ; alway keep x log files

            if (A_LoopField = "") ; Omit the last linefeed (blank item) at the end of the list.
                continue

            fileCount -= 1
            StringSplit, FileItem, A_LoopField, %A_Tab%
            FileDelete, % this.logPath FileItem2
        }
    }

    ; Ensures the program folder for this script exists (eventually creats it or throws an error)
    EnsureLogFolderExists() {
        if !FileExist(this.logPath) {
            FileCreateDir, % this.logPath
            if ErrorLevel {
                ErrorMessage("Log Ordner konnte nicht erstellt werden (das ist nicht gut!)")
            }
        }
    }

    ; Sub Class to handle events properly
    class EventHook
    {
        __New(ui) {
            this.ui := ui

            fn := ObjBindMethod(this, "OnButtonClear")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btn_clear, % fn

            this.OnSysCommand := ObjBindMethod(this, "WM_SYSCOMMAND")
            OnMessage(0x112, this.OnSysCommand)
        }

        ; Called on button click and clears log
        OnButtonClear() {
            GuiControl,, % this.ui.controls.input, % ""
        }

        ; Windows Events
        WM_SYSCOMMAND(wParam, lParam, msg, hwnd) {
            if (hwnd != this.ui.scrollWindow.HWND) {
                return
            }

            if (wParam == C_SC_CLOSE) {
                this.Clear()
                return
            }
        }

        ; Called to clear the event hooks and does cleanup + destroy ui
        Clear() {
            try Gui, %A_Gui%:Destroy

            ; Cleanup
            OnMessage(0x112, this.OnSysCommand, 0)
            this.OnSysCommand := ""
            this.Clear := ""
        }
    }
}
