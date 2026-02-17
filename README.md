# 🛠️ Guia de Infraestrutura e Segurança

Bem-vindo ao repositório central de documentação técnica e automação. Este projeto foi pensado para auxiliar profissionais de TI (Service Desk, Administradores de Redes e Engenheiros de Endpoint) na padronização, segurança e eficiência operacional de ambientes corporativos.

## 📌 Objetivo

Centralizar guias práticos, scripts de automação e políticas de conformidade, garantindo que a infraestrutura seja escalável e segura, desde o deploy da imagem até a governança de novas tecnologias.

---

## 📂 Estrutura do Repositório

Navegue pelas pastas abaixo para encontrar o conteúdo desejado:

### [1. MDT - Implantação Automatizada]()

Focado na padronização de imagens Windows via Microsoft Deployment Toolkit.

**CustomSettings.ini:** Regras de automação e priorização de configurações.
 
**Nomenclatura Automática:** Lógica baseada em chassi para Desktop (DSK), Laptop (NTB) e Virtual (VM) .

**Task Sequences:** Manuais de criação e manutenção de sequências de tarefas.

### [2. Intune e MDM]()

Gerenciamento moderno de dispositivos móveis e computadores.

**Políticas de Conformidade e Configuração.** 

**Distribuição de aplicativos e perfis de Wi-Fi/VPN** 

**Criação/edição de arquivos .INTUNEWIN** 

### [3. Automação PowerShell]()

Scripts para otimizar o dia a dia do suporte técnico.

* Limpeza de perfil de usuário e logs do sistema.
* Scripts de inventário rápido e diagnóstico de rede.
* Coleta de dados para atendimento inicial.
* Resetar senha de usuário no AD.
* Desbloquear conta no Active Directory.

### [4. GPOs e Windows Server]()

Políticas de grupo para gerenciamento centralizado de servidores e estações.

* Hardening de Windows Server.
* Configurações de segurança para navegadores e mapeamentos de rede.
* Bloqueio de dispositivos removíveis (USB, discos externos).
* Controle de acesso ao Painel de Controle e Configurações.
* Scripts de logon/logoff para automação de tarefas (mapeamento de rede, impressoras).
* Políticas de senha: complexidade, expiração e histórico.
* Bloqueio de conta após tentativas de login inválidas.
* Políticas de energia (hibernação, desligamento automático).
* Bloqueio automático de sessão após inatividade.
* Atualizações automáticas via WSUS.
* Configuração de Remote Desktop Services (RDS).
* Inventário de hardware e software.
* Configuração automática de Wi*Fi corporativo.
* Controle de acesso remoto via RDP.


### [5. Segurança e Bloqueio de IA]()

Governança sobre ferramentas de Inteligência Artificial Generativa.

* Listas de domínios para bloqueio (ChatGPT, Gemini, Claude, etc).
* Scripts de bloqueio via arquivo `hosts` ou Firewall.

---

## 🚀 Como utilizar este guia

1. **Clone o repositório:**
```bash
git clone https://github.com/seu-usuario/Guia-Infraestrutura-e-Seguranca.git

```


2. **Consulte a documentação:** Cada pasta contém um `README.md` específico explicando os pré-requisitos e como aplicar as configurações.
3. **Teste antes de aplicar:** Nunca aplique scripts ou GPOs diretamente em produção sem validar em um ambiente de homologação.

---

## 🛡️ Melhores Práticas de Segurança

> [!CAUTION]
> 
> 
> **Senhas e Credenciais:** Nunca armazene senhas em texto claro dentro dos scripts ou arquivos de configuração (`.ini`, `.xml`, `.ps1`). Utilize o Azure Key Vault ou ferramentas de gerenciamento de segredos.
> 
> 

> [!IMPORTANT]
> 
> 
> **Logs:** Sempre mantenha o monitoramento ativo para auditar falhas em processos de deploy ou acesso indevido.
> 
> 

---

## 🤝 Contribuições

Sinta-se à vontade para abrir uma *Issue* ou enviar um *Pull Request* com melhorias e novos scripts. Toda contribuição que facilite a vida do time de TI é bem-vinda!
