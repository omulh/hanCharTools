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

Get the pronunciation, aka the reading, of a given character in different language systems, e.g. Mandarin and Vietnamese.  
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

## Acknowledgements

This tool is made possible greatly thanks to two databases:  
 1. [IDS Database](https://www.babelstone.co.uk/CJK/IDS.HTML), which consisits of the Ideographic Description Sequences (IDS) for all encoded CJK Unified Ideographs.  
Several small changes were introduced by myself (Omar L.) to make it more compatible with the scripts.  
 2. [Unicode Han Database](https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip), which has the Unicode's collective knowledge on the Han ideographs that are part of the Unicode Standard.

## Installation

Clone this repo with git:  
`$ git clone https://github.com/omulh/HanCharTools.git`  

If needed, make a symlink of the main wrapper script to a dir. which is included in PATH, for instance:  
`# ln -s ~/HanCharTools/hct /bin/hct`  

### Requirements

The scripts rely on basic tools such as curl, grep, readlink, sed, etc., that should be present already in most Linux installations.  
