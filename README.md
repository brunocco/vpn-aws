# Projeto VPN

Projeto tutorial completo de como instalar, configurar e testar uma OpenVPN na AWS usando Pritunl - desde o provisionamento da infraestrutura até os testes de conectividade.

## Índice

1. [O que é uma VPN?](#o-que-é-uma-vpn)
2. [Para que serve?](#para-que-serve)
3. [Tipos de VPN](#tipos-de-vpn)
4. [Requisitos](#requisitos)
   - [Sistema](#sistema)
   - [Infraestrutura](#infraestrutura)
5. [Provisionamento da Infraestrutura](#provisionamento-da-infraestrutura)
6. [Configuração da VPN Pritunl](#configuração-da-vpn-pritunl)
   - [Acesso Inicial](#1-acesso-inicial)
   - [Resgate de Senha](#2-resgate-de-senha)
   - [Login e Configuração Inicial](#3-login-e-configuração-inicial)
   - [Criação de Organização](#4-criação-de-organização)
   - [Criação do Server](#5-criação-do-server)
   - [Anexar Organização ao Server](#6-anexar-organização-ao-server)
   - [Iniciar o Server](#7-iniciar-o-server)
   - [Distribuir Perfil de Usuário](#8-distribuir-perfil-de-usuário)
7. [Instalação do Cliente Pritunl](#instalação-do-cliente-pritunl)
8. [Conectar à VPN](#conectar-à-vpn)
9. [Testes de Conexão](#testes-de-conexão)
   - [Teste com RDS PostgreSQL](#teste-com-rds-postgresql)
   - [Teste com EC2](#teste-com-ec2)
10. [Apêndice: Criação de Subdomínio](#apêndice-criação-de-subdomínio)

---

## O que é uma VPN?

VPN (Virtual Private Network) é uma tecnologia que cria uma conexão segura e criptografada entre seu dispositivo e uma rede privada através da internet pública. Ela funciona como um túnel protegido que permite acessar recursos de rede de forma segura, mesmo estando remotamente.

## Para que serve?

Uma VPN serve para:
- **Acesso remoto seguro**: Permite que funcionários acessem recursos internos da empresa de qualquer lugar
- **Segurança**: Criptografa o tráfego de dados, protegendo informações sensíveis
- **Acesso a recursos privados**: Conecta-se a servidores, bancos de dados e aplicações que não estão expostos publicamente na internet
- **Controle de acesso**: Gerencia quem pode acessar determinados recursos da infraestrutura

## Tipos de VPN

Existem duas principais formas de implementar uma VPN na AWS:

1. **VPN Nativa da Cloud Provider (AWS VPN)**: Serviço gerenciado pela AWS, pago, com alta disponibilidade e suporte oficial
2. **Soluções Open Source**: Alternativas gratuitas como Pritunl ou OpenVPN

Neste tutorial, utilizaremos o **Pritunl** pelos seguintes motivos:
- **Didático**: Interface web intuitiva, ideal para aprendizado
- **Gratuito**: Sem custos de licenciamento
- **Flexível**: Permite gerenciar múltiplas organizações e usuários facilmente
- **Baseado em OpenVPN**: Utiliza protocolo robusto e amplamente testado

---

## Requisitos

### Sistema

Antes de iniciar, certifique-se de ter instalado e configurado:

- **AWS CLI** configurada com suas credenciais (usuário e senha/access keys)
  - Veja instruções na pasta `Comece por aqui/2-instalacoes-necessarias`
- **Terraform** instalado
  - Veja instruções na pasta `Comece por aqui/2-instalacoes-necessarias`
- **Terragrunt** instalado
  - Veja instruções na pasta `Comece por aqui/2-instalacoes-necessarias`
- **Cliente Pritunl** instalado em sua máquina local
  - Veja instruções na pasta `Comece por aqui/2-instalacoes-necessarias`

### Infraestrutura

A infraestrutura necessária inclui:

- **VPC** (`my-proj-devops-vpc-test`): Rede virtual isolada na AWS com CIDR 10.0.0.0/16
- **Subnets públicas** (10.0.201.0/24, 10.0.202.0/24): Subredes com acesso direto à internet via Internet Gateway, onde a EC2 VPN será provisionada para receber conexões externas
- **Subnets privadas** (10.0.1.0/24, 10.0.2.0/24): Subredes sem acesso direto à internet, onde a EC2 App será provisionada, simulando um ambiente altamente restrito e seguro
- **Subnets database** (10.0.101.0/24, 10.0.102.0/24): Subredes dedicadas para o RDS, isoladas e sem acesso direto à internet
- **EC2 VPN** (`my-proj-devops-vpn-test`): Instância EC2 que funcionará como servidor VPN com Pritunl instalado via Docker
- **EC2 App** (`my-proj-devops-app-test`): Instância Linux para testes de acesso através da VPN
- **RDS PostgreSQL** (`my-proj-devops-rds-test`): Banco de dados para testes de conexão via VPN

**Observação sobre Arquitetura:**

Você pode deixar o projeto ainda mais restrito utilizando apenas subnets privadas para todos os recursos, mas nesse caso seria necessário adicionar à infraestrutura um **Network Load Balancer (NLB)** em subnet pública para receber as conexões VPN externas e encaminhá-las para a EC2 VPN em subnet privada. Adicionalmente, seria necessário um **NAT Gateway** para permitir que a EC2 VPN acesse a internet para atualizações e downloads (Docker, Pritunl, etc.).

Neste projeto, optei por uma arquitetura mais simples e didática para facilitar a replicação e prática. Por isso, a EC2 VPN está em uma subnet pública com IP público, permitindo acesso direto para configuração da VPN sem a necessidade de componentes adicionais como NLB e NAT Gateway, reduzindo custos (~$32/mês de NAT Gateway + ~$18/mês de NLB) e complexidade.

---

## Provisionamento da Infraestrutura

Este repositório contém todos os arquivos Terraform/Terragrunt necessários para provisionar a infraestrutura.

Para provisionar tudo de uma vez, execute na pasta principal do projeto:

```bash
cd my-proj-devops
terragrunt run --all init 
terragrunt run --all apply --non-interactive
```
### Nota Importante: Remote State Backend

Em algumas versões do Terragrunt, você precisará criar manualmente o bucket S3 e a tabela DynamoDB para o remote state antes de executar os comandos `terragrunt run --all`. Verifique sua versão caso apresente erros relacionados a bucket ou DynamoDB não encontrados.

#### Criar Bucket S3 para Remote State

```bash
# Substitua <SEU_NOME_UNICO> por um nome único globalmente
aws s3 mb s3://my-proj-devops-terraform-state-<SEU_NOME_UNICO> --region us-east-1

# Habilitar versionamento (recomendado)
aws s3api put-bucket-versioning \
    --bucket my-proj-devops-terraform-state-<SEU_NOME_UNICO> \
    --versioning-configuration Status=Enabled
```
### Criar Tabela DynamoDB para State Lock

```bash
aws dynamodb create-table \
    --table-name my-proj-devops-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-east-1
```
### Nota Importante sobre o User Data

Dentro do **user data** da EC2 `my-proj-devops-vpn-test` está configurada a instalação automática de:
- Docker
- Pritunl (rodando em container Docker na porta 1194)

Você pode verificar o código completo do user data na pasta da `my-proj-devops/ec2/vpn`.

### Instalação Manual (caso necessário)

Se você provisionou a EC2 anteriormente sem o user data configurado, siga estes passos:

1. Acesse a máquina via **SSM (Systems Manager)**
2. Instale Docker e Pritunl manualmente via linha de comando
3. Consulte a [documentação oficial do Pritunl](https://docs.pritunl.com/docs/installation) para obter os comandos específicos de acordo com o sistema operacional da EC2 (Amazon Linux 2, Ubuntu, etc.)
4. Após a instalação, prossiga para o **Passo 1** de configuração da VPN Pritunl.

---

## Configuração da VPN Pritunl

### 1. Acesso Inicial

a. Acesse o **Console AWS** e localize o **endereço IP público** da EC2 `my-proj-devops-vpn-test`

b. Abra um navegador e acesse: `https://<IP_PUBLICO_DA_EC2>`

c. Você verá a página de login do Pritunl

### 2. Resgate de Senha

O usuário padrão é `pritunl`, mas a senha precisa ser resgatada do container Docker que esta rodando dentro da nossa EC2.

a. No Console AWS, pesquise por **EC2** na barra de pesquisa

b. Clique em **Instâncias** e selecione a EC2 `my-proj-devops-vpn-test`

c. Clique em **Conectar** e escolha **Session Manager (SSM)**

d. Execute os seguintes comandos:

```bash
# Obter privilégios de administrador
sudo su

# Voltar ao diretório home
cd ~

# Listar containers em execução
docker ps

# Acessar o container do Pritunl (substitua <CONTAINER_ID> pelo ID retornado)
docker exec -it <CONTAINER_ID> /bin/bash

# Dentro do container, execute o comando para obter a senha padrão
pritunl default-password
```

e. **Copie a senha** retornada pelo comando

### 3. Login e Configuração Inicial

a. Volte à página de login do Pritunl

b. Faça login com:
   - **Usuário**: `pritunl`
   - **Senha**: (senha copiada do passo anterior)

c. Após o login, será exibida uma tela solicitando o campo **Let's Encrypt Domain**

**Opção 1 - Sem domínio:**
- Deixe o campo em branco e clique em **Save**

**Opção 2 - Com domínio personalizado:**
- Se você possui uma zona hospedada no Route 53 e deseja usar um subdomínio, veja o [Apêndice: Criação de Subdomínio](#apêndice-criação-de-subdomínio)

### 4. Criação de Organização

Organizações permitem agrupar usuários por empresa ou departamento.

**Exemplo de cenário:**
Você é engenheiro DevOps da empresa fictícia "DevOps Tech" e está criando uma VPN para o cliente "DevOps Cliente Tech". Crie duas organizações:
- Uma para a empresa cliente (usuários autorizados do cliente)
- Uma para sua empresa (equipe interna de DevOps)

**Passos:**

a. Clique em **Users** → **Add Organization**

b. Digite o nome da organização (ex: `DevOps Tech`) e clique em **Add**

c. Repita para criar a segunda organização (ex: `DevOps Cliente Tech`)

**Adicionar usuários:**

a. Clique em **Add User**

b. Preencha os campos:
   - **Name**: Email do usuário (isso mesmo o email ou apenas a parte antes do @)
   - **Organization**: Selecione a organização correspondente
   - **Email**: Email do usuário
   - **PIN**: Deixe em branco (opcional)

c. Clique em **Add**

### 5. Criação do Server

a. No menu superior, clique em **Servers** → **Add Server**

b. Preencha os campos:

- **Name**: Nome do servidor (geralmente o nome da empresa cliente, ex: `DevOps Cliente Tech`)
- **Port**: `1194` (porta UDP definida no user data)
- **Protocol**: `UDP`
- **DNS Server**: Configure com dois valores separados por vírgula:
  - `8.8.8.8` (DNS público do Google)
  - `<PRIMEIRO_IP_DA_VPC>` (IP reservado para DNS interno da VPC)

**Como calcular o IP do DNS da VPC:**

A AWS reserva IPs específicos em cada VPC para o DNS Resolver (Route 53 Resolver).

Se sua VPC tem o range `10.0.0.0/16`, você pode usar:
- `10.0.0.2` (IP oficial do DNS Resolver)
- `10.0.0.1` (também funciona, pois a AWS redireciona para o DNS)
Obs: você pode verificar o range de sua vpc no console, pagina da sua vpc em "cidr ipv4".

Exemplo de configuração:
```
8.8.8.8,10.0.0.2
```

Ou:
```
8.8.8.8,10.0.0.1
```

**Por que esse IP?**
Esses IPs são o Amazon DNS Server (Route 53 Resolver) que permite resolução de nomes internos da VPC, essencial para acessar recursos como RDS por endpoint DNS ao invés de IP. Ambos funcionam perfeitamente.

c. Clique em **Add** para criar o servidor

### 6. Anexar Organização ao Server

a. No servidor criado, clique em **Attach Organization**

b. Selecione a organização e o servidor correspondente

**Exemplo:**
- **Organization**: `DevOps Tech` → **Server**: `DevOps Cliente Tech`
- **Organization**: `DevOps Cliente Tech` → **Server**: `DevOps Cliente Tech`

c. Clique em **Attach**

### 7. Iniciar o Server

a. Clique no botão **Start Server**

**Importante:** O servidor deve permanecer iniciado para que os usuários possam se conectar. Pare o servidor apenas para manutenções críticas, como alterações de configuração de rede ou atualizações que exijam reinicialização.

### 8. Distribuir Perfil de Usuário

Cada usuário autorizado precisa de um arquivo de perfil (`.ovpn`) para conectar-se à VPN.

a. Clique em **Users**

b. Localize o usuário desejado

c. Clique no ícone de **corrente/link** ao lado do email do usuário

d. Serão exibidos vários links. **Copie o penúltimo link** (Profile Link)

e. Envie este link ao usuário autorizado

f. O usuário deve acessar o link e usar a URL para importar o perfil no cliente Printunl ou fazer o download do arquivo `.ovpn`,
você pode baixar pelo 2º link(zip profie) após clicar na corrente ao lado do email do usuario e enviar para o usuario.

**Para testes:** Baixe o perfil de um usuário `.ovpn` para testar a conexão localmente pelo 2 link(zip profile)

---

## Instalação do Cliente Pritunl

O cliente Pritunl é o software que permite conectar-se à VPN a partir da sua máquina local.

1. Acesse: [https://client.pritunl.com/](https://client.pritunl.com/)
2. Baixe a versão correspondente ao seu sistema operacional (Windows, macOS, Linux)
3. Instale o cliente seguindo as instruções do instalador

---

## Conectar à VPN

1. **Inicie o cliente Pritunl** instalado em sua máquina

2. **Importe o perfil**:
   - Clique em **Import Profile**
   - Selecione o arquivo `.ovpn` baixado anteriormente

3. **Conecte-se**:
   - Clique no botão **Connect** ao lado do perfil importado
   - Aguarde a conexão ser estabelecida
   - Quando conectado, o status mudará para "Connected"

Pronto! Agora você está conectado à VPN e pode acessar os recursos privados da infraestrutura AWS.

---

## Testes de Conexão

### Teste com RDS PostgreSQL

Com a VPN conectada, você pode acessar o banco de dados RDS diretamente do seu VS Code ou qualquer cliente PostgreSQL.

**Configuração da conexão:**

1. Obtenha o **endpoint** do RDS no Console AWS:
   - Acesse **RDS** → **Databases** → `my-proj-devops-rds-test`
   - Copie o endpoint (ex: `my-proj-devops-rds-test.xxxxxx.us-east-1.rds.amazonaws.com`)

2. Configure a conexão no seu cliente PostgreSQL (ex: extensão PostgreSQL do VS Code, DBeaver, pgAdmin):
obs: Sugiro você baixar o DBeaver,configurar uma nova conexão e fazer os testes(muito mais simples)
   - **Host**: Endpoint do RDS
   - **Port**: `5432`
   - **Database**: Nome do banco configurado
   - **Username**: Usuário configurado no Terraform
   - **Password**: Senha configurada no Terraform
   
**Exemplo de teste no VS Code usando o plugin ou pelo DBeaver:**

```sql
-- Criar uma tabela de teste
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados
INSERT INTO usuarios (nome, email) VALUES 
('João Silva', 'joao@example.com'),
('Maria Santos', 'maria@example.com');

-- Consultar dados
SELECT * FROM usuarios;
```

Se a consulta funcionar, a conexão via VPN está operacional!

### Teste com EC2

Teste o acesso SSH à EC2 privada através da VPN.


**Via SSH (se configurado):**

```bash
# Do seu terminal local (com VPN conectada)
ssh -i vpn-test-key.pem ec2-user@<IP_PRIVADO_DA_EC2>
```
Obs: Essa chave foi criada junto com a EC2 com terragrunt
Se conseguir acessar e executar comandos, a VPN está funcionando corretamente!

---

## Apêndice: Criação de Subdomínio

Se você possui uma zona hospedada no Route 53 e deseja usar um subdomínio personalizado para acessar o Pritunl (ex: `vpn.seudominio.com`):

1. Acesse o **Route 53** no Console AWS

2. Clique em **Hosted Zones** e selecione sua zona

3. Clique em **Create Record**

4. Preencha os campos:
   - **Record name**: `vpn` (ou outro nome de sua preferência)
   - **Record type**: `A`
   - **Value**: IP público da EC2 `my-proj-devops-vpn-test`
   - **TTL**: `300` (padrão)

5. Clique em **Create records**

6. Aguarde a propagação DNS (pode levar alguns minutos)

7. Volte à interface do Pritunl, acesse **Settings**

8. No campo **Let's Encrypt Domain**, insira: `vpn.seudominio.com`

9. Clique em **Save**

10. O Pritunl solicitará automaticamente um certificado SSL válido via Let's Encrypt

Agora você pode acessar o Pritunl via: `https://vpn.seudominio.com`

---

## Conclusão

Você configurou com sucesso uma VPN Pritunl na AWS! Agora pode:
- Gerenciar usuários e organizações
- Acessar recursos privados (RDS, EC2) de forma segura
- Controlar quem tem acesso à sua infraestrutura

Para mais informações, consulte a [documentação oficial do Pritunl](https://docs.pritunl.com/).

---

## Autor

**Bruno Cesar**

📧 Email: bruno_cco@hotmail.com  
💼 LinkedIn: [bruno-cesar-704265223](https://www.linkedin.com/in/bruno-cesar-704265223)  
🐙 Medium: [brunosherlocked](https://medium.com/@brunosherlocked)

---

## Contribuições

Contribuições são bem-vindas! Por favor:

1. Faça fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

⭐ **Se este projeto foi útil, considere dar uma estrela no GitHub!**
