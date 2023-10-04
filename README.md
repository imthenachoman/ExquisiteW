# ExquisiteW <!-- omit from toc -->

ExquisiteW is a customizable GUI driven window manager utility for Windows 10 that lets you create custom window layouts and then quickly move and resize windows to zones using a GUI or keyboard shortcuts.

After layouts have been configured, and ExquisiteW is running, you can use ExquisiteW to move and resize the window under the mouse to a specific zones in one of 2 ways:

1. Activate the ExquisiteW GUI (using your configured trigger) and then either:
   - Click on the zone you want 
   - Press the zone's [activator](#layoutsjson) key
2. Press the [global keyboard](#layoutszoneshotkey) shortcut you have defined for the zone

![GUI with multiple monitors](images/GUI%20with%20multiple%20monitors.png)

*ExquisiteW was [inspired by Exquisite](#httpsgithubcomqewer33exquisite) and the beta version was written in [AutoHotKey](https://www.autohotkey.com/) by [Malcev](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=59835).*

# Table of Contents <!-- omit from toc -->

- [Features](#features)
- [How It Works](#how-it-works)
- [Getting It](#getting-it)
  - [Requirements](#requirements)
  - [Installation](#installation)
- [Using It](#using-it)
  - [Configuration File Specification](#configuration-file-specification)
    - [`settings.ini`](#settingsini)
      - [Section `General`](#section-general)
      - [Section `Layout Selector`](#section-layout-selector)
    - [`layouts.json`](#layoutsjson)
      - [`windowPaddingInPixels`](#windowpaddinginpixels)
      - [`padAtMonitorEdges`](#padatmonitoredges)
      - [`layouts[].zones[].hotkey`](#layoutszoneshotkey)
  - [AutoHotKey Hotkeys](#autohotkey-hotkeys)
- [Limitations And Known Bugs](#limitations-and-known-bugs)
- [Support / Help](#support--help)
- [Inspiration](#inspiration)
- [Credits](#credits)

# Features

- [**Custom layouts**](#layoutsjson) (currently through a JSON configuration file)
- **GUI** for moving + resizing the window under the mouse
- Customizable **keyboard shortcuts** 
- **Multi-monitor** support to move + resize a window to another monitor from the GUI

# How It Works

- ExquisiteW uses layouts to define a set of zones
- You can have multiple layouts
  - A layout represents the usable area of a monitor (the taskbar is automatically excluded)
  - A layout is a **12 row** by **12 column** representation of a a monitor (for the [same reason](https://github.com/qewer33/Exquisite#:~:text=choose%2012%20since%20it%27s%20a%20relatively%20small%20number%20and%20can%20be%20divided%20by%202%2C%203%20and%204) as the [inspiration](#inspiration) for ExquisiteW)
- Each layout can have multiple zones
  - A zone represents the location and area of the monitor where you want a window to be moved and resized to

![layout example](images/layout%20example.png)

# Getting It

## Requirements

- Windows 10 *
- [AutoHotKey 2.0](https://www.autohotkey.com/)

\* I only have Windows 10 machines. I do not have access to Windows 11 ([nor do I really want it](https://answers.microsoft.com/en-us/windows/forum/all/cant-un-combine-taskbar-items-in-windows-11-after/06f4aa5d-2a0a-4276-b2e1-a5680e8acd37)). If you have Windows 11 and are willing to help me test ExquisiteW, please [contact me](#support--help). 

## Installation

1. Go to https://github.com/imthenachoman/ExquisiteW/releases
2. Download the latest release ZIP file
3. Extract the ZIP file to wherever you like/want
4. [Edit `settings.ini` and `layouts.json` to your liking](#configuration-file-specification)
5. Run/execute `ExquisiteW.ahk`

You'll get a notification letting you know it's running, along with what ExquisiteW's GUI activation trigger is.

![started notification](images/started%20notification.png)

# Using It

- You can customize the [global shortcut/trigger](#section-layout-selector) used to show ExquisiteW's GUI
- ExquisiteW's GUI will show you all of your configured layouts 
  - Each layout will have 1+ buttons to represent each zone in that layout
  - Each button/zone will be visually placed in the layout to represent the area of the monitor the window will be moved and resized to 
  - Clicking on a zone, or pressing the zone's [activator](#layoutsjson) key, will move and resize the window that was under the mouse when you activated the GUI
  - If you have multiple monitors, ExquisiteW's GUI will let you select the monitor you want to move and resize the window to
- You can configure a [global shortcut/trigger](#layoutszoneshotkey) for a specific zone
  - This will let you move and resize the window under the mouse **without** opening ExquisiteW's GUI

## Configuration File Specification

There are two configuration files used by ExquisiteW:

- [`settings.ini`](#settingsini)
- [`layouts.json`](#layoutsjson)

### `settings.ini`

This is a standard [INI file](https://en.wikipedia.org/wiki/INI_file) with some global, non-layout specific settings.

#### Section `General`

| Setting                  | Valid Options                | Default | Description                                                                                                                                                        |
| ------------------------ | ---------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Update Check Frequency` | whole number greater than -1 | `24`    | How often to check for updates, in hours: <ul><li>`-1` = check once at start up</li><li>`0` = do not check for updates</li><li>`X` = check every X hours</li></ul> |


#### Section `Layout Selector`

| Setting                       | Valid Options                     | Default                  | Description                                                                                                                                |
| ----------------------------- | --------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `Close After Selection`       | `1` or `0`                        | `1`                      | <ul><li>`0` = leave ExquisiteW's GUI open after you select a zone</li><li>`1` = close it</li></ul>                                         |
| `Opacity`                     | whole number from `0` to `100`    | `100`                    | <ul><li>`0` = make ExquisiteW's GUI completely transparent</li><li>`...` = percent transparent</li><li>`100` = completely opaque</li></ul> |
| `Trigger`                     | [AHK HotKey](#autohotkey-hotkeys) | `^!d` (`ctrl + alt + d`) | The global keyboard shortcut to show ExquisiteW's GUI when the mouse is over a window/application that can be resized                      |
| `Number Of Layouts In A Row`  | whole number greater than 3       | `4`                      | Number of layouts per row in ExquisiteW's GUI; `3` is the minimum                                                                          |
| `Layout Box Width In Pixels`  | whole number greater than 50      | `200`                    | Width of each layout (in pixels) in ExquisiteW's GUI; `50` is the minimum                                                                  |
| `Layout Box Height In Pixels` | whole number greater than 50      | `125`                    | Height of each layout (in pixels) in ExquisiteW's GUI; `50` is the minimum                                                                 |


### `layouts.json`

`layouts.json` is a JSON formatted configuration file where layouts are defined. The structure of `layouts.json` is below. See [`layouts.json`](layouts.json) for a real example.

``` json
{
    "windowPaddingInPixels" : number,    //optional
    "padAtMonitorEdges"     : bool,      //optional
    "layouts"               : [
        {
            "name"                  : string,
            "windowPaddingInPixels" : number,    //optional
            "padAtMonitorEdges"     : bool,      //optional
            "zones" : [
                {
                    "topLeftRowNumber"      : 0-12,
                    "topLeftColumnNumber"   : 0-12,
                    "numberOfRows"          : 1-12,
                    "numberOfColumns"       : 1-12,
                    "activator"             : single letter,                 //optional
                    "hotkey"                : AutoHotKey HotKey,             //optional
                    "windowPaddingInPixels" : whole number greater than 1,   //optional
                    "padAtMonitorEdges"     : bool                           //optional
                },
                {...}
            ]
        },
        {...}
    ]
}
```

| Property                                  | Valid Options                     | Description                                                                                                                                                     |
| ----------------------------------------- | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `windowPaddingInPixels`                   | number                            | Global window padding for all zones in all layouts (see [`windowPaddingInPixels`](#windowpaddinginpixels))                                                      |
| `padAtMonitorEdges`                       | `true` or `false`                 | Global setting for if padding should be added when a window is at the edge of the monitor (see [`padAtMonitorEdges`](#padAtMonitorEdges))                       |
| `layouts` *                               | array of layouts                  | All of the layouts                                                                                                                                              |
| `layouts[].name` *                        | string                            | Name of the layout to show in the GUI                                                                                                                           |
| `layouts[].windowPaddingInPixels`         | number                            | Window padding for all of zones in this layout (see [`windowPaddingInPixels`](#windowpaddinginpixels))                                                          |
| `layouts[].padAtMonitorEdges`             | number                            | Setting for this layout for if padding should be added when a window is at the edge of the monitor (see [`padAtMonitorEdges`](#padAtMonitorEdges))              |
| `layouts[].zones` *                       | array of zones                    | All of the zones for this layout                                                                                                                                |
| `layouts[].zones[].topLeftRowNumber` *    | `0` - `11`                        | Row number of the top left corner of the window (see [How It Works](#how-it-works))                                                                             |
| `layouts[].zones[].topLeftColumnNumber` * | `0` - `11`                        | Column number of the top left corner of the window (see [How It Works](#how-it-works))                                                                          |
| `layouts[].zones[].numberOfRows` *        | `1` - `12`                        | Height of the window, in number of rows (see [How It Works](#how-it-works))                                                                                     |
| `layouts[].zones[].numberOfColumns` *     | `1` - `12`                        | Width of the window, in number of columns (see [How It Works](#how-it-works))                                                                                   |
| `layouts[].zones[].activator`             | letter                            | Single letter to activate a zone/button in the GUI                                                                                                              |
| `layouts[].zones[].hotkey`                | [AHK HotKey](#autohotkey-hotkeys) | Global shortcut to activate a zone without the GUI (see [`layouts[].zones[].hotkey`](#layoutszoneshotkey))                                                      |
| `layouts[].zones[].windowPaddingInPixels` | number                            | Window padding for this zone in this layout (see [`windowPaddingInPixels`](#windowpaddinginpixels))                                                             |
| `layouts[].zones[].padAtMonitorEdges`     | number                            | Setting for this zone in this layout for if padding should be added when a window is at the edge of the monitor (see [`padAtMonitorEdges`](#padAtMonitorEdges)) |

**\* required properties**

#### `windowPaddingInPixels`

- You can add a custom padding (in pixels) around a window when it is moved and resized
- Window padding can be set in 3 places:
  - globally, for all layouts, by setting the `windowPaddingInPixels` property at the root of `layouts.json`
  - for all zones of a specific layout by setting the `windowPaddingInPixels` property for a layout
  - for a specific zone by setting the `windowPaddingInPixels` property of a specific zone
- If `windowPaddingInPixels` is not set for a zone, it will use the value of `windowPaddingInPixels` for the layout
- If `windowPaddingInPixels` is not set for a layout, it will use the global value of `windowPaddingInPixels`

#### `padAtMonitorEdges`

- If you have set `windowPaddingInPixels` then padding will be added to all four sides of the window
- If the window is at the edge of the monitor, you may not want padding added to that edge
- This lets you disable padding at the edge
- This setting can be set in 3 places:
  - globally, for all layouts, by setting the `padAtMonitorEdges` property at the root of `layouts.json`
  - for all zones of a specific layout by setting the `padAtMonitorEdges` property for a layout
  - for a specific zone by setting the `padAtMonitorEdges` property of a specific zone
- If `padAtMonitorEdges` is not set for a zone, it will use the value of `padAtMonitorEdges` for the layout
- If `padAtMonitorEdges` is not set for a layout, it will use the global value of `padAtMonitorEdges`

#### `layouts[].zones[].hotkey`

- This is an [AutoHotKey HotKey](#autohotkey-hotkeys)
- If set, a global keyboard shortcut will be created and associated to the zone
- When the ExquisiteW GUI is **not active**, and this keyboard shortcut is used, the **current window under the mouse** will be moved and resized according to the zone's configuration 

## AutoHotKey Hotkeys

Since ExquisiteW is written in [AutoHotKey](https://www.autohotkey.com/), it uses AHK's structure for defining hotkeys. You can read about it and see examples at https://www.autohotkey.com/docs/v2/Hotkeys.htm.

# Limitations And Known Bugs

| Issue                                | Type       | Details                                                                                                                                                                                  |
| ------------------------------------ | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| No support for administrator windows | limitation | ExquisiteW cannot move and resize windows running as an administrator.                                                                                                                   |
| Not monitor/desktop change aware     | limitation | ExquisiteW does not know when your monitor arrangement/configuration changes, or your desktop changes. You will need to manually reload ExquisiteW when you make those kinds of changes. |

# Support / Help

You can get support/help in one of two ways:

- Open an issue at https://github.com/imthenachoman/ExquisiteW/issues
- Contact me at the information listed in my [GitHub profile](https://github.com/imthenachoman)

# Inspiration

- My daily driver is Linux (Debian + KDE Plasma)
- [Exquisite](https://github.com/qewer33/Exquisite) (without the W) is a window manager for KDE written by [qewer33](https://github.com/qewer33)
- It is the **best window manager I have ever seen**
- I still use Windows 10 on some machines
- Windows 10 built-in window snapping is adequate
- [FancyZones](https://learn.microsoft.com/en-us/windows/powertoys/fancyzones) (part of [PowerToys](https://learn.microsoft.com/en-us/windows/powertoys/)) is awesome but you have to drag/drop windows and that's a lot of mouse travel (especially on an ultrawide monitor)

So I* decided to build a Windows clone of [Exquisite](https://github.com/qewer33/Exquisite).

Disclaimer: I didn't know [AutoHotKey](https://www.autohotkey.com/) when I started. I reached out to [Malcev](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=59835) who created the beta version for me. I took his's code -- with his permission -- and ran with it. (In the interest of transprency, I paid him for his work.)

# Credits

- [Malcev](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=59835) for the initial version
- [andymbody](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=79819) for https://www.autohotkey.com/boards/viewtopic.php?p=540471#p540471
- [jNizM](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=75) for https://www.autohotkey.com/boards/viewtopic.php?p=540898#p540898
- [just me](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=148) for https://www.autohotkey.com/boards/viewtopic.php?p=539922#p539922  and https://www.autohotkey.com/boards/viewtopic.php?p=540310#p540310 
- [neogna2](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=72371) for https://www.autohotkey.com/boards/viewtopic.php?p=539921#p539921
- [niCode](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=149812) for https://www.autohotkey.com/boards/viewtopic.php?p=540587#p540587
- [ntepa](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=149849) for https://www.autohotkey.com/boards/viewtopic.php?p=540461#p540461
- [teadrinker](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=62433) for https://www.autohotkey.com/boards/viewtopic.php?p=540162#p540162