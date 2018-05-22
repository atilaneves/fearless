D implementation of Rust's std::sync::Mutex
====================================================

This package tries to make using `shared` easier in D by locking and unlocking
a mutex for the user.

It also aims to be `@safe` by using `scope` and DIP1000.

For now consult the example code in the only source file.

The Rust type is called Mutex but here it's called Shared. It's not a good name, but
also calling it Mutex might have been confusing given core.sync.mutex.Mutex.
