Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -AssemblyName System.Xaml

$nativeSource = @'
using System;
using System.Runtime.InteropServices;
namespace Pulse {
  public static class NativeMetrics {
    [StructLayout(LayoutKind.Sequential)] public struct FILETIME { public uint Low; public uint High; public ulong Value { get { return ((ulong)High << 32) | Low; } } }
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)] private class MEMORYSTATUSEX {
      public uint dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
      public uint dwMemoryLoad; public ulong ullTotalPhys; public ulong ullAvailPhys;
      public ulong ullTotalPageFile; public ulong ullAvailPageFile; public ulong ullTotalVirtual;
      public ulong ullAvailVirtual; public ulong ullAvailExtendedVirtual;
    }
    [DllImport("kernel32.dll", SetLastError=true)] private static extern bool GetSystemTimes(out FILETIME idle, out FILETIME kernel, out FILETIME user);
    [DllImport("kernel32.dll", CharSet=CharSet.Auto, SetLastError=true)] private static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX status);
    [DllImport("shell32.dll", CharSet=CharSet.Unicode, PreserveSig=true)] private static extern int SetCurrentProcessExplicitAppUserModelID(string appID);
    public static int SetAppId(string appID) { return SetCurrentProcessExplicitAppUserModelID(appID); }
    public static ulong[] CpuTimes() {
      FILETIME idle, kernel, user;
      if(!GetSystemTimes(out idle, out kernel, out user)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
      return new ulong[] { idle.Value, kernel.Value, user.Value };
    }
    public static ulong[] Memory() {
      MEMORYSTATUSEX s = new MEMORYSTATUSEX();
      if(!GlobalMemoryStatusEx(s)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
      return new ulong[] { s.ullTotalPhys, s.ullAvailPhys, s.dwMemoryLoad };
    }
  }
}
'@
try { Add-Type -TypeDefinition $nativeSource -Language CSharp }
catch { [void][System.Windows.MessageBox]::Show($_.Exception.ToString(), 'Pulse startup error'); exit 1 }
[void][Pulse.NativeMetrics]::SetAppId('Pulse.HardwareMonitor')

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:shell="clr-namespace:System.Windows.Shell;assembly=PresentationFramework"
 Title="Pulse — Hardware Monitor" Width="1200" Height="880" MinWidth="940" MinHeight="680" WindowState="Normal" WindowStartupLocation="Manual" WindowStyle="None" ResizeMode="CanResizeWithGrip" Background="#0B0E15" Foreground="#E8ECF2" FontFamily="Segoe UI" UseLayoutRounding="True">
 <shell:WindowChrome.WindowChrome><shell:WindowChrome CaptionHeight="36" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="0" UseAeroCaptionButtons="False"/></shell:WindowChrome.WindowChrome>
 <Window.Resources>
  <SolidColorBrush x:Key="Lime" Color="#C4F078"/><SolidColorBrush x:Key="Muted" Color="#7D8796"/>
  <Style TargetType="ScrollBar"><Setter Property="Background" Value="Transparent"/><Setter Property="Width" Value="8"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar"><Grid Background="Transparent"><Track x:Name="PART_Track" IsDirectionReversed="True"><Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.LineUpCommand" Opacity="0" Focusable="False"/></Track.DecreaseRepeatButton><Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb"><Border Background="#384252" CornerRadius="4" Margin="1"/></ControlTemplate></Thumb.Template></Thumb></Track.Thumb><Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.LineDownCommand" Opacity="0" Focusable="False"/></Track.IncreaseRepeatButton></Track></Grid><ControlTemplate.Triggers><Trigger Property="Orientation" Value="Horizontal"><Setter Property="Height" Value="8"/><Setter Property="Width" Value="Auto"/><Setter TargetName="PART_Track" Property="IsDirectionReversed" Value="False"/></Trigger><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#526071"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
  <Style x:Key="Card" TargetType="Border"><Setter Property="Background" Value="#11151E"/><Setter Property="BorderBrush" Value="#242B37"/><Setter Property="BorderThickness" Value="1"/><Setter Property="CornerRadius" Value="7"/><Setter Property="Padding" Value="17"/></Style>
  <Style x:Key="TinyLabel" TargetType="TextBlock"><Setter Property="Foreground" Value="#87919F"/><Setter Property="FontSize" Value="10"/><Setter Property="FontFamily" Value="Consolas"/></Style>
  <Style TargetType="Button"><Setter Property="Foreground" Value="#C4F078"/><Setter Property="Background" Value="#1A2119"/><Setter Property="BorderBrush" Value="#35442A"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Padding" Value="12,7"/><Setter Property="Cursor" Value="Hand"/></Style>
  <Style TargetType="ComboBox"><Setter Property="Background" Value="#171D26"/><Setter Property="Foreground" Value="#DDE3EC"/><Setter Property="BorderBrush" Value="#303846"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Padding" Value="7,4"/><Setter Property="FontSize" Value="10"/><Setter Property="ItemContainerStyle"><Setter.Value><Style TargetType="ComboBoxItem"><Setter Property="Background" Value="#171D26"/><Setter Property="Foreground" Value="#DDE3EC"/><Setter Property="Padding" Value="8,6"/><Style.Triggers><Trigger Property="IsHighlighted" Value="True"><Setter Property="Background" Value="#263321"/><Setter Property="Foreground" Value="#C4F078"/></Trigger></Style.Triggers></Style></Setter.Value></Setter><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ComboBox"><Grid><ToggleButton x:Name="ToggleButton" Background="#171D26" BorderBrush="#303846" BorderThickness="1" Focusable="False" ClickMode="Press" IsChecked="{Binding IsDropDownOpen,Mode=TwoWay,RelativeSource={RelativeSource TemplatedParent}}"><Grid Margin="7,0,7,0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/></Grid.ColumnDefinitions><ContentPresenter Grid.Column="0" Content="{TemplateBinding SelectionBoxItem}" VerticalAlignment="Center" HorizontalAlignment="Left" TextElement.Foreground="#DDE3EC"/><Path Grid.Column="1" Data="M 0 0 L 4 4 L 8 0 Z" Fill="#A9B3C1" HorizontalAlignment="Right" VerticalAlignment="Center"/></Grid></ToggleButton><Popup x:Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Fade"><Border Background="#171D26" BorderBrush="#394352" BorderThickness="1" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="{TemplateBinding MaxDropDownHeight}"><ScrollViewer Margin="2" SnapsToDevicePixels="True"><ItemsPresenter KeyboardNavigation.DirectionalNavigation="Contained"/></ScrollViewer></Border></Popup></Grid></ControlTemplate></Setter.Value></Setter></Style>
 </Window.Resources>
 <Grid><Grid.RowDefinitions><RowDefinition Height="36"/><RowDefinition Height="*"/></Grid.RowDefinitions>
  <Border x:Name="HeaderBar" Grid.Row="0" Background="#0E121A" BorderBrush="#222935" BorderThickness="0,0,0,1">
   <DockPanel><StackPanel DockPanel.Dock="Right" Orientation="Horizontal"><Button x:Name="MinButton" shell:WindowChrome.IsHitTestVisibleInChrome="True" Content="—" Width="42" Background="Transparent" BorderThickness="0" Foreground="#AAB2BF" Padding="0"/><Button x:Name="MaxButton" shell:WindowChrome.IsHitTestVisibleInChrome="True" Content="❐" Width="42" Background="Transparent" BorderThickness="0" Foreground="#AAB2BF" Padding="0"/><Button x:Name="CloseButton" shell:WindowChrome.IsHitTestVisibleInChrome="True" Content="×" Width="46" Background="Transparent" BorderThickness="0" Foreground="#AAB2BF" Padding="0"/></StackPanel>
   <StackPanel x:Name="TitleDragArea" Orientation="Horizontal" VerticalAlignment="Center" Margin="16,0,0,0"><Border Width="18" Height="18" CornerRadius="5" Background="#20291A" BorderBrush="#3C4B2D" BorderThickness="1" Margin="0,0,8,0"><TextBlock Text="⌁" Foreground="#C4F078" FontSize="14" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-2,0,0"/></Border><TextBlock Text="pulse" FontWeight="Bold" FontSize="12"/><TextBlock Text="." Foreground="#C4F078" FontWeight="Bold" FontSize="12"/><TextBlock Text="  HARDWARE MONITOR" Foreground="#727D8C" FontFamily="Consolas" FontSize="9" VerticalAlignment="Center" Margin="8,0,0,0"/></StackPanel>
   </DockPanel>
  </Border>
  <Grid Grid.Row="1"><Grid.ColumnDefinitions><ColumnDefinition Width="210"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
   <Border Grid.Column="0" Background="#0D1118" BorderBrush="#202733" BorderThickness="0,0,1,0"><Grid Margin="16,19,16,15"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <StackPanel><StackPanel Orientation="Horizontal" Margin="4,0,0,32"><Border Width="30" Height="30" CornerRadius="8" Background="#20291A" BorderBrush="#39482A" BorderThickness="1" Margin="0,0,10,0"><TextBlock Text="⌁" Foreground="#C4F078" FontSize="21" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-4,0,0"/></Border><TextBlock Text="pulse" FontSize="23" FontWeight="Bold" VerticalAlignment="Center"/><TextBlock Text="." Foreground="#C4F078" FontSize="23" FontWeight="Bold" VerticalAlignment="Center"/></StackPanel><TextBlock Text="MONITOR" Style="{StaticResource TinyLabel}" Margin="7,0,0,10"/><Border Background="#1A211F" CornerRadius="5" Padding="10,11"><StackPanel Orientation="Horizontal"><TextBlock Text="◫" Foreground="#C4F078" FontSize="17" Margin="0,0,10,0"/><TextBlock Text="Overview" Foreground="#E7EDDE" FontSize="12" VerticalAlignment="Center"/></StackPanel></Border></StackPanel>
    <StackPanel Grid.Row="2"><Border Style="{StaticResource Card}" Padding="11"><StackPanel Orientation="Horizontal"><Ellipse Width="7" Height="7" Fill="#C4F078" Margin="0,0,10,0"/><StackPanel><TextBlock Text="Monitoring live" FontSize="11"/><TextBlock Text="Refreshing every 2 seconds" Foreground="#75808E" FontSize="9" Margin="0,3,0,0"/></StackPanel></StackPanel></Border><TextBlock Text="LOCAL SYSTEM MONITOR  ·  v1.0" Foreground="#596473" FontFamily="Consolas" FontSize="8" Margin="3,15,0,0"/></StackPanel>
   </Grid></Border>
   <Grid Grid.Column="1"><Grid.RowDefinitions><RowDefinition Height="52"/><RowDefinition Height="*"/></Grid.RowDefinitions>
    <Border Grid.Row="0" Background="#0D1118" BorderBrush="#202733" BorderThickness="0,0,0,1" Padding="22,0"><DockPanel LastChildFill="False" VerticalAlignment="Center"><StackPanel Orientation="Horizontal" DockPanel.Dock="Left"><TextBlock Text="SYSTEM" Foreground="#7D8796" FontFamily="Consolas" FontSize="9"/><TextBlock Text="  /  " Foreground="#4A5563" FontFamily="Consolas" FontSize="9"/><TextBlock Text="OVERVIEW" Foreground="#ADB5C1" FontFamily="Consolas" FontSize="9"/></StackPanel><StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center"><Ellipse Width="6" Height="6" Fill="#C4F078" VerticalAlignment="Center" Margin="0,0,8,0"/><TextBlock x:Name="HostText" Text="This PC" Foreground="#AEB7C4" FontSize="10" VerticalAlignment="Center"/><TextBlock x:Name="ClockText" Text="--:--:--" Foreground="#9CA6B5" FontFamily="Consolas" FontSize="10" Margin="18,0,0,0" VerticalAlignment="Center"/><Button x:Name="RefreshButton" Content="↻  Refresh" Margin="16,0,0,0" Padding="10,5" FontSize="10"/></StackPanel></DockPanel></Border>
    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><StackPanel Margin="27,23,27,20">
     <DockPanel LastChildFill="False" Margin="0,0,0,20"><StackPanel DockPanel.Dock="Left"><StackPanel Orientation="Horizontal"><Ellipse Width="6" Height="6" Fill="#C4F078" Margin="0,0,8,0"/><TextBlock Text="LIVE SYSTEM OVERVIEW" Style="{StaticResource TinyLabel}"/></StackPanel><TextBlock FontSize="27" FontWeight="SemiBold" Margin="0,7,0,3"><TextBlock.Inlines><Run Text="Your system, "/><Run Text="in focus." Foreground="#C4F078"/></TextBlock.Inlines></TextBlock><TextBlock Text="A real-time look at the hardware doing the work." Foreground="#7F8998" FontSize="11"/></StackPanel><Border DockPanel.Dock="Right" Background="#151B17" BorderBrush="#34412F" BorderThickness="1" CornerRadius="4" Padding="9,6" VerticalAlignment="Top" Margin="16,0,0,0"><StackPanel Orientation="Horizontal" VerticalAlignment="Center"><Ellipse Width="6" Height="6" Fill="#C4F078" Margin="0,0,7,0"/><TextBlock Text="LIVE  ·  " Foreground="#C9E3A1" FontFamily="Consolas" FontSize="9"/><TextBlock x:Name="UpdatedText" Text="Connecting…" Foreground="#89947A" FontFamily="Consolas" FontSize="9"/></StackPanel></Border></DockPanel>
     <UniformGrid Columns="4" Margin="0,0,0,21">
      <Border Style="{StaticResource Card}" Margin="0,0,7,0"><StackPanel><TextBlock Text="PROCESSOR LOAD" Style="{StaticResource TinyLabel}"/><StackPanel Orientation="Horizontal" Margin="0,13,0,0"><TextBlock x:Name="CpuValue" Text="—" FontSize="30" FontWeight="Medium"/><TextBlock Text=" %" Foreground="#A4ADBA" FontFamily="Consolas" VerticalAlignment="Bottom" Margin="4,0,0,5"/></StackPanel><TextBlock x:Name="CpuSub" Text="Total utilization" Foreground="#7B8695" FontSize="10" Margin="0,4,0,0"/></StackPanel></Border>
      <Border Style="{StaticResource Card}" Margin="7,0"><StackPanel><TextBlock Text="MEMORY IN USE" Style="{StaticResource TinyLabel}"/><StackPanel Orientation="Horizontal" Margin="0,13,0,0"><TextBlock x:Name="MemoryValue" Text="—" FontSize="30" FontWeight="Medium"/><TextBlock Text=" %" Foreground="#A4ADBA" FontFamily="Consolas" VerticalAlignment="Bottom" Margin="4,0,0,5"/></StackPanel><TextBlock x:Name="MemorySub" Text="— of —" Foreground="#7B8695" FontSize="10" Margin="0,4,0,0"/><ProgressBar x:Name="MemoryBar" Height="3" Minimum="0" Maximum="100" Value="0" Foreground="#70B8FF" Background="#28303B" BorderThickness="0" Margin="0,12,0,0"/></StackPanel></Border>
      <Border Style="{StaticResource Card}" Margin="7,0"><StackPanel><TextBlock Text="CPU TEMPERATURE" Style="{StaticResource TinyLabel}"/><StackPanel Orientation="Horizontal" Margin="0,13,0,0"><TextBlock x:Name="TempValue" Text="—" FontSize="30" FontWeight="Medium"/><TextBlock Text=" °C" Foreground="#A4ADBA" FontFamily="Consolas" VerticalAlignment="Bottom" Margin="4,0,0,5"/></StackPanel><Border Background="#251A16" BorderBrush="#574034" BorderThickness="1" CornerRadius="3" Padding="4,2" HorizontalAlignment="Left" Margin="0,6,0,0"><TextBlock Text="ESTIMATED · USAGE BASED" Foreground="#E7AA7D" FontFamily="Consolas" FontSize="8"/></Border></StackPanel></Border>
      <Border Style="{StaticResource Card}" Margin="7,0,0,0"><StackPanel><TextBlock Text="ACTIVE PROCESSES" Style="{StaticResource TinyLabel}"/><StackPanel Orientation="Horizontal" Margin="0,13,0,0"><TextBlock x:Name="ProcessValue" Text="—" FontSize="30" FontWeight="Medium"/><TextBlock Text=" running" Foreground="#A4ADBA" FontSize="10" VerticalAlignment="Bottom" Margin="5,0,0,6"/></StackPanel><TextBlock Text="System processes" Foreground="#7B8695" FontSize="10" Margin="0,4,0,0"/></StackPanel></Border>
     </UniformGrid>
     <DockPanel LastChildFill="False" Margin="0,0,0,11"><StackPanel><TextBlock Text="PERFORMANCE" Style="{StaticResource TinyLabel}"/><TextBlock Text="System activity" FontSize="16" FontWeight="Medium" Margin="0,4,0,0"/></StackPanel><StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Bottom"><TextBlock Text="RANGE" Foreground="#788392" FontFamily="Consolas" FontSize="8" VerticalAlignment="Center" Margin="0,0,8,0"/><ComboBox x:Name="ChartRange" Width="105" Height="27" SelectedIndex="1"><ComboBoxItem Content="30 seconds" Tag="30"/><ComboBoxItem Content="1 minute" Tag="60"/><ComboBoxItem Content="5 minutes" Tag="300"/><ComboBoxItem Content="15 minutes" Tag="900"/><ComboBoxItem Content="60 minutes" Tag="3600"/></ComboBox></StackPanel></DockPanel>
     <Border Style="{StaticResource Card}" Padding="11,12,13,9"><Grid><Grid.RowDefinitions><RowDefinition Height="132"/><RowDefinition Height="17"/></Grid.RowDefinitions><Canvas x:Name="Chart" Grid.Row="0" ClipToBounds="True"/><Grid Grid.Row="1" Margin="0,3,0,0"><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions><TextBlock x:Name="ChartStart" Text="-60s" Foreground="#65707E" FontFamily="Consolas" FontSize="8"/><TextBlock x:Name="ChartMiddle" Grid.Column="1" Text="-30s" Foreground="#65707E" FontFamily="Consolas" FontSize="8" HorizontalAlignment="Center"/><TextBlock x:Name="ChartEnd" Grid.Column="2" Text="NOW" Foreground="#65707E" FontFamily="Consolas" FontSize="8" HorizontalAlignment="Right"/></Grid></Grid></Border>
     <DockPanel LastChildFill="False" Margin="0,20,0,11"><StackPanel><TextBlock Text="YOUR MACHINE" Style="{StaticResource TinyLabel}"/><TextBlock Text="Hardware overview" FontSize="16" FontWeight="Medium" Margin="0,4,0,0"/></StackPanel><TextBlock x:Name="PlatformText" DockPanel.Dock="Right" Text="DETECTING DEVICE" Foreground="#7D8796" FontFamily="Consolas" FontSize="8" VerticalAlignment="Bottom"/></DockPanel>
     <UniformGrid Columns="2" Margin="0,0,0,20">
      <Border Style="{StaticResource Card}" Margin="0,0,7,0" MinHeight="173"><StackPanel><DockPanel><Border Width="30" Height="30" CornerRadius="5" Background="#20291A" BorderBrush="#39482A" BorderThickness="1"><TextBlock Text="⌁" Foreground="#C4F078" FontSize="18" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><TextBlock Text="MONITORING" DockPanel.Dock="Right" Foreground="#A8C780" FontFamily="Consolas" FontSize="8" VerticalAlignment="Center"/></DockPanel><TextBlock Text="Processor" Foreground="#87919E" FontSize="10" Margin="0,11,0,0"/><TextBlock x:Name="CpuName" Text="Detecting processor…" FontSize="13" FontWeight="Medium" TextTrimming="CharacterEllipsis" Margin="0,3,0,0"/><Grid Margin="0,12,0,0"><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="UTILIZATION" Style="{StaticResource TinyLabel}" FontSize="8"/><TextBlock x:Name="CpuDetail" Text="—" FontSize="14" Margin="0,3,0,0"/></StackPanel><StackPanel Grid.Column="1"><TextBlock Text="EST. TEMPERATURE" Style="{StaticResource TinyLabel}" FontSize="8"/><TextBlock x:Name="TempDetail" Text="—" FontSize="14" Margin="0,3,0,0"/></StackPanel></Grid><ProgressBar x:Name="CpuBar" Height="3" Minimum="0" Maximum="100" Value="0" Foreground="#C4F078" Background="#28303B" BorderThickness="0" Margin="0,9,0,0"/><DockPanel Margin="0,7,0,0"><TextBlock x:Name="CpuMeta" Text="— logical processors" Foreground="#778290" FontFamily="Consolas" FontSize="8"/><TextBlock x:Name="CpuSpeed" Text="— MHz" Foreground="#778290" FontFamily="Consolas" FontSize="8" DockPanel.Dock="Right"/></DockPanel></StackPanel></Border>
      <Border Style="{StaticResource Card}" Margin="7,0,0,0" MinHeight="173"><StackPanel><DockPanel><Border Width="30" Height="30" CornerRadius="5" Background="#1B202B" BorderBrush="#29313D" BorderThickness="1"><TextBlock Text="◈" Foreground="#9EA8B7" FontSize="17" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><TextBlock x:Name="GpuStatus" Text="SCANNING ADAPTERS" DockPanel.Dock="Right" Foreground="#8993A2" FontFamily="Consolas" FontSize="8" VerticalAlignment="Center"/></DockPanel><TextBlock Text="Graphics processors" Foreground="#87919E" FontSize="10" Margin="0,11,0,2"/><StackPanel x:Name="AdaptersPanel"><TextBlock Text="Detecting display adapters…" Foreground="#A9B2BF" FontSize="12"/></StackPanel></StackPanel></Border>
     </UniformGrid>
     <DockPanel LastChildFill="False" Margin="0,0,0,11"><StackPanel><TextBlock Text="WHAT’S RUNNING" Style="{StaticResource TinyLabel}"/><TextBlock Text="Top processes" FontSize="16" FontWeight="Medium" Margin="0,4,0,0"/></StackPanel><TextBlock x:Name="ProcessCountText" DockPanel.Dock="Right" Text="— processes detected" Foreground="#7D8796" FontFamily="Consolas" FontSize="8" VerticalAlignment="Bottom"/></DockPanel>
     <Border Style="{StaticResource Card}" Padding="0"><StackPanel><Border Background="#151A24" Padding="12,8" CornerRadius="7,7,0,0"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="65"/><ColumnDefinition Width="65"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions><TextBlock Text="PROCESS" Style="{StaticResource TinyLabel}" FontSize="8"/><TextBlock Grid.Column="1" Text="PID" Style="{StaticResource TinyLabel}" FontSize="8"/><TextBlock Grid.Column="2" Text="CPU" Style="{StaticResource TinyLabel}" FontSize="8"/><TextBlock Grid.Column="3" Text="MEMORY" Style="{StaticResource TinyLabel}" FontSize="8"/></Grid></Border><StackPanel x:Name="ProcessesPanel" MinHeight="47"><TextBlock Text="Reading process activity…" Foreground="#7D8796" FontSize="10" Margin="12,14"/></StackPanel><Border BorderBrush="#242B37" BorderThickness="0,1,0,0" Padding="12,8"><DockPanel><TextBlock Text="●  LIVE PROCESS SNAPSHOT" Foreground="#75808E" FontFamily="Consolas" FontSize="8"/><TextBlock x:Name="ProcessUpdated" Text="Updates every 2 seconds" DockPanel.Dock="Right" Foreground="#667180" FontFamily="Consolas" FontSize="8"/></DockPanel></Border></StackPanel></Border>
     <DockPanel Margin="0,16,0,0"><TextBlock Text="LOCAL SYSTEM MONITOR    ·    DATA STAYS ON THIS DEVICE" Foreground="#596473" FontFamily="Consolas" FontSize="8"/><TextBlock x:Name="UptimeText" Text="UPTIME —" DockPanel.Dock="Right" Foreground="#596473" FontFamily="Consolas" FontSize="8"/></DockPanel>
    </StackPanel></ScrollViewer>
   </Grid>
  </Grid>
 </Grid>
