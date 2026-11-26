<#
.SYNOPSIS
    Graphical front end for Microsoft's Win32 Content Prep Tool (IntuneWinAppUtil.exe).

.DESCRIPTION
    Pick (or drag and drop) a source folder, the setup file inside it and an
    output folder, then press Convert to build the .intunewin package for
    Microsoft Intune. Works as a .ps1 and when compiled to an .exe with PS2EXE.
    IntuneWinAppUtil.exe must sit in the same folder as this script or EXE.

.NOTES
    Author: Mohammed AlAttar · https://github.com/mozalattar
    Requires: Windows PowerShell 5.1 (recommended) or PowerShell 7 on Windows.
#>

# --- WinForms needs a single-threaded apartment (STA) ---
# A compiled PS2EXE build already runs in STA; only a .ps1 started from an MTA host is relaunched.
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA' -and $PSCommandPath) {
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$PSCommandPath`""
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Get base folder (works for .ps1 AND PS2EXE .exe) ---
function Get-BaseDir {
    # 1) When compiled to EXE (PS2EXE), this is the most reliable
    try {
        $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        if ($exePath -and (Test-Path $exePath)) {
            $d = Split-Path -Parent $exePath
            if ($d) { return $d }
        }
    } catch {}

    # 2) When running as a script
    if ($PSScriptRoot) { return $PSScriptRoot }

    # 3) Fallback
    try {
        $p = $MyInvocation.MyCommand.Path
        if ($p) { return (Split-Path -Parent $p) }
    } catch {}

    return $null
}

$BaseDir = Get-BaseDir
if (-not $BaseDir) {
    [System.Windows.Forms.MessageBox]::Show("Cannot determine application folder.","Error") | Out-Null
    exit
}

# --- Locate IntuneWinAppUtil.exe next to GUI ---
$IntuneUtil = Join-Path $BaseDir "IntuneWinAppUtil.exe"
if (!(Test-Path $IntuneUtil)) {
    [System.Windows.Forms.MessageBox]::Show(
        "IntuneWinAppUtil.exe not found in:`n$BaseDir`n`nPlace IntuneWinAppUtil.exe next to the GUI EXE/PS1.",
        "Missing IntuneWinAppUtil.exe",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit
}

# -------------------- UI --------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "IntuneWinAppUtil GUI"
$form.Size = New-Object System.Drawing.Size(560,270)
$form.StartPosition = "CenterScreen"

# Source Folder
$sourceLabel = New-Object System.Windows.Forms.Label
$sourceLabel.Text = "Source Folder:"
$sourceLabel.Location = New-Object System.Drawing.Point(10,20)
$sourceLabel.Size = New-Object System.Drawing.Size(110,20)
$form.Controls.Add($sourceLabel)

$sourceTextBox = New-Object System.Windows.Forms.TextBox
$sourceTextBox.Location = New-Object System.Drawing.Point(130,20)
$sourceTextBox.Size = New-Object System.Drawing.Size(310,20)
$form.Controls.Add($sourceTextBox)

$sourceButton = New-Object System.Windows.Forms.Button
$sourceButton.Text = "Browse..."
$sourceButton.Location = New-Object System.Drawing.Point(450,18)
$sourceButton.Size = New-Object System.Drawing.Size(85,23)
$form.Controls.Add($sourceButton)

$sourceButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $sourceTextBox.Text = $folderBrowser.SelectedPath
    }
})

# Setup File
$setupLabel = New-Object System.Windows.Forms.Label
$setupLabel.Text = "Setup File:"
$setupLabel.Location = New-Object System.Drawing.Point(10,60)
$setupLabel.Size = New-Object System.Drawing.Size(110,20)
$form.Controls.Add($setupLabel)

$setupTextBox = New-Object System.Windows.Forms.TextBox
$setupTextBox.Location = New-Object System.Drawing.Point(130,60)
$setupTextBox.Size = New-Object System.Drawing.Size(310,20)
$form.Controls.Add($setupTextBox)

$setupButton = New-Object System.Windows.Forms.Button
$setupButton.Text = "Browse..."
$setupButton.Location = New-Object System.Drawing.Point(450,58)
$setupButton.Size = New-Object System.Drawing.Size(85,23)
$form.Controls.Add($setupButton)

$setupButton.Add_Click({
    $fileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    $fileBrowser.Filter = "Installer/Executable (*.exe;*.msi;*.bat;*.cmd;*.ps1)|*.exe;*.msi;*.bat;*.cmd;*.ps1|All Files (*.*)|*.*"
    if (Test-Path $sourceTextBox.Text) { $fileBrowser.InitialDirectory = $sourceTextBox.Text }
    if ($fileBrowser.ShowDialog() -eq "OK") {
        $setupTextBox.Text = $fileBrowser.FileName
    }
})

