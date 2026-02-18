# 📘 Montando um CustomSettings.ini Eficiente

> [!WARNING]
> **AVISO DE DESCONTINUIDADE:** O MDT foi descontinuado e não suporta oficialmente o Windows 11. Este guia serve como referência para a manutenção de ambientes legados. Recomenda-se o planejamento de migração para o Microsoft Intune ou Autopilot.

Este documento tem como objetivo orientar profissionais de TI sobre a estrutura, função e manutenção segura do arquivo `CustomSettings.ini` utilizado no Microsoft Deployment Toolkit (MDT).

## 📑 Sumário
1. [O que é o CustomSettings.ini?](#-o-que-é-o-customsettingsini)
2. [O Arquivo Completo (Referência)](#-o-arquivo-completo-referência)
3. [Entendendo as Lógicas Avançadas](#-entendendo-as-lógicas-avançadas)
4. [Dicionário de Variáveis (Seção Default)](#-dicionário-de-variáveis-seção-default)
5. [Boas Práticas e Segurança](#-boas-práticas-e-segurança)


## 📌 O que é o `CustomSettings.ini`?

O `CustomSettings.ini` é o "cérebro" do MDT. Ele define como os deployments devem se comportar, aplicando regras e parâmetros automaticamente durante a instalação do sistema operacional, aplicativos e configurações personalizadas.

Neste documento, exploraremos um arquivo robusto utilizado em ambiente de produção/testes, repleto de recursos avançados que podem ser adaptados para aprimorar o seu ambiente.


## 📄 O Arquivo completo (referência)

<details>
<summary><b>Clique aqui para expandir e ver o código completo do CustomSettings.ini</b></summary>

```ini
[Settings]
Priority=Init, ByDesktop, ByLaptop, ByVirtual, Default
Properties=MyCustomProperty, ComputerSerialNumber, ComputerTypeName, ComputerPrefix, VMPlatform

[Init]
ComputerSerialNumber=#Right("%SerialNumber%",9)#

[ByLaptop]
Subsection=Laptop-%IsLaptop%

[ByDesktop]
Subsection=Desktop-%IsDesktop%

[ByVirtual]
Subsection=Virtual-%IsVM%

[Virtual-True]
Subsection=VM-%VMPlatform%

[VMPlatform]
VMPlatform=Unknown
VMPlatform=#IfStrIEquals("%Model%", "VMware Virtual Platform") Then "VMware" ElseIfStrIEquals("%Model%", "VirtualBox") Then "VirtualBox" ElseIfStrIEquals("%Model%", "Virtual Machine") Then "Hyper-V" Else "Unknown"#

[VM-VMware]
ComputerTypeName=V
ComputerPrefix=VMW

[VM-VirtualBox]
ComputerTypeName=V
ComputerPrefix=VBX

[VM-Unknown]
ComputerTypeName=V
ComputerPrefix=VMU

[Desktop-True]
ComputerTypeName=D
ComputerPrefix=DSK

[Laptop-True]
ComputerTypeName=L
ComputerPrefix=NTB

[Default]
OSInstall=Y
_SMSTSOrgName=SUPORTE TI
_SMSTSPackageName=%TaskSequenceID% on %OSDComputername%
SkipCapture=YES
SkipAdminPassword=YES
AdminPassword=Teste@123
SkipDeploymentType=YES
SkipProductKey=YES
SkipComputerBackup=YES
SkipBitLocker=YES
SkipComputerName=NO
SkipTaskSequence=NO
SkipUserData=YES
OSDComputerName=%ComputerPrefix%-%ComputerSerialNumber%
SkipPackageDisplay=NO
SkipLocaleSelection=NO
KeyboardLocale=0416:00010416
SkipTimeZone=YES
TimeZone=065
TimeZoneName=E. South America Standard Time
BitsPerPel=32
VRefresh=60
XResolution=1
YResolution=1
SkipSummary=YES
SkipFinalSummary=NO
SLShareDynamicLogging=\\SERVIDOR\deploymentshare$\DeploymentLogs
SLShare=\\SRV-2025-RJ\deploymentshare$\CompletedDeployments
EventService=http://SERVIDOR:9800
WSUSServer=http://SERVIDOR:8530
FinishAction=REBOOT

```

</details>


## 🧠 Entendendo as lógicas avançadas

A seção `[Settings]` define a ordem de prioridade (`Priority=Init, ByDesktop, ByLaptop, ByVirtual, Default`). O MDT lerá essas seções exatamente nesta ordem.

### 1. Inicialização e Serial (Seção `Init`)

Calcula o número de série personalizado:

```ini
ComputerSerialNumber=#Right("%SerialNumber%",9)#

```

> [!TIP]
> **DICA:** Ideal para otimizar ambientes corporativos onde o nome da estação utiliza o Serial Number ou Service Tag (Dell) do equipamento, capturando apenas os últimos 9 caracteres.

### 2. Detecção de Chassi (Laptops e Desktops)

O MDT usa as variáveis nativas `%IsLaptop%` e `%IsDesktop%` para direcionar a configuração. Edite apenas os sufixos se necessário:

```ini
ComputerPrefix=DSK  ; para desktops
ComputerPrefix=NTB  ; para notebooks

```

### 3. Detecção Inteligente de Máquinas Virtuais

O script avalia a variável nativa `%Model%` para descobrir o hypervisor exato e aplicar um prefixo específico:

* **VMware:** Prefixo `VMW`
* **VirtualBox:** Prefixo `VBX`
* **Hyper-V / Outros:** Prefixo `VMU`


## 📖 Dicionário de Variáveis (Seção Default)

A seção `[Default]` contém as configurações aplicadas se nenhuma outra regra se encaixar. Dividimos abaixo por categorias para facilitar a consulta.

### 🔒 Segurança e Senhas

> [!CAUTION]
> **SEGURANÇA DA SENHA LOCAL:**
> EVITE definir a senha de administrador diretamente no arquivo `CustomSettings.ini` (`AdminPassword=Teste@123`). O método mais seguro é configurar essa credencial durante a criação da `Task Sequence`. Mantivemos no script acima apenas para fins didáticos.

### ⚙️ Controle do Assistente (Wizard)

| Variável | Descrição |
| --- | --- |
| `SkipCapture=YES` | Oculta a etapa de captura de imagem. |
| `SkipDeploymentType=YES` | Pula a escolha entre nova instalação ou atualização. |
| `SkipBitLocker=YES` | Ignora a configuração do BitLocker no Wizard. |
| `SkipComputerName=NO` | Permite que o técnico altere o nome da máquina, se necessário. |
| `SkipTaskSequence=NO` | Exibe a tela para escolher qual imagem instalar. |
| `SkipSummary=YES` | Oculta o resumo das configurações *antes* da instalação. |

### 🌍 Regionalização e Tela

| Variável | Descrição |
| --- | --- |
| `KeyboardLocale=0416:00010416` | Layout do teclado para Português Brasil (ABNT2). |
| `TimeZoneName=E. South America Standard Time` | Fuso horário de Brasília. |
| `XResolution=1` / `YResolution=1` | O valor `1` força o sistema a usar a resolução nativa do monitor. |

### 📡 Infraestrutura, Logs e Updates

| Variável | Descrição |
| --- | --- |
| `SLShareDynamicLogging` | Caminho UNC para logs gerados em *tempo real* (`\\SERVIDOR\DeploymentLogs`). |
| `SLShare` | Pasta de destino para os logs finais *após* a instalação. |
| `EventService` | Endereço do serviço (porta 9800) para monitoramento via console do MDT. |
| `WSUSServer` | Define o servidor WSUS local (`http://SERVIDOR:8530`) para baixar atualizações. |
| `FinishAction=REBOOT` | Reinicia automaticamente a máquina após finalizar a Task Sequence. |


## 🔒 Boas Práticas e Segurança

> [!IMPORTANT]
> **REGRAS DE OURO PARA MANUTENÇÃO:**
> 1. **Não altere** variáveis condicionais (`#IfStrIEquals(...)#`) ou sequência de prioridade (`Priority=`) sem aprovação técnica prévia.
> 2. **Faça backup** do arquivo `CustomSettings.ini` original antes de realizar qualquer alteração.
> 3. **Comente o código:** Use `;` para comentar a linha alterada e adicione a data e o seu nome.
> 4. **Teste em VM:** Valide todas as mudanças em um ambiente isolado (Máquina Virtual) antes de atualizar o *Deployment Share* de produção.