</Window>
'@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)
function Find-Control([string]$Name) { $window.FindName($Name) }
$names = @('HeaderBar','TitleDragArea','MinButton','MaxButton','CloseButton','RefreshButton','HostText','ClockText','UpdatedText','CpuValue','CpuSub','MemoryValue','MemorySub','MemoryBar','TempValue','ProcessValue','Chart','ChartRange','ChartStart','ChartMiddle','ChartEnd','PlatformText','CpuName','CpuDetail','TempDetail','CpuBar','CpuMeta','CpuSpeed','GpuStatus','AdaptersPanel','ProcessCountText','ProcessesPanel','ProcessUpdated','UptimeText')
foreach ($name in $names) { Set-Variable -Name $name -Value (Find-Control $name) }
$MinButton.Add_Click({ $window.WindowState='Minimized' })
$MaxButton.Add_Click({ if ($script:PulseMaximized) { $window.Left=$script:RestoreLeft; $window.Top=$script:RestoreTop; $window.Width=$script:RestoreWidth; $window.Height=$script:RestoreHeight; $script:PulseMaximized=$false; $MaxButton.Content='□' } else { $script:RestoreLeft=$window.Left; $script:RestoreTop=$window.Top; $script:RestoreWidth=$window.Width; $script:RestoreHeight=$window.Height; $window.Left=$workArea.Left; $window.Top=$workArea.Top; $window.Width=$workArea.Width; $window.Height=$workArea.Height; $script:PulseMaximized=$true; $MaxButton.Content='❐' } })
$CloseButton.Add_Click({ $window.Close() })
$RefreshButton.Add_Click({ Update-Dashboard })
$TitleDragArea.Add_MouseLeftButtonDown({ if ($_.ButtonState -eq 'Pressed') { $window.DragMove() } })
$iconPath = Join-Path $PSScriptRoot 'Pulse.ico'
if (Test-Path $iconPath) { $decoder=[Windows.Media.Imaging.BitmapDecoder]::Create([Uri]::new($iconPath),[Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,[Windows.Media.Imaging.BitmapCacheOption]::OnLoad); $window.Icon=$decoder.Frames[$decoder.Frames.Count-1] }

$script:PreviousCpu = $null
$script:PreviousSampleAt = Get-Date
$script:PreviousProcesses = @{}
$script:Samples = [System.Collections.Generic.List[object]]::new()
$script:GpuAdapters = @()
$script:Polls = 0
$script:CpuNameValue = 'Unknown processor'
$script:CpuSpeedValue = 0
try {
  $cpuProps = Get-ItemProperty -Path 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' -ErrorAction Stop
  if ($cpuProps.ProcessorNameString) { $script:CpuNameValue = [string]$cpuProps.ProcessorNameString }
  if ($cpuProps.'~MHz') { $script:CpuSpeedValue = [int]$cpuProps.'~MHz' }
} catch { }

function Get-DisplayAdapters {
  $exe = Join-Path $env:windir 'System32\pnputil.exe'
  if (-not (Test-Path $exe)) { return @() }
  $raw = (& $exe /enum-devices /class Display /connected 2>$null | Out-String)
  $found = @()
  foreach ($block in ($raw -split '(?:\r?\n){2,}')) {
    if ($block -notmatch '(?im)^\s*Device Description:\s*(.+?)\s*$') { continue }
    $name = $Matches[1].Trim()
    if ($block -notmatch '(?im)^\s*Instance ID:\s*PCI\\') { continue }
    if ($block -match '(?im)^\s*Status:\s*(.+?)\s*$' -and $Matches[1].Trim() -ne 'Started') { continue }
    if ($name -match '(?i)DisplayLink|Remote Display|Virtual Display|Indirect Display') { continue }
    $integrated = $name -match '(?i)Intel.*(?:HD Graphics|UHD Graphics|Iris(?: Xe)? Graphics|Arc(?:\(TM\))?(?: Graphics|.*\b(?:130|140)V\b))|(?:AMD|ATI).*?(?:Radeon(?:\(TM\))? Graphics|Radeon (?:[6-9]\d{2,3}M|RX Vega \d+))'
    $type = if ($integrated) { 'INTEGRATED GRAPHICS' } else { 'DISCRETE / OTHER ADAPTER' }
    $found += [pscustomobject]@{ Name=$name; Type=$type; Integrated=[bool]$integrated }
  }
  return @($found | Sort-Object @{Expression={ if ($_.Integrated) {0} else {1} }},Name -Unique)
}

function Update-AdapterList {
  $script:GpuAdapters = @(Get-DisplayAdapters)
  $AdaptersPanel.Children.Clear()
  if ($script:GpuAdapters.Count -eq 0) {
    $GpuStatus.Text = 'NO DISPLAY ADAPTER FOUND'
    $line = [Windows.Controls.TextBlock]::new(); $line.Text='Windows did not report a PCI display adapter.'; $line.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#7D8796'); $line.FontSize=10; $line.Margin='0,8,0,0'; [void]$AdaptersPanel.Children.Add($line)
    return
  }
  $integrated = @($script:GpuAdapters | Where-Object Integrated)
  if ($integrated.Count) { $GpuStatus.Text = "$($integrated.Count) INTEGRATED GPU$(if($integrated.Count -ne 1){'S'}) DETECTED" } else { $GpuStatus.Text = "$($script:GpuAdapters.Count) ADAPTER$(if($script:GpuAdapters.Count -ne 1){'S'}) DETECTED" }
  foreach ($adapter in $script:GpuAdapters) {
    $panel = [Windows.Controls.StackPanel]::new(); $panel.Orientation='Horizontal'; $panel.Margin='0,9,0,0'
    $dot = [Windows.Shapes.Ellipse]::new(); $dot.Width=7; $dot.Height=7; $dot.Margin='0,0,8,0'; $dot.VerticalAlignment='Center'; $dot.Fill=[Windows.Media.BrushConverter]::new().ConvertFromString($(if($adapter.Integrated){'#C4F078'}else{'#78AEEA'})); [void]$panel.Children.Add($dot)
    $texts = [Windows.Controls.StackPanel]::new()
    $label = [Windows.Controls.TextBlock]::new(); $label.Text=$adapter.Name; $label.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#E0E5ED'); $label.FontSize=11; $label.TextTrimming='CharacterEllipsis'; $label.MaxWidth=430; [void]$texts.Children.Add($label)
    $kind = [Windows.Controls.TextBlock]::new(); $kind.Text=$adapter.Type; $kind.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString($(if($adapter.Integrated){'#A8C780'}else{'#8CA1BB'})); $kind.FontFamily='Consolas'; $kind.FontSize=8; $kind.Margin='0,3,0,0'; [void]$texts.Children.Add($kind)
    [void]$panel.Children.Add($texts); [void]$AdaptersPanel.Children.Add($panel)
  }
}

function Format-Bytes([double]$bytes) {
  if ($bytes -lt 1GB) { return '{0:N0} MB' -f ($bytes/1MB) }
  return '{0:N1} GB' -f ($bytes/1GB)
}

function Draw-Chart {
  $Chart.Children.Clear(); $width=$Chart.ActualWidth; $height=$Chart.ActualHeight
  if ($width -lt 20 -or $height -lt 20) { return }
  foreach ($fraction in @(0,.25,.5,.75,1)) { $line=[Windows.Shapes.Line]::new(); $line.X1=0; $line.X2=$width; $line.Y1=$height*$fraction; $line.Y2=$height*$fraction; $line.Stroke=[Windows.Media.BrushConverter]::new().ConvertFromString('#27303B'); $line.StrokeThickness=1; $line.StrokeDashArray=[Windows.Media.DoubleCollection]::new([double[]]@(2,4)); [void]$Chart.Children.Add($line) }
  $rangeSeconds=60; if($ChartRange.SelectedItem -and $ChartRange.SelectedItem.Tag){$rangeSeconds=[int]$ChartRange.SelectedItem.Tag}
  $cutoff=(Get-Date).AddSeconds(-$rangeSeconds); $visible=@($script:Samples | Where-Object { $_.At -ge $cutoff })
  $startValue=if($rangeSeconds -ge 60){'-'+[string]($rangeSeconds/60)+'m'}else{'-'+[string]$rangeSeconds+'s'}
  $halfRange=[int]($rangeSeconds/2); $middleValue=if($halfRange -ge 60){'-'+[string]($halfRange/60)+'m'}else{'-'+[string]$halfRange+'s'}
  $ChartStart.Text=$startValue; $ChartMiddle.Text=$middleValue
  if ($visible.Count -lt 2) { return }
  $points=[Windows.Media.PointCollection]::new()
  for ($i=0; $i -lt $visible.Count; $i++) { $age=([DateTime]::Now-$visible[$i].At).TotalSeconds; $x=[Math]::Max(0,[Math]::Min($width,(($rangeSeconds-$age)/$rangeSeconds)*$width)); $value=[double]$visible[$i].Value; $y=$height-([Math]::Max(0,[Math]::Min(100,$value))/100*$height); [void]$points.Add([Windows.Point]::new($x,$y)) }
  $polyline=[Windows.Shapes.Polyline]::new(); $polyline.Points=$points; $polyline.Stroke=[Windows.Media.BrushConverter]::new().ConvertFromString('#C4F078'); $polyline.StrokeThickness=2; $polyline.StrokeLineJoin='Round'; [void]$Chart.Children.Add($polyline)
}

function Update-ProcessList($Processes) {
  $ProcessesPanel.Children.Clear(); $top=@($Processes | Sort-Object CPUUsage -Descending | Select-Object -First 8)
  foreach ($process in $top) {
    $row=[Windows.Controls.Grid]::new(); $row.Margin='12,0,12,0'; $row.Height=34
    foreach ($size in @('*','65','65','80')) { $column=[Windows.Controls.ColumnDefinition]::new(); if($size -eq '*'){$column.Width=[Windows.GridLength]::new(1,[Windows.GridUnitType]::Star)}else{$column.Width=[Windows.GridLength]::new([double]$size)}; [void]$row.ColumnDefinitions.Add($column) }
    $name=[Windows.Controls.TextBlock]::new(); $name.Text=$process.Name; $name.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#DDE3EC'); $name.FontSize=10; $name.VerticalAlignment='Center'; $name.TextTrimming='CharacterEllipsis'; [Windows.Controls.Grid]::SetColumn($name,0); [void]$row.Children.Add($name)
    $pidText=[Windows.Controls.TextBlock]::new(); $pidText.Text=[string]$process.Id; $pidText.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#939EAC'); $pidText.FontFamily='Consolas'; $pidText.FontSize=9; $pidText.VerticalAlignment='Center'; [Windows.Controls.Grid]::SetColumn($pidText,1); [void]$row.Children.Add($pidText)
    $cpuText=[Windows.Controls.TextBlock]::new(); $cpuText.Text=('{0:N1}%' -f $process.CPUUsage); $cpuText.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#C4F078'); $cpuText.FontFamily='Consolas'; $cpuText.FontSize=9; $cpuText.VerticalAlignment='Center'; [Windows.Controls.Grid]::SetColumn($cpuText,2); [void]$row.Children.Add($cpuText)
    $memoryText=[Windows.Controls.TextBlock]::new(); $memoryText.Text=Format-Bytes $process.WorkingSet64; $memoryText.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#939EAC'); $memoryText.FontFamily='Consolas'; $memoryText.FontSize=9; $memoryText.VerticalAlignment='Center'; [Windows.Controls.Grid]::SetColumn($memoryText,3); [void]$row.Children.Add($memoryText)
    [void]$ProcessesPanel.Children.Add($row); $separator=[Windows.Controls.Border]::new(); $separator.Height=1; $separator.Background=[Windows.Media.BrushConverter]::new().ConvertFromString('#202733'); [void]$ProcessesPanel.Children.Add($separator)
  }
  $ProcessCountText.Text="$($Processes.Count) running processes"; $ProcessUpdated.Text='Snapshot at '+(Get-Date -Format 'HH:mm:ss')
  $ProcessValue.Text=[string]$Processes.Count
}

function Update-Dashboard {
  try {
    $now=Get-Date; $cpuTimes=[Pulse.NativeMetrics]::CpuTimes(); $usage=0.0
    if ($null -ne $script:PreviousCpu) { $idleDelta=[double]($cpuTimes[0]-$script:PreviousCpu[0]); $totalDelta=[double](($cpuTimes[1]-$script:PreviousCpu[1])+($cpuTimes[2]-$script:PreviousCpu[2])); if($totalDelta -gt 0){$usage=[Math]::Max(0,[Math]::Min(100,[Math]::Round((1-$idleDelta/$totalDelta)*100)))} }
    $script:PreviousCpu=$cpuTimes; $memory=[Pulse.NativeMetrics]::Memory(); $total=[double]$memory[0]; $available=[double]$memory[1]; $memUse=if($total -gt 0){[Math]::Round(($total-$available)/$total*100)}else{0}; $temp=[Math]::Round(36+$usage*.34)
    $CpuValue.Text=[string]$usage; $CpuSub.Text="$([Environment]::ProcessorCount) logical threads · total utilization"; $MemoryValue.Text=[string]$memUse; $MemorySub.Text="$(Format-Bytes ($total-$available)) of $(Format-Bytes $total)"; $MemoryBar.Value=$memUse; $TempValue.Text=[string]$temp
    $CpuName.Text=$script:CpuNameValue; $CpuDetail.Text="$usage%"; $TempDetail.Text="$temp °C"; $CpuBar.Value=$usage; $CpuMeta.Text="$([Environment]::ProcessorCount) logical processors"; $CpuSpeed.Text="$($script:CpuSpeedValue) MHz"
    $ProcessList=@(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $cpuSeconds=0.0; try{if($null -ne $_.CPU){$cpuSeconds=[double]$_.CPU}}catch{}; $old=$script:PreviousProcesses[[int]$_.Id]; $cpuPercent=0.0; if($null -ne $old){$elapsed=[Math]::Max(.25,($now-$script:PreviousSampleAt).TotalSeconds);$cpuPercent=[Math]::Max(0,[Math]::Min(100,(($cpuSeconds-$old)/$elapsed/[Environment]::ProcessorCount)*100))}; $script:PreviousProcesses[[int]$_.Id]=$cpuSeconds; [pscustomobject]@{Name=$_.ProcessName;Id=$_.Id;CPUUsage=$cpuPercent;WorkingSet64=$_.WorkingSet64} })
    $script:PreviousSampleAt=$now; Update-ProcessList $ProcessList
    $script:Samples.Add([pscustomobject]@{ At=$now; Value=[double]$usage }); if($script:Samples.Count -gt 1801){$script:Samples.RemoveAt(0)}; Draw-Chart
    $HostText.Text=[Environment]::MachineName; $arch=if([Environment]::Is64BitOperatingSystem){'X64'}else{'X86'}; $PlatformText.Text="$([Environment]::OSVersion.VersionString.ToUpper())  ·  $arch"
    $uptime=[TimeSpan]::FromMilliseconds([Environment]::TickCount64); $UptimeText.Text='UPTIME {0}D {1:00}H {2:00}M' -f [Math]::Floor($uptime.TotalDays),$uptime.Hours,$uptime.Minutes
    $UpdatedText.Text='Updated '+$now.ToString('HH:mm:ss'); $ClockText.Text=$now.ToString('HH:mm:ss'); $script:Polls++; if($script:Polls -eq 1 -or $script:Polls%15 -eq 0){Update-AdapterList}
  } catch { $UpdatedText.Text='Sensor read failed'; $CpuSub.Text=$_.Exception.Message; Write-Warning $_ }
}

