Add-Type -AssemblyName PresentationFramework
# Inicialização turbo
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

[System.GC]::Collect()

if ($Host.Runspace.ApartmentState -ne "STA") {
    powershell -STA -File $PSCommandPath
    exit
}

# -------------------------------------------------------------------
# BLOCO DE COLETA DE DADOS (Rodará em Background)
# -------------------------------------------------------------------
$DataCollectionScript = {
    $computerSystem = Get-CimInstance Win32_ComputerSystem
    $operatingSystem = Get-CimInstance Win32_OperatingSystem
    $processor = Get-CimInstance Win32_Processor
    $bios = Get-CimInstance Win32_BIOS
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

	# Busca o usuário logado de forma mais robusta (funciona em RDP)
	$loggedUser = (Get-Process -Name explorer -ErrorAction SilentlyContinue | 
				   Select-Object -ExpandProperty IncludeUserName -First 1 -ErrorAction SilentlyContinue)

	if (-not $loggedUser) {
		# Fallback caso o IncludeUserName falhe (requer privilégios)
		$loggedUser = (tasklist /FI "IMAGENAME eq explorer.exe" /FO LIST /V | 
					   Select-String "Nome de Usuário:" | ForEach-Object { $_.ToString().Split(":")[1].Trim() })
	}

	if (-not $loggedUser) {
		# Última tentativa pelo Win32_ComputerSystem original
		$loggedUser = $computerSystem.UserName
	}

	# Limpa o domínio (ex: DOMINIO\usuario vira apenas usuario)
	$currentUserClean = ($loggedUser -split '\\')[-1]


    $net = Get-NetIPConfiguration |
        Where-Object {
            $_.IPv4DefaultGateway -ne $null -and
            $_.NetAdapter.Status -eq "Up"
        } |
        Select-Object -First 1

    # Identificação de VPN (Baseado em Nomes Comuns de Adaptadores VPN)
    $isVpn = $false
    if ($net) {
        $adapterDesc = $net.NetAdapter.InterfaceDescription
        $adapterAlias = $net.NetAdapter.InterfaceAlias
        if ($adapterDesc -match "Cisco|Fortinet|Palo Alto|GlobalProtect|WireGuard|OpenVPN|TAP-Windows" -or $adapterAlias -match "VPN") {
            $isVpn = $true
        }
    }

	# ===== DISCO AVANÇADO (CORRIGIDO PARA NVMe) =====
		try {
			# Obtém o disco físico e as propriedades de barramento
			$physical = Get-PhysicalDisk | Select-Object -First 1
			
			# Primeiro, verificamos o protocolo. Se for NVMe, não importa o MediaType.
			if ($physical.BusType -eq "NVMe") {
				$diskType = "NVMe"
			}
			elseif ($physical.MediaType -eq "SSD") {
				$diskType = "SSD"
			}
			elseif ($physical.MediaType -eq "HDD") {
				$diskType = "HDD"
			}
			else {
				$diskType = "Desconhecido"
			}

			$diskHealth = if($physical.HealthStatus -eq "Healthy"){ "Saudável" }
						  elseif($physical.HealthStatus){ $physical.HealthStatus }
						  else{ "Indisponível" }
		} catch {
			$diskType = "Erro na coleta"
			$diskHealth = "Indisponível"
		}

    # Memória
    $totalMemoryMB = [math]::Round($computerSystem.TotalPhysicalMemory / 1MB, 0)
    $totalMemoryGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 1)

    # Rede
    $ipAddress = if ($net) { $net.IPv4Address.IPAddress } else { "Não disponível" }
    $macAddress = if ($net) { $net.NetAdapter.MacAddress } else { "Não disponível" }

    # Disco
    $diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
    $diskTotalGB = [math]::Round($disk.Size / 1GB, 1)

    # Bateria REAL
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    $batteryPercent = -1
    $batteryDegraded = $false

    if (!$battery) {
        $batteryStatus = "N/A (Desktop)"
    } else {
        $batteryPercent = $battery.EstimatedChargeRemaining
        $wear = 100 - $batteryPercent
        $batteryDegraded = $wear -gt 60

        if ($batteryDegraded) {
            $batteryStatus = "$($batteryPercent)% - Degradada"
        } else {
            $batteryStatus = "$($batteryPercent)%"
        }
    }

    $bootDate = $operatingSystem.LastBootUpTime
	# para testar a lógica de cores de reinicialização, comente a linha acima e descomente a linha abaixo
	#$bootDate = (Get-Date).AddDays(-12)
    $uptimeSpan = (Get-Date) - $bootDate
	$daysSinceBoot = ((Get-Date) - $bootDate).Days
	

    # Score de saúde
    $score = 100
    $isSSD = ($diskType -eq "SSD" -or $diskType -eq "NVMe")
    if (!$isSSD) { $score -= 20 }
    if ($batteryDegraded) { $score -= 15 }

    $uptimeDays = ((Get-Date) - $operatingSystem.LastBootUpTime).Days
    if ($uptimeDays -gt 7) { $score -= 10 }
    if ($totalMemoryGB -lt 8) { $score -= 10 }
    if ($diskFreeGB -lt 20) { $score -= 10 }

    if ($score -ge 90) { $health = "Excelente" }
    elseif ($score -ge 75) { $health = "Bom" }
    elseif ($score -ge 60) { $health = "Atenção" }
    else { $health = "Crítico" }

    # Build Windows
    $buildNumber = [int]$operatingSystem.BuildNumber
    $windowsVersion = if ($buildNumber -ge 26300) { "26H1/26H2" }
    elseif ($buildNumber -ge 26200) { "25H2" }
    elseif ($buildNumber -ge 26100) { "24H2" }
    elseif ($buildNumber -ge 22631) { "23H2" }
    elseif ($buildNumber -ge 22621) { "22H2" }
    elseif ($buildNumber -ge 19045) { "10 22H2" }
    else { "Build $buildNumber" }

    $lastBootUpTimeFormatted = $operatingSystem.LastBootUpTime.ToString("dd/MM/yyyy HH:mm:ss")


    return [PSCustomObject]@{
        ComputerName      = $computerSystem.Name
        Model             = $computerSystem.Model
        CurrentUser       = $currentUserClean
        TotalMemoryMB     = $totalMemoryMB
        TotalMemoryGB     = $totalMemoryGB
        IPAddress         = $ipAddress
        MACAddress        = $macAddress
        IsVPN             = $isVpn
        CPU               = $processor.Name.Trim()
        Cores             = $processor.NumberOfCores
        OS                = "$($operatingSystem.Caption) - $($operatingSystem.Version) ($buildNumber) - $windowsVersion"
        LastBootUpTime    = $lastBootUpTimeFormatted
        DaysSinceBoot     = $daysSinceBoot # Nova propriedade para controle da UI
        SerialNumber      = $bios.SerialNumber
        DiskInfo          = "$diskFreeGB GB livres de $diskTotalGB GB"
        DiskType          = $diskType
        DiskHealth        = $diskHealth
        Battery           = $batteryStatus
        BatteryPercent    = $batteryPercent
        BatteryDegraded   = $batteryDegraded
        HealthScore       = $score
        HealthStatus      = $health
    }
}

