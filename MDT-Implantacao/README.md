# 🖥️ MDT - Implantação Automatizada

Esta seção contém a documentação e os arquivos de configuração para o **Microsoft Deployment Toolkit (MDT)**. O foco principal é a automação do processo de deploy, garantindo que todos os dispositivos da organização sigam o mesmo padrão de configuração.

> [!CAUTION]
> **AVISO DE DESCONTINUIDADE E SEGURANÇA**
> conforme comunicado oficial da Microsoft, o Microsoft Deployment Toolkit (MDT) foi descontinuado em janeiro de 2026.
> * O MDT **não é homologado** para Windows 11 ou versões posteriores.
> * A utilização contínua desta ferramenta pode expor o ambiente a vulnerabilidades não corrigidas.
> * A Microsoft recomenda a transição para soluções modernas como **Microsoft Intune** ou **Windows Autopilot**, mas ambientes que possuem a ferramenta funcionando poderão mante-la até conseguirem efetivamente realizarem a transição para as soluções Microsoft ou outra solução open source como por exemplo **OPSI** ou **FOG Project**.
> 
> 
> **Link Oficial:** [Documentação de Suporte do MDT (Microsoft)](https://learn.microsoft.com/pt-br/troubleshoot/mem/configmgr/mdt/mdt-retirement)


## 📄 O arquivo CustomSettings.ini

O `CustomSettings.ini` é o "cérebro" do MDT. Ele define as regras de priorização e automatiza as etapas do assistente de instalação permitindo padronização e eficiência do ambiente.

### Estrutura de Prioridade

As configurações são aplicadas seguindo esta ordem de precedência:

1. **Init**: Inicializa o número de série do hardware.

2. **ByDesktop, ByLaptop, ByVirtual**: Identifica o tipo de chassi.

3. **Default**: Aplica as configurações gerais do ambiente.

---

## 🏷️ Lógica de Nomenclatura Automática

Para evitar conflitos e padronizar o inventário, o nome do computador (**OSDComputerName**) é gerado automaticamente combinando um prefixo de hardware com o número de série.

### Definição de Prefixos

| Tipo de Dispositivo | Variável de Gatilho | Prefixo (`ComputerPrefix`) | ID (`ComputerTypeName`) |
| --- | --- | --- | --- |
| **Laptop** | `%IsLaptop%` | `NTB` | `L` |
| **Desktop** | `%IsDesktop%` | `DSK` | `D` |
| **Virtual** | `%IsVM%` | `VM` | `V` |

> 
> **Exemplo:** Um notebook com serial `123456789` receberá o nome `NTB-123456789`.
> 
> 

---

## ⚙️ Configurações de Automação (Default)

Para agilizar o processo de suporte, diversas telas do assistente são suprimidas:

* **Senha de Administrador**: Definida automaticamente como `Teste@123` (deve ser alterada para produção).


* **Regionalização**: Teclado configurado em Português (Brasil) ABNT2 e Fuso Horário de Brasília.


* **Página Inicial**: Configurada para `https://www.google.com.br`.


* **Ação Final**: O computador realiza um **REBOOT** automático ao finalizar a Task Sequence.



---

## 📊 Monitoramento e Logs

Os logs de cada instalação são enviados em tempo real para o servidor para facilitar o diagnóstico remoto:

* **Caminho dos Logs**: `\\SRV-2025-RJ\deploymentshare$\DeploymentLogs`.


* **Serviço de Eventos**: `http://SRV-2025-RJ:9800`.



---

## ⚠️ Manutenção

> [!IMPORTANT]
> Qualquer alteração no arquivo `CustomSettings.ini` deve ser testada em ambiente de homologação antes de ser aplicada em produção.
> 
> 

---
