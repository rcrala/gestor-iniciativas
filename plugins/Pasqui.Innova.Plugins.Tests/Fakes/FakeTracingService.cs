using Microsoft.Xrm.Sdk;

namespace Pasqui.Innova.Plugins.Tests.Fakes;

/// <summary>
/// Fake ITracingService: captura trazas en memoria para inspeccion.
/// </summary>
internal sealed class FakeTracingService : ITracingService
{
    public List<string> Traces { get; } = new();

    public void Trace(string format, params object[] args)
    {
        Traces.Add(args.Length == 0 ? format : string.Format(format, args));
    }
}
