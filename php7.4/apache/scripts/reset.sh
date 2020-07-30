#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation

cp ./vanilla-save/phar.php $PHP_SRC_PATH/ext/phar/phar.php
cp ./vanilla-save/zend_language_scanner.l $PHP_SRC_PATH/Zend/zend_language_scanner.l
cp ./vanilla-save/zend_language_parser.y $PHP_SRC_PATH/Zend/zend_language_parser.y

cd $PHP_SRC_PATH; make -o ext/phar/phar.php install -k; cd $POLYSCRIPT_PATH;