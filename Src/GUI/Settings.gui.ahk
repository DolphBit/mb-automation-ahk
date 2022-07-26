#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; UI for Settings
class GuiSettings
{
    __New() {
        this.Show()
    }

    ; Show UI
    Show() {
        if (this.events) {
            this.events.Clear()
        }

        Gui, Main:+OwnDialogs +Disabled
        Gui, Settings:New, +hwndhGui
        this.hwnd := hGui
        this.controls := {}

        Gui, Settings:+OwnerMain
        Gui, Settings:Margin, 10, 10
        Gui, Settings:Font, s8 normal, Segoe UI
        Gui, Settings:Color, % G_STYLES.main.color

        Gui, Settings:Add, Text,, Version: %G_VERSION% (%G_DATE%)
        Gui, Settings:Add, Text,, Programm Ordner: %G_PROGRAMM_FOLDER%
        Gui, Settings:Add, Text,, Compiled With AutoHotky v%A_AhkVersion%

        Gui, Settings:Add, Button, hwndBtn, Programm Ordner öffnen
        this.controls.btnOpenSettingsFolder := Btn

        bValue := G_SETTINGS.bIgnoreWarning
        Gui, Settings:Add, CheckBox, Checked%bValue% hwndCbox, Warnung Buchungsperiode ignorieren
        this.controls.cboxIgnoreWarning := Cbox

        bValue := G_SETTINGS.bNoAdsMode
        Gui, Settings:Add, CheckBox, Checked%bValue% hwndCbox, "Keine Werbung"-Modus
        this.controls.cboxNoAds := Cbox

        bValue := G_SETTINGS.bSKR04
        Gui, Settings:Add, CheckBox, Checked%bValue% hwndCbox, "Konto SKR04"
        this.controls.cboxSKR04 := Cbox

        Gui, Settings:Add, Button, hwndBtn, GitHub Repository
        this.controls.btnOpenGitHub := Btn

        Gui, Settings:Show,,Einstellungen

        this.events := new this.EventHook(this)
    }

    __Delete() {
        this.events.Clear()
    }

    ; Sub Class to handle events properly
    class EventHook
    {
        __New(ui) {
            this.ui := ui

            fn := ObjBindMethod(this, "OnButtonOpenSettingsFolder")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btnOpenSettingsFolder, % fn
            fn := ObjBindMethod(this, "OnButtonGithub")
            GuiControl, % this.ui.hwnd ":+g", % this.ui.controls.btnOpenGitHub, % fn

            this.OnSysCommand := ObjBindMethod(this, "WM_SYSCOMMAND")
            OnMessage(0x112, this.OnSysCommand)
        }

        ; Called on button click and open the settings folder
        OnButtonOpenSettingsFolder() {
            G_SETTINGS.OpenSettingsFolder()
        }

        ; Called on button click and opens the github repo in web browser
        OnButtonGithub() {
            Run, % G_GITHUB_REPO
        }

        ; Windows Events
        WM_SYSCOMMAND(wParam, lParam, msg, hwnd) {
            if (hwnd != this.ui.hwnd) {
                return
            }

            if (wParam == C_SC_CLOSE) {
                ; Store & write settings
                GuiControlGet, bValue,, % this.ui.controls.cboxIgnoreWarning
                G_SETTINGS.SetIgnoreWarning(bValue)

                GuiControlGet, bValue,, % this.ui.controls.cboxNoAds
                G_SETTINGS.SetNoAdsMode(bValue)

                GuiControlGet, bValue,, % this.ui.controls.cboxSKR04
                G_SETTINGS.SetSKR04(bValue)

                G_SETTINGS.WriteSettings()

                this.Clear()
                return
            }
        }

        ; Called to clear the event hooks and does cleanup + destroy ui
        Clear() {
            Gui, Main:-Disabled
            try Gui, %A_Gui%:Destroy

            ; Cleanup
            OnMessage(0x112, this.OnSysCommand, 0)
            this.OnSysCommand := ""
            this.Clear := ""
        }
    }
}
