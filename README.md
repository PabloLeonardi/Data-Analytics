# Zabbix Incident Intelligence: Connector for Power BI

Este repositório contém um script robusto em **Power Query** projetado para extrair, tratar e transformar dados de eventos da API do Zabbix em insights estratégicos para dashboards de monitoramento.

![Status](https://img.shields.io/badge/Status-Production-brightgreen)
![Power Query](https://img.shields.io/badge/Language-Power%20Query-blue)

---

## 🎯 Objetivo
Este projeto visa transformar dados técnicos brutos em inteligência de negócio, permitindo responder a três perguntas fundamentais para a saúde da sua infraestrutura:

1. **Agressores de Incidentes:** Quais hosts e serviços disparam o maior volume de alertas?
2. **Impacto:** Qual host possui a maior indisponibilidade acumulada?
3. **Recorrência:** Qual é o alerta mais frequente que exige correção definitiva?

---

## ⚙️ Como Utilizar

1. No **Power BI Desktop**, vá em **Obter Dados** > **Consulta Em Branco** > Exibição.
2. Clique em **Editor Avançado** na faixa de opções superior.
3. Cole o código do script e clique em **Concluído**.
4. Certifique-se de preencher as variáveis de conexão:
   - `url`: A URL da API do seu servidor Zabbix.
   - `token`: Seu token de autenticação gerado no Zabbix.
   - `TimestampInicio` / `TimestampFim`: Defina o período de análise (formato Unix Epoch).

---

## 🛠️ Personalização

O script já inclui uma camada de tratamento para facilitar a análise:

* **Tratamento de Eventos:** O bloco `#"Tratar Eventos"` padroniza nomes de alertas complexos (ex: CPU, SWAP, Memória).
* **Categorização:** A coluna `Categoria Alertas` agrupa incidentes por tipo (Disco, Memória, Rede, etc.), permitindo filtros rápidos.

Para adicionar novas regras, basta editar o bloco condicional no script:

```powerquery
else if Text.Contains(RawName, "SEU_NOVO_ALERTA") then "Sua Categoria"
