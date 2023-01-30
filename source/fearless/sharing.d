/**
D implementation of Rust's std::sync::Mutex
*/
module fearless.sharing;

import fearless.from;
import ic.mem;

/**
A reference counted exclusive object (see above).
*/
auto exclusive(T, A...)(auto ref A args) {
	import std.functional: forward;
	return alloc!(Exclusive!T)(forward!args);
}

alias Exclusive(T) = shared(ExclusiveImpl!T);

/**
Provides @safe exclusive access (via a mutex) to a payload of type T.
Allows to share mutable data across threads safely.
*/
package struct ExclusiveImpl(T) {
	import std.traits: hasUnsharedAliasing, isAggregateType;
	
	import core.sync.mutex: Mutex; // TODO: make the mutex type a parameter
	
	private T _payload;
	private Mutex _mutex;
	private bool _locked;
	
	@disable this(this);
	
	/**
	The constructor is responsible for initialising the payload so that
	it's not possible to escape it.
	*/
	this(A...)(auto ref A args) shared {
		import std.functional: forward;
		this._payload = T(forward!args);
		init();
	}
	
	static if(isAggregateType!T && !hasUnsharedAliasing!T) {
		/**
		Take a payload by ref in the case that it's safe, and set the original
		to T.init.
		*/
		private this(ref T payload) shared {
			import std.algorithm: move;
			import std.traits: Unqual;
			
			_payload = () @trusted {  return cast(shared) move(payload); }();
			payload = payload.init;

			init();
		}
	}
	
	private void init() shared {
		this._mutex = new shared Mutex;
	}
	
	/**
	Whether or not the mutex is locked.
	*/
	bool isLocked() shared const {
		return _locked;
	}
	
	/**
	Obtain exclusive access to the payload. The mutex is locked and
	when the returned `Guard` object's lifetime is over the mutex
	is unloked.
	*/
	auto lock() shared {
		() @trusted { _mutex.lock_nothrow; }();
		_locked = true;
		return Guard(&_payload, _mutex, &_locked);
	}
	
	alias borrow = lock;
	
	// non-static didn't work - weird error messages
	static struct Guard {
		
		private shared T* _payload;
		private shared Mutex _mutex;
		private shared bool* _locked;
		
		alias reference this;
		
		ref T reference() @trusted return scope {
			return *(cast(T*) _payload);
		}
		
		~this() scope @trusted {
			*_locked = false;
			_mutex.unlock_nothrow();
		}
	}
}
