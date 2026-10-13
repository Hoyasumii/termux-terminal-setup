<div align="center">

# termux-terminal-setup

Um único script que deixa o **Termux** e o **Debian (proot-distro)** com o mesmo terminal do meu Mac:
zsh + plugins, starship, lsd, bat, mise, JetBrains Mono Nerd Font e a mesma paleta de cores.

<img src="https://skill-icons.alanreisanjo.workers.dev/icons?i=android,linux,debian,bash,zsh,starship,mise,git,github,curl" alt="Tecnologias" />

</div>

---

## Instalação

No **Termux** (fora do proot), rode:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Hoyasumii/termux-terminal-setup/main/setup-terminal.sh)
```

Ou baixe e execute:

```bash
curl -fsSLO https://raw.githubusercontent.com/Hoyasumii/termux-terminal-setup/main/setup-terminal.sh
bash setup-terminal.sh
```

No final, feche e abra o Termux de novo (ou rode `exec zsh`). Para entrar no Debian: `proot-distro login debian`.

## O que ele faz

### <img src="https://skill-icons.alanreisanjo.workers.dev/icons?i=android" height="22" align="top" /> Termux

- Atualiza o sistema e instala `zsh`, `git`, `curl`, `unzip`, `starship`, `lsd`, `bat`, `proot-distro` e `mise` (se estiver no repositório)
- Instala a **JetBrains Mono Nerd Font** em `~/.termux/font.ttf`
- Aplica a paleta escura do meu perfil do iTerm2 em `~/.termux/colors.properties`
- Instala os dotfiles e deixa o zsh como shell padrão

### <img src="https://skill-icons.alanreisanjo.workers.dev/icons?i=debian" height="22" align="top" /> Debian (proot-distro)

- Instala `zsh`, `git`, `curl`, `bat` e `lsd` via apt
- Instala o `starship` e o `mise` em `/usr/local/bin` pelos instaladores oficiais
- Aplica os mesmos dotfiles para o `root` e para cada usuário em `/home`, e deixa o zsh como shell padrão de todos

### <img src="https://skill-icons.alanreisanjo.workers.dev/icons?i=zsh" height="22" align="top" /> Shell

O mesmo `.zshrc` funciona nos dois ambientes:

| Item | Detalhe |
| --- | --- |
| Plugins ([antidote](https://github.com/mattmc3/antidote)) | `zsh-completions`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search` |
| Prompt | [starship](https://starship.rs), com uma etiqueta ` debian` quando você está dentro do proot |
| Aliases | `ls` / `ll` / `la` / `lt` → `lsd` · `cat` → `bat` (ou `batcat` no Debian) |
| Histórico | 50 000 entradas, compartilhado entre sessões, sem duplicatas |
| Setas ↑ ↓ | Busca no histórico pelo que você já digitou |

## Opções

| Variável | Padrão | Efeito |
| --- | --- | --- |
| `DISTRO` | `debian` | Nome da distro do proot-distro a configurar |
| `SKIP_DISTRO` | — | Se definida, configura só o Termux |

```bash
DISTRO=ubuntu bash setup-terminal.sh
SKIP_DISTRO=1 bash setup-terminal.sh
```

## Pode rodar de novo?

Pode. Arquivos que já existiam e eram diferentes são guardados como `*.bak.<data>` antes de serem substituídos, e o antidote só é atualizado se já estiver instalado.

## Paleta

| Cor | Hex |
| --- | --- |
| Fundo | `#15191f` |
| Texto | `#dcdcdc` |
| Cursor | `#ffffff` |
| ANSI 0–7 | `#14191e` `#b43c2a` `#00c200` `#c7c400` `#2744c7` `#c040be` `#00c5c7` `#c7c7c7` |
| ANSI 8–15 | `#686868` `#dd7975` `#58e790` `#ece100` `#a7abf2` `#e17ee1` `#60fdff` `#ffffff` |

---

<div align="center">

Ícones por [skill-icons](https://skill-icons.alanreisanjo.workers.dev/pt-BR/)

</div>
