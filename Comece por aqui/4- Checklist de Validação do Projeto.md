# ✅ Checklist de Validação - VPN AWS Project

## 📋 Pré-Provisionamento

### AWS CLI
- [ ] AWS CLI instalado
- [ ] Profile `SeuPerfilAWS` configurado
- [ ] Credenciais válidas testadas: `aws sts get-caller-identity --profile SeuPerfilAWS`
- [ ] Região correta configurada (us-east-1)

### Ferramentas
- [ ] Terraform instalado (>= 1.5.0)
- [ ] Terragrunt instalado (>= 0.50.0)
- [ ] Git configurado (email local para projeto pessoal)

### Configuração do Projeto
- [ ] `config.hcl` com profile correto
- [ ] `root.hcl` com região correta
- [ ] `vars.hcl` com nome do projeto correto
- [ ] Senha do RDS alterada (se produção)

## 🚀 Provisionamento

### Inicialização
- [ ] `cd my-proj-devops`
- [ ] `terragrunt run --all init` executado com sucesso
- [ ] Bucket S3 criado: `my-proj-devops-terraform-state-test`
- [ ] Tabela DynamoDB criada: `my-proj-devops-terraform-lock-test`

### Planejamento
- [ ] `terragrunt run --all plan` executado
- [ ] Plano revisado (número de recursos a criar)
- [ ] Sem erros de validação
- [ ] Dependências resolvidas corretamente

### Aplicação
- [ ] `terragrunt run --all apply` executado
- [ ] VPC criada com sucesso
- [ ] Security Groups criados
- [ ] EC2 VPN provisionada
- [ ] EC2 App provisionada
- [ ] RDS PostgreSQL criado

## 🔍 Validação da Infraestrutura

### VPC
- [ ] VPC criada: `my-proj-devops-vpc-test`
- [ ] CIDR: 10.0.0.0/16
- [ ] 2 subnets públicas criadas
- [ ] 2 subnets privadas criadas
- [ ] 2 subnets database criadas
- [ ] Internet Gateway criado
- [ ] Route tables configuradas

### EC2 VPN
- [ ] Instance criada: `my-proj-devops-vpn-test`
- [ ] IP público atribuído
- [ ] Security Group correto
- [ ] User data executado (Docker + Pritunl)
- [ ] IAM Role com SSM anexada
- [ ] Acessível via SSM Session Manager

### EC2 App
- [ ] Instance criada: `my-proj-devops-app-test`
- [ ] Em subnet privada
- [ ] Sem IP público
- [ ] Security Group correto
- [ ] User data executado (Nginx)
- [ ] IAM Role com SSM anexada
- [ ] Acessível via SSM Session Manager

### RDS
- [ ] Instance criada: `my-proj-devops-rds-test`
- [ ] Engine: PostgreSQL 15.4
- [ ] Em subnet database
- [ ] Security Group correto
- [ ] Endpoint disponível
- [ ] Backup configurado (7 dias)
- [ ] Criptografia habilitada

### Security Groups
- [ ] SG VPN: portas 443, 1194/udp, 80 abertas
- [ ] SG App: portas 22, 80, 443 apenas da VPC
- [ ] SG RDS: porta 5432 apenas da VPC

## 🔐 Configuração da VPN

### Acesso ao Pritunl
- [ ] IP público da EC2 VPN obtido
- [ ] Acesso via HTTPS funcionando: `https://<IP_PUBLICO>`
- [ ] Senha padrão resgatada via SSM
- [ ] Login realizado com sucesso

### Configuração Pritunl
- [ ] Organização criada
- [ ] Usuário criado
- [ ] Server criado (porta 1194 UDP)
- [ ] DNS configurado (8.8.8.8, 10.0.0.2)
- [ ] Organização anexada ao server
- [ ] Server iniciado

### Cliente VPN
- [ ] Cliente Pritunl instalado
- [ ] Perfil .ovpn baixado
- [ ] Perfil importado no cliente
- [ ] Conexão VPN estabelecida

