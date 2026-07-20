# Registro de Progresso e Planejamento — fdb-hudpremium

Este documento registra todo o histórico de desenvolvimento do HUD, os problemas superados, a especificação técnica atual e o planejamento das próximas fases. Ele serve como memória para futuras sessões da IA e auditorias.

---

## 1. O que já foi feito e está 100% Funcional (Fase 1 e LUA-1)

### Frontend (Svelte + Vite)
- **Base Transparente:** O CSS padrão do Svelte (`app.css`) foi totalmente limpo e substituído por uma base transparente de tela cheia (`width: 100vw; height: 100vh; background: transparent !important`). O mouse e cliques não bloqueiam o jogo por padrão (`pointer-events: none`).
- **Resolução de Caminhos (NUI Assets):** Configurado `base: './'` no `vite.config.js` e alterado todos os caminhos de imagens em `StatusCores.svelte` de absolutos (`/assets/`) para relativos (`./assets/`) para evitar erros 404 de carregamento dentro do protocolo CEF do RedM (`nui://`).
- **Ícones SVG Otimizados (SVGO):** Todos os 18 ícones SVG originais foram minificados pelo SVGO, caindo de milhares de linhas para apenas uma linha por arquivo, reduzindo drasticamente o tamanho do bundle final.
- **Renderização dos Ícones (Compatibilidade CEF):** Substituída a lógica de `mask-image` com variáveis CSS (que falhava no CEF do RedM) por uma estrutura nativa com tags `<img>`, usando filtros de cor CSS (`filter: brightness(0) invert(1)`) e uma div de corte (`clip-path` dinâmico via altura) que simula o preenchimento de baixo para cima.

### Backend (Lua Client)
- **fxmanifest.lua:** Configurado o manifesto do zero apontando para a build do Vite (`ui/dist/index.html`), declarando os assets e o script de client.
- **Salvar Configurações (`saveSettings`):** Callback NUI que recebe as posições, escalas e cores customizadas em JSON e as armazena no cliente via `SetResourceKvp("fdb-hudpremium:settings", json.encode(data))`.
- **Fechar Menu (`closeEditor`):** Callback NUI que desativa o foco do mouse e teclado do jogo usando `SetNuiFocus(false, false)`.
- **Carregar Configurações (`loadSettings`):** Executado em `onResourceStart` e no callback `uiReady`, enviando as configurações salvas no KVP de volta para o Svelte via `SendNUIMessage`.
- **Comando `/hud`:** Registrado no Lua client para forçar o foco NUI (`SetNuiFocus(true, true)`) e mandar a action `toggleEditor` (com `value = true`) para abrir o painel de edição visual do HUD.

---

## 2. Referência Analisada (BLN HUD v2)

Fizemos uma auditoria completa do comportamento do BLN HUD v2 para estruturar o nosso norte de desenvolvimento:
- **Studio Editor:** Sidebar contendo *Global Settings* (Grid Size, Show Dark Background, layouts de minimapa), *Player Cores*, *Horse Cores*, *Other Cores* e *Extras*.
- **Editor por Elemento:** Opções de checkbox `Visible`, slider `Size`, inputs com pop-up Color Picker (Outer/Damage/Gold/Max/Inner Colors).
- **Segments:** Sistema para fatiar o anel de progresso em pedaços (estilo nativo RDR2).
- **Tip/Badge:** Textos ou valores numéricos dinâmicos flutuantes acima de cada círculo de status.
- **Extras:** Job Display, Money Display, Gold Display, User ID e relógio in-game.

---

## 3. Planejamento das Próximas Fases

### Fase Lua-2 — Dados e Ticks em Tempo Real (Próximo Passo)
- **Native HUD Hide:** Adicionar no `client/main.lua` o código para esconder os círculos de status nativos do RDR2.
- **Loop de Atualização:** Coletar a saúde e o fôlego reais do jogador e do cavalo (se montado) a cada 200~500ms e enviar para a UI.
- **Sistemas de Sobrevivência (Metabolismo):** Drenar fome e sede passivamente conforme o tempo passa, aplicando efeitos de vida caso fiquem zerados, e salvar esses dados no KVP.

### Fase UI-Editor — O Novo Painel
- Criar a aba lateral estilo Studio com abas e sliders para todas as cores (Outer, Inner, Damage, etc.).
- Implementar o Color Picker RGB no Svelte.
- Criar a visualização centralizada ampliada (100px) do componente que está sendo editado.

### Fase Extras — Munição e Status
- Adicionar o indicador flutuante de munição (Primary/Secondary).
- Adicionar displays no canto superior esquerdo para dinheiro, ouro, cargo e ID.
