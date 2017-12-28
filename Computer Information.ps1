Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
[xml]$xaml = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp7"
        Title="Computer Information" Height="768" Width="1024" WindowStartupLocation="CenterScreen">
    <Grid x:Name="Results_grpbx">
        <GroupBox x:Name="Actions" Header="Actions" HorizontalAlignment="Left" Height="161" VerticalAlignment="Top" Width="196">
            <Grid HorizontalAlignment="Left" Height="142" Margin="4,9,0,-12" VerticalAlignment="Top" Width="172">
                <Button x:Name="Processes_btn" Content="Processes" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Width="75"/>
                <Button x:Name="Services_btn" Content="Services" HorizontalAlignment="Left" Margin="10,37,0,0" VerticalAlignment="Top" Width="75"/>
                <Button x:Name="Disks_btn" Content="Disks" HorizontalAlignment="Left" Margin="10,64,0,0" VerticalAlignment="Top" Width="75"/>
            </Grid>
        </GroupBox>
        <GroupBox x:Name="ComputerName" Header="ComputerName" HorizontalAlignment="Left" Height="107" Margin="201,0,0,0" VerticalAlignment="Top" Width="805">
            <Grid x:Name="Txtbx_action" HorizontalAlignment="Left" Height="67" Margin="10,10,0,0" VerticalAlignment="Top" Width="766">
                <Button x:Name="Browse_btn" Content="Browse" HorizontalAlignment="Left" Margin="665,0,0,0" VerticalAlignment="Top" Width="75" ToolTipService.ToolTip="Browse for file containing computernames"/>
            </Grid>
        </GroupBox>
        <TextBox x:Name="Text_bx" HorizontalAlignment="Left" Height="23" Margin="217,25,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="650"/>
        <GroupBox x:Name="Computers" Header="Computers" HorizontalAlignment="Left" Height="367" VerticalAlignment="Top" Width="195" Margin="1,155,0,0">
            <ListBox x:Name="ComputerNames_lstbx" HorizontalAlignment="Left" Width="177" Margin="-1,2,0,0" Height="335" VerticalAlignment="Top">
            </ListBox>
        </GroupBox>
        <GroupBox x:Name="Results" Header="Results" HorizontalAlignment="Left" Height="399" VerticalAlignment="Top" Width="805" Margin="201,123,0,0">
            <DataGrid x:Name="Results_dtgrd" HorizontalAlignment="Left" Height="369" VerticalAlignment="Top" Width="773" Margin="10,0,0,0" AlternatingRowBackground = "LightBlue"  AlternationCount="2" CanUserAddRows="False"/>
        </GroupBox>
        <CheckBox x:Name="Chkbx_txtbx" Content="TextBox" HorizontalAlignment="Left" Margin="799,53,0,0" VerticalAlignment="Top" ToolTipService.ToolTip="Check to use TextBox ComputerName"/>
        <TextBox x:Name="Txtbx_action2" HorizontalAlignment="Left" Height="23" TextWrapping="Wrap" VerticalAlignment="Top" Width="89" Margin="97,36,0,0" IsEnabled="False"/>
    </Grid>
</Window>
"@

$reader= New-Object System.Xml.XmlNodeReader $xaml
$Window=[Windows.Markup.XamlReader]::Load( $reader )
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach {
  New-Variable  -Name $_.Name -Value $Window.FindName($_.Name) -Force
}

$Browse_btn.Add_Click({
    $fd = New-Object system.windows.forms.openfiledialog
    $fd.InitialDirectory = "c:\scripts"
    $fd.Filter = "Text Files (*.txt)|*.txt"
    $fd.showdialog() | out-null
    $fd.FileName
    if ($fd.FileName) {
        $names = get-content -path $fd.FileName
        if ($ComputerNames_lstbx.Items.Count -ge 1) { $ComputerNames_lstbx.Items.Clear() }
        $Results_dtgrd.ItemsSource = $null
        $Text_bx.Text = $null
        $Txtbx_action2.Text = $null 
        foreach ($name in $names) { $ComputerNames_lstbx.items.add($name) }
    }
})

