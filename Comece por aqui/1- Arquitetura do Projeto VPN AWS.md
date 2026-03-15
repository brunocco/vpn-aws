# 🏗️ Arquitetura do Projeto VPN AWS

## Diagrama de Rede

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                   │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 │ HTTPS (443)
                                 │ OpenVPN (1194/UDP)
                                 │
┌────────────────────────────────┴──────────────────────────────────────┐
│                         AWS Region: us-east-1                         │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │              VPC: my-proj-devops-vpc-test                      │   │
│  │              CIDR: 10.0.0.0/16                                 │   │
│  │                                                                │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │  Availability Zone: us-east-1a                           │  │   │
│  │  │                                                          │  │   │
│  │  │  ┌─────────────────────────────────────────────────┐     │  │   │
│  │  │  │  Public Subnet: 10.0.201.0/24                   │     │  │   │
│  │  │  │                                                 │     │  │   │
│  │  │  │  ┌────────────────────────────────────────┐     │     │  │   │
│  │  │  │  │  EC2 VPN (Pritunl)                     │     │     │  │   │
│  │  │  │  │  - Instance: t3a.small                 │     │     │  │   │
│  │  │  │  │  - OS: Ubuntu 22.04                    │     │     │  │   │
│  │  │  │  │  - Public IP: ✓                        │     │     │  │   │
│  │  │  │  │  - Docker + Pritunl + MongoDB          │     │     │  │   │
│  │  │  │  │  - Ports: 443, 1194/udp, 80            │     │     │  │   │
│  │  │  │  └────────────────────────────────────────┘     │     │  │   │
│  │  │  └─────────────────────────────────────────────────┘     │  │   │
│  │  │                                                          │  │   │
│  │  │  ┌─────────────────────────────────────────────────┐     │  │   │
│  │  │  │  Private Subnet: 10.0.1.0/24                    │     │  │   │
│  │  │  │                                                 │     │  │   │
│  │  │  │  ┌────────────────────────────────────────┐     │     │  │   │
│  │  │  │  │  EC2 App                               │     │     │  │   │
│  │  │  │  │  - Instance: t3a.micro                 │     │     │  │   │
│  │  │  │  │  - OS: Amazon Linux 2023               │     │     │  │   │
│  │  │  │  │  - Public IP: ✗                        │     │     │  │   │
│  │  │  │  │  - Nginx                               │     │     │  │   │
│  │  │  │  │  - Access: VPN only                    │     │     │  │   │
│  │  │  │  └────────────────────────────────────────┘     │     │  │   │
│  │  │  └─────────────────────────────────────────────────┘     │  │   │
│  │  │                                                          │  │   │
│  │  │  ┌─────────────────────────────────────────────────┐     │  │   │
│  │  │  │  Database Subnet: 10.0.101.0/24                 │     │  │   │
│  │  │  │                                                 │     │  │   │
│  │  │  │  ┌────────────────────────────────────────┐     │     │  │   │
│  │  │  │  │  RDS PostgreSQL                        │     │     │  │   │
│  │  │  │  │  - Engine: PostgreSQL 15.4             │     │     │  │   │
│  │  │  │  │  - Instance: db.t3.micro               │     │     │  │   │
│  │  │  │  │  - Storage: 20GB (encrypted)           │     │     │  │   │
│  │  │  │  │  - Database: vpntest                   │     │     │  │   │
│  │  │  │  │  - Access: VPN only                    │     │     │  │   │
│  │  │  │  └────────────────────────────────────────┘     │     │  │   │
│  │  │  └─────────────────────────────────────────────────┘     │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │  Availability Zone: us-east-1b                           │  │   │
│  │  │  (Subnets para alta disponibilidade - não utilizadas)    │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  Security Groups                                                │  │
│  │                                                                 │  │
│  │  • SG-VPN:  0.0.0.0/0 → 443, 1194/udp, 80                       │  │
│  │  • SG-App:  10.0.0.0/16 → 22, 80, 443                           │  │
│  │  • SG-RDS:  10.0.0.0/16 → 5432                                  │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  IAM Roles                                                      │  │
│  │                                                                 │  │
│  │  • EC2-VPN-Role:  AmazonSSMManagedInstanceCore                  │  │
│  │                   CloudWatchAgentServerPolicy                   │  │
│  │                                                                 │  │
│  │  • EC2-App-Role:  AmazonSSMManagedInstanceCore                  │  │
│  │                   CloudWatchAgentServerPolicy                   │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         Terraform State Backend                         │
│                                                                         │
│  ┌──────────────────────────────────┐  ┌──────────────────────────────┐ │
│  │  S3 Bucket                       │  │  DynamoDB Table              │ │
│  │  my-proj-devops-terraform-       │  │  my-proj-devops-terraform-   │ │
│  │  state-test                      │  │  lock-test                   │ │
│  │                                  │  │                              │ │
│  │  • Encrypted: ✓                  │  │  • Purpose: State locking    │ │
│  │  • Versioning: ✓                 │  │  • Prevents conflicts        │ │
│  └──────────────────────────────────┘  └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

