let
    url = "URL DO ZABBIX",
    token = "TOKEN",
  
    TimestampInicio = "1770508800",
    TimestampFim = "1771027199",

    CorpoRecord = [
        jsonrpc = "2.0",
        method = "event.get",
        params = [
            output = {"eventid", "r_eventid", "name", "severity", "clock", "value"},
            selectHosts = {"name"},
            sortfield = "clock",
            sortorder = "DESC",
            time_from = TimestampInicio,
            time_till = TimestampFim
        ],
        auth = token,
        id = 1
    ],
    
    CorpoJson = Json.FromValue(CorpoRecord),
    Source = Json.Document(Web.Contents(url, [Content = CorpoJson, Headers = [#"Content-Type"="application/json"]])),
    result = Source[result],
    TabelaBase = Table.FromList(result, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expandido" = Table.ExpandRecordColumn(TabelaBase, "Column1", {"eventid", "r_eventid", "name", "severity", "clock", "value", "hosts"}),

    EventosProblema = Table.SelectRows(#"Expandido", each ([value] = "1")),
    EventosRecuperacao = Table.SelectRows(#"Expandido", each ([value] = "0")),

    #"Cruzamento" = Table.NestedJoin(EventosProblema, {"r_eventid"}, EventosRecuperacao, {"eventid"}, "FimDados", JoinKind.LeftOuter),
    #"Expandir Fim" = Table.ExpandTableColumn(#"Cruzamento", "FimDados", {"clock"}, {"clock_fim"}),

    #"Extrair Host" = Table.AddColumn(#"Expandir Fim", "Host", each if [hosts] <> null and List.Count([hosts]) > 0 then Text.BeforeDelimiter([hosts]{0}[name], ".") else "Desconhecido"),
    
    #"Data Inicio" = Table.AddColumn(#"Extrair Host", "Data Inicio", each #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, Number.From([clock])), type datetime),
    #"Data Fim" = Table.AddColumn(#"Data Inicio", "Data Fim", each if [clock_fim] = null then DateTime.LocalNow() else #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, Number.From([clock_fim])), type datetime),

    #"Adicionar Duracao" = Table.AddColumn(#"Data Fim", "Duracao_Minutos", each 
        let 
            Diff = [Data Fim] - [Data Inicio],
            TotalMinutos = Duration.TotalMinutes(Diff)
        in 
            Number.Round(TotalMinutos, 2), type number),

    #"Tratar Eventos" = Table.AddColumn(#"Adicionar Duracao", "Evento", each 
        let RawName = [name] in
            if Text.Contains(RawName, "CPU") then "CPU > 90%"
            else if Text.Contains(RawName, "SWAP") then "SWAP = 70%"
            else if Text.Contains(RawName, "MEMORIA") then "MEMORIA > 90%"
            else if Text.Contains(RawName, "DISCO") then "DISCO < 90%"
            else if Text.Contains(RawName, "reiniciado") then "API reiniciada"
            else RawName
    ),
    
    #"Mapear Severidade" = Table.AddColumn(#"Tratar Eventos", "Severidade", each 
        if [severity] = "5" then "Desastre"
        else if [severity] = "4" then "Alto"
        else if [severity] = "3" then "Médio"
        else if [severity] = "2" then "Aviso"
        else "Informação"
    ),
    
    #"Adicionar Ordem Severidade" = Table.AddColumn(#"Mapear Severidade", "Ordem Severidade", each Number.From([severity]), type number),

    #"Adicionar Categoria" = Table.AddColumn(#"Adicionar Ordem Severidade", "Categoria Alertas", each 
        if Text.Contains([Evento], "DISCO") then "Disco"
        else if Text.Contains([Evento], "MEMORIA") then "Memória"
        else if Text.Contains([Evento], "FortiGate") then "Firewall"
        else if Text.Contains([Evento], "CPU") then "CPU"
        else if Text.Contains([Evento], "SWAP") then "Memória"
        else if Text.Contains([Evento], "PHP") then "Serviço"
        else "Outros"
    ),

    #"Colunas Finais" = Table.SelectColumns(#"Adicionar Categoria", {"Host", "Evento", "Severidade", "Ordem Severidade", "Categoria Alertas", "Data Inicio", "Data Fim", "Duracao_Minutos", "eventid"}),
    #"Linhas Filtradas" = Table.SelectRows(#"Colunas Finais", each ([Host] <> "Desconhecido")),
    #"Valor Substituído" = Table.ReplaceValue(#"Linhas Filtradas","Número de processos do PHP-FPM atingiu o limite","PHP-FPM atingiu o limite",Replacer.ReplaceText,{"Evento"})
in
    #"Valor Substituído"
