# Stats (fork)

<p align="center"><img src="Stats/Supporting%20Files/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="120"></p>

macOS system monitor in your menu bar.

This is a personal fork of [exelban/stats](https://github.com/exelban/stats) by Serhiy Mytrovtsiy, who wrote and
maintains the app. The fork adds a handful of menu bar options (listed below) and is otherwise the upstream app.
It is **not affiliated with or endorsed by the upstream project**, and it is maintained by [Nicholas Cupo](https://github.com/nickcupo)
on a best-effort basis. If you are not specifically after the changes below, use the
[official Stats](https://github.com/exelban/stats/releases).

## What this fork changes
- **Menu bar spacing** (Settings > General): a slider for the space between Stats widgets. With *Combined modules* on,
  it also controls the padding macOS draws around the Stats block, so the icons can sit much tighter than the system default.
- **Open details on hover** (Settings > General): resting the cursor on a widget opens its popup without a click and
  without taking focus away from the app you are using. Moving across widgets switches popups. A click pins the popup:
  the widget stays highlighted and the popup stays open until you click the widget again or anywhere outside it.
- **Fit width to value** (Network widget settings): the speed widget sizes its numbers column to the unit shown instead
  of reserving space for the largest possible value.
- Labels under the circle charts in the CPU and GPU popups.
- Update checks go to this fork's GitHub releases.

Everything else, including all the features, modules and translations, is upstream's work.

## Installation
Download `Stats.dmg` from the [latest release of this fork](https://github.com/nickcupo/stats/releases/latest/download/Stats.dmg),
open it and move the app to the Applications folder. Releases are signed with a Developer ID certificate and notarized
by Apple, so they open without extra steps.

The fork keeps upstream's bundle identifier (`eu.exelban.Stats`). Installing it **replaces the official Stats app** and
uses the same settings; switching back is a matter of installing the official release again. Homebrew's `stats` formula
installs the official app, not this fork.

### Uninstall
Run the uninstall script bundled with the app (requires administrator privileges to remove the SMC helper):
```bash
sh /Applications/Stats.app/Contents/Resources/Scripts/uninstall.sh
```
The script quits Stats and removes:

   - the SMC helper (`/Library/LaunchDaemons/eu.exelban.Stats.SMC.Helper.plist` and `/Library/PrivilegedHelperTools/eu.exelban.Stats.SMC.Helper`)
   - `Stats.app`
   - application data and preferences (`~/Library/Application Support/Stats`, widget containers, and `eu.exelban.Stats` defaults)

If the app has already been moved to the Trash, the script can be run directly from the repository:
```bash
curl -fsSL https://raw.githubusercontent.com/nickcupo/stats/master/Kit/scripts/uninstall.sh | sh
```

## Requirements
Stats is supported on macOS 12 (Monterey) and newer.
Beta versions of macOS are not supported - only stable releases.

## Features
Stats is an application that allows you to monitor your macOS system.

 - CPU utilization
 - GPU utilization
 - Memory usage
 - Disk utilization
 - Network usage
 - Battery level
 - Fan's control (not maintained)
 - Sensors information (Temperature/Voltage/Power)
 - Bluetooth devices
 - Multiple time zone clock

## Issues, questions and contributions
Please keep the two projects apart so neither maintainer gets reports for code they did not write:

- **Something about the options listed above**, or a problem that only happens with this fork: open an issue
  [here](https://github.com/nickcupo/stats/issues). Pull requests for the fork's own features are welcome.
- **Anything else** (a module, a sensor, a crash, a translation): it is upstream code, so check the
  [upstream issues](https://github.com/exelban/stats/issues) first and report there, after confirming it also happens
  with the official build. Upstream has its own contribution policy, described in its README; please respect it and do
  not send upstream pull requests on behalf of this fork.

Translations are inherited from upstream. New or improved translations are best contributed upstream so everyone gets them.

## FAQ

### How do you change the order of the menu bar icons?
macOS decides the order of the menu bar items, not Stats. It may change after the first reboot after installing Stats.

To change the order of any menu bar icon (macOS Mojave 10.14 and up):

1. Hold down ⌘ (command key).
2. Drag the icon to the desired position on the menu bar.
3. Release ⌘ (command key).

### Stats icons do not appear in the menu bar
macOS 26 introduced a new privacy control under System Settings → Menu Bar. Apps must be explicitly allowed there to
display menu bar items. If Stats is running with at least one module active and one widget enabled, but none of its
icons show up, this is almost certainly the cause (see [upstream issue #3120](https://github.com/exelban/stats/issues/3120)).

**Solution:** open **System Settings → Menu Bar** and toggle **Stats** ON.

### Desktop widgets not showing the data
Due to a problem with high data load in the system process (`chronod`) responsible for communication between the app
and widgets, communication is disabled by default. To enable it, the `macOS widgets` option must be enabled in the Stats
settings (see [upstream issue #2733](https://github.com/exelban/stats/issues/2733)).

**Solution:** open **Stats Settings** and toggle **macOS widgets** ON.

### How to reduce energy impact or CPU usage of Stats?
Reading some data periodically is not a cheap task and each module has its own cost. To reduce the energy impact,
disable modules you do not need. The most expensive modules are Sensors and Bluetooth; disabling them can reduce CPU
usage noticeably.

### Fan control
Fan control is in legacy mode upstream: it receives no updates or fixes and is kept only because it works acceptably on
older Macs. This fork does not change it.

### Sensors show incorrect CPU/GPU core count
CPU/GPU sensors are thermal zones on the CPU/GPU and have no relation to the number of cores or to specific cores.
A CPU is typically divided into efficiency and performance clusters, each containing several temperature sensors, and
Stats simply displays those sensors. "CPU Efficient Core 1" is one temperature sensor within the efficiency cluster, not
the temperature of a single core. Apple also changes the sensor keys with each new SoC, so matching them takes time.

### App crash – what to do?
Make sure you run the latest release. If it still crashes, check whether it also happens with the official Stats build:
if it does, it is an upstream problem and belongs in the upstream issue tracker; if it only happens with this fork,
open an issue here.

## External services
Stats does not collect any telemetry or analytics. This fork makes the following external requests:

- `https://api.github.com` – update checks against this fork's releases (the upstream release server is no longer used).
- `https://api.mac-stats.com/ip` – the public IP address shown in the Network module. This endpoint is run by the
  upstream author and is unchanged from upstream. If you would rather not use it, disable the public IP option in the
  Network module or block the host with a network filter.
- The optional **System Stats** remote monitoring feature (Remote module) talks to the upstream author's hosted service
  exactly as the official app does. This fork does not run or change that service.

## Supported languages
- English
- Polski
- Українська
- Русский
- 中文 (简体) (thanks to [chenguokai](https://github.com/chenguokai), [Tai-Zhou](https://github.com/Tai-Zhou), and [Jerry](https://github.com/Jerry23011))
- Türkçe (thanks to [yusufozgul](https://github.com/yusufozgul) and [setanarut](https://github.com/setanarut))
- 한국어 (thanks to [escapeanaemia](https://github.com/escapeanaemia) and [iamhslee](https://github.com/iamhslee))
- German (thanks to [natterstefan](https://github.com/natterstefan) and [aneitel](https://github.com/aneitel))
- 中文 (繁體) (thanks to [iamch15542](https://github.com/iamch15542) and [jrthsr700tmax](https://github.com/jrthsr700tmax))
- Spanish (thanks to [jcconca](https://github.com/jcconca))
- Vietnamese (thanks to [HXD.VN](https://github.com/xuandung38))
- French (thanks to [RomainLt](https://github.com/RomainLt))
- Italian (thanks to [gmcinalli](https://github.com/gmcinalli))
- Portuguese (Brazil) (thanks to [marcelochaves95](https://github.com/marcelochaves95) and [pedroserigatto](https://github.com/pedroserigatto))
- Norwegian Bokmål (thanks to [rubjo](https://github.com/rubjo))
- 日本語 (thanks to [treastrain](https://github.com/treastrain))
- Portuguese (Portugal) (thanks to [AdamModus](https://github.com/AdamModus))
- Czech (thanks to [mpl75](https://github.com/mpl75))
- Magyar (thanks to [moriczr](https://github.com/moriczr))
- Bulgarian (thanks to [zbrox](https://github.com/zbrox))
- Romanian (thanks to [razluta](https://github.com/razluta))
- Dutch (thanks to [ngohungphuc](https://github.com/ngohungphuc))
- Hrvatski (thanks to [milotype](https://github.com/milotype))
- Danish (thanks to [casperes1996](https://github.com/casperes1996) and [aleksanderbl29](https://github.com/aleksanderbl29))
- Catalan (thanks to [davidalonso](https://github.com/davidalonso))
- Indonesian (thanks to [yooody](https://github.com/yooody))
- Hebrew (thanks to [BadSugar](https://github.com/BadSugar))
- Slovenian (thanks to [zigapovhe](https://github.com/zigapovhe))
- Greek (thanks to [sudoxcess](https://github.com/sudoxcess) and [vaionicle](https://github.com/vaionicle))
- Persian (thanks to [ShawnAlisson](https://github.com/ShawnAlisson))
- Slovenský (thanks to [martinbernat](https://github.com/martinbernat))
- Thai (thanks to [apiphoomchu](https://github.com/apiphoomchu))
- Estonian (thanks to [postylem](https://github.com/postylem))
- Hindi (thanks to [patiljignesh](https://github.com/patiljignesh))
- Finnish (thanks to [eightscrow](https://github.com/eightscrow))
- Bengali (thanks to [adnan29979](https://github.com/adnan29979))
- Tamil (thanks to [sabapathy7](https://github.com/sabapathy7))

You can help by adding a new language or improving the existing translation.

## License
Stats is released under the [MIT License](LICENSE), copyright (c) 2019 Serhiy Mytrovtsiy. The changes in this fork are
released under the same license. The license file, the copyright notice and the translator credits above must be kept
in any further fork or redistribution.

## Building
Clone the repository and open `Stats.xcodeproj`, or build from the command line.

A build signed with your own Apple Development certificate (put your team ID in `Signing.xcconfig`):
```bash
xcodebuild -scheme Stats -configuration Release -xcconfig Signing.xcconfig build
```

A distributable build needs a *Developer ID Application* certificate for the team in `Release.xcconfig` and, once,
stored notarization credentials (`xcrun notarytool store-credentials "AC_PASSWORD"`). Then:
```bash
make build
```
This archives, exports, notarizes, staples and produces `Stats.dmg` next to the Makefile. The in-app updater looks for a
GitHub release tagged `vX.Y.Z` (matching `MARKETING_VERSION`) with a `Stats.dmg` asset attached.

If you fork this fork, change the update source in `Stats/AppDelegate.swift` to your own repository so your users are
not offered releases from here.
