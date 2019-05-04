module dynamic;
import std.stdio;
import core.sys.posix.sys.mman;
import core.sys.posix.signal;
import std.conv;
import std.array;
import std.range;
import std.string;
import std.traits;
import xunit;
import core.vararg;

public interface IDynamic
{
    public TypeInfo Type();
    public bool Compare(IDynamic other);
}

public class DynamicValue(T) : IDynamic
{
    private T _value;

    this(T value)
    {
        _value = value;
    }

    public TypeInfo Type()
    {
        return typeid(T);
    }

    public bool Compare(IDynamic other)
    {
        if (Type() != other.Type())
        {
            return false;
        }

        if (!(cast(DynamicLambda!T) other)._predicate(_value))
        {
            return false;
        }

        return true;
    }

    public T Value()
    {
        return _value;
    }
}

public class DynamicLambda(T) : IDynamic
{
    private bool delegate(T) _predicate;

    this(bool delegate(T) predicate)
    {
        _predicate = predicate;
    }

    public TypeInfo Type()
    {
        return typeid(T);
    }

    public bool Compare(IDynamic other)
    {
        return false;
    }
}

T get(T)(IDynamic dynamic)
{
    return (cast(DynamicValue!T) dynamic).Value();
}

unittest
{
    auto d1 = new DynamicValue!int(13);
    auto d2 = new DynamicLambda!int((x) { return true; });

    Assert.True(d1.Compare(d2));
}

unittest
{
    auto d1 = new DynamicValue!int(13);
    auto d2 = new DynamicLambda!int((x) { return false; });

    Assert.False(d1.Compare(d2));
}

unittest
{
    auto d1 = new DynamicValue!int(13);
    auto d2 = new DynamicLambda!int((x) { return x == 13; });

    Assert.True(d1.Compare(d2));
}

unittest
{
    auto d1 = new DynamicValue!int(13);
    auto d2 = new DynamicLambda!int((x) { return x == 15; });

    Assert.False(d1.Compare(d2));
}