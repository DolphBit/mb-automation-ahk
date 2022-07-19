#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

Global DebugLoggerEdit := 0

Class Logger {

    static MAX_LOG_FILES := 3
    static MAP_TYPES := Object(0, "Error", 1, "Warn", 2, "Info", 3, "Debug")

    ; Init Logger
    ; logPath (string) absolute path to log directory
    ; logName (string) filename of log file w/o/ extension
    ; logLevel (int) 0-4 [0: error, 1: warn, 2: info, 3: debug], default is 3, which includes error, warn, info
    ; debugWindow (boolean) shows a very basic debug info with all messages
    __New(logPath, logName, logLevel := 3, debugWindow := False)
    {
        this.logPath := logPath
        this.logFilepath := logPath logName ".txt"
        this.logLevel := logLevel
        this.debugWindow := debugWindow

        if (logLevel < 0 || logLevel > 4) {
            logLevel := 3
            WarnMessage("Invalid log level, must be between [0-4], using default (3)")
        }

        if (debugWindow) {
            Gui, Logger:Add, Edit, Readonly x10 y10 w400 h300 vDebugLoggerEdit
            Gui, Logger:Show, w420 h320, Debug Logger
        }

        this.EnsureLogFolderExists()
        if (FileExist(this.logFilepath)) {
            FileMove, % this.logFilepath, % logPath logName "-" A_Now ".txt"
        }
        level := this.MAP_TYPES[logLevel]
        this.Info("Logger initialized (loglevel: " . level . ")")

        this.PruneOlderLogFiles()
    }

    Error(text)
    {
        this.Write(0, text)
    }

    Warn(text)
    {
        this.Write(1, text)
    }

    Info(text)
    {
        this.Write(2, text)
    }

    Debug(text)
    {
        this.Write(3, text)
    }

    Write(type, text)
    {
        typeLabel := this.MAP_TYPES[type]
        debugOutput := "[" . typeLabel . "]: " . text
        OutputDebug, % debugOutput

        if (this.logLevel < type) {
            return
        }

        typeShort := SubStr(typeLabel, 0, 1)
        FileAppend, % A_Now "[" . typeShort . "]: " text "`n", % this.logFilepath

        if (this.debugWindow) {
            GuiControlGet, DebugLoggerEdit, Logger:,
            GuiControl, Logger:, DebugLoggerEdit, %debugOutput%`r`n%DebugLoggerEdit%
        }
    }

    ; Open the settings folder of the script
    OpenLogsFolder()
    {
        Run, % this.logPath
    }

    PruneOlderLogFiles()
    {
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
    EnsureLogFolderExists()
    {
        if !FileExist(this.logPath)
            FileCreateDir, % this.logPath
        if ErrorLevel
            ErrorMessage("Log Ordner konnte nicht erstellt werden (das ist nicht gut!)")
    }
}
