# Guia de Instalações Necessárias

Este guia contém instruções detalhadas para instalar e configurar todas as ferramentas necessárias para o projeto de VPN Pritunl na AWS.

## Índice

1. [AWS CLI](#1-aws-cli)
2. [Terraform](#2-terraform)
3. [Terragrunt](#3-terragrunt)
4. [Cliente Pritunl](#4-cliente-pritunl)

---

## 1. AWS CLI

A AWS CLI (Command Line Interface) permite interagir com os serviços da AWS através da linha de comando.

### Windows

**Opção 1 - Instalador MSI (Recomendado):**

1. Baixe o instalador: [AWS CLI MSI Installer](https://awscli.amazonaws.com/AWSCLIV2.msi)
2. Execute o instalador e siga as instruções
3. Verifique a instalação:

```cmd
aws --version
```

**Opção 2 - Via Chocolatey:**

```cmd
choco install awscli
```

### macOS

**Opção 1 - Via Homebrew (Recomendado):**

```bash
brew install awscli
```

**Opção 2 - Instalador PKG:**

1. Baixe o instalador: [AWS CLI PKG](https://awscli.amazonaws.com/AWSCLIV2.pkg)
2. Execute o instalador
3. Verifique a instalação:

```bash
aws --version
```

### Linux

**Ubuntu/Debian:**

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Amazon Linux 2:**

```bash
sudo yum install aws-cli -y
```

**Verificar instalação:**

```bash
aws --version
```

### Configuração da AWS CLI

Após instalar, configure suas credenciais:

```bash
aws configure
```

Você será solicitado a fornecer:

- **AWS Access Key ID**: Sua chave de acesso
- **AWS Secret Access Key**: Sua chave secreta
- **Default region name**: Região padrão (ex: `us-east-1`)
- **Default output format**: Formato de saída (recomendado: `json`)

**Como obter as credenciais:**

1. Acesse o Console AWS
2. Clique no seu nome de usuário (canto superior direito)
3. Selecione **Security credentials**
4. Em **Access keys**, clique em **Create access key**
5. Copie o **Access Key ID** e **Secret Access Key**

**Testar configuração:**

```bash
aws sts get-caller-identity
```

Se retornar informações da sua conta, está configurado corretamente!

---

## 2. Terraform

Terraform é uma ferramenta de Infrastructure as Code (IaC) para provisionar recursos na nuvem.

### Windows

**Opção 1 - Via Chocolatey (Recomendado):**

```cmd
choco install terraform
```

**Opção 2 - Download Manual:**

1. Acesse: [https://www.terraform.io/downloads](https://www.terraform.io/downloads)
2. Baixe o arquivo ZIP para Windows
3. Extraia o arquivo `terraform.exe`
4. Mova para um diretório no PATH (ex: `C:\Windows\System32`)
5. Verifique a instalação:

```cmd
terraform --version
```

### macOS

**Via Homebrew (Recomendado):**

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Verificar instalação:**

```bash
terraform --version
```

### Linux

**Ubuntu/Debian:**

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Amazon Linux 2:**

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

**Verificar instalação:**

```bash
terraform --version
```

---

## 3. Terragrunt

Terragrunt é um wrapper para Terraform que facilita o gerenciamento de múltiplos módulos e ambientes.

### Windows

**Opção 1 - Via Chocolatey (Recomendado):**

```cmd
choco install terragrunt
```

**Opção 2 - Download Manual:**

1. Acesse: [https://github.com/gruntwork-io/terragrunt/releases](https://github.com/gruntwork-io/terragrunt/releases)
2. Baixe o arquivo `terragrunt_windows_amd64.exe`
3. Renomeie para `terragrunt.exe`
4. Mova para um diretório no PATH (ex: `C:\Windows\System32`)
5. Verifique a instalação:

```cmd
terragrunt --version
```

### macOS

**Via Homebrew (Recomendado):**

```bash
brew install terragrunt
```

**Verificar instalação:**

```bash
terragrunt --version
```

### Linux

**Download direto (todas as distribuições):**

```bash
# Baixar a versão mais recente
TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64

# Tornar executável e mover para PATH
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
```

**Verificar instalação:**

```bash
terragrunt --version
```

---

## 4. Cliente Pritunl

O Cliente Pritunl é o software que permite conectar-se à VPN a partir da sua máquina local.

### Windows

1. Acesse: [https://client.pritunl.com/](https://client.pritunl.com/)
2. Clique em **Download for Windows**
3. Baixe o instalador `.exe`
4. Execute o instalador e siga as instruções
5. Após a instalação, o cliente estará disponível na bandeja do sistema

### macOS

**Opção 1 - Download direto:**

1. Acesse: [https://client.pritunl.com/](https://client.pritunl.com/)
2. Clique em **Download for macOS**
3. Baixe o arquivo `.pkg`
4. Execute o instalador e siga as instruções

**Opção 2 - Via Homebrew:**

```bash
brew install --cask pritunl
```

### Linux

**Ubuntu/Debian:**

```bash
sudo tee /etc/apt/sources.list.d/pritunl.list << EOF
deb https://repo.pritunl.com/stable/apt jammy main
EOF

sudo apt --assume-yes install gnupg
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A | sudo tee /etc/apt/trusted.gpg.d/pritunl.asc
sudo apt update
sudo apt install pritunl-client-electron
```

**Fedora/CentOS/RHEL:**

```bash
sudo tee /etc/yum.repos.d/pritunl.repo << EOF
[pritunl]
name=Pritunl Repository
baseurl=https://repo.pritunl.com/stable/yum/centos/8/
gpgcheck=1
enabled=1
EOF

gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-pritunl
sudo yum install pritunl-client-electron
```

**Arch Linux:**

```bash
yay -S pritunl-client-electron
```

### Verificação

Após a instalação, inicie o Cliente Pritunl:

- **Windows**: Procure por "Pritunl" no menu Iniciar
- **macOS**: Abra o Launchpad e procure por "Pritunl"
- **Linux**: Execute `pritunl-client` no terminal ou procure no menu de aplicativos

---

## Verificação Final

Após instalar todas as ferramentas, verifique se tudo está funcionando:

```bash
# AWS CLI
aws --version

# Terraform
terraform --version

# Terragrunt
terragrunt --version

# Cliente Pritunl (abra a interface gráfica)
```

Se todos os comandos retornarem as versões instaladas, você está pronto para prosseguir com o tutorial!

---

## Troubleshooting

### AWS CLI não reconhecido

**Windows:**
- Reinicie o terminal/PowerShell
- Verifique se o PATH foi atualizado: `echo %PATH%`

**Linux/macOS:**
- Execute: `source ~/.bashrc` ou `source ~/.zshrc`
- Verifique o PATH: `echo $PATH`

### Terraform/Terragrunt não encontrado

- Certifique-se de que o executável está em um diretório incluído no PATH
- No Windows, pode ser necessário reiniciar o terminal
- No Linux/macOS, verifique as permissões de execução: `chmod +x /caminho/para/executavel`

### Cliente Pritunl não inicia

**Linux:**
- Verifique se todas as dependências foram instaladas
- Execute: `pritunl-client` no terminal para ver mensagens de erro

**macOS:**
- Permita a execução em **System Preferences** → **Security & Privacy**

**Windows:**
- Execute como Administrador
- Verifique se o Windows Defender não está bloqueando

---

## Recursos Adicionais

- [Documentação AWS CLI](https://docs.aws.amazon.com/cli/)
- [Documentação Terraform](https://www.terraform.io/docs)
- [Documentação Terragrunt](https://terragrunt.gruntwork.io/docs/)
- [Documentação Pritunl Client](https://docs.pritunl.com/docs/client)
