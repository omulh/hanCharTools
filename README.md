# Han Character Tools

Han Character Tools is cli tool that allows to get useful information about Han characters, specially for people learning a foreign language that uses them.  
The tool consists of a couple of databases, a collection of bash scripts and main wrapper script to put it all together.  

Han characters would be most commonly associated with the Chinese language, however, Chinese is not the only language that uses them.  
From the [Wikipedia](https://en.wikipedia.org/wiki/Han_unification) article:  
> Han characters are a feature shared in common by written Chinese (hanzi), Japanese (kanji), Korean (hanja) and Vietnamese (chữ Hán).

## Features at a glance

Get the composition of a given character by using ideographic description characters (IDCs) and providing information of the source regions that uses such composition.  
```
$ hct composition 的
⿰白勺(GHTJPV)  ⿰白⿹勹丶(K)

$ hct composition 刃
⿹刀㇒(GKV[B])  ⿹刀丶(HT)  ⿻刀丶(JP)  ⿹𠃌㐅(X)
```

Get the decomposition of a given character into its most basic elements, which may go down to every individual stroke.  
```
$ hct components 他
㇒丨𠃌乚丨

$ hct components 在
一丿丨一丨一
```

Get the pronunciation, aka the reading, of a given character in different language systems.  
```
$ hct reading 人 -s M
rén

$ hct reading 㕵 -s V
uống
```

Get the basic definition of a given character.  
```
$ hct reading --definition 和
harmony, peace; peaceful, calm
```

## Installation

Clone this repo with git:  
`$ git clone https://github.com/omulh/HanCharTools.git`  

If needed, make a symlink of the main wrapper script to a dir. which is included in PATH, for instance:  
`# ln -s ~/HanCharTools/hct /bin/hct`  

### Requirements

A few basic tools must be available in the system for this tool to work:  
curl, grep, tr, readlink, sed  