# Output Folder
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = "Output Folder:"
$outputLabel.Location = New-Object System.Drawing.Point(10,100)
$outputLabel.Size = New-Object System.Drawing.Size(110,20)
$form.Controls.Add($outputLabel)

$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(130,100)
$outputTextBox.Size = New-Object System.Drawing.Size(310,20)
$form.Controls.Add($outputTextBox)

$outputButton = New-Object System.Windows.Forms.Button
$outputButton.Text = "Browse..."
$outputButton.Location = New-Object System.Drawing.Point(450,98)
$outputButton.Size = New-Object System.Drawing.Size(85,23)
$form.Controls.Add($outputButton)

$outputButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $outputTextBox.Text = $folderBrowser.SelectedPath
    }
})

# Convert Button
$convertButton = New-Object System.Windows.Forms.Button
$convertButton.Text = "Convert"
$convertButton.Location = New-Object System.Drawing.Point(220,145)
$convertButton.Size = New-Object System.Drawing.Size(120,34)
$form.Controls.Add($convertButton)

# Status
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = ""
$statusLabel.Location = New-Object System.Drawing.Point(10,195)
$statusLabel.Size = New-Object System.Drawing.Size(525,40)
$form.Controls.Add($statusLabel)

# --- Drag & Drop (correct) ---
foreach ($tb in @($sourceTextBox,$setupTextBox,$outputTextBox)) {
    $tb.AllowDrop = $true
    $tb.Add_DragEnter({
        if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) { $_.Effect = 'Copy' }
        else { $_.Effect = 'None' }
    })
}

$sourceTextBox.Add_DragDrop({
    $items = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($items -and (Test-Path $items[0]) -and (Get-Item $items[0]).PSIsContainer) {
        $sourceTextBox.Text = $items[0]
    }
})

$setupTextBox.Add_DragDrop({
    $items = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($items -and (Test-Path $items[0]) -and -not (Get-Item $items[0]).PSIsContainer) {
        $setupTextBox.Text = $items[0]
    }
})

$outputTextBox.Add_DragDrop({
    $items = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($items -and (Test-Path $items[0]) -and (Get-Item $items[0]).PSIsContainer) {
        $outputTextBox.Text = $items[0]
    }
})

# -------------------- Convert logic --------------------
$convertButton.Add_Click({
    # A trailing backslash would escape the closing quote on the command line, so drop it
    $sourceFolder = $sourceTextBox.Text.Trim().TrimEnd('\')
    $setupPath    = $setupTextBox.Text.Trim()
    $outputFolder = $outputTextBox.Text.Trim().TrimEnd('\')

    if (!(Test-Path $sourceFolder)) {
        [System.Windows.Forms.MessageBox]::Show("Source folder not found.","Error") | Out-Null
        return
    }
    if (!(Test-Path $setupPath)) {
        [System.Windows.Forms.MessageBox]::Show("Setup file not found.","Error") | Out-Null
        return
    }
    if (!(Test-Path $outputFolder)) {
        [System.Windows.Forms.MessageBox]::Show("Output folder not found.","Error") | Out-Null
        return
    }

    # IntuneWinAppUtil requires setup file to be inside source folder (and -s must be leaf name)
    $setupLeaf = Split-Path -Leaf $setupPath
    $setupInsideSource = Join-Path $sourceFolder $setupLeaf

    if (!(Test-Path $setupInsideSource)) {
        [System.Windows.Forms.MessageBox]::Show(
            "The setup file must be inside the Source Folder for IntuneWinAppUtil.`n`nMove/copy:`n$setupPath`ninto:`n$sourceFolder`n`nThen select it again.",
            "Invalid setup location",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    # Each path is quoted so folders with spaces work; -q runs the tool without prompts
    $toolArgs = "-c `"$sourceFolder`" -s `"$setupLeaf`" -o `"$outputFolder`" -q"
    $expected = Join-Path $outputFolder ([System.IO.Path]::GetFileNameWithoutExtension($setupLeaf) + '.intunewin')

    $statusLabel.Text = "Running: IntuneWinAppUtil.exe $toolArgs"
    $convertButton.Enabled = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $form.Refresh()

    try {
        $p = Start-Process -FilePath $IntuneUtil -ArgumentList $toolArgs -WindowStyle Hidden -Wait -PassThru
        if ($p.ExitCode -eq 0) {
            $statusLabel.Text = "Completed: $expected"
            [System.Windows.Forms.MessageBox]::Show("Package created:`n$expected", "Done",
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        } else {
            $statusLabel.Text = "Failed. Exit code: $($p.ExitCode)"
            [System.Windows.Forms.MessageBox]::Show("Conversion failed. Exit code: $($p.ExitCode)", "Failed",
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    } catch {
        $statusLabel.Text = "Failed: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Failed: $($_.Exception.Message)", "Failed",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } finally {
        $convertButton.Enabled = $true
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
})

# Show
[void]$form.ShowDialog()
