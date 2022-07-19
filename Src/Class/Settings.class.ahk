#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

Class Settings {
    ; Init Settings
    __New()
    {
        this.EnsureProgramFolderExists()

        this.bIgnoreWarning := False
        this.bNoAdsMode := False

        if (FileExist(G_SETTINGS_FILE)) {
            ; future: upgrade settings file, etc
            this.ReadSettings()
        }

        ; write version info into file
        IniWrite, %G_VERSION%, %G_SETTINGS_FILE%, app, version
    }

    ; Read settings ini
    ReadSettings()
    {
        IniRead, bValue, %G_SETTINGS_FILE%, options, IgnoreWarning, % False
        this.SetIgnoreWarning(bValue)

        IniRead, bValue, %G_SETTINGS_FILE%, options, NoAds, % False
        this.SetNoAdsMode(bValue)
    }

    ; Write settings ini
    WriteSettings()
    {
        Gui, Settings:Submit, NoHide
        this.EnsureProgramFolderExists()

        ; write settings entries...
        IniWrite, % this.bIgnoreWarning, %G_SETTINGS_FILE%, options, IgnoreWarning
        IniWrite, % this.bNoAdsMode, %G_SETTINGS_FILE%, options, NoAds
    }

    ; Open the settings folder of the script
    OpenSettingsFolder()
    {
        this.EnsureProgramFolderExists()
        Run, "%G_PROGRAMM_FOLDER%"
    }

    ; Ensures the program folder for this script exists (eventually creats it or throws an error)
    EnsureProgramFolderExists()
    {
        if !FileExist(G_PROGRAMM_FOLDER)
            FileCreateDir, %G_PROGRAMM_FOLDER%
        if ErrorLevel
            MsgBox, Settings Ordner konnte nicht erstellt werden (das ist nicht gut!)
    }

    SetIgnoreWarning(on)
    {
        this.bIgnoreWarning := on
    }

    SetNoAdsMode(on)
    {
        this.bNoAdsMode := on
        if (on) {
            this.StartNoAdsMode()
        } else {
            this.StopNoAdsMode()
        }
    }

    StartNoAdsMode()
    {
        this.StopNoAdsMode()
        fn := this["NoAdsModePoll"].bind(this)
        SetTimer, % fn, 1000
    }

    StopNoAdsMode()
    {
        fn := this["NoAdsModePoll"].bind(this)
        SetTimer, % fn, Off
    }

    NoAdsModePoll()
    {
        OutputDebug, % "ads check..."
        ; TODO check for annoying ads window and close it :)
    }
}
