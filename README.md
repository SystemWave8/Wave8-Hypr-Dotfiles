Intro:
---

This is a repository for a dotfiles setup designed for Arch Linux & Hyprland.

Though it's nice to have an easily accessible .dotfiles repo, my recommendation is to find out how to build your own .dotfiles repository.

Doing so will bring extra confidence behind knowing your system.

---

Installation:
---

This repository assumes you have a minimal Arch installation and is intended for fresh installations and really....solely Arch (by the way :)

A word of caution - though it should be pretty idempotent, be prepared to have data loss if you don't know how .dotfiles work and git works.

Also, 'archinstall' was personally used on my installation so it should be noob friendly.

---

The only package that is required to run this installation is git, which you can grab like so:

```bash
sudo pacman -S git
```
Use the following command to clone and auto setup:
```bash
git clone https://github.com/SystemWave8/Wave8-Hypr-Dotfiles.git ~/.dotfiles && bash ~/.dotfiles/bin/setup.sh
```
---

Again, we have to assume that this is from a fresh installation with virtually nothing installed. If you do actually have a '.dotfiles' directory, it will not work.
I can't point out enough...run this after a fresh minimal installation as this is basically my system installer.

Knowing this, it should automatically link any .dotfiles to your system and backup any configs that might be in place.
Other then that, take it an run with it, though there are probably better .dotfiles out there.

Have fun,

Wave-8


---
Update: Hyprland Plugins
---

Some of my hyprland conf files are designed to work with a couple of hyprland plugins.
For simplicity sake I will provide the setup and installation here.

Hyprscolling:

```bash
hyprpm update
```

Add the following repositories:

```bash
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm add https://github.com/KZDKM/Hyprspace
```

Enable your plugins:
```bash
hyprpm enable Hyprspace
hyprpm enable hyprscrolling
```

A small note: You may need to purge-cache, update and reinstall after hyprland gets updated