function Get-ComputerName {
        if ([string]::IsNullOrEmpty($ComputerNames_lstbx.SelectedItem) -and ([string]::IsNullOrEmpty($Text_bx.Text))) { 
            $error = [System.Windows.Forms.Messagebox]::Show("This action requires a ComputerName","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
            return 
         }
        if ($Chkbx_txtbx.IsChecked -and $Text_bx.Text) { $Computername = $Text_bx.Text }
        if ( -not ($Chkbx_txtbx.IsChecked) -and $ComputerNames_lstbx.SelectedItem) { $Computername = $ComputerNames_lstbx.SelectedItem; $Text_bx.Text = $Computername } 
        if ($Chkbx_txtbx.IsChecked -and ([string]::IsNullorEmpty($Text_bx.Text))) { 
            $error = [System.Windows.Forms.Messagebox]::Show("This action requires a ComputerName","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
            return
         }
        if (-not($Chkbx_txtbx.IsChecked) -and $Text_bx.Text -and (-not ($ComputerNames_lstbx.SelectedItem))) { 
            $error = [System.Windows.Forms.Messagebox]::Show("Please ensure 'TextBox' is checked.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
             return 
             }
        switch($button) {
            "processes" { Get-Processes $Computername }
            "services"  { Get-Services $Computername }
            "disks"     { Get-Disks $Computername }
        }
}

Function Get-Processes {
    if ($Computername -eq "localhost") { 
        $Text_bx.Text = $Computername 
        $Txtbx_action2.Text = "Processes" 
        Format-Processes $Computername 
        $Results_dtgrd.ItemsSource = $Processes 
        } 
    else { 
        if (-not ([string]::IsNullOrEmpty($Computername))) { 
            try { 
                Format-Processes $Computername  $Text_bx.Text = $Computername 
                $Txtbx_action2.Text = "Processes" 
                $Results_dtgrd.ItemsSource = $Processes 
                } 
            catch { 
                $error = [System.Windows.Forms.Messagebox]::Show("$_","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
                } 
            } 
      }  
}

Function Get-Services {
    if (-not ([string]::IsNullOrEmpty($Computername))) { 
        try { 
            Format-Services $Computername 
            $Text_bx.Text = $Computername 
            $Txtbx_action2.Text = "Services" 
            $Results_dtgrd.ItemsSource = $Services 
            } 
        catch { 
            $error = [System.Windows.Forms.Messagebox]::Show("$_","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
                 } 
         }
}

function Get-Disks {
if (-not ([string]::IsNullOrEmpty($Computername))) { 
        try { 
            Format-Disks $Computername 
            $Text_bx.Text = $Computername 
            $Txtbx_action2.Text = "Disks" 
            $Results_dtgrd.ItemsSource = $Disks 
            } 
        catch { 
            $error = [System.Windows.Forms.Messagebox]::Show("$_","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
                 } 
         }
}

function Format-Processes {
        if ($Computername -eq "localhost") { $Procstmp = Get-Process } else { $Procstmp = Get-Process -Computername $Computername }
        $script:Processes = foreach ($Proc in $Procstmp) {
            [pscustomobject]@{
                "Process Name"         = $Proc.Name
                "Virtual Memory(MB)"   = [math]::round(($Proc.VM / 1MB))
                "Physical Memory(MB)"  = [math]::round(($Proc.PM) / 1MB)
                "Non-Paged Memory(KB)" = [math]::round(($Proc.NPM) / 1KB)
                "Handles"              = ($Proc).Handles
                "Path"                 = $Proc.Path
            }
      }        
}

Function Format-Services {
        $Servicestmp = Get-Service -Computername $Computername
        $script:Services = foreach ($Service in $Servicestmp) {
            [pscustomobject]@{
                "Service Name" = $Service.Name
                "Display Name" = $Service.DisplayName
                "Status"       = $Service.Status
                "Startup Type" = $Service.StartType
                }
        }
}

function Format-Disks {
    $Diskstmp = (Get-WmiObject -class Win32_logicaldisk -Computername $Computername | Where-Object {$_.DriveType -eq "3" -or $_.DriveType -eq "4" -or $_.DriveType -eq "5"})
    $script:Disks = foreach ($disk in $Diskstmp) {
    $drivetype = $disk.DriveType 
    switch($drivetype) {
            "3" { $script:description = "Local Fixed Disk" }
            "4" { $script:description = "Network Disk" }
            "5" { $script:description = "CD-ROM" }
            } 
      
        if ($disk.size -ge 1TB) { $dsize = [math]::round($disk.size /1TB) ; $size = "$dsize TB" }
        if ($disk.size -ge 1GB -and $disk.size -lt 1TB) { $dsize = [math]::round($disk.size /1GB) ; $size = "$dsize GB" }
        if ($disk.size -lt 1GB -and $disk.size -ge 1MB) { $dsize = [math]::round($disk.size /1MB) ; $size = "$dsize MB" }
        if ($disk.size -lt 1MB -and $disk.size -ge 1KB) { $dsize = [math]::round($disk.size /1KB) ; $size = "$dsize KB" }
        if ($disk.size -eq $null) { $size = $null }
        if ($disk.drivetype -eq "5") { $size = $null}
        
        if ($disk.freespace -ge 1TB) { $dfstmp = [math]::round($disk.freespace / 1TB) ; $dfsize = "$dfstmp TB" }
        if ($disk.freespace -ge 1GB -and $disk.freespace -lt 1TB) { $dfstmp = [math]::round($disk.freespace / 1GB) ; $dfsize = "$dfstmp GB" }
        if ($disk.freespace -lt 1GB -and $disk.freespace -ge 1MB) { $dfstmp = [math]::round($disk.freespace / 1MB) ; $dfsize = "$dfstmp MB" }
        if ($disk.freespace -lt 1MB -and $disk.freespace -ge 1KB) { $dfstmp = [math]::round($disk.freespace / 1KB) ; $dfsize = "$dfstmp KB" }
        if ($disk.freespace -eq $null) { $dfsize = $null }
        if ($disk.drivetype -eq "5") { $dfsize = $null }

        if (-not([string]::IsNullOrEmpty($disk.freespace)) -and (-not([string]::IsNullOrEmpty($disk.size)))) { $dfptmp = [math]::round((($disk.freespace / $disk.size) * 100)) }
        $dfp = "$dfptmp %"
        if ($disk.drivetype -eq "5") { $dfp = $null}
                      
        [pscustomobject]@{
        "Drive Letter"     = $disk.DeviceId
        "Description"      = $description
        "Size"             = $size
        "Free Space"       = $dfsize
        "% Free Space"     = $dfp
        "Network Location" = $disk.ProviderName
               }
             
       }
}
$Processes_btn.Add_Click({
    $button = "processes"
    Get-ComputerName $button
})

$Services_btn.Add_Click({
    $button = "services"
    Get-ComputerName $button
})
$Disks_btn.Add_Click({
    $button = "disks"
    Get-Computername $button
})

$Window.ShowDialog() | out-null