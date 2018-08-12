## 1.7.0

* add `redirect_eval_exekutor`
* `inplace_sed` moved to mulle-file.sh to fix problems on freebsd


### 1.6.2

* fix hostname for mingw

### 1.6.1

* small cleanups

## 1.6.0

* add `MULLE_USER_PWD` and mulle-case.sh


### 1.5.7

* fix installer rename in brew formula

### 1.5.6

* add bash and uuidgen dependencies for debian

### 1.5.5

* fix README.md

### 1.5.4

* rename install to installer, because of name conflict

### 1.5.3

* fix README.md some more

### 1.5.2

* fix README.md

### 1.5.1

* improve README, rename install.sh to install

## 1.5.0

* add `escaped_singlequotes,` add `MULLE_HOSTNAME`


## 1.4.0

* add escaping function and `sed_inplace` replace
* fix display bugs


### 1.3.2

* less confusing pid logging in exekutors
* don't use gratuitous subshell in eval exekutors if they can be avoided

### 1.3.1

* use MULLE_UNAME instead of UNAME in the future

## 1.3.0

* improve startup time greatly
* avoid globbing problems in for loops
* fast_dirname and fast_basename added


### 1.2.3

* make minimal loading possible, useful for many scripts
* fix bugs in versioning checks

### 1.2.2

* fix bad and superflous mktemp use

### 1.2.1

* fix for filepath concat

## 1.1.0

* improved concat
* remove snip, which is too specialized and was buggy
* add path_extension


# 1.0.0

* Initial spin-off from mulle-bootstrap. Heavily under-documented
