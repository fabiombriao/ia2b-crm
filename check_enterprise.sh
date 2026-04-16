#!/bin/bash

# ===========================================
# Script de Verificação do Enterprise
# ===========================================

echo "=========================================="
echo "  Chatwoot Enterprise - Verificação"
echo "=========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar 1: Diretório Enterprise
echo "1. Verificando diretório Enterprise..."
if [ -d "enterprise" ]; then
    echo -e "${GREEN}✓${NC} Diretório enterprise existe"
else
    echo -e "${RED}✗${NC} Diretório enterprise NÃO encontrado"
    exit 1
fi

# Verificar 2: Arquivo LICENSE
echo ""
echo "2. Verificando arquivo LICENSE..."
if [ -f "enterprise/LICENSE" ]; then
    echo -e "${GREEN}✓${NC} Arquivo LICENSE encontrado"
    echo "   Tamanho: $(du -h enterprise/LICENSE | cut -f1)"
else
    echo -e "${RED}✗${NC} Arquivo LICENSE NÃO encontrado"
    echo "   Coloque sua licença em: enterprise/LICENSE"
fi

# Verificar 3: Variáveis de ambiente
echo ""
echo "3. Verificando variáveis de ambiente..."
if [ -f ".env" ]; then
    if grep -q "INSTALLATION_PRICING_PLAN=enterprise" .env; then
        echo -e "${GREEN}✓${NC} INSTALLATION_PRICING_PLAN=enterprise configurado"
    else
        echo -e "${YELLOW}⚠${NC} INSTALLATION_PRICING_PLAN não configurado como 'enterprise'"
        echo "   Adicione: INSTALLATION_PRICING_PLAN=enterprise"
    fi

    if grep -q "DISABLE_ENTERPRISE" .env; then
        if grep -q "DISABLE_ENTERPRISE=true" .env; then
            echo -e "${RED}✗${NC} DISABLE_ENTERPRISE=true está ativado"
            echo "   Enterprise está DESATIVADO!"
        else
            echo -e "${GREEN}✓${NC} DISABLE_ENTERPRISE não está ativado"
        fi
    else
        echo -e "${GREEN}✓${NC} DISABLE_ENTERPRISE não definido (default: false)"
    fi
else
    echo -e "${RED}✗${NC} Arquivo .env NÃO encontrado"
    echo "   Crie o arquivo .env com as configurações"
fi

# Verificar 4: Arquivos do Enterprise
echo ""
echo "4. Verificando arquivos do Enterprise..."
enterprise_files=(
    "enterprise/lib/enterprise.rb"
    "enterprise/app/models/custom_role.rb"
    "enterprise/app/models/sla_policy.rb"
    "enterprise/app/models/company.rb"
    "enterprise/config/premium_features.yml"
    "enterprise/config/initializers/omniauth_saml.rb"
)

for file in "${enterprise_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file (FALTA)"
    fi
done

# Verificar 5: Rails console
echo ""
echo "5. Testando via Rails console..."
if command -v bundle &> /dev/null; then
    echo "   Executando verificações no Rails console..."
    echo ""

    # Verificar enterprise?
    result=$(bundle exec rails runner "puts ChatwootApp.enterprise?" 2>/dev/null)
    if [ "$result" == "true" ]; then
        echo -e "${GREEN}✓${NC} ChatwootApp.enterprise? = true"
    else
        echo -e "${RED}✗${NC} ChatwootApp.enterprise? = false ou erro"
    fi

    # Verificar self_hosted_enterprise?
    result=$(bundle exec rails runner "puts ChatwootApp.self_hosted_enterprise?" 2>/dev/null)
    if [ "$result" == "true" ]; then
        echo -e "${GREEN}✓${NC} ChatwootApp.self_hosted_enterprise? = true"
    else
        echo -e "${YELLOW}⚠${NC} ChatwootApp.self_hosted_enterprise? = false"
        echo "   Verifique se INSTALLATION_PRICING_PLAN=enterprise está configurado"
    fi

    # Verificar extensions
    result=$(bundle exec rails runner "puts ChatwootApp.extensions.inspect" 2>/dev/null)
    echo "   ChatwootApp.extensions = $result"
else
    echo -e "${YELLOW}⚠${NC} bundle não encontrado - pulando verificação do Rails"
fi

# Resumo
echo ""
echo "=========================================="
echo "  Resumo"
echo "=========================================="
echo ""

if [ -d "enterprise" ] && [ -f "enterprise/LICENSE" ] && \
   grep -q "INSTALLATION_PRICING_PLAN=enterprise" .env 2>/dev/null; then
    echo -e "${GREEN}✓ Enterprise está CONFIGURADO corretamente!${NC}"
    echo ""
    echo "Próximos passos:"
    echo "  1. Certifique-se de que todas as variáveis básicas estão configuradas"
    echo "  2. Execute: bundle exec rails db:migrate RAILS_ENV=production"
    echo "  3. Execute: bundle exec rake assets:precompile RAILS_ENV=production"
    echo "  4. Reinicie os serviços: sudo systemctl restart chatwoot-web.target"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠ Enterprise NÃO está totalmente configurado${NC}"
    echo ""
    echo "Verifique os itens marcados com ✗ acima"
    echo ""
    echo "Documentação completa:"
    echo "  cat ENTERPRISE_VPS_SETUP.md"
    echo ""
    exit 1
fi
