#!/bin/bash
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;93m'
B='\033[1;94m'
C='\033[1;96m'
W='\033[1;97m'
RS='\033[0m'

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

term_width=$(tput cols)
BOX_WIDTH=$(( term_width > 60 ? 58 : term_width - 2 ))
margin=$(( (term_width - BOX_WIDTH) / 2 ))
left_pad=$(printf '%*s' "$margin" "")

draw_line() {
    printf "${C}${left_pad}%s" "$1"
    for ((i=0; i<BOX_WIDTH-2; i++)); do printf "═"; done
    printf "%s${RS}\n" "$2"
}

print_center() {
    local text="$1"
    local color="$2"
    local len=${#text}
    local space_len=$(( (BOX_WIDTH - 2 - len) / 2 ))
    printf "${C}${left_pad}║%*s${color}%s${C}%*s║${RS}\n" $space_len "" "$text" $(( BOX_WIDTH - 2 - len - space_len )) ""
}

banner() {
    clear
    local R="\e[1;31m" 
    local G="\e[1;32m" 
    local C="\e[1;36m" 
    local W="\e[1;37m"
    local Y="\e[1;33m" 
    local N="\e[0m"    

    echo -e "${C}     ██╗██████╗  ██████╗  ██████╗██╗  ██╗ █████╗ "
    echo -e "${C}     ██║██╔══██╗██╔═══██╗██╔════╝██║  ██║██╔══██╗"
    echo -e "${C}     ██║██████╔╝██║   ██║██║     ███████║███████║"
    echo -e "${C}██   ██║██╔══██╗██║   ██║██║     ██╔══██║██╔══██║"
    echo -e "${C}╚█████╔╝██║  ██║╚██████╔╝╚██████╗██║  ██║██║  ██║"
    echo -e "${C} ╚════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝"
    echo -e ""
    echo -e "${W}      --[ ${G}Termux Optimization Tool ${W}]--       "
    echo -e ""
    echo -e "${R} [!]${W} Author  : ${C}JROCHA"
    echo -e "${R} [!]${W} Version : ${Y}v3.5 (Stable)"
    echo -e ""
    echo -e "${G} ==============================================${N}"
    echo -e ""
}

ensure_dependencies() {
    echo -e "${Y}[*] Checking dependencies...${RS}"
    local missing=()
    for pkg in zsh fish git figlet toilet ruby wget curl bat eza unzip xz-utils ca-certificates; do
        if ! command -v "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${Y}[*] Installing missing dependencies: ${missing[*]}...${RS}"
        pkg update -y && pkg install "${missing[@]}" -y
    fi
}

do_full_setup() {
    ensure_dependencies
    if command -v gem &>/dev/null && ! command -v lolcat &>/dev/null; then
        echo -e "${Y}[*] Installing lolcat gem...${RS}"
        gem install lolcat -y 2>/dev/null || gem install lolcat
    fi
    mkdir -p ~/.termux
    [ -f "$REPO_DIR/.object/.termux.properties" ] && cp "$REPO_DIR/.object/.termux.properties" ~/.termux/termux.properties
    [ -f "$REPO_DIR/.object/.colors.properties" ] && cp "$REPO_DIR/.object/.colors.properties" ~/.termux/colors.properties
    
    if [ -f "$REPO_DIR/.object/ANSI Shadow.flf" ]; then
        mkdir -p "$PREFIX/share/figlet"
        cp "$REPO_DIR/.object/ANSI Shadow.flf" "$PREFIX/share/figlet/ASCII-Shadow.flf"
    fi

    if command -v termux-reload-settings &>/dev/null; then
        termux-reload-settings
    fi
    echo -e "${G}[√] Necessary Setup completed!${RS}"
    sleep 2
    menu
}

# Shell installation logic
do_zsh_setup() {
    ensure_dependencies
    if [ ! -d ~/.oh-my-zsh ]; then
        echo -e "${Y}[*] Cloning Oh My Zsh...${RS}"
        git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh --depth=1
    fi
    if [ ! -d ~/.oh-my-zsh/plugins/zsh-autosuggestions ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions --depth=1
    fi
    if [ ! -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting --depth=1
    fi
    do_customize_prompts_menu "zsh"
}

do_zsh_switch() {
    pkg install zsh -y
    local zsh_path=$(command -v zsh)
    if [ -n "$zsh_path" ]; then
        chsh -s "$zsh_path"
        echo -e "${G}[√] Shell switched to Zsh. Reloading session...${RS}"
        sleep 2
        exec "$zsh_path"
    else
        echo -e "${R}[!] Zsh binary not found. Shell not switched.${RS}"
        sleep 2
        zsh_menu
    fi
}

do_bash_switch() {
    local bash_path=$(command -v bash)
    if [ -n "$bash_path" ]; then
        chsh -s "$bash_path"
        echo -e "${G}[√] Shell switched to Bash. Reloading session...${RS}"
        sleep 2
        exec "$bash_path"
    else
        echo -e "${R}[!] Bash binary not found. Shell not switched.${RS}"
        sleep 2
        bash_menu
    fi
}

do_bash_setup() {
    ensure_dependencies
    if [ ! -d ~/.local/share/blesh ]; then
        echo -e "${Y}[*] Downloading and installing ble.sh (Bash Line Editor)...${RS}"
        mkdir -p /tmp
        curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz -o /tmp/ble-nightly.tar.xz 2>/dev/null || curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz -o ~/.termux/ble-nightly.tar.xz
        local tar_file="/tmp/ble-nightly.tar.xz"
        [ ! -f "$tar_file" ] && tar_file="$HOME/.termux/ble-nightly.tar.xz"
        
        tar -xJf "$tar_file" -C "$HOME/.termux/"
        mkdir -p ~/.local/share/blesh
        cp -a "$HOME/.termux/ble-nightly/"* ~/.local/share/blesh/
        rm -rf "$HOME/.termux/ble-nightly" "$tar_file"
    fi
    do_customize_prompts_menu "bash"
}

do_fish_setup() {
    ensure_dependencies
    mkdir -p ~/.config/fish
    do_customize_prompts_menu "fish"
}

do_fish_switch() {
    pkg install fish -y
    local fish_path=$(command -v fish)
    if [ -n "$fish_path" ]; then
        chsh -s "$fish_path"
        echo -e "${G}[√] Shell switched to Fish. Reloading session...${RS}"
        sleep 2
        exec "$fish_path"
    else
        echo -e "${R}[!] Fish binary not found. Shell not switched.${RS}"
        sleep 2
        fish_menu
    fi
}

# Unified prompts customization configuration
do_customize_prompts_menu() {
    local shell=$1
    banner
    printf "\n${left_pad}${C}───[${W} Customizing ${shell} prompt & banner ${C}]───"
    
    echo -ne "\n${left_pad}${Y}[?]${W} Enter Welcome Banner Text (Default: JROCHA): ${RS}"
    read banner_text
    [ -z "$banner_text" ] && banner_text="JROCHA"
    
    echo -ne "${left_pad}${Y}[?]${W} Enter Shell Username (Default: JROCHA): ${RS}"
    read username
    [ -z "$username" ] && username="JROCHA"
    
    banner
    printf "\n${left_pad}${C}───[${W} Select FIGlet Font Style ${C}]───"
    printf "\n${left_pad}${C}[${W}1${C}]${G} ASCII-Shadow (Default)"
    printf "\n${left_pad}${C}[${W}2${C}]${G} Standard"
    printf "\n${left_pad}${C}[${W}3${C}]${G} Slant"
    printf "\n${left_pad}${C}[${W}4${C}]${G} Doom"
    printf "\n${left_pad}${C}[${W}5${C}]${G} Block\n\n"
    echo -ne "${left_pad}${C}Selection: ${RS}"
    read font_sel
    local fig_font="ASCII-Shadow"
    case $font_sel in
        2) fig_font="Standard" ;;
        3) fig_font="Slant" ;;
        4) fig_font="Doom" ;;
        5) fig_font="Block" ;;
    esac
    
    banner
    printf "\n${left_pad}${C}───[${W} Select Banner Color Style ${C}]───"
    printf "\n${left_pad}${C}[${W}1${C}]${G} Lolcat (Rainbow)"
    printf "\n${left_pad}${C}[${W}2${C}]${G} Matrix (Glowing Green)"
    printf "\n${left_pad}${C}[${W}3${C}]${G} Cyber (Cyan/Magenta)"
    printf "\n${left_pad}${C}[${W}4${C}]${G} Plain White\n\n"
    echo -ne "${left_pad}${C}Selection: ${RS}"
    read color_sel
    local color_style="lolcat"
    case $color_sel in
        2) color_style="matrix" ;;
        3) color_style="cyber" ;;
        4) color_style="white" ;;
    esac
    
    banner
    printf "\n${left_pad}${C}───[${W} Select Prompt Symbol ${C}]───"
    printf "\n${left_pad}${C}[${W}1${C}]${G} ❯ (Standard Arrow)"
    printf "\n${left_pad}${C}[${W}2${C}]${G} \$ (Classic Unix)"
    printf "\n${left_pad}${C}[${W}3${C}]${G} ⚡ (Power Bolt)"
    printf "\n${left_pad}${C}[${W}4${C}]${G} 🚀 (Rocket)"
    printf "\n${left_pad}${C}[${W}5${C}]${G} 💀 (Skull)"
    printf "\n${left_pad}${C}[${W}6${C}]${G} 🔥 (Flame)"
    printf "\n${left_pad}${C}[${W}7${C}]${G} 👾 (Alien)\n\n"
    echo -ne "${left_pad}${C}Selection: ${RS}"
    read sym_sel
    local prompt_sym="❯"
    case $sym_sel in
        2) prompt_sym="\$" ;;
        3) prompt_sym="⚡" ;;
        4) prompt_sym="🚀" ;;
        5) prompt_sym="💀" ;;
        6) prompt_sym="🔥" ;;
        7) prompt_sym="👾" ;;
    esac
    
    banner
    printf "\n${left_pad}${C}───[${W} Select Prompt Layout Style ${C}]───"
    printf "\n${left_pad}${C}[${W}1${C}]${G} Cyberpunk Outline (Default)"
    printf "\n${left_pad}${C}[${W}2${C}]${G} Minimalist (Single Line)"
    printf "\n${left_pad}${C}[${W}3${C}]${G} Git-Aware (Classic styling)\n\n"
    echo -ne "${left_pad}${C}Selection: ${RS}"
    read layout_sel
    local prompt_layout="cyberpunk"
    case $layout_sel in
        2) prompt_layout="minimalist" ;;
        3) prompt_layout="git-aware" ;;
    esac
    
    apply_shell_customizations "$shell" "$banner_text" "$username" "$fig_font" "$color_style" "$prompt_sym" "$prompt_layout"
}