# -------------------------------------------------------------------
# FUNÇÃO PARA GERAR O TEMPLATE DO CHAMADO
# -------------------------------------------------------------------
function New-ITSMTemplate {
    param($info)
    @"
INFORMAÇÕES DO EQUIPAMENTO
----------------------------------------
Nome do Computador : $($info.ComputerName)
Usuário Atual      : $($info.CurrentUser)
Endereço IP        : $($info.IPAddress)
Endereço MAC       : $($info.MACAddress)

Modelo             : $($info.Model)
Serial             : $($info.SerialNumber)

Processador        : $($info.CPU) ($($info.Cores) Cores)
Memória            : $($info.TotalMemoryGB) GB

Disco              : $($info.DiskInfo)
Tipo do Disco      : $($info.DiskType)
Saúde do Disco     : $($info.DiskHealth)

Sistema Operacional: $($info.OS)
Última Reinicializ.: $($info.LastBootUpTime)

Score de Saúde     : $($info.HealthScore) — $($info.HealthStatus)
----------------------------------------
DESCREVA O PROBLEMA ABAIXO:
"@
}

# -------------------------------------------------------------------
# TELA PRINCIPAL (WPF)
# -------------------------------------------------------------------
function Show-SystemInfo {

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Suporte Técnico - Informações do Sistema"
        WindowStartupLocation="CenterScreen"
        SizeToContent="WidthAndHeight"
        ResizeMode="CanResize"
        Background="#F5F5F5">
    <ScrollViewer VerticalScrollBarVisibility="Auto">
        <Grid Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

			<StackPanel Grid.Row="0" HorizontalAlignment="Center">
                <Image Name="LogoImage" MaxWidth="500" MaxHeight="150" 
                       Stretch="Uniform" Margin="0,0,0,10" 
                       Visibility="Collapsed"/>
                
                <TextBlock Name="LoadingText" Text="Aguarde, coletando informações do sistema..." 
                           Foreground="#0078D4" FontWeight="Bold" FontSize="16" 
                           HorizontalAlignment="Center" Margin="0,0,0,15" Visibility="Visible"/>
            </StackPanel>

            <StackPanel Grid.Row="1" MinWidth="450">
                <UniformGrid Columns="2">
                    <StackPanel Margin="5"><TextBlock Text="Nome do Computador" FontWeight="Bold" Foreground="#555"/><TextBlock Name="ComputerNameText" FontSize="14" Text="Aguarde..."/></StackPanel>
                    
                    <StackPanel Margin="5">
                        <TextBlock Text="Endereço IP" FontWeight="Bold" Foreground="#555"/>
                        <Border Name="IPAddressBorder" CornerRadius="3" Padding="2,0">
                            <TextBlock Name="IPAddressText" FontSize="14" Text="Aguarde..."/>
                        </Border>
                    </StackPanel>
                    
                    <StackPanel Margin="5"><TextBlock Text="Usuário Atual" FontWeight="Bold" Foreground="#555"/><TextBlock Name="CurrentUserText" FontSize="14" Text="Aguarde..."/></StackPanel>
                    <StackPanel Margin="5"><TextBlock Text="Modelo do Equipamento" FontWeight="Bold" Foreground="#555"/><TextBlock Name="ModelText" FontSize="14" Text="Aguarde..."/></StackPanel>
                    <StackPanel Margin="5"><TextBlock Text="Service Tag" FontWeight="Bold" Foreground="#555"/><TextBlock Name="SerialNumberText" FontSize="14" Text="Aguarde..."/></StackPanel>
                    <StackPanel Margin="5"><TextBlock Text="Memória Total" FontWeight="Bold" Foreground="#555"/><TextBlock Name="MemoryText" FontSize="14" Text="Aguarde..."/></StackPanel>
                    <StackPanel Margin="5"><TextBlock Text="Espaço em Disco" FontWeight="Bold" Foreground="#555"/><TextBlock Name="DiskText" FontSize="14" Text="Aguarde..."/></StackPanel>
                    <StackPanel Margin="5"><TextBlock Text="Tipo de Disco" FontWeight="Bold" Foreground="#555"/><TextBlock Name="TypeDiskText" FontSize="14" Text="Aguarde..."/></StackPanel>
                    <StackPanel Margin="5"><TextBlock Text="Saúde do Disco" FontWeight="Bold" Foreground="#555"/><TextBlock Name="DiskHealthText" FontSize="14" Text="Aguarde..."/></StackPanel>
                    <StackPanel Margin="5"><TextBlock Text="Status Bateria" FontWeight="Bold" Foreground="#555"/><TextBlock Name="BatteryText" FontSize="14" Text="Aguarde..."/></StackPanel>
                </UniformGrid>

                <Separator Margin="0,10"/>

                <TextBlock Text="Processador" FontWeight="Bold" Foreground="#555"/>
                <TextBlock Name="CPUText" Margin="0,0,0,10" TextWrapping="Wrap" Text="Aguarde..."/>

                <TextBlock Text="Endereço MAC" FontWeight="Bold" Foreground="#555"/>
                <TextBlock Name="MACAddressText" Margin="0,0,0,10" Text="Aguarde..."/>

                <TextBlock Text="Sistema Operacional" FontWeight="Bold" Foreground="#555"/>
                <TextBlock Name="OSText" Margin="0,0,0,10" TextWrapping="Wrap" Text="Aguarde..."/>

                <TextBlock Text="Última Reinicialização" FontWeight="Bold" Foreground="#555"/>
                <TextBlock Name="LastBootUpTimeTextBlock" Margin="0,0,0,10" Text="Aguarde..."/>
            </StackPanel>

            <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,20,0,0">
                <Button Name="CopyData" Content="Copiar para Chamado" Padding="10,5" Margin="5" IsEnabled="False"/>
                <Button Name="SendEmail" Content="Enviar por E-mail" Padding="10,5" Margin="5" Background="#0078D4" Foreground="White" IsEnabled="False"/>
                <Button Name="CloseWindow" Content="Fechar Janela" Padding="10,5" Margin="5"/>
            </StackPanel>
        </Grid>
    </ScrollViewer>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
	$iconPath = "$env:ProgramData\InfoPC\support-2.ico"
    if (Test-Path $iconPath) {
        $iconUri = New-Object System.Uri("file:///$iconPath")
        $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create($iconUri)
    } else {
        Write-Warning "Ícone não encontrado em $iconPath"
    }

    # Logo (Caminho padrão do seu script original)
	$imagePath = "$env:ProgramData\InfoPC\logo.webp" # Altere a imagem para a logo da sua empresa
	
	if (Test-Path $imagePath) {
		try {
			$logo = $window.FindName("LogoImage")
			$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
			$bitmap.BeginInit()
			$bitmap.UriSource = [System.Uri]::new($imagePath)
			$bitmap.EndInit()
			$logo.Source = $bitmap
			$logo.Visibility = "Visible"
		} catch {
			Write-Warning "Não foi possível carregar a imagem WebP. Verifique se o codec está instalado."
		}
	}
	
	
	
    if (Test-Path $imagePath) {
        $logo = $window.FindName("LogoImage")
        $logo.Source = [System.Windows.Media.Imaging.BitmapImage]::new((New-Object System.Uri($imagePath)))
        $logo.Visibility = "Visible"
    }
    
    # Variável para armazenar os dados no escopo da janela quando o background job terminar
    $script:SystemData = $null

    # -------------------------------------------------------------------
    # INICIALIZAÇÃO ASSÍNCRONA DA COLETA DE DADOS (RUNSPACE)
    # -------------------------------------------------------------------
    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "ReuseThread"
    $Runspace.Open()

    $PowerShellJob = [powershell]::Create().AddScript($DataCollectionScript)
    $PowerShellJob.Runspace = $Runspace
    $AsyncHandle = $PowerShellJob.BeginInvoke()

    # -------------------------------------------------------------------
    # MONITORAMENTO DO TRABALHO (TIMER NO DISPATCHER DA UI)
    # -------------------------------------------------------------------
    $Timer = New-Object System.Windows.Threading.DispatcherTimer
    $Timer.Interval = [TimeSpan]::FromMilliseconds(500)
    
    $Timer.Add_Tick({
        if ($PowerShellJob.InvocationStateInfo.State -eq 'Completed') {
            $Timer.Stop()
			         
            # Recupera os dados coletados no Runspace
            $script:SystemData = $PowerShellJob.EndInvoke($AsyncHandle)[0]
            
            # Limpa memória e fecha runspace
            $PowerShellJob.Dispose()
            $Runspace.Close()

            # --- ATUALIZA A UI ---
            $window.FindName("LoadingText").Visibility = "Collapsed"

            $window.FindName("ComputerNameText").Text = $script:SystemData.ComputerName
            $window.FindName("CurrentUserText").Text  = $script:SystemData.CurrentUser
            $window.FindName("ModelText").Text        = $script:SystemData.Model
            $window.FindName("SerialNumberText").Text = $script:SystemData.SerialNumber
            $window.FindName("MemoryText").Text       = "$($script:SystemData.TotalMemoryGB) GB ($($script:SystemData.TotalMemoryMB) MB)"
            $window.FindName("DiskText").Text         = $script:SystemData.DiskInfo
            $window.FindName("TypeDiskText").Text     = $script:SystemData.DiskType
            $window.FindName("CPUText").Text          = "$($script:SystemData.CPU) ($($script:SystemData.Cores) Cores)"
            $window.FindName("MACAddressText").Text   = $script:SystemData.MACAddress
            $window.FindName("OSText").Text           = $script:SystemData.OS
            $window.FindName("LastBootUpTimeTextBlock").Text = $script:SystemData.LastBootUpTime
			# --- LÓGICA DE CORES: ÚLTIMA REINICIALIZAÇÃO ---
            $bootTextCtrl = $window.FindName("LastBootUpTimeTextBlock")
            $bootTextCtrl.Text = "$($script:SystemData.LastBootUpTime) ($($script:SystemData.DaysSinceBoot) dias atrás)"

            if ($script:SystemData.DaysSinceBoot -gt 10) {
                $bootTextCtrl.Foreground = "Red"
                $bootTextCtrl.FontWeight = "Bold"
            } else {
                $bootTextCtrl.Foreground = "Black"
                $bootTextCtrl.FontWeight = "Normal"
            }


            # --- LÓGICA DE CORES: REDE / IP ---
            $ipText = $window.FindName("IPAddressText")
            $ipBorder = $window.FindName("IPAddressBorder")
            $ipText.Text = $script:SystemData.IPAddress

            if ($script:SystemData.IPAddress -eq "Não disponível") {
                $ipText.Foreground = "Red"
                $ipBorder.Background = "Transparent"
            } elseif ($script:SystemData.IsVPN) {
                $ipText.Foreground = "White"
                $ipBorder.Background = "ForestGreen"
            } else {
                $ipText.Foreground = "Blue"
                $ipBorder.Background = "Transparent"
            }

            # --- LÓGICA DE CORES: SAÚDE DO DISCO ---
            $diskHealthCtrl = $window.FindName("DiskHealthText")
            $diskHealthCtrl.Text = $script:SystemData.DiskHealth
            
            if ($script:SystemData.DiskHealth -eq "Saudável") {
                $diskHealthCtrl.Foreground = "ForestGreen"
            } elseif ($script:SystemData.DiskHealth -match "Atenção|Warning") {
                $diskHealthCtrl.Foreground = "Goldenrod" # Amarelo escuro (melhor leitura)
            } else {
                $diskHealthCtrl.Foreground = "Red"
            }

            # --- LÓGICA DE CORES: BATERIA ---
            $batteryCtrl = $window.FindName("BatteryText")
            $batteryCtrl.Text = $script:SystemData.Battery
            
            if ($script:SystemData.BatteryPercent -ne -1) {
                if ($script:SystemData.BatteryPercent -ge 50 -and -not $script:SystemData.BatteryDegraded) {
                    $batteryCtrl.Foreground = "ForestGreen"
                } elseif ($script:SystemData.BatteryPercent -ge 20 -or $script:SystemData.BatteryDegraded) {
                    $batteryCtrl.Foreground = "Goldenrod"
                } else {
                    $batteryCtrl.Foreground = "Red"
                }
            } else {
                $batteryCtrl.Foreground = "Black" # Desktop
            }

            # Habilita os botões agora que temos os dados
            $window.FindName("CopyData").IsEnabled = $true
            $window.FindName("SendEmail").IsEnabled = $true
        }
    })
    
    # Inicia o monitoramento e carrega a janela (ela abrirá instantaneamente agora)
    $Timer.Start()

    $window.FindName("CloseWindow").Add_Click({ $window.Close() })

    # BOTÃO COPIAR
    $window.FindName("CopyData").Add_Click({
        if ($null -ne $script:SystemData) {
            $template = New-ITSMTemplate $script:SystemData
            [System.Windows.Clipboard]::SetText($template)
            [System.Windows.MessageBox]::Show("Informações copiadas com sucesso!","Suporte Técnico")
        }
    })

    # BOTÃO EMAIL
    $window.FindName("SendEmail").Add_Click({
        if ($null -ne $script:SystemData) {
            $bodyText = New-ITSMTemplate $script:SystemData
            $subject = "Suporte - $($script:SystemData.ComputerName)"
            $mailto = "mailto:helpdesk@teste.com?subject=$([uri]::EscapeDataString($subject))&body=$([uri]::EscapeDataString($bodyText))"
            Start-Process $mailto
        }
    })

    $window.ShowDialog() | Out-Null
}

Show-SystemInfo
