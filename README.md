# Lightweight - Fast, native macOS OpenRouter LLM client

![Lightweight chat window](assets/lightweight-chat.jpg)

A minimal native macOS chat app for text-only LLMs through [OpenRouter](https://openrouter.ai).

Here are the entire reasons I needed this, and why you might like it too:

* No "memory"!
* Clean context every time.
* Fast as possible.
* No logging, saving chats, or any clutter to organize.
* OpenRouter API key is stored in the macOS Keychain, not some random dot file!

But you do get a few niceties:

* Pick from a variety of modern models.
* Enter a system prompt for tone/guidance.
* Change the color of the app.

## Build

Requires macOS 14+, Xcode command-line tools, and an Apple Development signing identity.

```sh
make
make run
```

Set your OpenRouter API key in Settings (`⌘,`) after launching the app.

MIT licensed.
