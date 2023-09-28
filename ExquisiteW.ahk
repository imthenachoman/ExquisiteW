; ExquisiteW
;
; A customizable GUI driven window manager utility for Windows 10 that lets you create custom window layouts and then quickly move and resize windows to zones using a GUI or keyboard shortcuts.
;
; version : see VERSION below
; homepage: https://github.com/imthenachoman/ExquisiteW
; author  : Anchal Nigam
; email   : imthenachoman@gmail.com

#Requires AutoHotkey v2.0
#Warn Unreachable, off
#SingleInstance Force

; GLOBAL CONSTANTS
VERSION     := "v1.0.0"
GITHUB_REPO := "imthenachoman/ExquisiteW"
HELP_URL    := "https://github.com/" GITHUB_REPO

; global settings
TraySetIcon A_ScriptDir "\ExquisiteW.ico"
SetWinDelay -1                    ; no delay for window commands; https://www.autohotkey.com/docs/v1/lib/SetWinDelay.htm
OnMessage(0x135, WM_REMOVESTATE)  ; WM_CTLCOLORBTN; catch messages sent to parent window when a button is drawn
OnMessage(0x0053, WM_HELP)
A_IconTip := "ExquisiteW v" VERSION

; needed to parse the layouts.json file
#Include "%A_ScriptDir%\JSON.ahk"

; need to be able to see if a window is elevated
#Include "%A_ScriptDir%\IsProcessElevated.ahk"

; global variables
; layoutSelectorGUI               = the GUI
; layoutSelectorGUIWindowHandleID
; layoutSelectorButtons           = array of buttons in the GUI
; layoutSelectorGUIWidth
; layoutSelectorGUIHeight
; targetWindowToMoveAndResizeWindowHandleID
; allMonitorDetails
; setting_CloseAfterSelection
; isAdminCheckForMovingWindowsNeeded

; create the GUI
TheMainEvent

; function to create the actual GUI
TheMainEvent()
{
    global isAdminCheckForMovingWindowsNeeded := false
    global allMonitorDetails := getAllMonitorDetails()
    
    ; read settings from settings.ini
    global setting_CloseAfterSelection := IniRead(A_ScriptDir "\settings.ini", "Layout Selector", "Close After Selection", 1    )
    setting_Trigger                    := IniRead(A_ScriptDir "\settings.ini", "Layout Selector", "Trigger"              , "^!d")

    ; create the GUI
    CreateGUI

    ; if ExquisiteW is running as admin or as admin UI rights, we can move admin windows
    ; so we need to check if the script is running as admin
    if !A_IsAdmin
    {
        DllCall("advapi32.dll\OpenProcessToken", "ptr", DllCall("GetCurrentProcess", "ptr"), "uint", TOKEN_QUERY := 0x0008, "ptr*", &hTokenSelf := 0)
        DllCall("advapi32\GetTokenInformation", "ptr", hTokenSelf, "uint", 26, "uint*", &TokenUIAccess := 0, "uint", 4, "uint*", &ReturnLength := 0)
        DllCall("CloseHandle", "ptr", hTokenSelf)
        if !TokenUIAccess
        {
            isAdminCheckForMovingWindowsNeeded := true
        }
    }

    ; enable the trigger
    HotKey setting_Trigger, ShowGUI

    ; let the user know it's started
    TrayTip "Press '" setting_Trigger "' to show the GUI.", "ExquisiteW Started", "0x4 0x20 Mute"

    ; if we are reloading, then show the UI again
    if (A_Args.length = 1) and (A_Args[1] = "reloaded")
    {
        ShowGUI("")
    }

    ; see if we want to check for updates
    updateCheckFrequency := IniRead(A_ScriptDir "\settings.ini", "General", "Update Check Frequency", 24)

    ; only if it's not disabled
    if (updateCheckFrequency != 0)
    {
        ; only if we don't have it set to check once
        if (updateCheckFrequency != -1)
        {
            SetTimer CheckFoUpdates, updateCheckFrequency * 1000 * 60 * 60
        }

        ; do initial check
        CheckFoUpdates
    }

}

