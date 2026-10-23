# Pulse Hardware Monitor

Pulse is a native Windows desktop dashboard built with Windows Presentation Foundation (WPF) and PowerShell. It has no Node.js, browser, or package installation requirement.

## Start

Double-click **Pulse.exe**. It opens the dashboard maximized as a resizable Windows desktop window. Windows PowerShell 5.1 and a supported Windows desktop session are required. The executable has the Pulse icon embedded in it.

## Icon and shortcut

The app window and taskbar use [Pulse.ico](./Pulse.ico), and the same icon is embedded in `Pulse.exe`. To create a desktop shortcut, right-click `Pulse.exe` and choose **Show more options → Create shortcut**; the shortcut inherits the icon. You can pin it to Start or the taskbar.

## Chart range

Choose 30 seconds, 1, 5, 15, or 60 minutes above the performance chart. Samples are captured every two seconds and kept for up to one hour while the app is open.

## Live readings

- CPU use is calculated from the Windows system CPU times API. Processor name and speed come from the Windows processor registry.
- Memory use comes from the Windows global memory status API.
- Process names, CPU time, and working-set memory come from Windows process information.
- Display adapters are detected using Windows Plug and Play (`pnputil`). The dashboard labels common Intel HD/UHD/Iris and AMD Radeon integrated graphics families as integrated GPUs.
- CPU temperature is an explicitly labeled, usage-based estimate. It is not a physical thermal sensor reading. Windows does not provide consistent GPU load/temperature readings across vendors without a vendor sensor interface.

Adapter family names are classified with model-name patterns, so newly released or less common integrated GPU names may be listed without an integrated label.
