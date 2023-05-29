# `gpt.sh`

`gpt.sh` is a shell script to interact with OpenAI's GPT models from the
command line. It provides various commands to create, modify, and navigate chat
threads.

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

## Quick example

You need to export your OPENAI_API_KEY

```bash
export OPENAI_API_KEY=...
```

And then, I like to alias `gpt` to the path `gpt.sh` is kept, and a `stream`
path to store this working session. I usually start a new session for each
task.

```bash
alias gpt="$(realpath ./gpt.sh) $(realpath ./stream)"
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

You can continue a chat thread. The `-` means, the last chat node.

```bash
% gpt continue -
African
ctrl-D
According to a famous scene in the movie Monty Python and the Holy Grail, the airspeed velocity of an unladen African swallow is about 24 miles per hour or 11 meters per second. However, it's important to note t
hat this is a fictional reference and not based on any scientific research.
exit code: 0

039LX9PJAAXEQPIGK6U6GZQ4N
```

To view the current full chat thread so far:

```
% gpt view -
## 039LX8L5PMS9U0JYTXFDTV1M0 :: user ::

What is the airspeed velocity of an unladen swallow?

## 039LX8LFV502VKGUUUNXI14XQ :: assistant :: gpt-3.5-turbo

As an AI language model, I must ask: African or European swallow?

## 039LX9OL89BU4BWPKM2TAN8Y6 :: user ::

African

## 039LX9PJAAXEQPIGK6U6GZQ4N :: assistant :: gpt-3.5-turbo

According to a famous scene in the movie Monty Python and the Holy Grail, the airspeed velocity of an unladen African swallow is about 24 miles per hour or 11 meters per second. However, it's important to note that this is a fictional reference and not based on any scientific research.
```

You can play 'choose your own adventure'. Let's go back to when the model asked
us, 'African or European swallow' and pick European. The ID for that chat node
was `039LX8LFV502VKGUUUNXI14XQ`:

```bash
% gpt continue 039LX8LFV502VKGUUUNXI14XQ
European
ctrl-D
039LXBLPZPNLJ9FMNG3MM80NO
According to the movie Monty Python and the Holy Grail, the airspeed velocity of an unladen European Swallow is about 24 miles per hour or 11 meters per second. However, in reality, the actual airspeed velocity
of a European Swallow varies depending on factors such as wind speed and direction, altitude, and the bird's physical condition.
exit code: 0

039LXBMVTKRGFE9W08MZ1R2Q2
```

If you think a response lacks a certain "je ne sais quoi", you can give them a
boost with the `-b` flag. This selects gpt-4, instead of the default
`gpt-3.5-turbo` model:

```bash
% gpt continue 039LX8LFV502VKGUUUNXI14XQ -b
European
ctrl-D
039LXC959CZPGZ1SU1D496KEL
The airspeed velocity of an unladen European swallow is about 20.1 miles per hour (32.4 kilometers per hour). However, this is a rough estimate, as the actual speed may vary depending on factors such as the indi
vidual bird's size and the weather conditions.
exit code: 0

039LXCCMAV7RNXR3WMV91FPG3
```

## A more practical example

`init` takes a `--fence` option. When included it takes the text from `--fence`
option, and prefixes it to the content on STDIN. It also wraps STDIN in a
markdown codefence.

```bash
cat gpt.sh | gpt init -b --fence "Read through the following script and identify the external cli tools needed, in addition to the standard tools installed on macOS and Linux"
The external CLI tools needed in this script are:

1. argc
2. realpath
3. curl
4. sed
5. jo
6. jq
7. xs
8. fzf
9. bp
exit code: 0

039LXD8X837VTQ0U7LEYYNIOI
```

You can grab the content of the last chat node in a thread:

```bash
% gpt content - >> README.md
```

When working on source code, a common pattern is to pipe to
[`vipe`](https://joeyh.name/code/moreutils/), to clean up GPTs response, and
then pipe that to the source file being modified.

```bash
% cat src/main.rs | gpt init -b --fence "This is our Rust program so far. Update to..."
% gpt content - | vipe > src/main.rs
```

