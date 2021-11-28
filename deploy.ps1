# Load the System.Windows.Forms assembly into PowerShell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a new Form object and assign to the variable $Form
$Form = New-Object System.Windows.Forms.Form
$Form.MinimizeBox = $false
$Form.MaximizeBox = $false
$Form.SizeGripStyle = "Hide"
# $Form.ShowInTaskbar = $false
# $Form.StartPosition = "CenterParent"     
$Form.BackColor = "#FFEEEEEE"
$Form.Size = New-Object System.Drawing.Size(500, 500)
# AutoSize ensures the Form size can contain the text
$Form.AutoSize = $true
$Form.AutoSizeMode = "GrowAndShrink"
$Form.Text = "Lighthouse Labs VM  Installer"

$FontFace = New-Object System.Drawing.Font(
  "Comic Sans MS", 14, [System.Drawing.FontStyle]::Regular
)
$Form.Font = $FontFace

# Create a Label object
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "This will deploy a LHL WSL Image on your system"
$Label.AutoSize = $true
$Form.Controls.Add($Label)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Size(10, 150)
$outputBox.Size = New-Object System.Drawing.Size(565, 200)
$outputBox.MultiLine = $True
$outputBox.Scrollbars = "Vertical"
$FontFace = New-Object System.Drawing.Font(
  "Lucida Console", 12, [System.Drawing.FontStyle]::Regular
)
$outputBox.Font = $FontFace

$Form.Controls.Add($OutputBox)

$DeployButton = New-Object System.Windows.Forms.Button
$DeployButton.Location = New-Object System.Drawing.Size(230, 50)
$DeployButton.Size = New-Object System.Drawing.Size(110, 80)
$DeployButton.Text = "Step 2: `r`nDownload VM Image"
$DeployButton.Add_Click( { OnClick } )
$Form.Controls.Add($DeployButton)

$EnableButton = New-Object System.Windows.Forms.Button
$EnableButton.Location = New-Object System.Drawing.Size(40, 50)
$EnableButton.Size = New-Object System.Drawing.Size(110, 80)
$EnableButton.Text = "Step 1: `r`nEnable WSL2"
$EnableButton.Add_Click( { EnableWSL })
$Form.Controls.Add($EnableButton)

$CloseButton1 = New-Object System.Windows.Forms.Button
$CloseButton1.Location = New-Object System.Drawing.Size(40, 50)
$CloseButton1.Size = New-Object System.Drawing.Size(110, 80)
$CloseButton1.Text = "Exit"
$CloseButton1.Add_Click( { $Form.Close() } )

$CloseButton2 = New-Object System.Windows.Forms.Button
$CloseButton2.Location = New-Object System.Drawing.Size(230, 50)
$CloseButton2.Size = New-Object System.Drawing.Size(110, 80)
$CloseButton2.Text = "Exit"
$CloseButton2.Add_Click( { $Form.Close() } )

$started = $false;
$ErrorActionPreference = 'Stop'
$tarFile = "$env:temp\Lighthouse_wsl-v1.2.tar"

function  EnableWSL {
  $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

  $error.Clear()
  # $EnableButton.Enabled = $false
  $DeployButton.Enabled = $false
  $EnableButton.Text = "Running"

  # outputs multi-byte char response
  $ver = ""
  $output1 = Invoke-Expression 'c:\windows\system32\wsl.exe --status'
  foreach ($item in $output1) {
    $nstr = toString($item)
    if ($nstr.length -gt 3) {
      # $match = ($nstr -Match "v.e.r.s.i.o.n.:.\s.5")
      $match = ($nstr -Match "version: 5")
      if ($match) {
        Write-Host  $item
        $outputBox.text += "$nstr`r`n"
        $ver = $item
      }
    }
  }

  Write-Host  "WSL Enabled=$match" 
  if ($match) {
    $msg = "You system already has WSL enabled.  You can proceed to Step 2"
    $outputBox.text += "$msg`r`n"
    $DeployButton.Enabled = $true
    return
  }


  $isAdmin = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  $outputBox.text += "Admin=$isAdmin`r`n`r`n"
  if (!$isAdmin) {
    $msg = "This Part of the process requires PowerShell to be started as Administrator`r`n`r`nPlease run PowerShell as Administrator and re-run"
    $outputBox.text += "$msg`r`n"
 
    $Form.Controls.Remove($EnableButton)
    $Form.Controls.Add($CloseButton1)
    return
  }

  # Download enable WSL cmd file

  $outputBox.text += "Enabling WSL ...`r`n"
  try {
    Invoke-Item 'D:\tmp\enable.cmd'
  }
  catch {
    $outputBox.text += "$out`r`n"
  }

  $outputBox.text += "Code = $LASTEXITCODE`r`n" 

  if (!$error) {
    $EnableButton.Text = "Done!"
    $outputBox.text += " `r`nDone!"
  }
  $outputBox.text += "$error`r`n"
}
function  OnClick {
  if ($started) {
    return
  }
  $started = $true;
  $DeployButton.Enabled = $false
  $DeployButton.Text = "Running"
  Write-Host "started"

  $url = "https://www.dropbox.com/s/ybtx4cn1351z2pr/Lighthouse_wsl-v1.2.zip?dl=1"
  $TempFile = Download($url);
  $ZipFile = "$TempFile.zip"
  if (!$error) {
    Write-Host "Renaming: $ZipFile"
    Rename-Item -Path $TempFile -NewName $ZipFile
  }

  if (!$error) {
    UnPack($ZipFile);
  }

  if ($error) {
    $outputBox.text += " `r`nDeploy Failed with errors"
  }
  else {
    $outputBox.text += " `r`nDone!"
  }

  Cleanup($ZipFile)
  $Form.Controls.Remove($DeployButton)
  $Form.Controls.Add($CloseButton2)
}

function  Download {
  param ($url)

  $TempFile = New-TemporaryFile
  Write-Host "Downloading Archive: $url"
  Write-Host "Writing: $TempFile"
  
  try {
    $outputBox.text += "Downloading Archive ..."
    Invoke-WebRequest $url -OutFile  $TempFile
  }
  catch {
    $outputBox.text += " `r`n$error"  
  }

  return $TempFile 
}

function  UnPack {
  param ($Filename)
  $outputBox.text += " `r`nExtracting Archive ..."
  Write-Host "Unpacking: $Filename"
  
  try {
    Expand-Archive -Force  $Filename  -DestinationPath $env:temp
  }
  catch {
    $outputBox.text += " `r`n$error"  
  }
}




function  Cleanup {
  param ($ZipFile)
  $outputBox.text += " `r`nCleaning up ..."
  Write-Host "Deleting: $ZipFile"
  Remove-Item $ZipFile
  # Remove-Item "$env:temp"

  Write-Host "Deleting: $tarFile"
  Remove-Item $tarFile
}

function toString {
  param ($in)
  $out = "";
  $chars = $in.toCharArray()
  foreach ($char in $chars) {
    if ($char) {
      $out += $char
    }
  }
  return $out;
}

[void] $Form.showDialog()