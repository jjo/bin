#!/bin/bash
#
# mplayer-1fm.sh - Play 1.FM internet radio streams
# Uses mplayer on Linux, cvlc on macOS
#

# Base URL for 1.FM streams
BASE_URL="https://strm112.1.fm"
SUFFIX="_mobile_mp3?aw_0_req.gdpr=true"

# Define stations: "slug|Display Name"
STATIONS=(
    # Blues & Jazz
    "blues|Blues"
    "jazz|Jazz"
    "adorejazz|Adore Jazz"
    "bayjazz|Bay Smooth Jazz"
    "bossanova|Bossa Nova Hits"

    # Classical
    "baroque|Baroque"
    "classical|Otto's Classical Music"
    "loveclassics|Love Classics"

    # Chill & Lounge
    "chilloutlounge|Chillout Lounge"
    "spa|Spa"
    "ambient|Ambient"

    # Rock
    "crock|Classic Rock"
    "rockclassics|Rock Classics"

    # Electronic & Dance
    "atr|Amsterdam Trance"
    "danceone|Dance One"
    "club1|Club 1"
    "deephouse|Deep House"
    "techno|Techno"
    "psytrance|PsyTrance"
    "dubstep|Dubstep"
    "trance|Trance"

    # Decades
    "60s_70s|Back to the 50's & 60's"
    "70s|Absolute 70's Pop"
    "80s|Absolute 80's"
    "90s|Absolute 90's"
    "00s|Hits 2000"

    # Pop & Hits
    "top40|Top 40"
    "absolutetop40|Absolute Top 40"
    "totalespanol|Total Hits En Espanol"

    # Urban & Soul
    "funkyexpress|Funky Express"
    "slowjamz|Slow Jamz"
    "rnb|RnB"
    "soul|Soul"
    "hiphop|Hip Hop"

    # Country & Folk
    "classiccountry|Classic Country"
    "country|Country"

    # Reggae & World
    "reggae|Reggae"
    "bombay|Bombay Beats India"
    "afrobeat|AfroBeats"
    "latina|Latina"
    "soca|Soca"

    # Other
    "christmas|Christmas"
    "acappella|A Cappella"
    "newage|New Age"
)

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Detect OS and set player
detect_player() {
    case "$(uname -s)" in
        Linux*)
            if command -v mplayer &> /dev/null; then
                PLAYER="mplayer"
                PLAYER_OPTS="-cache 1024"
            elif command -v mpv &> /dev/null; then
                PLAYER="mpv"
                PLAYER_OPTS="--cache=yes"
            elif command -v cvlc &> /dev/null; then
                PLAYER="cvlc"
                PLAYER_OPTS="--play-and-exit"
            else
                echo -e "${RED}Error: No suitable player found. Please install mplayer, mpv, or vlc.${NC}"
                exit 1
            fi
            ;;
        Darwin*)
            if command -v cvlc &> /dev/null; then
                PLAYER="cvlc"
                PLAYER_OPTS="--play-and-exit"
            elif command -v /Applications/VLC.app/Contents/MacOS/VLC &> /dev/null; then
                PLAYER="/Applications/VLC.app/Contents/MacOS/VLC"
                PLAYER_OPTS="-I dummy --play-and-exit"
            elif command -v mpv &> /dev/null; then
                PLAYER="mpv"
                PLAYER_OPTS="--cache=yes"
            elif command -v mplayer &> /dev/null; then
                PLAYER="mplayer"
                PLAYER_OPTS="-cache 1024"
            else
                echo -e "${RED}Error: No suitable player found. Please install VLC or mpv.${NC}"
                echo "  brew install vlc"
                echo "  or: brew install mpv"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Unsupported operating system${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}Using player: ${PLAYER}${NC}"
}

# Display station menu
show_menu() {
    echo -e "\n${BOLD}${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║            1.FM Internet Radio Player                   ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════╝${NC}\n"

    local i=1
    local category=""

    for station in "${STATIONS[@]}"; do
        IFS='|' read -r slug name <<< "$station"

        # Add category headers
        case $i in
            1) echo -e "${YELLOW}── Blues & Jazz ──${NC}" ;;
            6) echo -e "\n${YELLOW}── Classical ──${NC}" ;;
            9) echo -e "\n${YELLOW}── Chill & Lounge ──${NC}" ;;
            12) echo -e "\n${YELLOW}── Rock ──${NC}" ;;
            14) echo -e "\n${YELLOW}── Electronic & Dance ──${NC}" ;;
            23) echo -e "\n${YELLOW}── Decades ──${NC}" ;;
            28) echo -e "\n${YELLOW}── Pop & Hits ──${NC}" ;;
            31) echo -e "\n${YELLOW}── Urban & Soul ──${NC}" ;;
            36) echo -e "\n${YELLOW}── Country & Folk ──${NC}" ;;
            38) echo -e "\n${YELLOW}── Reggae & World ──${NC}" ;;
            43) echo -e "\n${YELLOW}── Other ──${NC}" ;;
        esac

        printf "  ${GREEN}%2d)${NC} %s\n" $i "$name"
        ((i++))
    done

    echo -e "\n  ${GREEN} 0)${NC} Exit"
    echo -e "  ${GREEN} r)${NC} Random station"
    echo -e "  ${GREEN} s)${NC} Search stations"
    echo ""
}

