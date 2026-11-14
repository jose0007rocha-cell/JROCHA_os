#!/bin/bash
# JROCHA unstall - restores the terminal to how it was before JROCHA.
# Self-contained: works even if the project folder was deleted.
#   unstall          interactive
#   unstall -y       no questions (safe defaults)
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;93m'; C='\033[1;96m'; W='\033[1;97m'; RS='\033[0m'

BK="$HOME/.jrocha-backup"
YES=0; FROM_MENU=0
for a in "$@"; do
    case "$a" in -y|--yes) YES=1 ;; --from-menu) FROM_MENU=1 ;; esac
done

ask() {  # ask "question" default(y|n)
    local q=$1 d=$2 ans hint="[y/N]"
    [ "$d" = "y" ] && hint="[Y/n]"
    if [ "$YES" = 1 ]; then [ "$d" = "y" ]; return; fi
    echo -ne "${Y}$q ${hint}: ${RS}"
    read -r ans
    [ -z "$ans" ] && ans=$d
    [[ "$ans" =~ ^[yYsS]$ ]]
}

has_jrocha() { [ -f "$1" ] && grep -aqE 'termux-os-banner|jrocha|JROCHA|#LOCK_START' "$1"; }

# restore_file <target> <default-if-no-backup: remove|empty>
restore_file() {
    local f=$1 fallback=$2 name; name=$(basename "$f")
    if [ -f "$BK/$name" ]; then
        mkdir -p "$(dirname "$f")"; cp -p "$BK/$name" "$f"
        echo -e "${G}[√] $name restored from your original backup${RS}"
    elif [ -f "$BK/$name.none" ]; then
        rm -f "$f"
        echo -e "${G}[√] $name removed (it did not exist before)${RS}"
    elif [ -f "$f.bak" ] && ! has_jrocha "$f.bak"; then
        cp -p "$f.bak" "$f"
        echo -e "${G}[√] $name restored from $name.bak${RS}"
    elif [ -e "$f" ]; then
        if [ "$fallback" = "empty" ]; then : > "$f"; else rm -f "$f"; fi
        echo -e "${Y}[~] $name had no original backup: reset to Termux default${RS}"
    fi
}

clear
echo -e "${C}╔══════════════════════════════════════════╗"
echo -e "║   ${W}JROCHA UNSTALL${C} - restore the terminal    ║"
echo -e "╚══════════════════════════════════════════╝${RS}"
echo
echo -e "${W}This will:${RS}"
echo "  - remove the JROCHA banner, prompt theme and Cyber Lock"
echo "  - restore .bashrc, .zshrc and fish config to the originals"
echo "  - restore Termux colors and extra keys"
echo "  - set the login shell back to bash"
echo
ask "Continue?" y || { echo -e "${R}Cancelled.${RS}"; exit 3; }
echo

# 1) Lock + banner hooks (works even with no backup)
for f in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/fish/config.fish"; do
    [ -f "$f" ] && sed -i '/#LOCK_START/,/#LOCK_END/d' "$f"
done

# 2) Shell config files
restore_file "$HOME/.bashrc" empty
restore_file "$HOME/.zshrc" remove
restore_file "$HOME/.config/fish/config.fish" remove

# 3) Banner script + zsh theme
rm -f "$HOME/.termux-os-banner.sh" "$HOME/.oh-my-zsh/themes/jrocha.zsh-theme"
echo -e "${G}[√] Banner and prompt theme removed${RS}"

# 4) Termux settings
restore_file "$HOME/.termux/colors.properties" remove
restore_file "$HOME/.termux/termux.properties" remove

# Font: only touched when a backup exists, or when you say so.
if [ -f "$BK/font.ttf" ] || [ -f "$BK/font.ttf.none" ]; then
    restore_file "$HOME/.termux/font.ttf" remove
elif [ -f "$HOME/.termux/font.ttf" ]; then
    if ask "Also go back to the default Termux font?" n; then
        rm -f "$HOME/.termux/font.ttf"
        echo -e "${G}[√] Default font restored${RS}"
    else
        echo -e "${Y}[~] Font kept${RS}"
    fi
fi

# 5) Optional extras
if [ -d "$HOME/.oh-my-zsh" ] || [ -d "$HOME/.local/share/blesh" ]; then
    if ask "Also delete Oh My Zsh and ble.sh (installed by JROCHA)?" n; then
        rm -rf "$HOME/.oh-my-zsh" "$HOME/.local/share/blesh" "$HOME/.blerc"
        echo -e "${G}[√] Extras deleted${RS}"
    fi
fi

# 6) Login shell back to bash
if command -v chsh &>/dev/null && [ "$(basename "${SHELL:-bash}")" != "bash" ]; then
    chsh -s bash &>/dev/null && echo -e "${G}[√] Login shell set to bash${RS}"
fi

# 7) Clean up and apply
rm -rf "$BK"
[ -n "$PREFIX" ] && rm -f "$PREFIX/bin/unstall"
command -v termux-reload-settings &>/dev/null && termux-reload-settings

echo
echo -e "${G}[√] Terminal restored. Run 'bash os.sh' again anytime to reinstall JROCHA.${RS}"
sleep 1
[ "$FROM_MENU" = 1 ] && exit 0
exec bash
