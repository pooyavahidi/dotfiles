
# Define `emoji` associative array.
# References:
# - https://unicode.org/emoji/charts/full-emoji-list.html
# - https://github.com/github/gemoji/blob/master/vendor/unicode-emoji-test.txt
# - https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/emoji/emoji-char-definitions.zsh

case "$SHELL" in
*"/zsh")
    typeset -A emoji
    ;;
*"/bash")
    declare -A emoji
    ;;
*)
    echo "\nUnable to source emoji.sh file for unsupported shell `$SHELL`"
    return
    ;;
esac

emoji[check_mark_button]=$'\U2705'
emoji[no_entry]=$'\U26D4'
emoji[up_arrow_dotted]=$'\U21E1'
emoji[down_arrow_dotted]=$'\U21E3'
emoji[right_arrow_small]=$'\U279C'
emoji[cross_mark]=$'\U274C'
emoji[cross_mark_small]=$'\U2717'
