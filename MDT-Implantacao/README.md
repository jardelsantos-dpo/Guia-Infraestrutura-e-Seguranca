<p align="center">
<img src="../images/em_construcao.png" alt="Repositório em construção" width="60%">
</p>

# 🖥️ MDT - O que é

O Microsoft Deployment Toolkit (MDT) é uma solução da Microsoft que simplifica a implantação automatizada de sistemas operacionais e aplicações. Este espaço foi criado para centralizar recursos práticos usados em ambientes de **Service Desk**, **infraestrutura de TI** e **Segurança da Informação**, com foco em **padronização, eficiência e automação** do processo de deployment.

> 🎯 **Ideal para:** Equipes de suporte, administradores de rede e profissionais que desejam reduzir erros manuais, acelerar implantações e garantir consistência nos ambientes corporativos.

> [!CAUTION]
> **AVISO DE DESCONTINUIDADE E SEGURANÇA**
> conforme comunicado oficial da Microsoft, o Microsoft Deployment Toolkit (MDT) foi descontinuado em janeiro de 2026.
> * O MDT **não é homologado** para Windows 11 ou versões posteriores.
> * A utilização contínua desta ferramenta pode expor o ambiente a vulnerabilidades não corrigidas.
> * A Microsoft recomenda a transição para soluções modernas como **Microsoft Intune** ou **Windows Autopilot**, no entanto, ambientes que já utilizam a ferramenta poderão mantê-la em funcionamento até que consigam realizar efetivamente a transição para as soluções da Microsoft ou para alternativas open source, como o **OPSI** ou **FOG Project**.
> 
> 
> **Link Oficial:** [Documentação de Suporte do MDT (Microsoft)](https://learn.microsoft.com/pt-br/troubleshoot/mem/configmgr/mdt/mdt-retirement)

## 📋 Requisitos Básicos

* MDT instalado e configurado no servidor.
* Windows ADK compatível com sua versão do Sistema Operacional.
* Conhecimento básico em *Deployment Workbench*.
* Permissões administrativas no Active Directory e no Servidor de Arquivos.

## 📄 Guia Rápido: O arquivo CustomSettings.ini

O `CustomSettings.ini` é o "cérebro" do MDT. Ele define as regras de priorização e automatiza as etapas do assistente de instalação, permitindo a padronização do ambiente. Por exemplo:

### 1. Estrutura de Prioridade

As configurações são aplicadas seguindo esta ordem de precedência:

* **Init**: Inicializa o número de série do hardware.
* **ByDesktop, ByLaptop, ByVirtual**: Identifica o tipo de chassi.
* **Default**: Aplica as configurações gerais do ambiente.

### 2. Lógica de Nomenclatura Automática

Para evitar conflitos e padronizar o inventário, o nome do computador (**OSDComputerName**) é gerado automaticamente combinando um prefixo de hardware com o número de série.

| Tipo de Dispositivo | Variável de Gatilho | Prefixo (`ComputerPrefix`) | ID (`ComputerTypeName`) |
| --- | --- | --- | --- |
| **Laptop** | `%IsLaptop%` | `NTB` | `L` |
| **Desktop** | `%IsDesktop%` | `DSK` | `D` |
| **Virtual** | `%IsVM%` | `VM` | `V` |

> **Exemplo Prático:** Um notebook com o serial `123456789` receberá automaticamente o nome `NTB-123456789`.

### 3. Automação e Monitoramento (Default)

Para agilizar o processo de suporte, diversas telas do assistente são suprimidas:

* **Acesso:** Senha de Administrador local pré-definida (deve ser alterada via GPO/LAPS em produção).
* **Regionalização:** Teclado configurado em Português (Brasil) ABNT2 e Fuso Horário de Brasília.
* **Ação Final:** O computador realiza um **REBOOT** automático ao finalizar a Task Sequence.
* **Logs Centralizados:** Os logs de instalação são enviados em tempo real para `\\SERVIDOR\deploymentshare$\DeploymentLogs` para facilitar o diagnóstico remoto.

## 📚 Índice de Conteúdos e Tutoriais

Explore os documentos abaixo para aprofundar seus conhecimentos nas configurações do MDT:

### 🚀 Deploy & Otimização

* [Monte um CustomSettings.ini eficiente](./docs/custom-settings-ini.md) *(Versão Completa)*
* [Configuração de Drivers por Modelo e Fabricante]()
* [Instalação Silenciosa de Aplicativos via MDT]()
* [Definir Papel de Parede durante o Deploy]()
* [Criação de Imagem Personalizada (Capture)]()

### 🔐 Segurança e Compliance

* [Aplicação de Políticas de Segurança Pós-Deploy]()
* [Ativação Automática do BitLocker]()

### 📦 Integrações Avançadas

* [MDT + WSUS]()
* [MDT + Intune (Auto-enroll)]()
* [Deploy remoto via PXE + VPN]()

### 🛠 Suporte ao Service Desk

* [Fluxo Visual de Deployment para Treinamento]()
* [Checklist Pré e Pós-Deploy]()
* [Criação de Usuários Locais com Permissões]()

> [!IMPORTANT]
> Qualquer alteração nos arquivos de configuração do MDT deve ser testada rigorosamente em um ambiente de homologação (VMs) antes de ser replicada para o *Deployment Share* de produção.

