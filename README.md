Este repositório contém um script em Power Query projetado para extrair, tratar e transformar dados brutos de eventos da API do Zabbix em insights estratégicos para o seu dashboard de monitoramento.

🎯 Objetivo do Projeto
O propósito deste script não é apenas listar erros, mas transformar dados técnicos em inteligência de negócio. Com ele, você conseguirá responder a três perguntas fundamentais para a saúde da sua infraestrutura:

Quem são os "agressores" de incidentes? (Quais hosts/serviços disparam mais alertas).

Qual o Host mais impactado? (Onde a infraestrutura está mais vulnerável).

Qual o alerta mais frequente? (Identificação de gargalos recorrentes que exigem ação definitiva).

⚙️ Como utilizar e adaptar
O script foi criado para ser flexível. Para colocá-lo em funcionamento no seu Power BI, siga os passos abaixo:

1. Preparação
No Power BI, vá em Obter Dados > Consulta em Branco > Exibição > Editor Avançado e cole o código fornecido.

2. Adaptação (Configurações iniciais)
Você precisará alterar apenas as primeiras variáveis do script:

url: Substitua "URL DO ZABBIX" pela URL completa da API do seu Zabbix (http://seu-zabbix/api_jsonrpc.php).

token: Substitua "TOKEN" pelo seu token de autenticação gerado no painel do Zabbix (Configurações > Usuários > Autenticação API).

TimestampInicio e TimestampFim: O script utiliza o formato Unix Epoch. Certifique-se de ajustar esses valores para o período que deseja analisar.

3. Personalização de Regras (Opcional)
O script possui um bloco chamado #"Tratar Eventos" e #"Adicionar Categoria". Você pode adaptar essas condicionais para agrupar alertas conforme a sua necessidade:

Snippet de código
// Exemplo de adaptação para novos alertas
else if Text.Contains(RawName, "SEU_NOVO_ALERTA") then "Categoria Personalizada"
📊 O que este script processa?
O script executa um processo de ETL (Extract, Transform, Load) completo:

Extração: Conecta via API e recupera todos os eventos de problema (value = 1) e recuperação (value = 0).

Cruzamento: Relaciona o início e fim de cada incidente para calcular o tempo real de indisponibilidade.

Limpeza: Remove ruídos (ex: hosts não identificados) e padroniza nomes de alertas.

Enriquecimento: Cria colunas calculadas como Duracao_Minutos e Categoria Alertas, facilitando a criação de gráficos de Pareto e tabelas de recorrência.

💡 Dica Estratégica
Para extrair o máximo valor, recomendo utilizar este script em conjunto com gráficos de Matriz ou Gráficos de Barras (Top N) no Power BI, usando a coluna Categoria Alertas como eixo principal. Isso isolará rapidamente os ativos que estão consumindo o tempo da sua equipe de TI.
