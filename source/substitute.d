module substitute;
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
import xunit;

public class ArgumentMatcher
{
	protected IDynamic _dynamic;

	public bool IsExpected(IDynamic dynamic)
	{
		return dynamic.Compare(_dynamic) == true;
		// return _dynamic.Compare(dynamic) == true;
	}
};

public class AnyArgumentMatcher(T) : ArgumentMatcher
{
	public this()
	{
		_dynamic = new DynamicLambda!T((x) { return true; });
	}
}

public class ExactArgumentMatcher(T) : ArgumentMatcher
{
	public this(bool delegate(T) predicate)
	{
		_dynamic = new DynamicLambda!T(predicate);
	}
}

public interface IPostCondition
{
	public IDynamic Value();
}

public class PostCondition(T) : IPostCondition
{
	private T _default;
	private IDynamic _value;
	private void delegate() _doFunc;

	this()
	{
		_value = new DynamicValue!T(_default);
		_doFunc = () {};
	}

	public void Returns(T value)
	{
		_value = new DynamicValue!T(value);
		_doFunc = () {};
	}

	public void Do(void delegate() func)
	{
		_doFunc = func;
	}

	public IDynamic Value()
	{
		_doFunc();
		return _value;
	}
}

public class ExecutedCondition
{
	private int _count = 0;

	public this(int count)
	{
		_count = count;
	}

	public void Once()
	{
		if (_count != 1)
		{
			throw new StringException("Once()");
		}
	}

	public void Twice()
	{
		if (_count != 2)
		{
			throw new StringException("Once()");
		}
	}

	public void Times(int value)
	{
		if (_count != value)
		{
			throw new StringException("Times(int value)");
		}
	}
}

static class Arg
{
	public static ArgumentMatcher Any(T)()
	{
		return new AnyArgumentMatcher!T();
	}

	public static ArgumentMatcher Is(T)(bool delegate(T) predicate)
	{
		return new ExactArgumentMatcher!T(predicate);
	}
}

public interface ICall
{
	public ArgumentMatcher IndexOf(int index);
	public IPostCondition PostCondition();
	public void IncreaseCallCount();
	public int CallCount();
	public string Signature();
}

public class Call : ICall
{
	private string _signature;
	private IPostCondition _postCondition;
	public ArgumentMatcher[] _parameters;
	private int _called = 0;

	public this(string signature, IPostCondition postCondition, ArgumentMatcher[] arguments)
	{
		_signature = signature;
		_postCondition = postCondition;
		_parameters ~= arguments;
	}

	public IPostCondition PostCondition()
	{
		return _postCondition;
	}

	public ArgumentMatcher IndexOf(int index)
	{
		return _parameters[index];
	}

	public void IncreaseCallCount()
	{
		++_called;
	}

	public string Signature()
	{
		return _signature;
	}

	public int CallCount()
	{
		return _called;
	}
}

public class Receive(T)
{
	private Mock!T _mock;

	this(Mock!T mock)
	{
		_mock = mock;
	}

	public ExecutedCondition Invoke(string signature, IDynamic[] args...)
	{
		auto call = _mock.Find(signature, args);
		return new ExecutedCondition(call.CallCount());
	}

	// public ExecutedCondition Foo(int p0, int p1)
	// {
	// 	string signature = "int Foo(int p0, int p1)";

	// 	return Invoke(signature, new DynamicValue!int(p0), new DynamicValue!int(p1));
	// }

	mixin(Gen());

	public static string Gen()
	{
		string method = "";

		foreach (name; __traits(allMembers, T))
		{
			foreach (t; __traits(getVirtualMethods, T, name))
			{
				string[] parameters;
				string[] names;
				string[] parameters2;
				string[] names2;
				string[] xyz;
				auto p = 0;

				foreach (type; ParameterTypeTuple!(t))
				{
					xyz ~= "new DynamicValue!" ~ type.stringof ~ "(p" ~ to!string(p) ~ ")";
					parameters ~= type.stringof ~ " p" ~ to!string(p);
					names ~= "p" ~ to!string(p);
					parameters2 ~= "ArgumentMatcher!" ~ type.stringof ~ " p" ~ to!string(p);
					names2 ~= "p" ~ to!string(p) ~ ".Value";
					++p;
				}

				string signature = ReturnType!(t).stringof ~ " " ~ name ~ "(" ~ parameters.join(
						", ") ~ ")";

				// Normal Method
				method ~= "public ExecutedCondition " ~ name ~ "(" ~ parameters.join(
						", ") ~ ")" ~ "\n";
				method ~= "{\n";
				method ~= "\tstring signature = \"" ~ signature ~ "\";\n";
				method ~= "\n";
				method ~= "\t" ~ "return Invoke(signature, " ~ xyz.join(", ") ~ ");\n";
				method ~= "}\n";
			}
		}

		return method;
	}
}

public class Mock(T)  : T
{
	public Receive!T Received()
	{
		return new Receive!T(this);
	}

