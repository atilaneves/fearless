# fearless

[![Build Status](https://travis-ci.org/atilaneves/fearless.png?branch=master)](https://travis-ci.org/atilaneves/fearless)
[![Coverage](https://codecov.io/gh/atilaneves/fearless/branch/master/graph/badge.svg)](https://codecov.io/gh/atilaneves/fearless)

Safe concurrency in D

This package implements `@safe` easy sharing of data between threads without having
to cast and/or lock/unlock a mutex. It does so by using `scope` and
[DIP1000](https://github.com/dlang/DIPs/blob/master/DIPs/DIP1000.md).

Please consult the examples and/or unit tests.