# Search stations
search_stations() {
    echo -ne "${CYAN}Enter search term: ${NC}"
    read -r search_term

    if [[ -z "$search_term" ]]; then
        return
    fi

    echo -e "\n${YELLOW}Search results for '${search_term}':${NC}\n"

    local i=1
    local found=0
    for station in "${STATIONS[@]}"; do
        IFS='|' read -r slug name <<< "$station"
        if [[ "${name,,}" == *"${search_term,,}"* ]] || [[ "${slug,,}" == *"${search_term,,}"* ]]; then
            printf "  ${GREEN}%2d)${NC} %s\n" $i "$name"
            found=1
        fi
        ((i++))
    done

    if [[ $found -eq 0 ]]; then
        echo -e "${RED}No stations found matching '${search_term}'${NC}"
    fi
}

# Play a station by index
play_station() {
    local index=$1

    if [[ $index -lt 1 ]] || [[ $index -gt ${#STATIONS[@]} ]]; then
        echo -e "${RED}Invalid selection${NC}"
        return 1
    fi

    local station="${STATIONS[$((index-1))]}"
    IFS='|' read -r slug name <<< "$station"
    local url="${BASE_URL}/${slug}${SUFFIX}"

    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Now Playing: 1.FM - ${name}${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}Stream: ${url}${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop playback${NC}\n"

    exec $PLAYER $PLAYER_OPTS "$url"
}

# Play random station
play_random() {
    local random_index=$((RANDOM % ${#STATIONS[@]} + 1))
    echo -e "${CYAN}Selected random station...${NC}"
    play_station $random_index
}

# Direct play mode (command line argument)
direct_play() {
    local arg="$1"

    # Check if argument is a number
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        play_station "$arg"
        return
    fi

    # Search by name/slug
    local i=1
    for station in "${STATIONS[@]}"; do
        IFS='|' read -r slug name <<< "$station"
        if [[ "${slug,,}" == "${arg,,}" ]] || [[ "${name,,}" == *"${arg,,}"* ]]; then
            play_station $i
            return
        fi
        ((i++))
    done

    echo -e "${RED}Station not found: ${arg}${NC}"
    echo "Use --list to see available stations"
    exit 1
}

# Show help
show_help() {
    echo "Usage: $(basename "$0") [OPTIONS] [STATION]"
    echo ""
    echo "Play 1.FM internet radio streams"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -l, --list     List all available stations"
    echo "  -r, --random   Play a random station"
    echo ""
    echo "Station can be specified as:"
    echo "  - Station number (e.g., 1, 5, 12)"
    echo "  - Station slug (e.g., blues, reggae, trance)"
    echo "  - Partial name (e.g., jazz, rock)"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Interactive menu"
    echo "  $(basename "$0") 1            # Play station #1 (Blues)"
    echo "  $(basename "$0") blues        # Play Blues station"
    echo "  $(basename "$0") --random     # Play random station"
}

# List all stations
list_stations() {
    echo -e "${BOLD}Available 1.FM Stations:${NC}\n"
    local i=1
    for station in "${STATIONS[@]}"; do
        IFS='|' read -r slug name <<< "$station"
        printf "  %2d) %-20s [%s]\n" $i "$name" "$slug"
        ((i++))
    done
}

# Main function
main() {
    # Handle command line arguments
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--list)
            list_stations
            exit 0
            ;;
        -r|--random)
            detect_player
            play_random
            exit 0
            ;;
        "")
            # Interactive mode
            ;;
        *)
            detect_player
            direct_play "$1"
            exit 0
            ;;
    esac

    # Interactive mode
    detect_player

    while true; do
        show_menu
        echo -ne "${BOLD}Select station (0-${#STATIONS[@]}, r=random, s=search): ${NC}"
        read -r choice

        case "$choice" in
            0|q|Q|exit|quit)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            r|R|random)
                play_random
                ;;
            s|S|search)
                search_stations
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]]; then
                    play_station "$choice"
                else
                    echo -e "${RED}Invalid input. Please enter a number, 'r' for random, or 's' for search.${NC}"
                fi
                ;;
        esac

        echo ""
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read -r
    done
}

# Run main function
main "$@"
