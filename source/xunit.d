module xunit;
import std.stdio;
import std.conv;
import std.array;
import std.range;
import std.string;
import std.traits;
import core.vararg;

public static class Assert
{
    public static void Throws(E)(void delegate() action)
    {
        bool bad = false;

        try
        {
            action();
            bad = true;
        }
        catch (E exception)
        {
        }

        if (bad)
        {
            throw new StringException("Expected exception wasn't thrown.");
        }
    }

    public static void True(bool condition)
    {
        if (!condition)
        {
            throw new StringException("Expected true statement");
        }
    }

    public static void False(bool condition)
    {
        if (condition)
        {
            throw new StringException("Expected false statement");
        }
    }

    public static void Equals(T)(T expected, T actual)
    {
        if (expected != actual)
        {
            throw new StringException("Comparasion failed");
        }
    }
}
