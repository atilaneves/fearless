D implementation of Rust's std::sync::Mutex
====================================================

This package tries to make using `shared` easier in D by locking and unlocking
a mutex for the user.

It also aims to be `@safe` by using `scope` and DIP1000.

For now consult the example code in the only source file.
