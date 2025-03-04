// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -emit-module-path %t/StrictModule.swiftmodule -module-name StrictModule -swift-version 6 %S/Inputs/StrictModule.swift
// RUN: %target-swift-frontend -emit-module -emit-module-path %t/NonStrictModule.swiftmodule -module-name NonStrictModule %S/Inputs/NonStrictModule.swift
// RUN: %target-swift-frontend -emit-module -emit-module-path %t/OtherActors.swiftmodule -module-name OtherActors %S/Inputs/OtherActors.swift -disable-availability-checking

// RUN: %target-swift-frontend  -I %t %s -emit-sil -o /dev/null -verify  -parse-as-library -enable-upcoming-feature GlobalConcurrency
// RUN: %target-swift-frontend  -I %t %s -emit-sil -o /dev/null -verify -strict-concurrency=targeted -disable-region-based-isolation-with-strict-concurrency  -parse-as-library -enable-upcoming-feature GlobalConcurrency
// RUN: %target-swift-frontend  -I %t %s -emit-sil -o /dev/null -verify -strict-concurrency=complete -disable-region-based-isolation-with-strict-concurrency  -parse-as-library -enable-upcoming-feature GlobalConcurrency
// RUN: %target-swift-frontend  -I %t %s -emit-sil -o /dev/null -verify -strict-concurrency=complete  -parse-as-library -enable-upcoming-feature GlobalConcurrency

// REQUIRES: concurrency
// REQUIRES: asserts

@preconcurrency import NonStrictModule
@_predatesConcurrency import StrictModule // expected-warning{{'@_predatesConcurrency' has been renamed to '@preconcurrency'}}
@preconcurrency import OtherActors
// expected-warning@-1{{'@preconcurrency' attribute on module 'OtherActors' has no effect}}{{1-17=}}

func acceptSendable<T: Sendable>(_: T) { }

@available(SwiftStdlib 5.1, *)
func test(
  ss: StrictStruct, ns: NonStrictClass, oma: OtherModuleActor,
  ssc: SomeSendableClass
) async {
  acceptSendable(ss) // expected-warning{{type 'StrictStruct' does not conform to the 'Sendable' protocol}}
  acceptSendable(ns) // silence issue entirely
  acceptSendable(oma) // okay
  acceptSendable(ssc) // okay
}

let nonStrictGlobal = NonStrictClass() // no warning

let strictGlobal = StrictStruct() // expected-warning{{let 'strictGlobal' is not concurrency-safe because non-'Sendable' type 'StrictStruct' may have shared mutable state}}
// expected-note@-1{{isolate 'strictGlobal' to a global actor, or conform 'StrictStruct' to 'Sendable'}}
