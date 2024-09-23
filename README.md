# Han Character Tools

Han Character Tools is cli tool that allows to get useful information about Han characters, specially for people learning a foreign language that uses them.  
The tool consists of a couple of databases, a collection of bash scripts and main wrapper script to put it all together.  

Han characters would be most commonly associated with the Chinese language, however, Chinese is not the only language that uses them.  
From the [Wikipedia](https://en.wikipedia.org/wiki/Han_unification) article:  
> Han unification is an effort by the authors of Unicode and the Universal Character Set to map multiple character sets of the Han characters of the so-called CJK languages into a single set of unified characters.
> Han characters are a feature shared in common by written Chinese (hanzi), Japanese (kanji), Korean (hanja) and Vietnamese (chữ Hán).

## Features at a glance

### Character composition

Get the composition of a given character by using an ideographic description sequence ([IDS](https://en.wikipedia.org/wiki/Chinese_character_description_languages#Ideographic_Description_Sequences)).  
A letter code containing the source region(s) for any given composition is also included between parentheses.  
```
$ hct composition 和
⿰禾口(GHTJKPV)
```

Filter out compositions that do not match the specified source region(s).  
```
$ hct composition 刃
⿹刀㇒(GKV[B]) ⿹刀丶(HT) ⿻刀丶(JP) ⿹𠃌㐅(X)

$ hct composition 刃 -s HJ
⿹刀丶(HT) ⿻刀丶(JP)
```

Get the composition information from Wiktionary instead of the local database.  
This method is comparatively slow, and the formatting of the queried compositions is not as consistent as the ones in the local database.
This is useful, however, to query (the very few) characters which may be missing from the local database.  
```
$ hct composition 𬺷
The given character has no valid composition options.

$ hct composition 𬺷 -w
⿱丆⿹㇁丿
```

### Character components

Get the decomposition of a given character into its most basic elements, which may go down to every individual stroke.  
```
$ hct components 他
㇒丨𠃌乚丨
```

### Character reading and definition

Get the pronunciation, aka the reading, of a given character in different language systems, e.g. Mandarin (the default) or Vietnamese.  
```
$ hct reading 人
rén

$ hct reading 㕵 -s V
uống
```

Get the basic definition of a given character.  
```
$ hct reading 和 --definition
harmony, peace; peaceful, calm
```

### Character variants

Get the traditional or simplified variants of a given character.  
```
$ hct variants 么 --traditional
幺 麼 麽

$ hct variants 説 --simplified
说
```

Get the semantic variant, i.e. a character with identical meaning, of a given character.  
The dictionary source and some additional information are found between parentheses.  
```
$ hct variants 子 --semantic
只(Lau) 
```

### Process a file or the stdin instead of a single character

For any of the commands, a file may be specified as an input for serial processing.  
```
$ hct reading 5-chars.txt
的      de
是      shì
在      zài
有      yǒu
我      wǒ
```

For any of the commands, the input may be piped from other commands.  
```
$ head -n5 100-chars.txt | hct reading - --definition
的	possessive, adjectival suffix
一	one; a, an; alone
是	indeed, yes, right; to be; demonstrative pronoun, this, that
不	no, not; un-; negative prefix
了	to finish; particle of completed action
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
