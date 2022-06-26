# Compiler 2021-2

A project in SNU ECE Introduction to Compiler (430.414) lecture, at 2021 autumn.

Implemented front-end of SubC compiler, which generates stack machine code.

* [Grammar of SubC](https://github.com/ckswjd99/SNUCompiler-2021-2/blob/main/doc/project3-grammar.txt)
* [ISA of stack machine](https://github.com/ckswjd99/SNUCompiler-2021-2/blob/main/doc/project4.pdf)

## Build
### SubC Compiler
```
$ cd src/compiler
$ make all
```

### Stack Machine
```
$ cd src/stack_machine
$ make all
```

## Run
### Compiler
```
$ ./subc input_file.c output_name.s
```

### Stack Machine
```
$ ./sim input_file.s
```
