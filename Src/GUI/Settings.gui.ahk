#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Settings GUI
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class GuiSettings
{
    __New() {

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

        Gui, Settings:Add, Button, hwndBtn, Programm Ordner öffnen
        this.controls.btnOpenSettingsFolder := Btn

        bValue := G_SETTINGS.bIgnoreWarning
        Gui, Settings:Add, CheckBox, Checked%bValue% hwndCbox, Warnung Buchungsperiode ignorieren
        this.controls.cboxIgnoreWarning := Cbox

        bValue := G_SETTINGS.bNoAdsMode
        Gui, Settings:Add, CheckBox, Checked%bValue% hwndCbox, "Keine Werbung"-Modus
        this.controls.cboxNoAds := Cbox

        Gui, Settings:Add, Button, hwndBtn, GitHub Repository
        this.controls.btnOpenGitHub := Btn

        Gui, Settings:Show,,Einstellungen

        this.events := new this.EventHook(this.hwnd, this.controls)
    }

    __Delete() {
        try Gui, % this.hwnd . ":Destroy"
        this.events.Clear()
    }

    class EventHook
    {
        __New(hwnd, controls) {
            this.hwnd := hwnd
            this.controls := controls

            fn := ObjBindMethod(this, "OnButtonOpenSettingsFolder")
            GuiControl, %hwnd%:+g, % this.controls.btnOpenSettingsFolder, % fn
            fn := ObjBindMethod(this, "OnButtonGithub")
            GuiControl, %hwnd%:+g, % this.controls.btnOpenGitHub, % fn

            this.OnSysCommand := ObjBindMethod(this, "WM_SYSCOMMAND")
            OnMessage(0x112, this.OnSysCommand)
        }

        OnButtonOpenSettingsFolder() {
            G_SETTINGS.OpenSettingsFolder()
        }

        OnButtonGithub() {
            Global G_GITHUB_REPO
            Run, % G_GITHUB_REPO
        }

        WM_SYSCOMMAND(wParam, lParam, msg, hwnd) {
            if (hwnd != this.hwnd)
                Return

            static SC_CLOSE := 0xF060
            if (wParam = SC_CLOSE) {
                ; Store & write settings
                GuiControlGet, bValue,, % this.controls.cboxIgnoreWarning
                G_SETTINGS.SetIgnoreWarning(bValue)

                GuiControlGet, bValue,, % this.controls.cboxNoAds
                G_SETTINGS.SetNoAdsMode(bValue)

                G_SETTINGS.WriteSettings()

                this.Clear()
                return
            }
            return
        }

        Clear() {
            Gui, Main:-Disabled
            try Gui, % this.gui.hwnd . ":Destroy"

            ; Cleanup
            OnMessage(0x112, this.OnSysCommand, 0)
            this.OnSysCommand := ""
            this.Clear := ""
        }
    }
}