	private void Register(E)(string signature, IPostCondition postCondition,
			ArgumentMatcher[] arguments...)
	{
		auto call = new Call(signature, postCondition, arguments);

		_calls ~= call;
	}

	public int[string] _callsed;
	public ICall[] _calls;

	private void RegisterCallCount(string signature)
	{
		_callsed[signature] += 1;
	}

	public ICall Find(string signature, IDynamic[] dynamics)
	{
		foreach (call; _calls)
		{
			if (call.Signature() != signature)
			{
				continue;
			}

			auto index = 0;
			bool good = true;

			foreach (dynamic; dynamics)
			{
				auto matcher = call.IndexOf(index); // lambda

				if (matcher.IsExpected(dynamic) == true)
				{
					++index;
					continue;
				}

				good = false;
				break;
			}

			if (good)
			{
				return call;
			}
		}

		throw new StringException("Find Failed");
	}

	public E Invoke(E)(string signature, IDynamic[] args...)
	{
		auto call = Find(signature, args);
		auto post = call.PostCondition();
		auto value = post.Value();
		auto result = get!int(value);

		call.IncreaseCallCount();
		return result;
	}

	// public int Foo(int p0, int p1)
	// {
	// 	string signature = "int Foo(int p0, int p1)";

	// 	return Invoke!int(signature, new DynamicValue!int(p0), new DynamicValue!int(p1));
	// }

	// public PostCondition!int Foo(ArgumentMatcher p0, ArgumentMatcher p1)
	// {
	// 	string signature = "int Foo(int p0, int p1)";
	// 	auto post = new PostCondition!int();

	// 	Register!int(signature, post, p0, p1);
	// 	return post;
	// }

	mixin(Gen());

	public static string Gen()
	{
		string method = "";

		foreach (name; __traits(allMembers, T))
		{
			foreach (t; __traits(getVirtualMethods, T, name))
			{
				string[] parameters;
				string[] names;
				string[] parameters2;
				string[] parameters3;
				string[] names2;
				string[] xyz;
				auto p = 0;

				foreach (type; ParameterTypeTuple!(t))
				{
					parameters ~= type.stringof ~ " p" ~ to!string(p);
					names ~= "p" ~ to!string(p);
					parameters2 ~= "ArgumentMatcher p" ~ to!string(p);
					names2 ~= "p" ~ to!string(p) ~ ".Value";
					xyz ~= "new DynamicValue!" ~ type.stringof ~ "(p" ~ to!string(p) ~ ")";
					++p;
				}

				string signature = ReturnType!(t).stringof ~ " " ~ name ~ "(" ~ parameters.join(
						", ") ~ ")";

				// Normal Method
				method ~= "public " ~ signature ~ "\n";
				method ~= "{\n";
				method ~= "\tstring signature = \"" ~ signature ~ "\";\n";
				method ~= "\n";
				// method ~= "\tRegisterCallCount(\"" ~ signature ~ "\");\n";
				// method ~= "\t" ~ "return 0;\n";
				method ~= "\treturn Invoke!" ~ ReturnType!(t)
					.stringof ~ "(signature, " ~ xyz.join(", ") ~ ");\n";
				method ~= "}\n";
				method ~= "\n";

				// Bastard
				method ~= "public PostCondition!" ~ ReturnType!(t).stringof;
				method ~= " ";
				method ~= name;
				method ~= "(";
				method ~= parameters2.join(", ");
				method ~= ")\n";
				method ~= "{\n";
				method ~= "\tstring signature = \"" ~ signature ~ "\";\n";
				method ~= "\n";
				method ~= "	auto post = new PostCondition!" ~ ReturnType!(t).stringof ~ "();\n";
				method ~= "	Register!int(signature, post, " ~ names.join(", ") ~ ");\n";
				method ~= "\treturn post;\n";
				method ~= "}\n";
			}
		}

		return method;
	}
}

static class Substitute
{
	public static Mock!T For(T)()
	{
		return new Mock!T;
	}
}

unittest
{
	IDynamic d1 = new DynamicValue!int(13);
	ArgumentMatcher d2 = new ExactArgumentMatcher!int((x) { return true; });

	Assert.True(d2.IsExpected(d1));
}

unittest
{
	IDynamic d1 = new DynamicValue!int(13);
	ArgumentMatcher d2 = new ExactArgumentMatcher!int((x) { return false; });

	Assert.False(d2.IsExpected(d1));
}

unittest
{
	IDynamic d1 = new DynamicValue!int(13);
	ArgumentMatcher d2 = new ExactArgumentMatcher!int((x) { return x == 13; });

	Assert.True(d2.IsExpected(d1));
}

unittest
{
	IDynamic d1 = new DynamicValue!int(13);
	ArgumentMatcher d2 = new ExactArgumentMatcher!int((x) { return x == 15; });

	Assert.False(d2.IsExpected(d1));
}
