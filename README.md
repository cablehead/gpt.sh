# `gpt.sh`

`gpt.sh` is a command-line interface for managing and interacting with a chat
system using OpenAI's GPT models. It provides various commands to create,
modify, and navigate chat threads.

## Requirements

The following CLI tools are required to run `gpt.sh`:

- [`argc`](https://github.com/sigoden/argc)
- [`realpath`](https://formulae.brew.sh/formula/coreutils)
- [`jo`](https://github.com/jpmens/jo)
- [`jq`](https://github.com/jqlang/jq)
- [`xs`](https://github.com/cablehead/xs)
- [`bp`](https://github.com/printfn/bp)
- [`fzf`]() (only needed for the `pick` command)

## Usage

```
USAGE: gpt.sh <STREAM> <COMMAND>

ARGS:
  <STREAM>

COMMANDS:
  seed      Seed a system message
  init      Start a new chat thread
  content   Write a node's content to stdout
  continue  Continue a chat thread
  trigger   Trigger a request for a given node
  thread    Pull the context thread for a given node
  view      View a thread as markdown
  pick      Invoke fzf to find a node
```

## Quick Example

You need to export your OPEN

```bash
export OPENAI_API_KEY=...
```

And then, I like to alias `gpt` to the path `gpt.sh` is kept, and a `stream`
path to store this working session. I usually start a new session for each
task.

```bash
alias gpt="$(realpath ./gpt.sh $(realpath ./stream)"
```

Use `init` to start a thread. Note `init` (and `continue`) read from STDIN. You
can either pipe data to them, or enter text directly, and press ctrl-D on a new
line to signal end of file.

```bash
% gpt init
What is the airspeed velocity of an unladen swallow?
ctrl-D
As an AI language model, I must ask: African or European swallow?
exit code: 0

039LX8LFV502VKGUUUNXI14XQ
```

We can continue a chat thread

```bash
% gpt continue -
African
ctrl-D
According to a famous scene in the movie Monty Python and the Holy Grail, the airspeed velocity of an unladen African swallow is about 24 miles per hour or 11 meters per second. However, it's important to note t
hat this is a fictional reference and not based on any scientific research.
exit code: 0

039LX9PJAAXEQPIGK6U6GZQ4N
```

