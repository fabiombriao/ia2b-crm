# Guia de Instalação Chatwoot Enterprise na VPS

## Resumo Rápido

O Chatwoot Enterprise **já está injetado automaticamente** no seu código. Para ativá-lo na sua VPS, você precisa:

1. ✅ **Diretório enterprise presente** (já está no seu código)
2. ⚠️ **Licença válida** (requer assinatura paga)
3. ⚠️ **Configurar variável de ambiente** para ativar features enterprise

---

## 1. Como o Enterprise é Injetado

### Mecanismo de Injeção

O sistema usa **Ruby Modules** com `prepend` para estender funcionalidades:

```ruby
# lib/chatwoot_app.rb
module ChatwootApp
  def self.enterprise?
    return if ENV.fetch('DISABLE_ENTERPRISE', false)
    @enterprise ||= root.join('enterprise').exist?
  end
  
  def self.self_hosted_enterprise?
    enterprise? && !chatwoot_cloud? && 
      GlobalConfig.get_value('INSTALLATION_PRICING_PLAN') == 'enterprise'
  end
  
  def self.extensions
    if enterprise?
      %w[enterprise]
    else
      %w[]
    end
  end
end
```

### Quando o Enterprise é Carregado

```ruby
# config/application.rb
config.eager_load_paths << Rails.root.join('enterprise/lib')
config.eager_load_paths << Rails.root.join('enterprise/listeners')
config.eager_load_paths += Dir["#{Rails.root}/enterprise/app/**"]
config.paths['app/views'].unshift('enterprise/app/views')

# Carrega initializers do enterprise
enterprise_initializers = Rails.root.join('enterprise/config/initializers')
Dir[enterprise_initializers.join('**/*.rb')].each { |f| require f }
```

### Sistema de Prepend (Override de Métodos)

```ruby
# config/initializers/01_inject_enterprise_edition_module.rb
module InjectEnterpriseEditionModule
  def prepend_mod_with(constant_name, namespace: Object)
    each_extension_for(constant_name, namespace) do |constant|
      prepend_module(constant)  # Enterprise métodos são chamados primeiro
    end
  end
end

Module.prepend(InjectEnterpriseEditionModule)
```

**Exemplo de uso:**
```ruby
# app/models/account.rb
class Account < ApplicationRecord
  prepend_mod_with # Enterprise::Account é prependido
end

# enterprise/app/models/enterprise/account.rb
module Enterprise
  class Account < ApplicationRecord
    def some_method
      # Este método é chamado antes do original
      super  # Chama o método original se existir
    end
  end
end
```

---

## 2. Requisitos para Rodar Enterprise

### 2.1. Licença Enterprise (OBRIGATÓRIO)

**Você precisa de uma assinatura paga do Chatwoot Enterprise:**

1. Acesse: https://www.chatwoot.com/pricing
2. Entre em contato para assinatura Enterprise
3. Receberá um arquivo de licença: `LICENSE`
4. Coloque em: `enterprise/LICENSE`

**Verificação de licença:**
```ruby
# O sistema verifica se o arquivo LICENSE existe
# e valida contra os termos em https://www.chatwoot.com/terms-of-service
```

### 2.2. Variáveis de Ambiente

No seu `.env` ou configuração do servidor:

```bash
# Ativa o modo Enterprise (opcional - detecta automaticamente)
DISABLE_ENTERPRISE=false

# Define o plano de instalação (para self-hosted)
INSTALLATION_PRICING_PLAN=enterprise

# Opcional: Desabilita features específicas
# ENABLE_SAML_SSO_LOGIN=true
# ENABLE_GOOGLE_OAUTH_LOGIN=true
```

### 2.3. Features Enterprise Disponíveis

```yaml
# enterprise/config/premium_features.yml
Premium Features:
  - disable_branding          # Remove branding Chatwoot
  - audit_logs                # Logs de auditoria
  - sla                       # Políticas de SLA
  - custom_roles              # Roles customizadas
  - captain_integration       # IA Assistant (Copilot)
  - csat_review_notes         # Notas em CSAT
  - conversation_required_attributes  # Campos obrigatórios
```