$window.Add_ContentRendered({ Update-Dashboard })
$workArea = [System.Windows.SystemParameters]::WorkArea
$script:RestoreWidth = [Math]::Min(1200, $workArea.Width)
$script:RestoreHeight = [Math]::Min(880, $workArea.Height)
$script:RestoreLeft = $workArea.Left + [Math]::Max(0, ($workArea.Width - $script:RestoreWidth) / 2)
$script:RestoreTop = $workArea.Top + [Math]::Max(0, ($workArea.Height - $script:RestoreHeight) / 2)
$script:PulseMaximized = $true
$window.Left = $workArea.Left
$window.Top = $workArea.Top
$window.Width = $workArea.Width
$window.Height = $workArea.Height
$ChartRange.Add_SelectionChanged({ Draw-Chart })
$timer=[Windows.Threading.DispatcherTimer]::new(); $timer.Interval=[TimeSpan]::FromSeconds(2); $timer.Add_Tick({ Update-Dashboard }); $timer.Start()
$clockTimer=[Windows.Threading.DispatcherTimer]::new(); $clockTimer.Interval=[TimeSpan]::FromSeconds(1); $clockTimer.Add_Tick({ $ClockText.Text=Get-Date -Format 'HH:mm:ss' }); $clockTimer.Start()
$window.Add_Closed({ $timer.Stop(); $clockTimer.Stop() })
[void]$window.ShowDialog()