apply_shell_customizations() {
    local shell=$1
    local banner_text=$2
    local username=$3
    local fig_font=$4
    local color_style=$5
    local prompt_sym=$6
    local prompt_layout=$7
    
    ensure_dependencies
    
    local figlet_dir=""
    if [ -n "$PREFIX" ]; then
        figlet_dir="$PREFIX/share/figlet"
    else
        figlet_dir="$HOME/.local/share/figlet"
    fi
    mkdir -p "$figlet_dir"

    # Copy bundled ASCII-Shadow font if it exists
    if [ -f "$REPO_DIR/.object/ANSI Shadow.flf" ]; then
        cp "$REPO_DIR/.object/ANSI Shadow.flf" "$figlet_dir/ASCII-Shadow.flf"
    fi

    # CORREÇÃO APLICADA AQUI: Força o download da fonte se ela não existir, mesmo sendo a ASCII-Shadow
    if [ ! -f "$figlet_dir/$fig_font.flf" ] || [ ! -s "$figlet_dir/$fig_font.flf" ]; then
        echo -e "${Y}[*] Downloading figlet font: $fig_font...${RS}"
        curl -s -L "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/$fig_font.flf" -o "$figlet_dir/$fig_font.flf"
        # Fallback if download failed
        if [ ! -f "$figlet_dir/$fig_font.flf" ] || [ ! -s "$figlet_dir/$fig_font.flf" ]; then
            echo -e "${R}[!] Failed to download $fig_font.flf, using Standard.${RS}"
            fig_font="Standard"
            if [ ! -f "$figlet_dir/Standard.flf" ]; then
                curl -s -L "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/Standard.flf" -o "$figlet_dir/Standard.flf"
            fi
        fi
    fi

    local banner_script="$HOME/.termux-os-banner.sh"
    cat << 'EOF' > "$banner_script"
#!/bin/bash
clear
echo -e '\033[1;32m[*] BOOTING JROCHA...'
echo -ne '\033[1;36m[LOADING MODULES] \033[1;32m'
for i in {1..25}; do echo -ne '█'; sleep 0.01; done
echo -e '\033[0m'
sleep 0.2
clear

BOX_WIDTH=56
cyan='\033[0;36m'
reset='\033[0m'
EOF

    echo "FIGLET_DIR=\"$figlet_dir\"" >> "$banner_script"

    cat << 'EOF' >> "$banner_script"
print_center() { local text="$1"; local len=${#text}; local space_len=$(( (BOX_WIDTH - 2 - len) / 2 )); printf "${cyan} ║%*s${reset}%s${cyan}%*s║${reset}\n" $space_len "" "$text" $(( BOX_WIDTH - 2 - len - space_len )) ""; }
draw_line() { local char=$1; local end=$2; printf "${cyan} %s" "$char"; for ((i=0; i<BOX_WIDTH-2; i++)); do printf "═"; done; printf "%s${reset}\n" "$end"; }

draw_line '╔' '╗'
print_center ''
EOF

    if [ "$color_style" = "lolcat" ]; then
        if command -v gem &>/dev/null && ! command -v lolcat &>/dev/null; then
            gem install lolcat -y 2>/dev/null || gem install lolcat
        fi
        echo "figlet -d \"\$FIGLET_DIR\" -c -f '$fig_font' -w \$BOX_WIDTH '$banner_text' 2>/dev/null | lolcat 2>/dev/null || printf '  $banner_text\\n'" >> "$banner_script"
    elif [ "$color_style" = "matrix" ]; then
        echo "echo -e '\\033[1;32m'" >> "$banner_script"
        echo "figlet -d \"\$FIGLET_DIR\" -c -f '$fig_font' -w \$BOX_WIDTH '$banner_text' 2>/dev/null || printf '  $banner_text\\n'" >> "$banner_script"
        echo "echo -e '\\033[0m'" >> "$banner_script"
    elif [ "$color_style" = "cyber" ]; then
        echo "echo -e '\\033[1;36m'" >> "$banner_script"
        echo "figlet -d \"\$FIGLET_DIR\" -c -f '$fig_font' -w \$BOX_WIDTH '$banner_text' 2>/dev/null || printf '  $banner_text\\n'" >> "$banner_script"
        echo "echo -e '\\033[0m'" >> "$banner_script"
    else
        echo "echo -e '\\033[1;37m'" >> "$banner_script"
        echo "figlet -d \"\$FIGLET_DIR\" -c -f '$fig_font' -w \$BOX_WIDTH '$banner_text' 2>/dev/null || printf '  $banner_text\\n'" >> "$banner_script"
        echo "echo -e '\\033[0m'" >> "$banner_script"
    fi
    
    cat << EOF >> "$banner_script"
print_center ''
print_center 'SYSTEM: ONLINE  |  USER: $username'
if command -v termux-battery-status &>/dev/null; then
    bat_info=\$(termux-battery-status | grep -E 'percentage|status' | tr -d '", ' | paste -sd ' | ')
    [ -n "\$bat_info" ] && print_center "\$bat_info"
fi
if command -v free &>/dev/null; then
    mem_info=\$(free -m | awk '/Mem:/ {print "RAM: " \$3 "MB / " \$2 "MB"}')
    [ -n "\$mem_info" ] && print_center "\$mem_info"
fi
print_center 'SECURE CONNECTION ESTABLISHED'
print_center ''
draw_line '╚' '╝'
EOF

    chmod +x "$banner_script"
    if [ -f "$REPO_DIR/.object/ANSI Shadow.flf" ]; then
        mkdir -p "$PREFIX/share/figlet"
        cp "$REPO_DIR/.object/ANSI Shadow.flf" "$PREFIX/share/figlet/ASCII-Shadow.flf"
    fi

    if [ "$shell" = "bash" ]; then
        [ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc.bak
        
        echo '[[ ${USER-} ]] || export USER=$(id -un)' > ~/.bashrc
        echo "export LANG=en_US.UTF-8" >> ~/.bashrc
        echo "export LC_CTYPE=POSIX" >> ~/.bashrc
        echo "[[ -f ~/.local/share/blesh/ble.sh ]] && source ~/.local/share/blesh/ble.sh" >> ~/.bashrc
        echo "bash $banner_script" >> ~/.bashrc

        local blerc="$HOME/.blerc"
        if [ ! -f "$blerc" ]; then
            cat << 'EOF' > "$blerc"
# Suppress broken locale warnings in Termux safely
function ble/util/notify-broken-locale {
  return 0
}
EOF
        elif ! grep -Fq 'ble/util/notify-broken-locale' "$blerc"; then
            cat << 'EOF' >> "$blerc"

# Suppress broken locale warnings in Termux safely
function ble/util/notify-broken-locale {
  return 0
}
EOF
        fi
        
        if [ "$prompt_layout" = "cyberpunk" ]; then
            cat << 'EOF' >> ~/.bashrc
set_bash_prompt() {
    local EXIT="$?"
    local RED="\[\033[1;31m\]"
    local GREEN="\[\033[1;32m\]"
    local WHITE="\[\033[1;37m\]"
    local CYAN="\[\033[1;36m\]"
    local RESET="\[\033[0m\]"
    local git_info=""
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            git_info=" \[\033[1;31m\](${branch}*)${RESET}"
        else
            git_info=" \[\033[1;32m\](${branch})${RESET}"
        fi
    fi
    local arrow="${GREEN}__SYMBOL__"
    if [ "$EXIT" -ne 0 ]; then
        arrow="${RED}__SYMBOL__"
    fi
    PS1="\n${RED}┌─[${GREEN}__USERNAME__${RED}@${WHITE}termux${RED}]─[${CYAN}\w${RED}]${git_info}\n${RED}└─╼ ${arrow} ${RESET}"
}
PROMPT_COMMAND=set_bash_prompt
EOF
        elif [ "$prompt_layout" = "minimalist" ]; then
            cat << 'EOF' >> ~/.bashrc
set_bash_prompt() {
    local EXIT="$?"
    local RED="\[\033[1;31m\]"
    local GREEN="\[\033[1;32m\]"
    local CYAN="\[\033[1;36m\]"
    local RESET="\[\033[0m\]"
    local arrow="${GREEN}__SYMBOL__"
    if [ "$EXIT" -ne 0 ]; then
        arrow="${RED}__SYMBOL__"
    fi
    PS1="${CYAN}\w ${arrow} ${RESET}"
}
PROMPT_COMMAND=set_bash_prompt
EOF
        else
            cat << 'EOF' >> ~/.bashrc
set_bash_prompt() {
    local EXIT="$?"
    local GREEN="\[\033[1;32m\]"
    local RED="\[\033[1;31m\]"
    local YELLOW="\[\033[1;33m\]"
    local BLUE="\[\033[1;34m\]"
    local RESET="\[\033[0m\]"
    local git_info=""
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        git_info=" \[\033[1;33m\]git:(${branch})${RESET}"
    fi
    local arrow="${GREEN}__SYMBOL__"
    if [ "$EXIT" -ne 0 ]; then
        arrow="${RED}__SYMBOL__"
    fi
    PS1="\[\033[1;35m\]__USERNAME__ \[\033[1;34m\]\w${git_info} ${arrow} ${RESET}"
}
PROMPT_COMMAND=set_bash_prompt
EOF
        fi
        
        sed -i "s/__USERNAME__/$username/g" ~/.bashrc
        sed -i "s/__SYMBOL__/$prompt_sym/g" ~/.bashrc
        
        cat << 'EOF' >> ~/.bashrc
alias l='eza -la'
alias ls='command ls'
alias cat='command cat'
alias ll='eza -l'
EOF

    elif [ "$shell" = "zsh" ]; then
        [ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak
        
        cat << 'EOF' > ~/.zshrc
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="jrocha"
plugins=(git)
source $HOME/.oh-my-zsh/oh-my-zsh.sh
[[ -f "$HOME"/.oh-my-zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source "$HOME"/.oh-my-zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f "$HOME"/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source "$HOME"/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
bash ~/.termux-os-banner.sh
alias l='eza -la'
alias ls='command ls'
alias cat='command cat'
alias ll='eza -l'
EOF
        
        mkdir -p ~/.oh-my-zsh/themes
        local theme_file="$HOME/.oh-my-zsh/themes/jrocha.zsh-theme"
        
        if [ "$prompt_layout" = "cyberpunk" ]; then
            cat << 'EOF' > "$theme_file"
autoload -U colors && colors
setopt prompt_subst
function parse_git_status() {
    git rev-parse --is-inside-work-tree &>/dev/null || return
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        echo " %{$fg_bold[red]%}(${branch}*)%{$reset_color%}"
    else
        echo " %{$fg_bold[green]%}(${branch})%{$reset_color%}"
    fi
}
local user_info="%{$fg_bold[red]%}[%{$fg_bold[green]%}__USERNAME__%{$fg_bold[red]%}@%{$fg_bold[white]%}termux%{$fg_bold[red]%}]"
local current_dir="%{$fg_bold[red]%}[%{$fg_bold[cyan]%}%(5~|%-1~/…/%2~|%4~)%{$fg_bold[red]%}]"
local git_info='$(parse_git_status)'
local status_arrow="%(?.%{$fg_bold[green]%}__SYMBOL__.%{$fg_bold[red]%}__SYMBOL__)"
PROMPT="
%{$fg_bold[red]%}┌─${user_info}─${current_dir}${git_info}
%{$fg_bold[red]%}└─╼ ${status_arrow} %{$reset_color%}"
EOF
        elif [ "$prompt_layout" = "minimalist" ]; then
            cat << 'EOF' > "$theme_file"
autoload -U colors && colors
setopt prompt_subst
local current_dir="%{$fg[cyan]%}%~%{$reset_color%}"
local status_arrow="%(?.%{$fg_bold[green]%}__SYMBOL__.%{$fg_bold[red]%}__SYMBOL__)"
PROMPT="${current_dir} ${status_arrow} "
EOF
        else
            cat << 'EOF' > "$theme_file"
autoload -U colors && colors
setopt prompt_subst
function parse_git_status() {
    git rev-parse --is-inside-work-tree &>/dev/null || return
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    echo " %{$fg[yellow]%}git:(${branch})%{$reset_color%}"
}
local user_info="%{$fg[magenta]%}__USERNAME__%{$reset_color%}"
local current_dir="%{$fg[blue]%}%~%{$reset_color%}"
local git_info='$(parse_git_status)'
local status_arrow="%(?.%{$fg_bold[green]%}__SYMBOL__.%{$fg_bold[red]%}__SYMBOL__)"
PROMPT="${user_info} ${current_dir}${git_info} ${status_arrow} "
EOF
        fi
        
        sed -i "s/__USERNAME__/$username/g" "$theme_file"
        sed -i "s/__SYMBOL__/$prompt_sym/g" "$theme_file"

    elif [ "$shell" = "fish" ]; then
        mkdir -p ~/.config/fish
        [ -f ~/.config/fish/config.fish ] && cp ~/.config/fish/config.fish ~/.config/fish/config.fish.bak
        
        cat << 'EOF' > ~/.config/fish/config.fish
set fish_greeting
set -gx CLICOLOR 1
set -gx CLICOLOR_FORCE 1
set -gx fish_autosuggestion_enabled 1

bash ~/.termux-os-banner.sh

functions --erase ls
functions --erase cat
functions --erase ll
alias l='eza -la'
alias ls='command ls'
alias cat='command cat'
alias ll='eza -l'
EOF
        
        if [ "$prompt_layout" = "cyberpunk" ]; then
            cat << 'EOF' >> ~/.config/fish/config.fish
function fish_prompt
    set -l last_status $status
    echo
    set_color red
    printf "┌─["
    set_color green
    echo -n "__USERNAME__"
    set_color red
    echo -n "@"
    set_color white
    echo -n "termux"
    set_color red
    printf "]─["
    set_color cyan
    echo -n (prompt_pwd)
    set_color red
    echo -n "]"
    if command -v git >/dev/null 2>&1
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1
            set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
            set -l status_count (git status --porcelain 2>/dev/null | count)
            if test $status_count -gt 0
                set_color red
                echo -n " ($branch*)"
            else
                set_color green
                echo -n " ($branch)"
            end
        end
    end
    echo
    set_color red
    printf "└─╼ "
    if test $last_status -eq 0
        set_color green
    else
        set_color red
    end
    printf "__SYMBOL__ "
    set_color normal
end
EOF
        elif [ "$prompt_layout" = "minimalist" ]; then
            cat << 'EOF' >> ~/.config/fish/config.fish
function fish_prompt
    set -l last_status $status
    set_color cyan
    printf "%s " (prompt_pwd)
    if test $last_status -eq 0
        set_color green
    else
        set_color red
    end
    printf "__SYMBOL__ "
    set_color normal
end
EOF
        else
            cat << 'EOF' >> ~/.config/fish/config.fish
function fish_prompt
    set -l last_status $status
    set_color magenta
    echo -n "__USERNAME__ "
    set_color blue
    echo -n (prompt_pwd)
    if command -v git >/dev/null 2>&1
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1
            set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
            set_color yellow
            echo -n " git:($branch)"
        end
    end
    printf " "
    if test $last_status -eq 0
        set_color green
    else
        set_color red
    end
    printf "__SYMBOL__ "
    set_color normal
end
EOF
        fi
        
        sed -i "s/__USERNAME__/$username/g" ~/.config/fish/config.fish
        sed -i "s/__SYMBOL__/$prompt_sym/g" ~/.config/fish/config.fish
    fi
    
    # Auto-switch shell to the chosen one
    # Auto-switch shell to the chosen one
local target_shell_path=$(command -v "$shell")
if [ -n "$target_shell_path" ] && [ "$SHELL" != "$target_shell_path" ]; then
    echo -e "${Y}[*] Auto-switching default shell to ${shell}...${RS}"
    if [ -d /data/data/com.termux ] || [ -n "$TERMUX_VERSION" ]; then
        chsh -s "$target_shell_path"
    else
        chsh -s "$target_shell_path" 2>/dev/null || echo -e "${R}[!] Please change shell manually with: chsh -s $target_shell_path${RS}"
    fi
fi
    
    echo -e "\n${G}[√] Customizations applied to $shell!${RS}"
    echo -e "${Y}[*] Restart your terminal or run 'exec $shell' to see changes.${RS}"
    sleep 3
    menu
}

# Menu definitions
bash_menu() {
    banner
    printf "\n${left_pad}${C}───[${W} Bash Menu ${C}]───"
    printf "\n${left_pad}${C}[${W}01${C}]${G} Install/Setup Bash (ble.sh)"
    printf "\n${left_pad}${C}[${W}02${C}]${G} Switch to Bash"
    printf "\n${left_pad}${C}[${W}03${C}]${G} Customize Prompt & Welcome Banner"
    printf "\n${left_pad}${C}[${W}00${C}]${R} Back to Main Menu\n\n"
    echo -ne "${left_pad}${C}Selection: ${RS}"
    read choice
    case $choice in
        01) do_bash_setup ;;
        02) do_bash_switch ;;
        03) do_customize_prompts_menu "bash" ;;
        00) menu ;;
        *) echo -e "${R}[!] Invalid option${RS}"; sleep 1; bash_menu ;;
    esac
}

zsh_menu() {
    banner
    printf "\n${left_pad}${C}───[${W} Zsh Menu ${C}]───"
    printf "\n${left_pad}${C}[${W}01${C}]${G} Install/Setup Zsh (Oh My Zsh)"
    printf "\n${left_pad}${C}[${W}02${C}]${G} Switch to Zsh"
    printf "\n${left_pad}${C}[${W}03${C}]${G} Customize Prompt & Welcome Banner"
    printf "\n${left_pad}${C}[${W}00${C}]${R} Back to Main Menu\n\n"
    echo -ne "${left_pad}${C}Selection: ${RS}"
    read choice
    case $choice in
        01) do_zsh_setup ;;
        02) do_zsh_switch ;;
        03) do_customize_prompts_menu "zsh" ;;
        00) menu ;;
        *) echo -e "${R}[!] Invalid option${RS}"; sleep 1; zsh_menu ;;
    esac
}

