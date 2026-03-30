#!/bin/bash

PSTDL_REPO="CyrixJD115/PST-DL"
PSTDL_RAW_BASE="https://raw.githubusercontent.com/$PSTDL_REPO/main"
PSTDL_BIN="$HOME/.local/bin/pstdl"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${WHITE}"
cat << 'EOF'
██████╗ ███████╗████████╗    ██████╗ ██╗     
██╔══██╗██╔════╝╚══██╔══╝    ██╔══██╗██║     
██████╔╝███████╗   ██║       ██║  ██║██║     
██╔═══╝ ╚════██║   ██║       ██║  ██║██║     
██║     ███████║   ██║       ██████╔╝███████╗
╚═╝     ╚══════╝   ╚═╝       ╚═════╝ ╚══════╝
EOF
echo -e "${NC}"
echo -e "${WHITE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}${WHITE}Installing pstdl...${NC}"
echo ""

mkdir -p "$HOME/.local/bin"

echo -e "${YELLOW}> Downloading pstdl...${NC}"
curl -sL "${PSTDL_RAW_BASE}/.Unix/pstdl" -o "$PSTDL_BIN" 2>/dev/null

if [ ! -f "$PSTDL_BIN" ] || [ ! -s "$PSTDL_BIN" ]; then
    echo -e "${RED}x Error: Failed to download pstdl.${NC}"
    exit 1
fi

chmod +x "$PSTDL_BIN"
echo -e "${GREEN}* Downloaded to: ${CYAN}$PSTDL_BIN${NC}"
echo ""

PATH_UPDATED=0
add_to_path() {
    local rc_file="$1"
    local line='export PATH="$HOME/.local/bin:$PATH"'

    if ! grep -qF '.local/bin' "$rc_file" 2>/dev/null; then
        echo "" >> "$rc_file"
        echo "$line" >> "$rc_file"
        PATH_UPDATED=1
    fi
}

if [ -f "$HOME/.bashrc" ]; then
    add_to_path "$HOME/.bashrc"
fi
if [ -f "$HOME/.zshrc" ]; then
    add_to_path "$HOME/.zshrc"
fi
if [ -f "$HOME/.profile" ]; then
    add_to_path "$HOME/.profile"
fi

if [ $PATH_UPDATED -eq 1 ]; then
    echo -e "${GREEN}* Added ~/.local/bin to PATH${NC}"
else
    echo -e "${DIM}  ~/.local/bin already in PATH${NC}"
fi

echo ""
echo -e "${WHITE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}${GREEN}pstdl installed successfully!${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  ${DIM}Reload your shell:${NC}"
echo -e "  ${CYAN}source ~/.bashrc${NC} ${DIM}(or ~/.zshrc)${NC}"
echo ""
echo -e "  ${DIM}Install PalworldSaveTools:${NC}"
echo -e "  ${CYAN}pstdl -i${NC}"
echo ""
echo -e "  ${DIM}Show all commands:${NC}"
echo -e "  ${CYAN}pstdl -h${NC}"
echo ""