---

## 3. Funcionalidades Enterprise

### 3.1. SAML SSO Authentication

**Arquivo:** `enterprise/app/models/account_saml_settings.rb`

**Configuração:**
```bash
# .env
ENABLE_SAML_SSO_LOGIN=true
SAML_IDP_SSO_URL=https://your-saml-provider.com/sso
SAML_IDP_CERT=your-certificate-here
SAML_ENTITY_ID=your-entity-id
```

### 3.2. Custom Roles

**Arquivo:** `enterprise/app/models/custom_role.rb`

Permite criar roles com permissões granulares além das 3 roles padrão (admin, agent, supervisor).

### 3.3. SLA Policies

**Arquivo:** `enterprise/app/models/sla_policy.rb`

Define SLAs para conversas:
- First response time
- Resolution time
- Priority levels

### 3.4. Audit Logs

**Arquivo:** `enterprise/app/models/audit_log.rb`

Rastreia todas as ações importantes na conta.

### 3.5. Companies/Organizations

**Arquivo:** `enterprise/app/models/company.rb`

Estrutura multi-nível:
```
Account (Tenant)
  └── Companies
        └── Contacts
```

### 3.6. Agent Capacity Policies

**Arquivo:** `enterprise/app/models/agent_capacity_policy.rb`

Limites de capacidade por agente:
- Máximo de conversas simultâneas
- Limites por inbox
- Políticas de atribuição

### 3.7. Captain AI (Copilot)

**Arquivos:** `enterprise/app/models/captain/*`

- Sugestão de respostas
- Geração automática de mensagens
- Análise de sentimentos

---

## 4. Passos para Instalação na VPS

### Passo 1: Verificar Pré-requisitos

```bash
# Verificar se enterprise está presente
ls -la enterprise/

# Deve conter:
# - LICENSE (após compra)
# - app/
# - config/
# - lib/
```

### Passo 2: Configurar Variáveis de Ambiente

Edite `.env`:

```bash
# Plano de instalação
INSTALLATION_PRICING_PLAN=enterprise

# Opcional: desabilitar enterprise (default: false)
# DISABLE_ENTERPRISE=false

# SAML SSO (se usar)
ENABLE_SAML_SSO_LOGIN=true

# Google OAuth (se usar)
ENABLE_GOOGLE_OAUTH_LOGIN=true
```

### Passo 3: Colocar a Licença

```bash
# Após comprar a licença, coloque o arquivo:
cp /caminho/para/sua/licença LICENSE enterprise/

# Verificar permissões
chmod 644 enterprise/LICENSE
```

### Passo 4: Rodar Migrations

```bash
# As migrations do enterprise são rodadas junto com as do core
bundle exec rails db:migrate RAILS_ENV=production
```

### Passo 5: Precompile Assets

```bash
bundle exec rake assets:precompile RAILS_ENV=production
```

### Passo 6: Reiniciar Serviços

```bash
# Reiniciar web e workers
sudo systemctl restart chatwoot-web.target
sudo systemctl restart chatwoot-worker.target
```

---

## 5. Verificação de Instalação

### 5.1. Verificar se Enterprise está Ativo

```ruby
# No Rails console
bundle exec rails c

# Verificar status
ChatwootApp.enterprise?
# => true (se enterprise estiver presente e não desabilitado)

ChatwootApp.self_hosted_enterprise?
# => true (se INSTALLATION_PRICING_PLAN=enterprise)

ChatwootApp.extensions
# => ["enterprise"]
```

### 5.2. Verificar Features no Frontend

No navegador, abra DevTools e verifique:

```javascript
// No console do navegador
window.CHATWOOT_CONFIG.IS_ENTERPRISE
// => true
```

### 5.3. Verificar Features Disponíveis

