# Han Character Tools

Han Character Tools is a collection of command line tools and a main wrapper script that help get useful information about Han characters, specially for people learning a foreign language that uses them.  

Han characters would be most commonly associated with the Chinese language, however, Chinese is not the only language that uses them.  
From the [Wikipedia](https://en.wikipedia.org/wiki/Han_unification) article:  
> Han characters are a feature shared in common by written Chinese (hanzi), Japanese (kanji), Korean (hanja) and Vietnamese (chữ Hán).

## Features at a glance

Get the composition of a given character by using ideographic description characters (IDC) and providing information of the regions that use them.  
```
$ hct composition 的
⿰白勺(GHTJPV)    ⿰白⿹勹丶(K)
```

Get the decomposition of a given character into its most basic elements, which could go down to every individual stroke.  
```
$ hct components 他
㇒丨𠃌乚丨
```

Get the pronunciation, aka the reading, of a given character in different language systems.  
```
$ hct reading 人
rén
```

Get the basic definition of a given character.  
```
$ hct reading --definition 和
harmony, peace; peaceful, calm
```

## Installation

Clone this repo with git:  
`$ git clone https://github.com/omulh/HanCharTools.git`  

If needed, make a symlink of the main wrapper script to a dir. which is part of PATH, for instance:  
`# ln -s ~/HanCharTools/hct /bin/hct`  

### Requirements

 - curl
 - grep
 - readlink
 - sed
