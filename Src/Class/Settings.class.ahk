﻿#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

Class Settings {
    settingsFilePath := G_APP.program_folder . "settings.ini"
    bIgnoreWarning := false
    bNoAdsMode := false
    bSKR04 := false
    automationDelay := 1

    triedToCloseAdWindow := false

    ; Init Settings
    __New() {
        this.EnsureProgramFolderExists()

        if (FileExist(this.settingsFilePath)) {
            ; future: upgrade settings file, etc
            this.ReadSettings()
        }

        ; write version info into file
        IniWrite, % G_APP.version, % this.settingsFilePath, app, version
    }

    ; Read settings ini
    ReadSettings() {
        IniRead, bValue, % this.settingsFilePath, options, IgnoreWarning, % false
        this.SetIgnoreWarning(bValue)

        IniRead, bValue, % this.settingsFilePath, options, NoAds, % false
        this.SetNoAdsMode(bValue)

        IniRead, bValue, % this.settingsFilePath, options, SKR04, % false
        this.SetSKR04(bValue)

        IniRead, iValue, % this.settingsFilePath, options, AutomationDelay, 1
        this.automationDelay := iValue
    }

    ; Write settings ini
    WriteSettings() {
        Gui, Settings:Submit, NoHide
        this.EnsureProgramFolderExists()

        ; write settings entries...
        IniWrite, % this.bIgnoreWarning, % this.settingsFilePath, options, IgnoreWarning
        IniWrite, % this.bNoAdsMode, % this.settingsFilePath, options, NoAds
        IniWrite, % this.bSKR04, % this.settingsFilePath, options, SKR04
        IniWrite, % this.automationDelay, % this.settingsFilePath, options, AutomationDelay
    }

    ; Open the settings folder of the script
    OpenSettingsFolder() {
        this.EnsureProgramFolderExists()
        Run, % G_APP.program_folder
    }

    ; Ensures the program folder for this script exists (eventually creats it or throws an error)
    EnsureProgramFolderExists() {
        if !FileExist(G_APP.program_folder) {
            FileCreateDir, % G_APP.program_folder
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
            this.triedToCloseAdWindow := false
            return
        }

        ; failsafe, to only try to close the window once
        ; otherwise we would eventually click a button way to often and do something stupid...
        ; requires to have the ad window to disappear, before it can be closed again
        if (this.triedToCloseAdWindow) {
            return
        }

        ControlGet, CtrlButton, Hwnd,, %C_CTRL_AD_CLOSE_CLASSNN%, ahk_class %C_WIN_AD_CLASS%
        if ErrorLevel {
            G_LOGGER.Debug("Found ad window but can't find the close button!")
            ; Should we eventually fall back ato ALT+F4? I highly dislike this hotkey for obvious reason...
            return
        }

        this.triedToCloseAdWindow := true

        G_LOGGER.Debug("Try to close ad window now...")
        SetControlDelay -1
        try ControlClick,, ahk_id %CtrlButton%
        SetControlDelay %G_DEFAULT_DELAY%
    }
}
