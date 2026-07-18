# fdb-hudpremium

## Documentação do Contrato Lua -> Svelte (UI)

Este HUD foi construído em Svelte (Vite) e renderiza de forma condicional e autônoma, o que exige que o lado Lua seja explícito em *resetar* estados que não devem mais aparecer na tela.

**REGRA CRÍTICA DE RESET EXPLÍCITO:**
A renderização condicional de *todos* os campos (armadura, cavalo, oxigênio, urina, higiene, temperatura, veneno, doença e embriaguez) depende estritamente do `value` processado pela Store do Svelte. O Svelte *NÃO* esconde esses ícones automaticamente apenas porque o Lua "parou de enviá-los". 

Se o jogador curar um veneno, o lado Lua **DEVE OBRIGATORIAMENTE** enviar um evento com `poison = 0`.
Isso se aplica a tudo:
- `armor = 0` (quando o colete quebrar)
- `horseHealth = 0` (quando o jogador desmontar)
- `oxygen = 100` (quando respirar)
- `poison = 0` (quando tomar antídoto)
- `illness = 0` (quando curar doença)
- `drunkenness = 0` (quando passar o efeito do álcool)
- `coldResistance = 0 / heatResistance = 0` (quando o buff expirar)

Se você não enviar o valor de reset explicitamente, o ícone ficará preso eternamente na tela do jogador com o último valor recebido, gerando um "bug visual silencioso".
