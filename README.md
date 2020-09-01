# Passages is a website supporting reading and writing of stories that may be branching and interactive.

Authors may work alone or may collaborate or reuse parts of the writing of others, with permission and attribution.

Including quotes, excerpts, or entire public domain works such as [Project Gutenberg](https://www.gutenberg.org/) books and the [World English Bible](https://worldenglish.bible/) is supported.

The code is still pre-alpha and has not yet been deployed in a production environment.

It is being built using Rails 6, Ruby 2.6, and Bulma styles.

A lightly customized version of [twinejs](https://github.com/klembot/twinejs) 2.3 is included. It has been modified to read a story from the dom at startup, go directly to story edit view, and send an edited version back to Passages with a new button. 

[Twine](https://twinery.org) is a big inspiration for this project. Importing your own existing Twine stories is implemented and saving in Twine HTML format is the default way to read a Passages story. 
