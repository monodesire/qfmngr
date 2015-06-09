# QuickFix Manager

## Introduction

The QuickFix Manager is a Vim plugin that makes it possible to save/load QuickFix lists to/from disk. It provides a simple user interface to make it easy for the user to save and load lists. While saving a list, the user is asked to give the list a name. While loading, the plugin will list all previously saved lists and ask the user to select one of them to load.

Vim does have built-in support for remembering multiple QuickFix lists, but only up to ten lists, and they cannot be given individual names, so it's harder to keep track of what's in what list. A bit rudimentary so to speak. This plugin is an attempt to overcome that limitation.

## Requirements

This plugin has been tested with Vim 7.3 in a Linux environment. Only the regular text-based Vim has been used in this testing, not gVim. There are probably no special requirements for this plugin to work.

## Installation

In an essence, one needs to copy qfmngr.vim (the actual plugin code) and qfmngr.txt (the help file) to somewhere into 'runtimepath'. For a standard Unix environment, this most likely means $HOME/.vim/plugin/ and $HOME/.vim/doc/ respectively.

If one has a clone of the QuickFix Manager Git repository, one may add the path to it into 'runtimepath'.

After installation, don't forget to generate help tags files, to includes help tags for this plugin. Here's an example of how to run this command:

:helptags $VIMRUNTIME/doc

## Configure the plugin

Goto the configuration section in the plugin's help by running this command:

:help qfmngr-configuration

## How to use

To save the current QuickFix list, run this command:

:call QFMNGR_SaveQuickFix()

To load a QuickFix list, run this command:

:call QFMNGR_LoadQuickFix()

For deeper understanding, please read the plugin's help:

:help qfmngr

## License

MIT License, see file LICENSE.

## Maintainer

Mats Lintonsson <[mats.lintonsson@gmail.com](mats.lintonsson@gmail.com)>
