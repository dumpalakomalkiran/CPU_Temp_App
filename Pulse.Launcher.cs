using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class PulseLauncher
{
    [STAThread]
    private static void Main()
    {
        try
        {
            string folder = AppDomain.CurrentDomain.BaseDirectory;
            string script = Path.Combine(folder, "Pulse.Desktop.ps1");
            if (!File.Exists(script))
            {
                MessageBox.Show("Pulse.Desktop.ps1 must be beside Pulse.exe.", "Pulse", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            string powershell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),
                @"WindowsPowerShell\v1.0\powershell.exe");
            var start = new ProcessStartInfo
            {
                FileName = powershell,
                Arguments = "-NoLogo -NoProfile -WindowStyle Hidden -STA -ExecutionPolicy Bypass -File \"" + script + "\"",
                WorkingDirectory = folder,
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };
            Process.Start(start);
        }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message, "Could not start Pulse", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
