# CodexCount

Widget para a barra de menu do macOS que rastreia o consumo de tokens do [Codex CLI](https://github.com/openai/codex) em tempo real.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Funcionalidades

- **Visão diária** — tokens consumidos hoje
- **Visão semanal** — tokens da semana atual (segunda a domingo)
- **Visão mensal** — tokens do mês corrente
- **Filtro por período** — selecione datas de início e fim
- **Sessões detalhadas** — lista de sessões do dia com horário, projeto e total de tokens
- **Rate limits** — uso atual dos limites de taxa (input/output tokens por minuto)
- **Auto-refresh** — atualização automática a cada 15 minutos
- **Configurável** — seções visíveis personalizáveis + caminho dos logs

## Requisitos

- macOS 13 (Ventura) ou superior
- Swift 5.9+ (Command Line Tools do Xcode)
- [Codex CLI](https://github.com/openai/codex) instalado (gera os logs em `~/.codex/sessions/`)

## Instalação

```bash
git clone https://github.com/Renzo-Tognella/CodexCount.git
cd CodexCount
./install.sh
```

O script compila em modo release e instala o app em `~/Applications/CodexCount.app`.

Para iniciar manualmente:

```bash
open ~/Applications/CodexCount.app
```

### Iniciar no login

Vá em **System Settings → General → Login Items** e adicione `CodexCount.app`.

## Build manual

```bash
swift build -c release
```

O binário será gerado em `.build/release/CodexCount`.

## Configuração

Na primeira execução, o app usa o caminho padrão `~/.codex/sessions/`. Para alterar:

1. Clique no ícone na barra de menu
2. Vá em **Configurações** (ícone de engrenagem)
3. Selecione a pasta de sessões do Codex
4. Ative/desative as seções que deseja visualizar

## Como funciona

O Codex CLI salva logs de cada sessão em arquivos `.jsonl` organizados por data:

```
~/.codex/sessions/
  └── 2025/
      └── 06/
          └── 15/
              ├── rollout-2025-06-15T10-30-00-uuid.jsonl
              └── rollout-2025-06-15T14-45-00-uuid.jsonl
```

Cada arquivo contém eventos `token_count` com uso cumulativo. O CodexCount lê o último evento de cada sessão e agrega os totais por período.

### Detalhes dos tokens

| Campo | Descrição |
|-------|-----------|
| Input | Total de tokens de entrada |
| Cached | Tokens de entrada em cache (subconjunto de input) |
| Output | Total de tokens de saída |
| Reasoning | Tokens de raciocínio (subconjunto de output) |
| Total | Soma de input + output |

## Estrutura do projeto

```
codex_count/
├── Package.swift
├── Info.plist
├── install.sh
└── Sources/CodexCount/
    ├── CodexCountApp.swift          # Entry point
    ├── Models/
    │   └── TokenUsage.swift         # Modelos de dados
    ├── Services/
    │   ├── LogParser.swift          # Parser de arquivos .jsonl
    │   ├── SessionFinder.swift      # Busca de arquivos por período
    │   └── SettingsManager.swift    # Persistência de configurações
    ├── ViewModels/
    │   └── TokenViewModel.swift     # Lógica de negócio
    ├── Views/
    │   ├── ContentView.swift        # Interface principal
    │   └── SettingsView.swift       # Tela de configurações
    └── Helpers/
        └── TokenFormatter.swift     # Formatação de números
```

## Licença

MIT
