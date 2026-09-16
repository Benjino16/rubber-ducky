#!/usr/bin/env bash
#
# hacked_screamer.sh
#
# Rein visueller Terminal-Gag: zeigt einen "Matrix-Regen"
# und danach ein "YOU GOT HACKED"-Banner an.
#
# WICHTIG: Dieses Skript liest, schreibt oder löscht KEINE Dateien,
# öffnet KEINE Netzwerkverbindungen und verändert NICHTS am System.
# Es gibt nur Text im Terminal aus (per printf/echo) und wartet
# am Ende auf einen Tastendruck. 100% harmlos.
#
# Nutzung:
#   chmod +x hacked_screamer.sh
#   ./hacked_screamer.sh
#
# Beenden jederzeit mit Strg+C.

set -euo pipefail

# --- Aufräumen, falls mit Strg+C abgebrochen wird ---
cleanup() {
    tput cnorm 2>/dev/null || true   # Cursor wieder anzeigen
    tput sgr0 2>/dev/null || true    # Farben zurücksetzen
    clear
    exit 0
}
trap '' INT
trap cleanup TERM

# --- Terminalgröße ermitteln ---
COLS=$(tput cols)
LINES=$(tput lines)

GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

# --- Cursor ausblenden für die Animation ---
tput civis 2>/dev/null || true
clear

# --- Zeichen-Pool für den "Matrix-Regen" ---
CHARS="01ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@#%&*+-/\\<>[]{}"
CHARS_LEN=${#CHARS}

# --- Position (aktuelle Fallhöhe) je Spalte ---
declare -a drop_pos
for ((c = 0; c < COLS; c++)); do
    drop_pos[c]=$((RANDOM % LINES))
done

MATRIX_DURATION=5   # Sekunden, wie lange der Regen läuft
start_time=$(date +%s)

while [ $(( $(date +%s) - start_time )) -lt $MATRIX_DURATION ]; do
    # Für viele zufällige Spalten pro Frame ein Zeichen ausgeben (aggressiv/dicht)
    for ((i = 0; i < COLS; i++)); do
        col=$((RANDOM % COLS))
        row=${drop_pos[col]}

        ch=${CHARS:$((RANDOM % CHARS_LEN)):1}

        # Zeichen an Position (row, col) setzen
        tput cup "$row" "$col" 2>/dev/null || true
        if (( RANDOM % 4 == 0 )); then
            printf "%b%s%b" "$BRIGHT_GREEN" "$ch" "$RESET"
        else
            printf "%b%s%b" "$GREEN" "$ch" "$RESET"
        fi

        # Position nach unten bewegen, bei Bodenkontakt oben neu starten
        drop_pos[col]=$(( (row + 1) % LINES ))
    done
    sleep 0.015
done

# --- Banner anzeigen ---
clear
tput cup $(( LINES / 2 - 4 )) 0 2>/dev/null || true

BANNER=(
"__     ______  _   _    _____  ____ _____   _    _          _____ _  ________ _____  "
"\\ \\   / / __ \\| | | |  / ____|/ __ \\_   _| | |  | |   /\\   / ____| |/ /  ____|  __ \\ "
" \\ \\_/ / |  | | | | | | |  __| |  | || |   | |__| |  /  \\ | |    | ' /| |__  | |  | |"
"  \\   /| |  | | | | | | | |_ | |  | || |   |  __  | / /\\ \\| |    |  < |  __| | |  | |"
"   | | | |__| | |__| | | |__| | |__| || |_  | |  | |/ ____ \\ |___| . \\| |____| |__| |"
"   |_|  \\____/ \\____/   \\_____|\\____/_____| |_|  |_/_/    \\_\\____|_|\\_\\______|_____/ "
)

BANNER_START_ROW=$(( LINES / 2 - 4 ))

# Farbpalette fürs Flackern (Glitch-Effekt)
FLICKER_COLORS=('\033[1;31m' '\033[0;31m' '\033[1;37m' '\033[1;32m' '\033[0;32m')

draw_banner() {
    local color="$1"
    tput cup "$BANNER_START_ROW" 0 2>/dev/null || true
    for line in "${BANNER[@]}"; do
        padding=$(( (COLS - ${#line}) / 2 ))
        (( padding < 0 )) && padding=0
        printf "%*s" "$padding" ""
        printf "%b%s%b\n" "$color" "$line" "$RESET"
    done
}

# --- Flacker-/Glitch-Phase: Banner blinkt kurz wild ---
FLICKER_DURATION=2
flicker_start=$(date +%s)
while [ $(( $(date +%s) - flicker_start )) -lt $FLICKER_DURATION ]; do
    rand_color=${FLICKER_COLORS[$((RANDOM % ${#FLICKER_COLORS[@]}))]}
    draw_banner "$rand_color"
    # gelegentlich kurz "ausblenden" fürs Glitch-Gefühl
    if (( RANDOM % 5 == 0 )); then
        tput cup "$BANNER_START_ROW" 0 2>/dev/null || true
        for line in "${BANNER[@]}"; do
            printf "\n"
        done
        sleep 0.04
    fi
    sleep 0.07
done

# --- Banner bleibt jetzt stabil in Rot stehen ---
draw_banner "$RED"

echo
CENTER_TEXT="[ Keine Sorge - das ist nur eine Demo. Es wurde nichts veraendert. ]"
padding=$(( (COLS - ${#CENTER_TEXT}) / 2 ))
(( padding < 0 )) && padding=0
printf "%*s" "$padding" ""
printf "%b%s%b\n" "$BRIGHT_GREEN" "$CENTER_TEXT" "$RESET"

WARN_LINE1="Wenn du diesen Text hier lesen kannst, haette theoretisch"
WARN_LINE2="eine Malware installiert werden koennen."
padding=$(( (COLS - ${#WARN_LINE1}) / 2 ))
(( padding < 0 )) && padding=0
printf "%*s" "$padding" ""
printf "%b%s%b\n" "$RED" "$WARN_LINE1" "$RESET"
padding=$(( (COLS - ${#WARN_LINE2}) / 2 ))
(( padding < 0 )) && padding=0
printf "%*s" "$padding" ""
printf "%b%s%b\n\n" "$RED" "$WARN_LINE2" "$RESET"

WAIT_TEXT="Druecke eine beliebige Taste zum Beenden..."
padding=$(( (COLS - ${#WAIT_TEXT}) / 2 ))
(( padding < 0 )) && padding=0
printf "%*s" "$padding" ""
printf "%b%s%b" "$GREEN" "$WAIT_TEXT" "$RESET"

read -n 1 -s -r || true
echo
cleanup
