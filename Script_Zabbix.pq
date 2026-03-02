let
    url = "URL DO ZABBIX",
    token = "TOKEN",

    DataInicio = #datetime(2026, 2, 8, 0, 0, 0),
    DataFim = #datetime(2026, 2, 14, 23, 59, 59),

    UnixInicio = Number.ToText(Int64.From(Duration.TotalSeconds(DataInicio - #datetime(1970, 1, 1, 0, 0, 0)))),
    UnixFim = Number.ToText(Int64.From(Duration.TotalSeconds(DataFim - #datetime(1970, 1, 1, 0, 0, 0)))),

    CorpoRecord = [
        jsonrpc = "2.0",
        method = "event.get",
        params = [
            output = {"eventid", "r_eventid", "name", "severity", "clock", "value"},
            selectHosts = {"name"},
            sortfield = "clock",
            sortorder = "DESC",
            time_from = UnixInicio,
            time_till = UnixFim
        ],
        auth = token,
        id = 1
    ],
    
    CorpoJson = Json.FromValue(CorpoRecord),
    SourceRaw = Json.Document(Web.Contents(url, [Content = CorpoJson, Headers = [#"Content-Type"="application/json"]])),
    
    CheckError = if Record.HasFields(SourceRaw, "error") 
                 then error Error.Record("Erro na API Zabbix", SourceRaw[error][message], SourceRaw[error][data]) 
                 else SourceRaw[result],

    TabelaBase = Table.FromList(CheckError, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expandido" = Table.ExpandRecordColumn(TabelaBase, "Column1", {"eventid", "r_eventid", "name", "severity", "clock", "value", "hosts"}),

    EventosProblema = Table.SelectRows(#"Expandido", each ([value] = "1")),
    EventosRecuperacao = Table.SelectRows(#"Expandido", each ([value] = "0")),
    #"Cruzamento" = Table.NestedJoin(EventosProblema, {"r_eventid"}, EventosRecuperacao, {"eventid"}, "FimDados", JoinKind.LeftOuter),
    #"Expandir Fim" = Table.ExpandTableColumn(#"Cruzamento", "FimDados", {"clock"}, {"clock_fim"}),
    
    #"Extrair Host" = Table.AddColumn(#"Expandir Fim", "Host", each if [hosts] <> null and List.Count([hosts]) > 0 then Text.BeforeDelimiter([hosts]{0}[name], ".") else "DESCONHECIDO"),
    #"Data Inicio" = Table.AddColumn(#"Extrair Host", "Data Inicio", each #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, Number.From([clock])), type datetime),
    #"Data Fim" = Table.AddColumn(#"Data Inicio", "Data Fim", each if [clock_fim] = null then DateTime.LocalNow() else #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, Number.From([clock_fim])), type datetime),
    #"Adicionar Duracao" = Table.AddColumn(#"Data Fim", "Duracao_Minutos", each let Diff = [Data Fim] - [Data Inicio], TotalMinutos = Duration.TotalMinutes(Diff) in Number.Round(if TotalMinutos < 0 then 0 else TotalMinutos, 2), type number),

    #"Adicionar Colunas Estrategicas" = Table.AddColumn(#"Adicionar Duracao", "Temp", each 
        let 
            raw = Text.Upper([name]),
            sevNum = Number.From([severity]),
            
            eventoLimpo = 
                if Text.Contains(raw, "MEMORIA") or Text.Contains(raw, "MEMORY") then "MEMORY > 90%"
                else if Text.Contains(raw, "DISCO") or Text.Contains(raw, "DISK") then "DISK > 90%"
                else if Text.Contains(raw, "CPU") then "CPU > 90%"
                else [name],

            categoria = 
                if Text.Contains(raw, "PHP") or Text.Contains(raw, "APACHE") then "SERVIÇO"
                else if Text.Contains(raw, "MEMORIA") or Text.Contains(raw, "MEMORY") then "MEMORIA"
                else if Text.Contains(raw, "DISCO") or Text.Contains(raw, "DISK") then "DISCO"
                else if Text.Contains(raw, "CPU") then "CPU"
                else if Text.Contains(raw, "FORTIGATE") then "FIREWALL"
                else "OUTROS",

            severidadeTexto = 
                if sevNum = 5 then "Desastre"
                else if sevNum = 4 then "Alto"
                else if sevNum = 3 then "Médio"
                else if sevNum = 2 then "Aviso"
                else "Informação"
        in 
            [EventoLimpo = eventoLimpo, CategoriaFinal = categoria, SeveridadeTexto = severidadeTexto, OrdemSeveridade = sevNum]
    ),

    #"Expandir Colunas" = Table.ExpandRecordColumn(#"Adicionar Colunas Estrategicas", "Temp", {"EventoLimpo", "CategoriaFinal", "SeveridadeTexto", "OrdemSeveridade"}),

    #"Limpeza Final" = Table.TransformColumns(#"Expandir Colunas",{{"Host", Text.Upper, type text}}),
    #"Filtro Host" = Table.SelectRows(#"Limpeza Final", each ([Host] <> "DESCONHECIDO")),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Filtro Host",{{"OrdemSeveridade", Int64.Type}, {"Duracao_Minutos", type number}}),
    #"Colunas Finais" = Table.SelectColumns(#"Tipo Alterado", {"Host", "EventoLimpo", "CategoriaFinal", "SeveridadeTexto", "OrdemSeveridade", "Data Inicio", "Data Fim", "Duracao_Minutos"})
in
    #"Colunas Finais"
