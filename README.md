# QuickFix Manager

## Introduction

The QuickFix Manager is a Vim plugin that provides a simple user interface for creating custom-made QuickFix lists, and to save/load them to/from disk.

Custom-made QuickFix lists are created by adding entries into the current QuickFix list. An entry added will consist of the cursor's current position (filename + line number). It will also be tagged with the text of the current line or any descriptive text you input yourself.

While saving a QuickFix list to disk, the user is asked to give the list a name. While loading, the plugin will list all previously saved QuickFix lists and ask the user to select one of them to load.

Vim does have built-in support for remembering multiple QuickFix lists, but only up to ten lists, and they cannot be given individual names, so it's harder to keep track of what's in what QuickFix list. A bit rudimentary so to speak. This plugin is an attempt to overcome that limitation.

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

For adding an entry to the current QuickFix list, run this command:

:call QFMNGR_AddToQuickFix()

To clear the current QuickFix list, run this command:

:call QFMNGR_ClearQuickFix()

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