fish_menu() {
    banner
    printf "\n${left_pad}${C}───[${W} Fish Menu ${C}]───"
    printf "\n${left_pad}${C}[${W}01${C}]${G} Install/Setup Fish"
    printf "\n${left_pad}${C}[${W}02${C}]${G} Switch to Fish"
    printf "\n${left_pad}${C}[${W}03${C}]${G} Customize Prompt & Welcome Banner"
    printf "\n${left_pad}${C}[${W}00${C}]${R} Back to Main Menu\n\n"
    echo -ne "${left_pad}${C}Selection: ${RS}"
    read choice
    case $choice in
        01) do_fish_setup ;;
        02) do_fish_switch ;;
        03) do_customize_prompts_menu "fish" ;;
        00) menu ;;
        *) echo -e "${R}[!] Invalid option${RS}"; sleep 1; fish_menu ;;
    esac
}

menu() {
    banner
    printf "\n${left_pad}${C}───[${W} Main Menu ${C}]───"
    printf "\n${left_pad}${C}[${W}01${C}]${G} Full Setup (Dependencies + Configs)"
    printf "\n${left_pad}${C}[${W}02${C}]${G} Bash Management"
    printf "\n${left_pad}${C}[${W}03${C}]${G} Zsh Management"
    printf "\n${left_pad}${C}[${W}04${C}]${G} Fish Management"
    printf "\n${left_pad}${C}[${W}05${C}]${G} Reload Termux Settings"
    printf "\n${left_pad}${C}[${W}06${C}]${G} View Current Setup Info"
    printf "\n${left_pad}${C}[${W}00${C}]${R} Exit\n\n"
    echo -ne "${left_pad}${C}Selection: ${RS}"
    read choice
    case $choice in
        01) do_full_setup ;;
        02) bash_menu ;;
        03) zsh_menu ;;
        04) fish_menu ;;
        05) 
            if command -v termux-reload-settings &>/dev/null; then
                termux-reload-settings
                echo -e "${G}[√] Settings reloaded${RS}"
            else
                echo -e "${R}[!] termux-reload-settings not found${RS}"
            fi
            sleep 2
            menu
            ;;
        06)
            clear
            echo -e "${C}=== Current Setup Info ===${RS}"
            echo -e "${Y}Shell:${RS} $SHELL"
            echo -e "${Y}Termux:${RS} ${TERMUX_VERSION:-unknown}"
            echo -e "${Y}PREFIX:${RS} ${PREFIX:-not set}"
            echo -e "${Y}User:${RS} ${USER:-$(id -un)}"
            echo ""
            echo -e "${C}Installed Tools:${RS}"
            for cmd in bash zsh fish git figlet toilet lolcat ruby bat eza curl wget; do
                if command -v "$cmd" &>/dev/null; then
                    echo -e "  ${G}[✓]${RS} $cmd"
                else
                    echo -e "  ${R}[✗]${RS} $cmd"
                fi
            done
            echo ""
            read -p "Press Enter to return to menu..."
            menu
            ;;
        00) 
            echo -e "${G}Goodbye!${RS}"
            exit 0
            ;;
        *) 
            echo -e "${R}[!] Invalid option${RS}"
            sleep 1
            menu
            ;;
    esac
}

# Entry point
if [ -z "$TERMUX_VERSION" ] && [ ! -d /data/data/com.termux ]; then
    echo -e "${Y}[!] Warning: This script is optimized for Termux.${RS}"
    echo -e "${Y}[!] Some features may not work on other systems.${RS}"
    sleep 2
fi

menu