#!/bin/sh
mkdir target
javac -sourcepath src -d target src/lingutil/bleu/Main.java
jar cvfe bleu.jar lingutil.bleu.Main -C target/ .