## Fluxo de Conexão VPN

```
┌──────────────┐
│   Cliente    │
│   (Você)     │
└──────┬───────┘
       │
       │ 1. Conecta via Pritunl Client
       │    (OpenVPN - porta 1194/UDP)
       │
       v
┌──────────────────────┐
│   EC2 VPN (Pritunl)  │
│   IP Público         │
└──────┬───────────────┘
       │
       │ 2. Túnel VPN estabelecido
       │    IP virtual atribuído (ex: 192.168.236.x)
       │
       v
┌─────────────────────────────────────┐
│         VPC 10.0.0.0/16             │
│                                     │
│  ┌──────────────┐  ┌─────────────┐  │
│  │   EC2 App    │  │  RDS        │  │
│  │   10.0.1.x   │  │  10.0.101.x │  │
│  └──────────────┘  └─────────────┘  │
│                                     │
│  3. Acesso aos recursos privados    │
│     via túnel VPN                   │
└─────────────────────────────────────┘
```

## Fluxo de Dados

### Acesso ao RDS via VPN

```
Cliente Local
    │
    │ (1) Conecta VPN
    v
Pritunl Client
    │
    │ (2) Túnel criptografado
    v
EC2 VPN (Pritunl Server)
    │
    │ (3) Roteamento interno VPC
    v
RDS PostgreSQL (10.0.101.x:5432)
    │
    │ (4) Query SQL
    v
Database: vpntest
```

### Acesso ao EC2 App via VPN

```
Cliente Local
    │
    │ (1) Conecta VPN
    v
Pritunl Client
    │
    │ (2) Túnel criptografado
    v
EC2 VPN (Pritunl Server)
    │
    │ (3) Roteamento interno VPC
    v
EC2 App (10.0.1.x)
    │
    │ (4) HTTP/SSH
    v
Nginx / Shell
```

## Componentes de Segurança

```
┌─────────────────────────────────────────────────────────────┐
│                    Camadas de Segurança                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Network Layer                                           │
│     • VPC isolada (10.0.0.0/16)                             │
│     • Subnets privadas sem Internet Gateway                 │
│     • Security Groups restritivos                           │
│                                                             │
│  2. Access Layer                                            │
│     • VPN obrigatória para recursos privados                │
│     • Autenticação Pritunl (usuário + senha)                │
│     • Certificados OpenVPN                                  │
│                                                             │
│  3. Instance Layer                                          │
│     • IAM Roles (sem access keys)                           │
│     • SSM Session Manager (sem SSH keys)                    │
│     • CloudWatch Logs                                       │
│                                                             │
│  4. Data Layer                                              │
│     • EBS encryption at rest                                │
│     • RDS encryption at rest                                │
│     • Backups automáticos (7 dias)                          │
│                                                             │
│  5. State Layer                                             │
│     • S3 encryption                                         │
│     • DynamoDB locking                                      │
│     • Versioning habilitado                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Terragrunt Dependency Graph

```
root.hcl (remote state + provider)
    │
    ├── vpc/
    │   └── terragrunt.hcl
    │       │
    │       ├── ec2/vpn/security-group/
    │       │   └── terragrunt.hcl
    │       │       └── ec2/vpn/
    │       │           └── terragrunt.hcl
    │       │
    │       ├── ec2/app/security-group/
    │       │   └── terragrunt.hcl
    │       │       └── ec2/app/
    │       │           └── terragrunt.hcl
    │       │
    │       └── rds/security-group/
    │           └── terragrunt.hcl
    │               └── rds/
    │                   └── terragrunt.hcl
    │
    └── _envcommon/vpc.hcl (shared dependency)
```

## Estimativa de Custos (us-east-1)

```
┌──────────────────────────────────────────────────────────┐
│  Recurso              │  Tipo         │  Custo/mês (USD) │
├──────────────────────────────────────────────────────────┤
│  EC2 VPN              │  t3a.small    │  ~$15.00         │
│  EC2 App              │  t3a.micro    │  ~$7.00          │
│  RDS PostgreSQL       │  db.t3.micro  │  ~$15.00         │
│  EBS Volumes (30GB)   │  gp3          │  ~$2.40          │
│  S3 State             │  Standard     │  ~$0.10          │
│  DynamoDB Lock        │  On-demand    │  ~$0.10          │
├──────────────────────────────────────────────────────────┤
│  TOTAL ESTIMADO                        │  ~$39.60/mês    │
└──────────────────────────────────────────────────────────┘

* Custos podem variar baseado em uso e região
* Não inclui transferência de dados
* Valores aproximados para referência
```

## Recursos Terraform

```
Total de recursos provisionados: ~25

• 1 VPC
• 6 Subnets (2 public, 2 private, 2 database)
• 1 Internet Gateway
• 3 Route Tables
• 3 Security Groups
• 2 EC2 Instances
• 2 IAM Roles
• 2 IAM Instance Profiles
• 1 RDS Instance
• 1 DB Subnet Group
• 1 S3 Bucket (state)
• 1 DynamoDB Table (lock)
```

---

**Arquitetura validada e pronta para produção! 🏗️**
