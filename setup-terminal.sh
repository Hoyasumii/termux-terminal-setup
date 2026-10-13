#!/data/data/com.termux/files/usr/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# setup-terminal.sh — replica o terminal do Mac (zsh + antidote + starship +
# lsd + bat + mise, JetBrains Mono Nerd Font, paleta escura do iTerm2) no
# Termux E no Debian do proot-distro.
#
# Uso (no Termux, NÃO dentro do Debian):
#   bash setup-terminal.sh
#
# Variáveis opcionais:
#   DISTRO=debian        nome do proot-distro a configurar
#   SKIP_DISTRO=1        configura só o Termux
#
# Pode rodar quantas vezes quiser: arquivos existentes viram *.bak.<data>.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DISTRO="${DISTRO:-debian}"
STAMP="$(date +%Y%m%d-%H%M%S)"
WORK="$(mktemp -d "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/setup-terminal.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

c_blue=$'\e[1;34m'; c_green=$'\e[1;32m'; c_yellow=$'\e[1;33m'; c_red=$'\e[1;31m'; c_off=$'\e[0m'
step() { printf '\n%s==>%s %s\n' "$c_blue" "$c_off" "$*"; }
ok()   { printf '%s ✓%s %s\n' "$c_green" "$c_off" "$*"; }
warn() { printf '%s !%s %s\n' "$c_yellow" "$c_off" "$*"; }
die()  { printf '%s ✗%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }

[[ -n "${TERMUX_VERSION:-}" || -d /data/data/com.termux/files/usr ]] && [[ ! -r /etc/os-release ]] \
  || die "Rode este script no Termux, não dentro do proot."

# ── Dotfiles compartilhados (Termux e Debian usam os mesmos) ─────────────────
mkdir -p "$WORK/dotfiles"

cat > "$WORK/dotfiles/.zshrc" <<'ZSHRC'
# ── Ambiente ──────────────────────────────────────────
# /etc/os-release só existe dentro do proot (o Android não tem)
if [[ -r /etc/os-release ]]; then
  export IN_PROOT="$(. /etc/os-release; echo "${ID:-linux}")"
  export LANG="${LANG:-C.UTF-8}"
  export LC_ALL="${LC_ALL:-C.UTF-8}"
fi

# ── PATH ──────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Histórico ─────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# ── Plugins (antidote) ────────────────────────────────
source ~/.antidote/antidote.zsh
antidote load ~/.zsh_plugins.txt

# ── Autocompletar ─────────────────────────────────────
# -u: no proot os donos dos arquivos são "falsos", o check de segurança só atrapalha
autoload -Uz compinit && compinit -u

# Opções do zsh
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt autocd
bindkey -e
WORDCHARS=${WORDCHARS//[\/.-]}
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up    # setas em modo aplicação (Termux)
bindkey '^[OB' history-substring-search-down

# ── mise ──────────────────────────────────────────────
command -v mise >/dev/null && eval "$(mise activate zsh)"

# ── Aliases ───────────────────────────────────────────
if command -v lsd >/dev/null; then
  alias ls='lsd'
  alias ll='lsd -l'
  alias la='lsd -la'
  alias lt='lsd --tree'
fi
if command -v bat >/dev/null; then
  alias cat='bat --paging=never'
elif command -v batcat >/dev/null; then   # Debian instala como batcat
  alias bat='batcat'
  alias cat='batcat --paging=never'
fi

# ── Prompt (starship) ─────────────────────────────────
command -v starship >/dev/null && eval "$(starship init zsh)"
ZSHRC

cat > "$WORK/dotfiles/.zsh_plugins.txt" <<'PLUGINS'
zsh-users/zsh-completions kind:fpath path:src
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-history-substring-search
PLUGINS

mkdir -p "$WORK/dotfiles/.config"
cat > "$WORK/dotfiles/.config/starship.toml" <<'STARSHIP'
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = true

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[directory]
truncation_length = 3

# Mostra " debian" quando estiver dentro do proot
[env_var.IN_PROOT]
format = "[ $env_value]($style) "
style = "bold yellow"
STARSHIP

# Script que aplica os dotfiles numa home (usado nos dois lados)
cat > "$WORK/apply-dotfiles.sh" <<'APPLY'
#!/usr/bin/env bash
# uso: apply-dotfiles.sh <origem> <home> <stamp>
set -euo pipefail
src="$1"; home="$2"; stamp="$3"
install_file() {
  local rel="$1" dst="$home/$1"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" ]] && ! cmp -s "$src/$rel" "$dst"; then
    mv "$dst" "$dst.bak.$stamp"
    echo "   backup: $dst.bak.$stamp"
  fi
  cp "$src/$rel" "$dst"
}
install_file .zshrc
install_file .zsh_plugins.txt
install_file .config/starship.toml
# arquivo estático gerado pelo antidote no Mac aponta pra caminhos do macOS
rm -f "$home/.zsh_plugins.zsh"

if [[ -d "$home/.antidote/.git" ]]; then
  git -C "$home/.antidote" pull --quiet --ff-only || true
else
  rm -rf "$home/.antidote"
  git clone --quiet --depth=1 https://github.com/mattmc3/antidote.git "$home/.antidote"
fi
# baixa os plugins já agora, pra primeira abertura ser rápida
HOME="$home" zsh -c 'source ~/.antidote/antidote.zsh && antidote load ~/.zsh_plugins.txt' >/dev/null
APPLY
chmod +x "$WORK/apply-dotfiles.sh"

# ── Termux ────────────────────────────────────────────────────────────────────
step "Termux: atualizando pacotes"
export DEBIAN_FRONTEND=noninteractive
APT_OPTS=(-y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef)
apt-get update -q
apt-get "${APT_OPTS[@]}" upgrade -q
apt-get "${APT_OPTS[@]}" install -q zsh git curl unzip starship lsd bat proot-distro
apt-get "${APT_OPTS[@]}" install -q mise 2>/dev/null || warn "mise não disponível no repo do Termux (ok, é opcional)"
ok "pacotes instalados"

step "Termux: fonte JetBrains Mono Nerd Font"
mkdir -p ~/.termux
curl -fsSL -o "$WORK/font.zip" \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o -q "$WORK/font.zip" JetBrainsMonoNerdFont-Regular.ttf -d "$WORK"
[[ -f ~/.termux/font.ttf ]] && ! cmp -s "$WORK/JetBrainsMonoNerdFont-Regular.ttf" ~/.termux/font.ttf \
  && mv ~/.termux/font.ttf ~/.termux/font.ttf.bak."$STAMP"
cp "$WORK/JetBrainsMonoNerdFont-Regular.ttf" ~/.termux/font.ttf
ok "fonte instalada"

step "Termux: cores (paleta escura do seu iTerm2)"
cat > "$WORK/colors.properties" <<'COLORS'
background=#15191f
foreground=#dcdcdc
cursor=#ffffff
color0=#14191e
color1=#b43c2a
color2=#00c200
color3=#c7c400
color4=#2744c7
color5=#c040be
color6=#00c5c7
color7=#c7c7c7
color8=#686868
color9=#dd7975
color10=#58e790
color11=#ece100
color12=#a7abf2
color13=#e17ee1
color14=#60fdff
color15=#ffffff
COLORS
[[ -f ~/.termux/colors.properties ]] && ! cmp -s "$WORK/colors.properties" ~/.termux/colors.properties \
  && mv ~/.termux/colors.properties ~/.termux/colors.properties.bak."$STAMP"
cp "$WORK/colors.properties" ~/.termux/colors.properties
ok "cores aplicadas"

step "Termux: dotfiles + plugins"
"$WORK/apply-dotfiles.sh" "$WORK/dotfiles" "$HOME" "$STAMP"
chsh -s zsh
ok "zsh é o shell padrão do Termux"

command -v termux-reload-settings >/dev/null && termux-reload-settings || true

# ── Debian (proot-distro) ─────────────────────────────────────────────────────
if [[ -n "${SKIP_DISTRO:-}" ]]; then
  warn "SKIP_DISTRO definido — pulando o $DISTRO"
elif ! proot-distro login "$DISTRO" -- true 2>/dev/null; then
  warn "proot-distro '$DISTRO' não está instalado — pulando (instale com: proot-distro install $DISTRO)"
else
  step "$DISTRO: instalando pacotes e configurando"
  cat > "$WORK/inner.sh" <<'INNER'
#!/usr/bin/env bash
set -euo pipefail
src=/mnt/setup-terminal
stamp="$1"
export DEBIAN_FRONTEND=noninteractive
APT_OPTS=(-y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef)

apt-get update -q
apt-get "${APT_OPTS[@]}" install -q zsh git curl ca-certificates unzip bat
apt-get "${APT_OPTS[@]}" install -q lsd 2>/dev/null || echo " ! lsd não está no repo desta versão do Debian (ls normal será usado)"

if ! command -v starship >/dev/null; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin >/dev/null
fi
if ! command -v mise >/dev/null; then
  curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh >/dev/null || echo " ! falha ao instalar mise (opcional)"
fi

zsh_path="$(command -v zsh)"
grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" >> /etc/shells

configure_user() {
  local user="$1" home="$2"
  echo "   → $user ($home)"
  if [[ "$user" == root ]]; then
    bash "$src/apply-dotfiles.sh" "$src/dotfiles" "$home" "$stamp"
  else
    su - "$user" -s /bin/bash -c "bash '$src/apply-dotfiles.sh' '$src/dotfiles' '$home' '$stamp'" \
      || { bash "$src/apply-dotfiles.sh" "$src/dotfiles" "$home" "$stamp"; chown -R "$user:" "$home"; }
  fi
  usermod -s "$zsh_path" "$user"
}

configure_user root /root
# usuários normais (UID >= 1000 com home em /home)
while IFS=: read -r name _ uid _ _ home _; do
  [[ "$uid" -ge 1000 && "$uid" -lt 65534 && "$home" == /home/* && -d "$home" ]] && configure_user "$name" "$home"
done < /etc/passwd
INNER
  chmod +x "$WORK/inner.sh"
  proot-distro login "$DISTRO" --bind "$WORK:/mnt/setup-terminal" -- \
    bash /mnt/setup-terminal/inner.sh "$STAMP"
  ok "$DISTRO configurado (zsh é o shell padrão de root e dos usuários em /home)"
fi

# ── Fim ───────────────────────────────────────────────────────────────────────
printf '\n%sPronto!%s Feche e reabra o Termux (ou rode: exec zsh).\n' "$c_green" "$c_off"
printf 'Debian: proot-distro login %s   (ou --user <nome>)\n' "$DISTRO"
