# DSubstitute

```d
public interface IDummy
{
	public int Foo(int bar, int baz);
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
```