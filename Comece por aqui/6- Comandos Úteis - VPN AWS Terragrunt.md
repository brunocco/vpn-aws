# Comandos Úteis - VPN AWS Terragrunt

## 🚀 Provisionamento

### Provisionar tudo de uma vez
```bash
cd my-proj-devops
terragrunt run --all init
terragrunt run --all apply --non-interactive
```

### Provisionar apenas VPC
```bash
cd my-proj-devops/vpc
terragrunt init
terragrunt apply
```

### Provisionar EC2 VPN + Security Group
```bash
cd my-proj-devops/ec2/vpn
terragrunt run --all apply
```

### Provisionar EC2 App + Security Group
```bash
cd my-proj-devops/ec2/app
terragrunt run --all apply
```

### Provisionar RDS + Security Group
```bash
cd my-proj-devops/rds
terragrunt run --all apply
```

## 📋 Visualização

### Ver plano de execução
```bash
cd my-proj-devops
terragrunt run --all plan
```

### Ver outputs da VPC
```bash
cd my-proj-devops/vpc
terragrunt output
```

### Ver IP público da EC2 VPN
```bash
cd my-proj-devops/ec2/vpn
terragrunt output public_ip
```

### Ver endpoint do RDS
```bash
cd my-proj-devops/rds
terragrunt output db_instance_endpoint
```

## 🔄 Atualização

### Atualizar apenas EC2 VPN
```bash
cd my-proj-devops/ec2/vpn
terragrunt apply
```

### Atualizar todos os recursos
```bash
cd my-proj-devops
terragrunt run --all apply
```

## 🗑️ Destruição

### Destruir tudo (CUIDADO!)
```bash
cd my-proj-devops
terragrunt run --all destroy
```

### Destruir apenas RDS
```bash
cd my-proj-devops/rds
terragrunt run --all destroy
```

### Destruir apenas EC2 App
```bash
cd my-proj-devops/ec2/app
terragrunt run --all destroy
```

## 🔍 Troubleshooting

### Validar configuração do Terragrunt
```bash
cd my-proj-devops/vpc
terragrunt validate
```

### Ver dependências
```bash
cd my-proj-devops
terragrunt graph-dependencies
```

### Limpar cache do Terragrunt
```bash
# Windows
Get-ChildItem -Path . -Filter ".terragrunt-cache" -Recurse -Directory | Remove-Item -Recurse -Force

# Linux/Mac
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
```

### Forçar unlock do state
```bash
cd my-proj-devops/vpc
terragrunt force-unlock <LOCK_ID>
```

### Ver logs detalhados
```bash
export TF_LOG=DEBUG
terragrunt apply
```

## 🔐 AWS CLI

### Verificar profile configurado
```bash
aws configure list --profile SeuPerfilAWS
```

### Testar credenciais
```bash
aws sts get-caller-identity --profile SeuPerfilAWS
```

### Listar buckets S3
```bash
aws s3 ls --profile SeuPerfilAWS
```

### Ver tabelas DynamoDB
```bash
aws dynamodb list-tables --profile SeuPerfilAWS
```

### Ver locks ativos no DynamoDB
```bash
aws dynamodb scan \
  --table-name my-proj-devops-terraform-lock-test \
  --profile SeuPerfilAWS
```

## 📊 Informações Úteis

### Ver todas as EC2 instances
```bash
aws ec2 describe-instances \
  --profile SeuPerfilAWS \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PublicIpAddress,PrivateIpAddress]' \
  --output table
```

### Ver VPCs
```bash
aws ec2 describe-vpcs \
  --profile SeuPerfilAWS \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock]' \
  --output table
```

### Ver RDS instances
```bash
aws rds describe-db-instances \
  --profile SeuPerfilAWS \
  --query 'DBInstances[*].[DBInstanceIdentifier,Engine,DBInstanceStatus,Endpoint.Address]' \
  --output table
```

### Ver Security Groups
```bash
aws ec2 describe-security-groups \
  --profile SeuPerfilAWS \
  --query 'SecurityGroups[*].[GroupId,GroupName,VpcId]' \
  --output table
```

## 🔌 Conectar via SSM

### EC2 VPN
```bash
aws ssm start-session \
  --target <INSTANCE_ID> \
  --profile SeuPerfilAWS
```

### EC2 App
```bash
aws ssm start-session \
  --target <INSTANCE_ID> \
  --profile SeuPerfilAWS
```

## 📝 Git

### Adicionar arquivos
```bash
git add .
git commit -m "feat: complete terragrunt configuration"
git push origin main
```

### Ver status
```bash
git status
```

### Ver diferenças
```bash
git diff
```

## 🎯 Workflow Completo

```bash
# 1. Configurar AWS
aws configure --profile SeuPerfilAWS

# 2. Clonar/navegar para o projeto
cd vpn-aws/my-proj-devops

# 3. Inicializar
terragrunt run --all init

# 4. Ver plano
terragrunt run --all plan

# 5. Aplicar
terragrunt run --all apply --non-interactive

# 6. Ver outputs
cd vpc && terragrunt output
cd ../ec2/vpn && terragrunt output
cd ../rds && terragrunt output

# 7. Acessar VPN
# Copiar IP público da EC2 VPN e seguir README.md

# 8. Testar conexões
# Conectar VPN e acessar RDS/EC2 App

# 9. Destruir (quando terminar)
cd ../..
terragrunt run-all destroy
```

## 💡 Dicas

1. **Sempre use `run-all plan` antes de `apply`**
2. **Mantenha backups do state** (já está no S3)
3. **Use `--non-interactive` em CI/CD**
4. **Revise security groups antes de aplicar**
5. **Altere senhas padrão em produção**
6. **Use tags para organizar recursos**
7. **Monitore custos no AWS Cost Explorer**

## 📚 Referências

- [Terragrunt Docs](https://terragrunt.gruntwork.io/docs/)
- [Terraform AWS Modules](https://registry.terraform.io/namespaces/terraform-aws-modules)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [Pritunl Docs](https://docs.pritunl.com/)