; create the GUI
CreateGUI()
{
    global layoutSelectorGUI               := Gui()
    global layoutSelectorGUIWindowHandleID := layoutSelectorGUI.Hwnd
    global layoutSelectorButtons           := []
    global layoutSelectorGUIWidth
    global layoutSelectorGUIHeight

    ; read settings
    setting_NumberOfLayoutsInARow   := IniRead(A_ScriptDir "\settings.ini", "Layout Selector", "Number Of Layouts In A Row" , 4  )
    setting_LayoutBoxWidthInPixels  := IniRead(A_ScriptDir "\settings.ini", "Layout Selector", "Layout Box Width In Pixels" , 200)
    setting_LayoutBoxHeightInPixels := IniRead(A_ScriptDir "\settings.ini", "Layout Selector", "Layout Box Height In Pixels", 125)
    setting_Opacity                 := IniRead(A_ScriptDir "\settings.ini", "Layout Selector", "Opacity"                    , 100)

    ; we need a minimum of 3 columns
    setting_NumberOfLayoutsInARow   := setting_NumberOfLayoutsInARow < 3 ? 3 : setting_NumberOfLayoutsInARow
    setting_LayoutBoxWidthInPixels  := setting_LayoutBoxWidthInPixels < 50 ? 50 : setting_LayoutBoxWidthInPixels
    setting_LayoutBoxHeightInPixels := setting_LayoutBoxHeightInPixels < 50 ? 50 : setting_LayoutBoxHeightInPixels

    ; ; some measurement calculations
    groupBoxInsidePadding                    := 5
    groupBoxInsideTopOffset                  := 20 + groupBoxInsidePadding
    groupBoxInsideBottomOffset               := 1 + groupBoxInsidePadding
    layoutButtonsAvailableAreaWidthInPixels  := setting_LayoutBoxWidthInPixels - groupBoxInsidePadding * 2
    layoutButtonsAvailableAreaHeightInPixels := setting_LayoutBoxHeightInPixels - groupBoxInsideTopOffset - groupBoxInsideBottomOffset

    ; read the layouts
    layoutsData := JSON.parse(FileRead(A_ScriptDir "\layouts.json"))

    ; read global windowPaddingInPixels
    windowPaddingInPixels_global := layoutsData.has("windowPaddingInPixels") ? layoutsData["windowPaddingInPixels"] : 0

    ; how many columns of layouts will we have
    numberOfActualColumnsInGUI := layoutsData["layouts"].Length < setting_NumberOfLayoutsInARow ? layoutsData["layouts"].Length : setting_NumberOfLayoutsInARow

    ; create the GUI
    layoutSelectorGUI.SetFont("s12", "Calibri")
    layoutSelectorGUI.Title := "ExquisiteW v" VERSION
    layoutSelectorGUI.Opt("+AlwaysOnTop -MinimizeBox -DPIScale")
    layoutSelectorGUI.OnEvent("Close", ProcessUserInput)
    layoutSelectorGUI.OnEvent("Escape", ProcessUserInput) ; allow closing with the escape key

    ; set the opacity of the window
    if (setting_Opacity != 100)
    {
        WinSetTransColor("FF0000 " Round(setting_Opacity / 100 * 255), layoutSelectorGUI)
        ; WinSetTransColor(Round(setting_Opacity / 100 * 255), layoutSelectorGUI)
    }


    ; this is how wide the inside of the box will be
    insideWidthInPixels := (((setting_LayoutBoxWidthInPixels + layoutSelectorGUI.MarginX) * numberOfActualColumnsInGUI) - layoutSelectorGUI.MarginX)

    ; add text boxes to show the active application's name
    layoutSelectorGUI.Add("Text", "VactiveApplicationName R1 w" insideWidthInPixels, "TBD").SetFont("bold")

    ; now create each window and zone buttons
    groupBoxLeftPosition := " xm" ; the first box will start from the left going to margin in
    groupBoxTopPosition  := ""     ; and will start at a new row
    
    for arrayIndex, layoutSpecification in layoutsData["layouts"]
    {
        ; get global zone
        windowPaddingInPixels_layout := layoutSpecification.Has("windowPaddingInPixels") ? layoutSpecification["windowPaddingInPixels"] : windowPaddingInPixels_global

        ; add a group box
        layoutSelectorGUI.Add("GroupBox", "Section" groupBoxLeftPosition groupBoxTopPosition " w" setting_LayoutBoxWidthInPixels " h" setting_LayoutBoxHeightInPixels, "  " layoutSpecification["name"] "  ")
        
        ; go through each zone
        for arrayIndex1, layoutZoneSpecification in layoutSpecification["zones"]
        {
            ; calculation location and dimension of the button
            layoutZoneSpecification_topLeftRowNumber    := layoutZoneSpecification["topLeftRowNumber"]
            layoutZoneSpecification_topLeftColumnNumber := layoutZoneSpecification["topLeftColumnNumber"]
            layoutZoneSpecification_numberOfRows        := layoutZoneSpecification["numberOfRows"]
            layoutZoneSpecification_numberOfColumns     := layoutZoneSpecification["numberOfColumns"]
            layoutZoneSpecification_activator           := layoutZoneSpecification.Has("activator") ? "&" SubStr(layoutZoneSpecification["activator"], 1, 1) : ""
            layoutZoneSpecification_hotkey              := layoutZoneSpecification.Has("hotkey") ? layoutZoneSpecification["hotkey"] : ""
            
            windowPaddingInPixels_zone                    := layoutZoneSpecification.Has("windowPaddingInPixels") ? layoutZoneSpecification["windowPaddingInPixels"] : windowPaddingInPixels_layout
            
            ; figure out where the button will go
            buttonLeft   := "xs+" groupBoxInsidePadding + (layoutButtonsAvailableAreaWidthInPixels / 12) * layoutZoneSpecification_topLeftColumnNumber
            buttonTop    := " ys+" groupBoxInsideTopOffset + (layoutButtonsAvailableAreaHeightInPixels / 12) * layoutZoneSpecification_topLeftRowNumber
            buttonWidth  := " w" (layoutButtonsAvailableAreaWidthInPixels / 12) * layoutZoneSpecification_numberOfColumns
            buttonHeight := " h" (layoutButtonsAvailableAreaHeightInPixels / 12) * layoutZoneSpecification_numberOfRows

            ; add the button
            zoneButton := layoutSelectorGUI.add("button", buttonLeft buttonTop buttonWidth buttonHeight, layoutZoneSpecification_activator (layoutZoneSpecification_hotkey != "" ? " (" layoutZoneSpecification_hotkey ")" : ""))
            
            ; add to the array for processing later
            layoutSelectorButtons.Push(zoneButton)

            ; add a click event for the button
            zoneButton.OnEvent("Click", ZoneButtonClick.Bind("Normal", layoutZoneSpecification_topLeftRowNumber, layoutZoneSpecification_topLeftColumnNumber, layoutZoneSpecification_numberOfRows, layoutZoneSpecification_numberOfColumns, windowPaddingInPixels_zone))

            if (layoutZoneSpecification_hotkey)
            {
                Hotkey layoutZoneSpecification_hotkey, ZoneShortcutResponse.Bind(layoutZoneSpecification_topLeftRowNumber, layoutZoneSpecification_topLeftColumnNumber, layoutZoneSpecification_numberOfRows, layoutZoneSpecification_numberOfColumns, windowPaddingInPixels_zone)
            }
        }

        ; calculate where the next group box will go
        groupBoxLeftPosition := " xs+" setting_LayoutBoxWidthInPixels + layoutSelectorGUI.MarginX ; the next box will next to the previous box
        groupBoxTopPosition  := " ys+0"                                                            ; and on the same row

        ; unless we're at the end of the column
        if (Mod(arrayIndex, setting_NumberOfLayoutsInARow) = 0)
        {
            ; then
            groupBoxLeftPosition := " xm"                                                              ; we start back at the left
            groupBoxTopPosition  := " ys+" setting_LayoutBoxHeightInPixels + layoutSelectorGUI.MarginY  ; and go down a row
        }
    }

    ; add a horizontal line
    layoutSelectorGUI.add("Text", "0x10 xm ys+" setting_LayoutBoxHeightInPixels + layoutSelectorGUI.MarginY " w" insideWidthInPixels, "")

    ; add a help link button
    ; starts from left
    ; goes 10 pixels down above the horizontal line (we'll move it later)
    helpLink := layoutSelectorGUI.add("Link", "xm yp+10 w" setting_LayoutBoxWidthInPixels, '<a href="' HELP_URL '">Help</a>')
    helpLink.GetPos(&helpLinkLeft, &helpLinkTop, &helpLinkWidth, &helpLinkHeight)
    
    ; add a cancel button
    ; sarts from left (we'll move it later)
    ; and top is aligned with the link from above
    cancelButton := layoutSelectorGUI.add("button", "xm yp+0", "Cancel")
    layoutSelectorButtons.Push(cancelButton)
    cancelButton.OnEvent("Click", ProcessUserInput)
    cancelButton.GetPos(&cancelButtonLeft, &cancelButtonTop, &cancelButtonWidth, &cancelButtonHeight)

    ; add a reload button
    ; sarts from left (we'll move it later)
    ; and top is aligned with the link from above
    reloadButton := layoutSelectorGUI.add("button", "xm yp+0", "Reload")
    layoutSelectorButtons.Push(reloadButton)
    reloadButton.OnEvent("Click", ReloadExquisiteW)
    reloadButton.GetPos(&reloadButtonLeft, &reloadButtonTop, &reloadButtonWidth, &reloadButtonHeight)
    
    ; allMonitorDetails := [1, 2, 3]
    ; if we have multiple monitors, we need to show a monitor selection
    if (allMonitorDetails.Length > 1)
    {
        ; this box will have smaller font
        ; and won't have zone buttons
        ; so they need different padding
        groupBoxInsidePadding   := 10
        groupBoxInsideTopOffset := 10 + groupBoxInsidePadding

        ; add a new group box
        ; it should start at the 2nd column
        ; and top is aligned with the cancel button from above
        groupBox := layoutSelectorGUI.add("GroupBox", "Section CGray xm+" setting_LayoutBoxWidthInPixels + layoutSelectorGUI.MarginX " yp+0 w" setting_LayoutBoxWidthInPixels " h50", "  Send To Monitor  ")
        groupBox.setFont("s9")

        radioLeft := " xs+" groupBoxInsidePadding   ; the first radio should be 10 over from the left
        radioTop  := " ys+" groupBoxInsideTopOffset ; and down the necessary offset
        radioName := " VmonitorSelection"           ; we want to name the first radio
        for arrayIndex, monitorDetails in allMonitorDetails
        {
            radioControl := layoutSelectorGUI.add("Radio", radioLeft radioTop radioName, arrayIndex).SetFont("s9")

            ; the first radio set the placement
            ; the next radios just go next to it
            radioLeft := " x+5"
            radioTop  := ""

            ; we only want to set name for the first element
            radioName := ""
        }
        
        ; we need to move the help link and cancel button
        groupBox.GetPos(&groupBoxLeft, &groupBoxTop, &groupBoxWidth, &groupBoxHeight)
        cancelButton.Move(insideWidthInPixels - cancelButtonWidth + layoutSelectorGUI.MarginX, cancelButtonTop + (groupBoxHeight - cancelButtonHeight))
        reloadButton.Move(insideWidthInPixels - cancelButtonWidth + layoutSelectorGUI.MarginX - reloadButtonWidth - layoutSelectorGUI.MarginX, reloadButtonTop + (groupBoxHeight - cancelButtonHeight))
        helpLink.Move(, helpLinkTop + (groupBoxHeight - helpLinkHeight))
    }
    else
    {
        ; we need to move the help link and cancel button
        cancelButton.Move(insideWidthInPixels - cancelButtonWidth + layoutSelectorGUI.MarginX)
        reloadButton.Move(insideWidthInPixels - reloadButtonWidth - cancelButtonWidth)
        helpLink.Move(, helpLinkTop + (cancelButtonHeight - helpLinkHeight))
    }

    ; quickly hide and show the GUI so we can get it's dimensions
    layoutSelectorGUI.show("Hide")
    layoutSelectorGUI.hide()

    ; get the GUI's dimensions
    layoutSelectorGUI.GetPos(&junk, &junk, &layoutSelectorGUIWidth, &layoutSelectorGUIHeight)
}

; removes blue border from button remaining after clicking
WM_REMOVESTATE(wParam, lParam, msg, hwnd)
{
    ControlSetStyle(-0x1, lParam, "ahk_id " hwnd)
    return
}

ProcessUserInput(*)
{
    global layoutSelectorGUI
    
    layoutSelectorGUI.hide()
    return
}

ReloadExquisiteW(*)
{
    if A_IsCompiled
        Run Format('"{1}" /force /restart', A_ScriptFullPath)
    else
        Run Format('"{1}" /force /restart "{2}" reloaded', A_AhkPath, A_ScriptFullPath)
    ExitApp

    return
}

; run when a buttin in the GUI is clicked
ZoneButtonClick(A_GuiEvent, Info*)
{
    ; get the zone spec details
    layoutZoneSpecification_topLeftRowNumber    := Info[1]
    layoutZoneSpecification_topLeftColumnNumber := Info[2]
    layoutZoneSpecification_numberOfRows        := Info[3]
    layoutZoneSpecification_numberOfColumns     := Info[4]
    paddingInPixels                             := Info[5]
    
    ; get the monitor index to send the window to
    submitInfo     := layoutSelectorGUI.Submit(false)
    monitorIndex   := submitInfo.HasOwnProp("monitorSelection") ? submitInfo.monitorSelection : 1

    MoveAndResizeWindow(targetWindowToMoveAndResizeWindowHandleID, layoutZoneSpecification_topLeftRowNumber, layoutZoneSpecification_topLeftColumnNumber, layoutZoneSpecification_numberOfRows, layoutZoneSpecification_numberOfColumns, paddingInPixels, monitorIndex)

    return
}

; gets info about the target window that needs to be moved
GetTargetWindowToMoveAndResizeInfo(&mousePositionLeft, &mousePositionTop, &windowUnderMouseHandleID, &monitorDetails)
{
    ; https://www.autohotkey.com/boards/viewtopic.php?p=540587#p540587
    static windowsToAvoid := 'WorkerW Shell_TrayWnd Shell_SecondaryTrayWnd'

    ; we want mouse position based on screen, so temporarily set the current coordinate mode
    Local CMM := A_CoordModeMouse
    A_CoordModeMouse := "Screen"
    ; get the mouse position and the window handle ID of the active window
    MouseGetPos(&mousePositionLeft, &mousePositionTop, &windowUnderMouseHandleID)
    ; change coordinate mode back
    A_CoordModeMouse := CMM

    ; if the trigger was run when the mouse is over the GUI, then don't do anything
    if (windowUnderMouseHandleID = layoutSelectorGUIWindowHandleID)
    {
        TrayTip "ExquisiteW is already open.", "ExquisiteW Warning", "Mute Icon!"
        return false
    }

    if (windowUnderMouseHandleID = "")
    {
        TrayTip "Cannot get the window under the mouse.", "ExquisiteW Error", "Mute Iconx"
        return false
    }
    
    ; get the PID of the window and see if it is running elevated
    if isAdminCheckForMovingWindowsNeeded and (IsProcessElevated(WinGetPID("ahk_id " windowUnderMouseHandleID)) = 1)
    {
        TrayTip "Cannot interact with applications running as administrator.", "ExquisiteW Error", "Mute Iconx"
        return false
    }

    if InStr(windowsToAvoid, WinGetClass('ahk_id ' windowUnderMouseHandleID))
    {
        TrayTip "Not over a window.", "ExquisiteW Error", "Mute Icon!"
        return false
    }

    ; set the target window to move
    global targetWindowToMoveAndResizeWindowHandleID := windowUnderMouseHandleID

    ; get the details of the monitor the mouse is on
    monitorDetails := getDetailsOfMonitorMouseIsIn(&mousePositionLeft, &mousePositionTop)

    return true
}

; runs when a global zone shortcut is run
ZoneShortcutResponse(topLeftRowNumber, topLeftColumnNumber, numberOfRows, numberOfColumns, paddingInPixels, *)
{
    ; get necessary details
    if !GetTargetWindowToMoveAndResizeInfo(&mousePositionLeft, &mousePositionTop, &windowUnderMouseHandleID, &monitorDetails)
    {
        return
    }

    ; move the window
    MoveAndResizeWindow(windowUnderMouseHandleID, topLeftRowNumber, topLeftColumnNumber, numberOfRows, numberOfColumns, paddingInPixels, monitorDetails.index)
}

; show the GUI
ShowGUI(ThisHotKey)
{
    global layoutSelectorGUI

    ; get necessary details
    if !GetTargetWindowToMoveAndResizeInfo(&mousePositionLeft, &mousePositionTop, &windowUnderMouseHandleID, &monitorDetails)
    {
        return
    }

    ; set the active application text the window the mouse was over
    layoutSelectorGUI["activeApplicationName"].Text := WinGetProcessName(windowUnderMouseHandleID) " > " WinGetTitle(windowUnderMouseHandleID)
      
    ; if there are multiple monitors
    ; update the selected radio
    if (allMonitorDetails.Length > 1)
    {
        ; select the current monitor radio button
        firstMonitorRadioButtonNN     := ControlGetClassNN(layoutSelectorGUI["monitorSelection"])
        firstMonitorRadioButtonNumber := SubStr(firstMonitorRadioButtonNN, 7)
        layoutSelectorGUI['Button' . (firstMonitorRadioButtonNumber + monitorDetails.index - 1)].Value := 1
    }

    ; we want the GUI to be centered under the mouse
    ; for that we need to know the top/left of the GUI based on the mouse
    layoutSelectorGUILeft := mousePositionLeft - round(layoutSelectorGUIWidth / 2)
    ; but we need to account for situations where the mouse is near the edge and the GUI will be offscreen
    if(layoutSelectorGUILeft < monitorDetails.workArea.Left)
    {
        layoutSelectorGUILeft := monitorDetails.workArea.Left
    }
    else if ((layoutSelectorGUILeft + layoutSelectorGUIWidth) > monitorDetails.workArea.Right)
    {
        layoutSelectorGUILeft := layoutSelectorGUILeft - ((layoutSelectorGUILeft + layoutSelectorGUIWidth) - monitorDetails.workArea.Right)
    }

    layoutSelectorGUITop := mousePositionTop - round(layoutSelectorGUIHeight / 2)
    if(layoutSelectorGUITop < monitorDetails.workArea.Top)
    {
        layoutSelectorGUITop := monitorDetails.workArea.Top
    }
    else if ((layoutSelectorGUITop + layoutSelectorGUIHeight) > monitorDetails.workArea.Bottom)
    {
        layoutSelectorGUITop := layoutSelectorGUITop - ((layoutSelectorGUITop + layoutSelectorGUIHeight) - monitorDetails.workArea.Bottom)
    }

    ; move the GUI to the right place so it is centered under the mouse
    layoutSelectorGUI.Move(layoutSelectorGUILeft, layoutSelectorGUITop)

    ; show the GUI
    layoutSelectorGUI.show()

    return
}

; move the window
MoveAndResizeWindow(windowHandleID, topLeftRowNumber, topLeftColumnNumber, numberOfRows, numberOfColumns, paddingInPixels, monitorIndex)
{
    ; we want modal msgbox (https://www.autohotkey.com/docs/v2/lib/Gui.htm#OwnDialogs)
    layoutSelectorGUI.Opt("+OwnDialogs")

    ; get details about the monitor we are moving to
    monitorDetails := allMonitorDetails[monitorIndex]

    ; now we need information about the client window to calculate some offset details
    targetWindowToMoveAndResizeWindowInfo := Buffer(60, 0)
    NumPut("uint", 60, targetWindowToMoveAndResizeWindowInfo, 0)
    getWindowInfoResponse := DllCall("GetWindowInfo", "uptr", targetWindowToMoveAndResizeWindowHandleID, "ptr", targetWindowToMoveAndResizeWindowInfo)
    if !getWindowInfoResponse
    {
        MsgBox("Cannot get position of window hwnd: " targetWindowToMoveAndResizeWindowHandleID ".", "ExquisiteW Error", "OK Iconx 0x1000 0x4000")
    }
    else
    {
        clientWindowLeftPadding := NumGet(targetWindowToMoveAndResizeWindowInfo, 20, "int") - NumGet(targetWindowToMoveAndResizeWindowInfo, 4, "int")
        clientWindowRightPadding := NumGet(targetWindowToMoveAndResizeWindowInfo, 12, "int") - NumGet(targetWindowToMoveAndResizeWindowInfo, 28, "int")
        clientWindowBottomPadding := NumGet(targetWindowToMoveAndResizeWindowInfo, 16, "int") - NumGet(targetWindowToMoveAndResizeWindowInfo, 32, "int")

        ; calculate the window's new dimensions
        newLeft := monitorDetails.workArea.left + (monitorDetails.workArea.width * topLeftColumnNumber / 12) - clientWindowLeftPadding + paddingInPixels
        newTop := monitorDetails.workArea.top + (monitorDetails.workArea.height * topLeftRowNumber / 12) + paddingInPixels
        newWidth := (monitorDetails.workArea.width * numberOfColumns / 12) + clientWindowLeftPadding + clientWindowRightPadding - paddingInPixels - paddingInPixels
        newHeight := (monitorDetails.workArea.height * numberOfRows / 12) + clientWindowBottomPadding - paddingInPixels - paddingInPixels

        ; get the status of the current window
        WinStatus := WinGetMinMax("ahk_id " targetWindowToMoveAndResizeWindowHandleID)
        if (WinStatus = 0) or (WinStatus = 1)
        {
            if (WinStatus = 1)
                WinRestore("ahk_id " targetWindowToMoveAndResizeWindowHandleID)
            try
            {
                WinMove(newLeft, newTop, newWidth, newHeight, "ahk_id " targetWindowToMoveAndResizeWindowHandleID)
            }
            catch as err
            {
                MsgBox("Cannot move window hwnd: " targetWindowToMoveAndResizeWindowHandleID ". `n`n" type(err) ": " err.Message, "ExquisiteW Error", "OK Iconx 0x1000 0x4000")
            }
        }
    }

    if (setting_CloseAfterSelection = 1)
    {
        layoutSelectorGUI.hide()
    }
    return
}

; get details about all the connected monitors
getAllMonitorDetails()
{
    allMonitorDetails := []

    ; loop through the number of monitors
    Loop MonitorGetCount()
    {
        ; get details about the monitor
        monitorIndex := A_Index
        monitorName  := MonitorGetName(monitorIndex)
        MonitorGet(monitorIndex, &screenLeft, &screenTop, &screenRight, &screenBottom)
        MonitorGetWorkArea(monitorIndex, &workAreaLeft, &workAreaTop, &workAreaRight, &workAreaBottom)
        
        ; save for later
        allMonitorDetails.Push({
            index: monitorIndex,
            name: monitorName,
            screen: {
                left: screenLeft,
                top: screenTop,
                right: screenRight,
                bottom: screenBottom,
                width: screenRight - screenLeft,
                height: screenBottom - screenTop
            },
            workArea: {
                left: workAreaLeft,
                top: workAreaTop,
                right: workAreaRight,
                bottom: workAreaBottom,
                width: workAreaRight - workAreaLeft,
                height: workAreaBottom - workAreaTop
            }
        })
    }

    return allMonitorDetails
}

; get the details of the monitor the mouse is under
getDetailsOfMonitorMouseIsIn(&mousePositionLeft, &mousePositionTop)
{
    for arrayIndex, monitorDetails in allMonitorDetails
    {
        if (mousePositionLeft >= monitorDetails.screen.left) && (mousePositionLeft <= monitorDetails.screen.right) && (mousePositionTop >= monitorDetails.screen.top) && (mousePositionTop <= monitorDetails.screen.bottom)
        {
            return monitorDetails
        }
    }
    return -1
}

WM_HELP(wParam, lParam, msg, hwnd)
{
    Run HELP_URL
}

; https://www.autohotkey.com/docs/v2/lib/Download.htm#ExXHR
CheckFoUpdates()
{
    ; let the user know we're checking for updates
    TrayTip "Checking for updates.", "ExquisiteW Updater", "0x4 0x20 Mute"

    ; https://www.autohotkey.com/docs/v2/lib/Download.htm#ExXHR

    req := ComObject("Msxml2.XMLHTTP")
    req.open("GET", "https://api.github.com/repos/" GITHUB_REPO "/releases/latest", true)
    req.onreadystatechange := CheckFoUpdates_Ready.Bind(req)
    req.send()
}

; https://www.autohotkey.com/docs/v2/lib/Download.htm#ExXHR
CheckFoUpdates_Ready(req)
{
    if (req.readyState != 4)
    {
        return
    }
    if (req.status == 200)
    {
        ; we want modal msgbox (https://www.autohotkey.com/docs/v2/lib/Gui.htm#OwnDialogs)
        global layoutSelectorGUI
        layoutSelectorGUI.Opt("+OwnDialogs")

        data := JSON.parse(req.responseText)
        if (data["tag_name"] != VERSION) and (MsgBox("A newer version is available.`n`nCurrent Version: " VERSION "`nNew Version: " data["tag_name"] "`n`nWould you like to go to the download page?", "ExquisiteW Update", "YesNo Icon? 0x1000") = "Yes")
        {
            Run "https://github.com/" GITHUB_REPO "/releases/latest"
        }
    }
    else
    {
        ; we want modal msgbox (https://www.autohotkey.com/docs/v2/lib/Gui.htm#OwnDialogs)
        global layoutSelectorGUI
        layoutSelectorGUI.Opt("+OwnDialogs")

        MsgBox("Latest AutoHotkey version: " req.responseText, "ExquisiteW Update Error", "Iconx 0x1000")
    }
}