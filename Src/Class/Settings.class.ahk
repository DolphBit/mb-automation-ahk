#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

Class Settings {
    ; Init Settings
    __New() {
        this.EnsureProgramFolderExists()

        this.bIgnoreWarning := false
        this.bNoAdsMode := false
        this.bSKR04 := false

        if (FileExist(G_SETTINGS_FILE)) {
            ; future: upgrade settings file, etc
            this.ReadSettings()
        }

        ; write version info into file
        IniWrite, %G_VERSION%, %G_SETTINGS_FILE%, app, version
    }

    ; Read settings ini
    ReadSettings() {
        IniRead, bValue, %G_SETTINGS_FILE%, options, IgnoreWarning, % false
        this.SetIgnoreWarning(bValue)

        IniRead, bValue, %G_SETTINGS_FILE%, options, NoAds, % false
        this.SetNoAdsMode(bValue)

        IniRead, bValue, %G_SETTINGS_FILE%, options, SKR04, % false
        this.SetSKR04(bValue)
    }

    ; Write settings ini
    WriteSettings() {
        Gui, Settings:Submit, NoHide
        this.EnsureProgramFolderExists()

        ; write settings entries...
        IniWrite, % this.bIgnoreWarning, %G_SETTINGS_FILE%, options, IgnoreWarning
        IniWrite, % this.bNoAdsMode, %G_SETTINGS_FILE%, options, NoAds
    }

    ; Open the settings folder of the script
    OpenSettingsFolder() {
        this.EnsureProgramFolderExists()
        Run, % G_PROGRAMM_FOLDER
    }

    ; Ensures the program folder for this script exists (eventually creats it or throws an error)
    EnsureProgramFolderExists() {
        if !FileExist(G_PROGRAMM_FOLDER) {
            FileCreateDir, %G_PROGRAMM_FOLDER%
            if ErrorLevel
                MsgBox, Settings Ordner konnte nicht erstellt werden (das ist nicht gut!)
        }
    }

    ; Toggle ignore warning, which will close automatically any warning after OK (from Zahlung)
    SetIgnoreWarning(on) {
        this.bIgnoreWarning := Truthy(on)
    }

    ; Toggle ad check mode, which will automatically close the ad window
    SetNoAdsMode(on) {
        this.bNoAdsMode := Truthy(on)
        if (on) {
            this.StartNoAdsMode()
        } else {
            this.StopNoAdsMode()
        }
    }

    ; Toggle between SKR03 (default) and SKR04
    SetSKR04(on) {
        this.bSKR04 := Truthy(on)
    }

    ; Start Ad window check
    StartNoAdsMode() {
        this.StopNoAdsMode()
        fn := this["NoAdsModePoll"].bind(this)
        SetTimer, % fn, 1000
    }

    ; Stop Ad window check
    StopNoAdsMode() {
        fn := this["NoAdsModePoll"].bind(this)
        SetTimer, % fn, Off
    }

    ; Checks for annoying ad window and automatically closes it
    NoAdsModePoll() {
        if(!HasExeFocus()) {
            return
        }

        WinWaitActive, ahk_class %C_WIN_AD_CLASS%,, 5
        if ErrorLevel {
            return
        }

        ControlGet, CtrlButton, Hwnd,, %C_CTRL_AD_CLOSE_CLASSNN%, ahk_class %C_WIN_AD_CLASS%
        if ErrorLevel {
            G_LOGGER.Debug("Found ad window but can't find the close button!")
            ; Should we eventually fall back ato ALT+F4? I highly dislike this hotkey for obvious reason...
            return
        }

        G_LOGGER.Debug("Try to close ad window now...")
        SetControlDelay -1
        try ControlClick,, ahk_id %CtrlButton%
        SetControlDelay %G_DEFAULT_DELAY%
    }
}
