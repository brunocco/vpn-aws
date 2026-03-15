# Guia de Uso do Terragrunt

## Estrutura do Projeto

```
vpn-aws/
├── config.hcl                    # Configuração do profile AWS
├── my-proj-devops/
│   ├── root.hcl                  # Configuração root (remote state, provider)
│   ├── vars.hcl                  # Variáveis globais do projeto
│   ├── _envcommon/
│   │   └── vpc.hcl              # Dependency compartilhada da VPC
│   ├── vpc/
│   │   └── terragrunt.hcl       # Módulo VPC
│   ├── ec2/
│   │   ├── vpn/
│   │   │   ├── security-group/
│   │   │   │   └── terragrunt.hcl
│   │   │   └── terragrunt.hcl   # EC2 VPN (Pritunl)
│   │   └── app/
│   │       ├── security-group/
│   │       │   └── terragrunt.hcl
│   │       └── terragrunt.hcl   # EC2 App (teste)
│   └── rds/
│       ├── security-group/
│       │   └── terragrunt.hcl
│       └── terragrunt.hcl       # RDS PostgreSQL
```

## Pré-requisitos

1. **AWS CLI** configurado com profile `SeuPerfilAWS`:
```bash
aws configure --profile SeuPerfilAWS
```

2. **Terraform** instalado (versão >= 1.5.0)

3. **Terragrunt** instalado (versão >= 0.50.0)

## Comandos Principais

### 1. Inicializar e Provisionar Tudo

```bash
cd my-proj-devops
terragrunt run --all init
terragrunt run --all plan
terragrunt run --all apply --non-interactive
```

### 2. Provisionar Recursos Específicos

**VPC:**
```bash
cd my-proj-devops/vpc
terragrunt init
terragrunt plan
terragrunt apply
```

**EC2 VPN:**
```bash
cd my-proj-devops/ec2/vpn
terragrunt run --all init    # Inicializa security-group e ec2
terragrunt run --all apply
```

**EC2 App:**
```bash
cd my-proj-devops/ec2/app
terragrunt run --all apply
```

**RDS:**
```bash
cd my-proj-devops/rds
terragrunt run --all apply
```

### 3. Destruir Recursos

**Destruir tudo (cuidado!):**
```bash
cd my-proj-devops
terragrunt run --all destroy
```

**Destruir recurso específico:**
```bash
cd my-proj-devops/ec2/vpn
terragrunt destroy
```

### 4. Ver Outputs

```bash
cd my-proj-devops/vpc
terragrunt output

cd my-proj-devops/ec2/vpn
terragrunt output
```

## Ordem de Provisionamento

O Terragrunt gerencia automaticamente as dependências, mas a ordem lógica é:

1. **VPC** (base da infraestrutura)
2. **Security Groups** (dependem da VPC)
3. **EC2 VPN** (depende de VPC e SG)
4. **EC2 App** (depende de VPC e SG)
5. **RDS** (depende de VPC e SG)

## Configurações Importantes

### Remote State

O estado do Terraform é armazenado em:
- **Bucket S3**: `my-proj-devops-terraform-state-test`
- **DynamoDB Table**: `my-proj-devops-terraform-lock-test`

Esses recursos são criados automaticamente pelo Terragrunt na primeira execução.

### Profile AWS

Configurado em `config.hcl`:
```hcl
locals {
  aws_profile = "SeuPerfilAWS"
}
```

### Região

Configurada em `root.hcl`:
```hcl
locals {
  region = "us-east-1"
}
```

## Módulos Utilizados

Todos os módulos são oficiais da AWS Registry:

- **VPC**: `terraform-aws-modules/vpc/aws` (v5.1.2)
- **EC2**: `terraform-aws-modules/ec2-instance/aws` (v5.5.0)
- **Security Group**: `terraform-aws-modules/security-group/aws` (v5.1.0)
- **RDS**: `terraform-aws-modules/rds/aws` (v6.3.0)

## Troubleshooting

### Erro de credenciais AWS

Verifique se o profile está configurado:
```bash
aws configure list --profile SeuPerfilAWS
```

### Erro de lock no DynamoDB

Se houver um lock travado:
```bash
# Liste os locks
aws dynamodb scan --table-name my-proj-devops-terraform-lock-test --profile SeuPerfilAWS

# Force unlock (use com cuidado!)
terragrunt force-unlock <LOCK_ID>
```

### Limpar cache do Terragrunt

```bash
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
```

## Segurança

⚠️ **IMPORTANTE:**

1. **Senha do RDS**: Altere a senha padrão em `rds/terragrunt.hcl` antes de usar em produção!

2. **State remoto**: O bucket S3 e a tabela DynamoDB são criados com criptografia habilitada.

3. **Recursos privados**: EC2 App e RDS estão em subnets privadas sem acesso direto à internet.

4. **VPN**: A EC2 VPN está em subnet pública para permitir conexões externas.

## Próximos Passos

Após provisionar a infraestrutura, siga o [README.md](README.md) principal para:
1. Configurar o Pritunl
2. Criar usuários VPN
3. Testar conexões com RDS e EC2 App
