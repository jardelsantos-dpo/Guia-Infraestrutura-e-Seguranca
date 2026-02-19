# ⚡ Automação com PowerShell (Service Desk)

Esta pasta centraliza scripts desenvolvidos em PowerShell para otimizar a rotina do suporte técnico, reduzir o tempo de atendimento inicial e automatizar tarefas repetitivas de administração de sistemas.

## 🚀 Scripts Disponíveis

### [📂 Coleta de Dados](./SystemInfo/systeminfo.md)

* **Nome:** `Systeminfo.ps1`
* **Status:** ✅ Operacional e atualizado.
* **Descrição:** Coleta informações essenciais do hardware e software (HostName, IP, Serial Number, Versão do Windows e tempo de atividade) para agilizar o atendimento inicial.

---

## 🛠️ Próximas Implementações (Roadmap)

Os seguintes scripts estão em fase de desenvolvimento e serão adicionados em breve:

* **Gestão de Active Directory:**
* [ ] `Reset-ADUserPassword.ps1`: Reset de senha de usuário de forma segura.
* [ ] `Unlock-ADAccount.ps1`: Desbloqueio rápido de contas travadas no AD.


* **Manutenção de Sistema:**
* [ ] `Clean-UserProfiles.ps1`: Limpeza de perfis de usuário antigos e logs temporários do sistema para liberar espaço em disco.


* **Diagnóstico:**
* [ ] `Net-Inventory-Tool.ps1`: Script de inventário simples para uso em rede e testes de conectividade.

---

## 📖 Como utilizar os scripts

1. **Execução Local:**
Abra o PowerShell como Administrador e execute:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\NomeDoScript.ps1

```


2. **Segurança:**
Sempre revise o código antes de executá-lo. Estes scripts foram projetados para ambiente corporativo, mas devem ser validados conforme a política de segurança da sua empresa.

---

## 🛡️ Boas Práticas

> [!TIP]
> **Dica:** Utilize o script `Systeminfo` logo no início de cada chamado para garantir que você tem todos os dados técnicos antes de iniciar o troubleshooting.

> [!IMPORTANT]
> Para scripts que interagem com o Active Directory, certifique-se de que o módulo `ActiveDirectory` está instalado na estação ou servidor de gerenciamento (RSAT).