```ruby
# Lista de features enterprise
InstallationConfig.where(name: 'premium_features')

# Ou verificar no código
Enterprise::PremiumFeatures.all
```

---

## 6. Configurações Específicas

### 6.1. SAML SSO Configuração Completa

```yaml
# enterprise/config/initializers/omniauth_saml.rb
# Configuração detalhada do SAML
```

**Passos:**
1. Obter metadata do seu IdP (Okta, Azure AD, Keycloak, etc.)
2. Configurar URLs de SSO
3. Configurar certificado
4. Mapear atributos (email, nome, etc.)

### 6.2. Custom Branding (disable_branding)

```ruby
# enterprise/config/premium_installation_config.yml
InstallationConfig.create!(
  name: 'INSTALLATION_NAME',
  value: 'Sua Marca',
  flags: { enterprise_only: true }
)
```

### 6.3. Configurar SLA Policies

```ruby
# Via Rails console
bundle exec rails c

# Criar política de SLA
account = Account.first
sla_policy = account.sla_policies.create!(
  name: 'Premium Support',
  priority: 'high',
  first_response_time: 3600,  # 1 hora
  resolution_time: 86400      # 24 horas
)
```

---

## 7. Troubleshooting

### Problema: Enterprise não está carregando

**Solução:**
```bash
# Verificar se diretório existe
ls -la enterprise/

# Verificar variável de ambiente
echo $DISABLE_ENTERPRISE
# Deve estar vazio ou "false"

# Verificar no console
bundle exec rails c
ChatwootApp.enterprise?  # Deve retornar true
```

### Problema: Features enterprise não aparecem

**Solução:**
```bash
# Verificar plano de instalação
echo $INSTALLATION_PRICING_PLAN
# Deve ser "enterprise"

# Verificar no console
ChatwootApp.self_hosted_enterprise?  # Deve retornar true

# Verificar se assets foram pré-compilados
bundle exec rake assets:clobber
bundle exec rake assets:precompile
```

### Problema: Erro ao carregar initializers do enterprise

**Solução:**
```bash
# Verificar logs
tail -f log/production.log

# Verificar sintaxe dos arquivos Ruby
ruby -c enterprise/config/initializers/*.rb
```

---

## 8. Resumo das Variáveis de Ambiente

```bash
# ===== OBRIGATÓRIO PARA ENTERPRISE =====
INSTALLATION_PRICING_PLAN=enterprise

# ===== OPCIONAL =====
DISABLE_ENTERPRISE=false  # Default: false (não definir)

# ===== SAML SSO =====
ENABLE_SAML_SSO_LOGIN=true
SAML_IDP_SSO_URL=
SAML_IDP_CERT=
SAML_ENTITY_ID=

# ===== Google OAuth =====
ENABLE_GOOGLE_OAUTH_LOGIN=true

# ===== Azure AD =====
AZURE_APP_ID=

# ===== Outras Configurações =====
DEPLOYMENT_ENV=production  # ou 'cloud' para Chatwoot Cloud
```

---

## 9. Próximos Passos

1. **Comprar licença Enterprise** - https://www.chatwoot.com/pricing
2. **Colocar arquivo LICENSE** em `enterprise/LICENSE`
3. **Configurar variáveis** no `.env`
4. **Reiniciar serviços**
5. **Verificar instalação** via Rails console
6. **Configurar features específicas** (SAML, SLA, etc.)

---

## 10. Links Úteis

- **Pricing:** https://www.chatwoot.com/pricing
- **Terms:** https://www.chatwoot.com/terms-of-service
- **Docs Enterprise:** https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38
- **Suporte:** https://chatwoot.com/community

---

## Notas Importantes

⚠️ **Licença Obrigatória:** O código Enterprise requer uma licença válida. Usar sem licença viola os termos de serviço.

⚠️ **Single Database:** Todos os tenants compartilham o mesmo banco de dados com isolamento via `account_id`.

⚠️ **Support:** Para suporte Enterprise, contate https://www.chatwoot.com/contact-sales
