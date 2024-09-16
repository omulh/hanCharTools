# Han Character Tools

Han Character Tools is a collection of command scripts and a main wrapper script that help get useful information about Han characters, specially for people learning a foreign language that uses them.  

Han characters would be most commonly associated to Chinese characters, however, Chinese is not the only language that uses them.  
From the [Wikipedia](https://en.wikipedia.org/wiki/Han_unification) article:  
> Han characters are a feature shared in common by written Chinese (hanzi), Japanese (kanji), Korean (hanja) and Vietnamese (chữ Hán).

## Features

Get the composition(s) of a given character by using ideographic description characters (IDC) and provide information of which regions use such composition.  

## Installation

Clone this repo with git:  
`$ git clone https://github.com/omulh/HanCharTools.git`  

If needed, make a symlink of the main wrapper script to a dir. which is part of PATH, for instance:  
`# ln -s ~/HanCharTools/hct.sh /bin/hct`  

### Requirements

 - curl
 - grep
 - readlink
 - sed