## 🧪 Testes de Conectividade

### Teste RDS
- [ ] VPN conectada
- [ ] Cliente PostgreSQL configurado
- [ ] Conexão ao RDS bem-sucedida
- [ ] Query de teste executada
- [ ] Tabela criada e dados inseridos

### Teste EC2 App
- [ ] VPN conectada
- [ ] Acesso via SSM funcionando
- [ ] Nginx rodando
- [ ] Arquivo de teste criado

### Teste de Rede
- [ ] Ping entre EC2 VPN e EC2 App
- [ ] Resolução DNS interna funcionando
- [ ] Acesso ao RDS via endpoint DNS

## 📊 Outputs Validados

### VPC
```bash
cd vpc && terragrunt output
```
- [ ] vpc_id
- [ ] vpc_cidr_block
- [ ] private_subnets
- [ ] public_subnets
- [ ] database_subnets

### EC2 VPN
```bash
cd ec2/vpn && terragrunt output
```
- [ ] id
- [ ] public_ip
- [ ] private_ip

### EC2 App
```bash
cd ec2/app && terragrunt output
```
- [ ] id
- [ ] private_ip

### RDS
```bash
cd rds && terragrunt output
```
- [ ] db_instance_endpoint
- [ ] db_instance_name
- [ ] db_instance_username

## 🔒 Segurança

### Credenciais
- [ ] Senha do RDS alterada (se produção)
- [ ] Credenciais AWS não commitadas
- [ ] .gitignore configurado corretamente

### Acesso
- [ ] EC2 App sem IP público
- [ ] RDS em subnet privada
- [ ] Security Groups restritivos
- [ ] Acesso apenas via VPN aos recursos privados

### Criptografia
- [ ] EBS volumes criptografados
- [ ] RDS storage criptografado
- [ ] State S3 criptografado

## 💰 Custos

### Recursos Ativos
- [ ] EC2 VPN (t3a.small): ~$15/mês
- [ ] EC2 App (t3a.micro): ~$7/mês
- [ ] RDS (db.t3.micro): ~$15/mês
- [ ] EBS volumes: ~$2/mês
- [ ] S3 + DynamoDB: < $1/mês
- [ ] **Total estimado**: ~$40/mês

### Monitoramento
- [ ] AWS Cost Explorer configurado
- [ ] Alertas de billing configurados (opcional)
- [ ] Tags aplicadas para rastreamento

## 📝 Documentação

### Arquivos Criados
- [ ] README.md (principal)
- [ ] TERRAGRUNT_GUIDE.md
- [ ] COMMANDS.md
- [ ] SETUP_SUMMARY.md
- [ ] my-proj-devops/README.md
- [ ] .gitignore

### Git
- [ ] Repositório inicializado
- [ ] Commit inicial realizado
- [ ] Push para GitHub realizado
- [ ] Email local configurado (pessoal)

## 🧹 Limpeza (Quando Terminar)

### Destruir Recursos
- [ ] `cd my-proj-devops`
- [ ] `terragrunt run --all destroy`
- [ ] Confirmar destruição de todos os recursos
- [ ] Verificar no console AWS

### Limpar State
- [ ] Bucket S3 vazio (se necessário)
- [ ] Tabela DynamoDB vazia (se necessário)
- [ ] Cache local limpo

## ✨ Resultado Final

Após completar todos os itens:

✅ Infraestrutura AWS provisionada
✅ VPN Pritunl configurada e funcionando
✅ Acesso seguro aos recursos privados
✅ RDS PostgreSQL acessível via VPN
✅ EC2 App acessível via VPN
✅ Documentação completa
✅ Código versionado no Git

---

**Status do Projeto**: [ ] Em Progresso | [ ] Concluído | [ ] Destruído

**Data**: ___/___/______

**Notas**:
_____________________________________________
_____________________________________________
_____________________________________________
