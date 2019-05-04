import std.stdio;
import core.sys.posix.sys.mman;
import core.sys.posix.signal;
import std.conv;
import std.array;
import std.range;
import std.string;
import std.traits;
import core.vararg;
import dynamic;
import substitute;
import xunit;

public interface IDummy
{
	public int Foo(int bar, int baz);
}

void main()
{
	auto mock = Substitute.For!IDummy;
	// // IDummy dummy = mock;

	// // mock.Foo(Arg.Any!int(), Arg.Is!int((x){ return x == 3; })).Returns(14);
	// mock.Foo(Arg.Any!int(), Arg.Is!int((x) { return x == 3; })).Do(() {
	// 	throw new StringException("Go Went Gone!");
	// });
	// auto result = mock.Foo(2, 3);

	// writeln(result);

	// writeln(mock.Gen());
	writeln(mock.Received().Gen());
}

unittest
{
	auto mock = Substitute.For!IDummy;
	mock.Foo(Arg.Any!int(), Arg.Is!int((x) { return x == 3; })).Returns(13);
	auto result = mock.Foo(2, 3);

	Assert.Equals(13, result);
}

unittest
{
	auto mock = Substitute.For!IDummy;
	mock.Foo(Arg.Any!int(), Arg.Is!int((x) { return x == 3; })).Returns(13);
	mock.Foo(Arg.Any!int(), Arg.Is!int((x) { return x == 4; })).Returns(15);
	auto result = mock.Foo(2, 4);

	Assert.Equals(15, result);
}

unittest
{
	auto mock = Substitute.For!IDummy;
	mock.Foo(Arg.Any!int(), Arg.Is!int((x) { return x == 3; })).Do(() {
		throw new StringException("Go Went Gone!");
	});

	Assert.Throws!StringException(() { mock.Foo(2, 3); });
}

unittest
{
	auto mock = Substitute.For!IDummy;
	mock.Foo(Arg.Any!int(), Arg.Any!int()).Returns(15);

	mock.Foo(2, 3);
	mock.Foo(2, 5);
	mock.Received().Foo(2, 3).Twice();
}
