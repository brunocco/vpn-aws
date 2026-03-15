# ❓ FAQ - Perguntas Frequentes

## Geral

### O que é este projeto?
Um projeto de infraestrutura como código (IaC) usando Terragrunt para provisionar uma VPN Pritunl na AWS, permitindo acesso seguro a recursos privados (RDS e EC2).

### Por que usar Terragrunt ao invés de Terraform puro?
- **DRY (Don't Repeat Yourself)**: Reutilização de código
- **Remote state automático**: Configuração centralizada
- **Gerenciamento de dependências**: Automático entre módulos
- **Múltiplos ambientes**: Fácil replicação

### Quanto custa rodar este projeto?
Aproximadamente **$40/mês** na AWS (us-east-1), incluindo EC2, RDS, EBS e outros recursos.

## Configuração

### Como alterar a região AWS?
Edite `my-proj-devops/root.hcl`:
```hcl
locals {
  region = "us-west-2"  # Altere aqui
}
```

### Como usar outro profile AWS?
Edite `config.hcl`:
```hcl
locals {
  aws_profile = "production"  # Altere aqui
}
```

### Como alterar o CIDR da VPC?
Edite `my-proj-devops/vpc/terragrunt.hcl` e ajuste o CIDR e as subnets proporcionalmente.

### Posso usar outro banco de dados além do PostgreSQL?
Sim! Edite `my-proj-devops/rds/terragrunt.hcl` e altere:
```hcl
engine = "mysql"  # ou "mariadb", etc
```

## Provisionamento

### Qual a ordem de provisionamento?
O Terragrunt resolve automaticamente, mas a ordem lógica é:
1. VPC
2. Security Groups
3. EC2 e RDS

### Posso provisionar apenas um recurso?
Sim:
```bash
cd my-proj-devops/ec2/vpn
terragrunt apply
```

### Como ver o que será criado antes de aplicar?
```bash
terragrunt run --all plan
```

### Quanto tempo leva para provisionar tudo?
Aproximadamente **10-15 minutos** para todos os recursos.

## VPN

### Por que a EC2 VPN precisa estar em subnet pública?
Para receber conexões VPN da internet. Sem IP público, não seria acessível externamente.

### Posso usar outra solução VPN além do Pritunl?
Sim, mas precisará alterar o user_data da EC2 VPN. Pritunl foi escolhido por ser gratuito e ter interface web.

### Como adicionar mais usuários VPN?
Acesse a interface web do Pritunl e crie novos usuários na organização desejada.

### A VPN suporta múltiplas organizações?
Sim! O Pritunl permite criar várias organizações (ex: empresa, clientes, parceiros).

### Como obter o IP público da VPN?
```bash
cd my-proj-devops/ec2/vpn
terragrunt output public_ip
```

## Segurança

### A senha padrão do RDS é segura?
**NÃO!** Altere em `my-proj-devops/rds/terragrunt.hcl` antes de usar em produção:
```hcl
password = "SuaSenhaSegura123!@#"
```

### Como acessar as EC2 sem SSH keys?
Use AWS Systems Manager (SSM):
```bash
aws ssm start-session --target <INSTANCE_ID> --profile SeuPerfilAWS
```

### Os dados estão criptografados?
Sim:
- EBS volumes: criptografados
- RDS storage: criptografado
- S3 state: criptografado

### Como restringir acesso à VPN por IP?
Edite `my-proj-devops/ec2/vpn/security-group/terragrunt.hcl` e altere:
```hcl
cidr_blocks = "SEU_IP/32"  # ao invés de "0.0.0.0/0"
```

## Rede

### Por que não tem NAT Gateway?
Para economia de custos (~$32/mês). EC2 privadas não precisam de internet neste cenário.

### Como adicionar NAT Gateway?
Edite `my-proj-devops/vpc/terragrunt.hcl`:
```hcl
enable_nat_gateway = true
single_nat_gateway = true  # ou false para HA
```

### EC2 App pode acessar a internet?
Não, está em subnet privada sem NAT Gateway. Para habilitar, adicione NAT Gateway.

### Como funciona a resolução DNS interna?
A VPC tem DNS Resolver (10.0.0.2) que resolve nomes internos como o endpoint do RDS.

## RDS

### Como conectar ao RDS?
1. Conecte à VPN
2. Use o endpoint: `terragrunt output db_instance_endpoint`
3. Porta: 5432
4. Database: vpntest
5. User: postgres

### Como fazer backup manual do RDS?
```bash
aws rds create-db-snapshot \
  --db-instance-identifier my-proj-devops-rds-test \
  --db-snapshot-identifier manual-backup-$(date +%Y%m%d) \
  --profile SeuPerfilAWS
```

### Como restaurar um backup?
Via console AWS ou CLI, criando nova instância a partir do snapshot.

### Posso aumentar o storage do RDS?
Sim, edite `my-proj-devops/rds/terragrunt.hcl`:
```hcl
allocated_storage = 50  # GB
```

## State e Lock

### Onde fica o state do Terraform?
No bucket S3: `my-proj-devops-terraform-state-test`

### O que é o DynamoDB lock?
Previne que múltiplas pessoas apliquem mudanças simultaneamente, evitando conflitos.

### Como fazer backup do state?
O S3 já tem versionamento habilitado. Para backup manual:
```bash
aws s3 sync s3://my-proj-devops-terraform-state-test ./backup-state --profile SeuPerfilAWS
```

### State travado, como resolver?
```bash
# Ver locks
aws dynamodb scan --table-name my-proj-devops-terraform-lock-test --profile SeuPerfilAWS

# Forçar unlock (cuidado!)
terragrunt force-unlock <LOCK_ID>
```

## Troubleshooting

### Erro: "No valid credential sources found"
Configure o profile AWS:
```bash
aws configure --profile SeuPerfilAWS
```

### Erro: "Error acquiring the state lock"
Alguém está aplicando mudanças ou houve um travamento. Aguarde ou force unlock.

### Erro: "Insufficient capacity"
A AWS não tem capacidade para o instance type na AZ. Tente outra AZ ou instance type.

### Erro: "VPC limit exceeded"
Você atingiu o limite de VPCs. Delete VPCs não utilizadas ou solicite aumento de limite.

### Como limpar cache do Terragrunt?
```bash
# Windows
Get-ChildItem -Path . -Filter ".terragrunt-cache" -Recurse -Directory | Remove-Item -Recurse -Force

# Linux/Mac
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
```

### Pritunl não está acessível
1. Verifique se EC2 está rodando
2. Verifique Security Group (portas 443, 80, 1194/udp)
3. Aguarde 5-10 min após provisionamento (user_data executando)
4. Acesse via SSM e verifique: `docker ps`

## Custos

### Como reduzir custos?
1. Use instances menores (t3a.micro)
2. Destrua recursos quando não usar
3. Desabilite backups do RDS (não recomendado)
4. Use Spot Instances (não recomendado para VPN)

### Como monitorar custos?
- AWS Cost Explorer
- AWS Budgets (alertas)
- Tags para rastreamento

### Posso usar Free Tier?
Parcialmente. RDS e EC2 t3a não estão no Free Tier, mas t2.micro está (limitado).

## Manutenção

### Como atualizar versões dos módulos?
Edite os arquivos `terragrunt.hcl` e altere a versão:
```hcl
source = "tfr:///terraform-aws-modules/vpc/aws?version=5.2.0"
```

### Como fazer upgrade do Terraform/Terragrunt?
1. Baixe nova versão
2. Teste em ambiente de dev
3. Atualize em produção

### Como adicionar novos recursos?
1. Crie novo diretório em `my-proj-devops/`
2. Adicione `terragrunt.hcl`
3. Configure dependências
4. Execute `terragrunt apply`

## Git

### Como configurar Git para projeto pessoal?
```bash
cd vpn-aws
git config --local user.email "seu-email@pessoal.com"
git config --local user.name "Seu Nome"
```

### Devo commitar arquivos .tfstate?
**NÃO!** O `.gitignore` já está configurado para ignorá-los. State fica no S3.

### Devo commitar .terragrunt-cache?
**NÃO!** Já está no `.gitignore`. É cache local.

## Produção

### Este projeto está pronto para produção?
Quase! Ajustes necessários:
1. Alterar senha do RDS
2. Configurar backups adequados
3. Habilitar multi-AZ para RDS (HA)
4. Adicionar monitoring/alertas
5. Configurar WAF (opcional)
6. Usar domínio personalizado para VPN

### Como criar múltiplos ambientes (dev, staging, prod)?
Duplique a pasta `my-proj-devops` para cada ambiente e ajuste `vars.hcl`.

### Como implementar CI/CD?
Use GitHub Actions, GitLab CI ou Jenkins com:
```bash
terragrunt run --all plan
terragrunt run --all apply --non-interactive
```

## Suporte

### Onde encontrar mais informações?
- [Terragrunt Docs](https://terragrunt.gruntwork.io/docs/)
- [Terraform AWS Modules](https://registry.terraform.io/namespaces/terraform-aws-modules)
- [Pritunl Docs](https://docs.pritunl.com/)
- [AWS Documentation](https://docs.aws.amazon.com/)

### Como reportar problemas?
Abra uma issue no repositório GitHub do projeto.

### Posso contribuir?
Sim! Faça um fork, crie uma branch, implemente melhorias e abra um Pull Request.

---

**Não encontrou sua pergunta? Abra uma issue no GitHub!** 🤝
