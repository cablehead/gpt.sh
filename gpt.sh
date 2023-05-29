#!/usr/bin/env bash

# JABOSS-ware
# requires: argc, realpath, curl, sed, jo, jq, xs, fzf, bp

# @arg arg1! <STREAM>

set -euo pipefail
shopt -s lastpipe
set +m # disable job control

_id() {
    XS="xs $(realpath "$1")"
    ID="$2"
    if [[ "$ID" == "-" ]]; then
        $XS cat | tail -n1 | jq -r .id | read -r ID
    fi
    echo $ID
}

# @cmd Seed a system message
# @arg arg2 <PARENT-ID>
seed() {
    XS="xs $(realpath "$1")"
    PARENTID=""
    if [[ $# -gt 1 ]]; then
        PARENTID="parent_id="$(_id "$1" "$2")""
    fi
    jo -- $PARENTID role="system" -s content="$(cat)" | $XS put --topic chat --attribute .node
}

# @cmd Start a new chat thread
# @flag -b --boost  Use gpt-4 (default is gpt-3.5-turbo)
# @option --max-tokens=1000
# @option -f --fence <MESSAGE>
init() {
    CONTENT="$(cat)"
    if [[ -v argc_fence ]]; then
        CONTENT="$argc_fence:"$'\n\n```\n'"$CONTENT"$'\n```\n'
    fi

    XS="xs $(realpath "$1")"
    jo -- -s content="$CONTENT" | $XS put --topic chat --attribute .node | read -r ID
    trigger "$1" "$ID"
}

# @cmd Write a node's content to stdout
# @arg arg2! <ID>
content() {
    XS="xs $(realpath "$1")"
    ID="$2"
    if [[ "$ID" == "-" ]]; then
        $XS cat | tail -n1 | jq -r .id | read -r ID
    fi
    $XS get "$ID" | jq -r '.data | fromjson | .content'
}

# @cmd Continue a chat thread
# @arg arg2! <ID>
# @flag -b --boost  Use gpt-4 (default is gpt-3.5-turbo)
# @option --max-tokens=1000
continue() {
    XS="xs $(realpath "$1")"
    ID="$2"
    if [[ "$ID" == "-" ]]; then
        $XS cat | tail -n1 | jq -r .id | read -r ID
    fi
    jo -- -s parent_id="$ID" role=user -s content="$(cat)" |
        $XS put --topic chat --attribute .node |
        read -r ID
    echo $ID
    trigger "$1" "$ID"
}

# @cmd Trigger a request for a given node
# @arg arg2! <ID>
# @flag -b --boost  Use gpt-4 (default is gpt-3.5-turbo)
# @option --max-tokens=1000
trigger() {
    XS="xs $(realpath "$1")"
    ID="$(_id "$1" "$2")"
    CONTENT=""

    MODEL="gpt-3.5-turbo"
    if [[ -v argc_boost ]]; then
        MODEL="gpt-4"
    fi

    _gen_call_meta() {
        jo \
            model="$MODEL" \
            max_tokens="$argc_max_tokens" \
            top_p="0.3" \
            stream=true \
            messages="$(cat | jq -cs)"
    }

    _call() {
        curl -s https://api.openai.com/v1/chat/completions \
            --fail-with-body \
            -H "Authorization:Bearer $OPENAI_API_KEY" \
            -H "Content-Type: application/json" \
            --no-buffer \
            -d @-
    }

    _stream() {
        sed -u -n '/^data: /s/^data: //p' |
            sed -u '/^\[DONE\]/d' |
            jq --unbuffered -j '.choices[].delta.content // ""'
    }

    # schema:
    #   "parent_id": ..., // optional
    #   "role": "user | assistant |system", // default: "user"
    #   "content": "Write a bash script ...",

    thread "$1" "$ID" |
        _gen_call_meta |
        _call |
        tee /tmp/capture |
        _stream | tee >(
        jo -- -s parent_id="$ID" role=assistant model="$MODEL" -s content="$(cat)" |
            $XS put --topic chat --attribute .node
    )
    CODE=$?
    echo
    echo exit code: $CODE
    echo
    # ideally we'd pause until the tee subshell completes
    sleep 0.1
}

# @cmd Pull the context thread for a given node
# @arg arg2! <ID>
# @flag -i --id  Include node id in the output
thread() {
    XS="xs $(realpath "$1")"
    ID="$2"
    if [[ "$ID" == "-" ]]; then
        $XS cat | tail -n1 | jq -r .id | read -r ID
    fi
    $XS get $ID | read -r NODE
    echo "$NODE" | jq -c '.data | fromjson' | read -r DATA

    echo "$DATA" | jq -r '.parent_id // ""' | read -r PARENT_ID
    if [[ ! -z "$PARENT_ID" ]]; then
        # running in a subprocess to not clobber the NODE variable
        (thread "$1" "$PARENT_ID")
    fi

    echo "$DATA" | jq -r '.link_id // ""' | read -r LINK_ID
    if [[ ! -z "$LINK_ID" ]]; then
        (thread "$1" "$LINK_ID")
        exit
    fi

    if [[ -v argc_id ]]; then
        { echo "$NODE" | jq '{id}' && echo "$DATA"; } | jq -cs add
        exit
    fi

    echo "$DATA" | jq -c '{role: (.role // "user"), content}'
}

# @cmd View a thread as markdown
# @arg arg2! <ID>
view() {
    XS="xs $(realpath "$1")"
    ID="$2"
    export argc_id=1
    thread "$1" "$2" | jq -sr '
    .[] | "## \(.id) :: \(.role // "user") :: \(.model // "")\n\n\(.content)\n"'
}


# @cmd Invoke fzf to find a node
pick() {
    XS="xs $(realpath "$1")"
    $XS cat | jq -r .id | sort | fzf \
        --cycle \
        --tac \
        --border none \
        --no-info \
        --color fg+:black,bg+:white,gutter:-1,pointer:green,prompt:blue,hl+:green \
        --preview-window 'border-none' \
        --preview "$0 "$1" view {}" | bp -s
}

eval "$(argc --argc-eval "$0" "$@")"
# argc --argc-eval "$0" "$@"
