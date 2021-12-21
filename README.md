# StringIntern

Java (as well as Objective-C and a few other languages) support a feature called "[String Interning](https://en.wikipedia.org/wiki/String_interning)" which basically means that instead of allocating more than one block of memory for the same string the existing copy of the string already in memory will be used.

Consider the following Java snippet.

```java
String one = "Hello World!";
String two = ("Hello " + "World" + "!").intern();
```

In Java this will result in only one block of memory being allocated for the string `"Hello World!"`. That's because the Java runtime recognizes that the resulting string stored in the variable `two` already exists in memory and so there's no need to store it again.

This library is an attempt to bring the same memory saving functionality to the [Swift](https://swift.org) programming language.

## String Interning in Swift

While I'm sure (at least one would hope) that Swift does compile-time string interning for string literals it is unclear if it does so for any run-time strings.

## Property Wrapper @Intern

This library's primary focus is on strings stored as properties. It does so by implementing a property wrapper called `@intern`. Simply annotating a string property with this wrapper will make it intern any string assigned to it and will return that interned string when read.

```swift
class SomeClass {
  /// Any string stored in this property will be interned.
  @intern var str: String
  
  init(string str: String) {
    self.str = str
  }
}
```

I chose to focus on properties rather than local and global variables for a few of reasons.

1. Property wrappers, which were designed for exactly this reason, only work on properties - not local and global variables.
2. Local variables tend to be very short lived anyways. They exist only during the time that the block of code (function, closure, control block, etc.) they live it executes. When execution exits that code block any strings whose scope has stayed in that block are deallocated automatically.
3. Global variables tend to be initialized using static string literals which, as I mentioned, tend to be interned by the compiler anyways.

That being said, there are a couple of places where an interned string makes sense that cannot be a property - ***collections***.

## Collections

There is a new class called IntString that can be used in place of a String type in collections.

```swift
var myArray: [IntString] = []
```

***[Copyright © 2022 Galen Rhodes. All rights reserved.](LICENSE)***
