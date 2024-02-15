#!/bin/bash
. ~/.bash_aliases.d/rlwrap_scripts.sh

function git-fzf-opts(){
local result returner
result=$(printf "Files\nPull/Push/Fetch\nCommit\nStage/Add - Unstage/Restore\nBranch/Worktree\nStashes\nTag\nReflogs\nConfig\nQuit\n" \
| fzf --sort --reverse  --cycle --preview-window='right,50%,border-left' --prompt="Git> " --header="CTRL-C / Quit to quit selection"); 
if test "$result" == "Quit" || test "$result" == ""; then
    echo "Quit";
elif test "$result" == "Files"; then
    returner="$(_fzf_git_files | xargs echo "$EDITOR")"
    echo "$returner";
    echo "Quit";
elif [[ "$result" =~ "Pull/Push" ]]; then
    result=$(printf "git pull\ngit push\ngit fetch\ngit push --force\ngit pull --force\ngit fetch --all\ngit fetch --all --depth=1" | fzf --sort --reverse  --cycle --preview-window='right,50%,border-left' --prompt="Git> ") 
    if test "$result" == "git pull" || test "$result" == "git push"; then
        returner="$returner$(_fzf_git_remotes | xargs echo "$result")"
        returner="$(_fzf_git_branches | xargs echo "$returner")"
    fi
    echo "$returner";
elif test "$result" == "Commit"; then
    result=$(printf "git commit\ngit commit staged\ngit commit --all\ngit reset HEAD~\ngit reset --hard\ngit commit --amend\ngit commit staged --amend\ngit commit --all --amend\n" \
    | fzf --sort --reverse --track --cycle --preview-window='right,50%,border-left' \
    --bind 'focus:transform-border-label:[[ {} =~ "To HEAD" ]] && echo "Git switch -" || [[ {} =~ "Previous Commit" ]] && echo "Git checkout {commit hash}" || [[ {} =~ "Different Branch" ]] && echo "Git checkout {branch}" || [[ {} =~ "For each ref" ]] && echo "Git for-each-ref"')  
    last_message="$(git show | head -n +5 | tail -1)"
    stty sane && reade -Q "CYAN" -i '\\\"\\\"' -p "Give up a commit message: " "" msg 
    returner="$result -m $msg";
    echo "$returner"
elif test "$result" == "Stage/Add - Unstage/Restore"; then
    result=$(printf "git add\ngit add --all\ngit reset\ngit reset --all\ngit restore\ngit restore --all" | fzf --sort --reverse --track --cycle --preview-window='right,50%,border-left' \
    --bind 'focus:transform-border-label:[[ {} =~ "To HEAD" ]] && echo "Git switch -" || [[ {} =~ "Previous Commit" ]] && echo "Git checkout {commit hash}" || [[ {} =~ "Different Branch" ]] && echo "Git checkout {branch}" || [[ {} =~ "For each ref" ]] && echo "Git for-each-ref"')  
    if [[ "$result" == "git add" ]]; then
        returner="$(_fzf_git_files | xargs echo "git add")"
        echo "$returner"
    elif [[ "$result" == "git reset" ]]; then
        returner="$(_fzf_git_files | xargs echo "git reset")"
        echo "$returner"
    elif [[ "$result" == "git restore" ]]; then
        returner="$(_fzf_git_files | xargs echo "git restore" )" 
        echo "$returner"
    fi
elif test "$result" == "branch/worktree"; then
    result=$(printf "to head\nprevious commit\ndifferent branch\nfor each ref\n" \
    | fzf --sort --reverse --track --cycle --preview-window='right,50%,border-left' \
    --bind 'focus:transform-border-label:[[ {} =~ "to head" ]] && echo "git switch -" || [[ {} =~ "previous commit" ]] && echo "git checkout {commit hash}" || [[ {} =~ "different branch" ]] && echo "git checkout {branch}" || [[ {} =~ "for each ref" ]] && echo "git for-each-ref"')  
    if [[ "$result" =~ "to head" ]]; then
        git switch -
    elif [[ "$result" =~ "different branch" ]]; then
        _fzf_git_branches --no-multi | xargs git checkout
    elif [[ "$result" =~ "for each ref" ]]; then
        _fzf_git_each_ref --no-multi | xargs git checkout
    fi
elif [[ "$result" == "Stashes" ]]; then
    result=$(printf "list\nshow\nshow --include-untracked\nshow --only-untracked\ndrop\ncreate\ndrop\nlist\npop\npush\nshow\nstore\n" \
    | fzf --sort --reverse  --cycle --preview-window='right,50%,border-left'  --bind 'change:change-prompt({q}> )') 
    if [[ "$result" == "list" ]]; then
        _fzf_git_stashes --no-multi
    elif [[ "$result" =~ "drop" ]]; then
        _fzf_git_each_ref --no-multi 
    fi
elif test "$result" == "Config"; then
    local confs allconfs
    confs=$(compgen -F _git_config 2> /dev/null)
    for conf in ${confs[@]}; do
        allconfs="$allconfs$(cur=$conf && compgen -F _git_config 2> /dev/null)"
    done
    allconfs=$(echo $allconfs | sed 's| |\n|g')
    result=$(printf "$allconfs" \
    | fzf --sort --reverse --track --cycle --preview-window='right,50%,border-left' \
    --bind 'focus:transform-border-label:[[ {} =~ "to head" ]] && echo "git switch -" || [[ {} =~ "previous commit" ]] && echo "git checkout {commit hash}" || [[ {} =~ "different branch" ]] && echo "git checkout {branch}" || [[ {} =~ "for each ref" ]] && echo "git for-each-ref"')
elif test "$result" == "reflogs"; then
    _fzf_git_lreflogs
fi
}

git-fzf(){
    local res result
    if [ ! -d ./.git ]; then
        echo "$(tput setaf 1)Not in a git directory!$(tput sgr0)";
        return 1;
    fi
    while [[ $res != "Quit" ]] || [[ $res =~ "Not in a" ]] ; do
        res=$(git-fzf-opts)
        if ! [[ "$res" =~ "Quit" ]]; then
            result="$result $res;"
        elif [[ "$res" =~ "Not in a" ]]; then
            break
        elif [[ "$res" =~ "Quit" ]] && ! [[ "$res" == "Quit" ]]; then
            res=$(echo "$res" | sed 's|Quit||g')
            result="$result $res;"
            break
        fi
    done
    eval "$result"
    git status
}

