# --- JROCHA banner engine (appended to ~/.termux-os-banner.sh by os.sh) ---
# Pure bash: no lolcat needed, adapts to the terminal width.
export LC_ALL=C
set -f

cols=$(tput cols 2>/dev/null)
[[ "$cols" =~ ^[0-9]+$ ]] || cols=56
if (( cols > 60 )); then BOX_WIDTH=58; else BOX_WIDTH=$(( cols - 2 )); fi
(( BOX_WIDTH < 24 )) && BOX_WIDTH=24
INNER=$(( BOX_WIDTH - 2 ))

frame=$'\033[1;38;5;80m'
reset=$'\033[0m'

case "$STYLE" in
    matrix) PAL=(22 28 34 40 46 82 118 82 46 40 34 28) ;;
    cyber)  PAL=(51 45 39 33 63 99 135 171 201) ;;
    white)  PAL=(255) ;;
    *)      PAL=(201 165 129 93 63 33 39 45 51 49 48 47 46) ;;
esac

hline() {
    local i
    printf '%s %s' "$frame" "$1"
    for ((i = 0; i < INNER; i++)); do printf '━'; done
    printf '%s%s\n' "$2" "$reset"
}

tick_row() { printf '%s ┃%*s┃%s\n' "$frame" "$INNER" '' "$reset"; }

# One line of figlet art, painted with a left-to-right gradient across its own width.
paint_line() {
    local line=$1 i=0 len=${#1} ch b seq k n first=-1 last=-1 span idx out
    local -a chs=()
    while (( i < len )); do
        ch=${line:i:1}
        printf -v b '%d' "'$ch" 2>/dev/null || b=32
        (( b < 0 )) && b=$(( b + 256 ))
        if   (( b >= 240 )); then seq=${line:i:4}; i=$(( i + 4 ))
        elif (( b >= 224 )); then seq=${line:i:3}; i=$(( i + 3 ))
        elif (( b >= 192 )); then seq=${line:i:2}; i=$(( i + 2 ))
        else seq=$ch; i=$(( i + 1 )); fi
        chs+=("$seq")
    done
    n=${#chs[@]}
    for ((k = 0; k < n; k++)); do
        if [[ "${chs[k]}" != " " ]]; then
            (( first < 0 )) && first=$k
            last=$k
        fi
    done
    if (( first < 0 )); then echo; return; fi
    span=$(( last - first + 1 ))
    out="  "
    for ((k = 0; k < n; k++)); do
        seq=${chs[k]}
        if [[ "$seq" == " " ]]; then
            out+=" "
        else
            idx=$(( (k - first) * ${#PAL[@]} / span ))
            (( idx >= ${#PAL[@]} )) && idx=$(( ${#PAL[@]} - 1 ))
            out+=$'\033[38;5;'"${PAL[idx]}"'m'"$seq"
        fi
    done
    printf '%s%s\n' "$out" "$reset"
}

fig() { figlet -d "$FIGLET_DIR" -f "$FONT" "$@" 2>/dev/null; }

# Renders one word; if it is too wide for the box it is split in halves
# (JROCHA -> JRO / CHA) so it never wraps or breaks the frame.
emit() {
    local w=$1 n h l
    n=$(fig -c -w "$INNER" "$w" | wc -l)
    if (( n <= FONT_H || ${#w} < 2 )); then
        while IFS= read -r l; do paint_line "$l"; done < <(fig -c -w "$INNER" "$w")
    else
        h=$(( (${#w} + 1) / 2 ))
        emit "${w:0:h}"
        emit "${w:h}"
    fi
}

FONT_H=$(fig -w 1000 "I" | wc -l)

clear
echo -e '\033[1;32m[*] BOOTING JROCHA...'
echo -ne '\033[1;36m[LOADING MODULES] \033[1;32m'
for i in {1..25}; do echo -ne '█'; sleep 0.01; done
echo -e '\033[0m'
sleep 0.2
clear

hline '┏' '┓'
tick_row
echo
if (( FONT_H > 0 )); then
    for word in $TEXT; do emit "$word"; done
else
    printf '%*s%s\n' $(( (cols - ${#TEXT}) / 2 )) '' "$TEXT"
fi
tick_row
hline '┗' '┛'
