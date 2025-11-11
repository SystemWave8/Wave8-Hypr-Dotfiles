Intro Thoughts:

################

This is a very early build of the .dotfiles and doesn't include any custom features that you might be accustomed to.

Though it's nice to have a .dotfiles setup, my recommendation is to find out how to build your own .dotfiles repository.

Doing so will bring extra confidence behind knowing your system.

################


Installation:

################

This repository assumes you have minimal Arch installation and is intended for fresh installations and really....solely Arch (by the way :)

A word of caution - though it should be pretty idempotent, be prepared to have data loss if you don't know how .dotfiles work.

Also, 'archinstall' was personally used on my installation so it should be noob friendly.

You will also need git so you can  grab it like so:
```bash
sudo pacman -S git
```
Use the following command to clone and auto setup:
```bash
git clone https://github.com/SystemWave8/Wave8-Hypr-Dotfiles.git ~/.dotfiles && bash ~/.dotfiles/bin/setup.sh
```
It should automatically link any .dotfiles to your system and backup any configs that might be in place.
Other then that, take it an run with it, though there are probably better .dotfiles out there.

Have fun,

Wave-8
