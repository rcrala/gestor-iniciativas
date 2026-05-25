using Microsoft.Xrm.Sdk;
using Pasqui.Innova.Plugins.Common;
using Pasqui.Innova.Plugins.Iniciativa;
using Pasqui.Innova.Plugins.Tests.Fakes;

namespace Pasqui.Innova.Plugins.Tests;

[TestFixture]
public class IniciativaEstadoTransitionPluginTests
{
    private FakeTracingService _tracing = null!;

    [SetUp]
    public void SetUp()
    {
        _tracing = new FakeTracingService();
    }

    private static Entity NewTarget(int? estado = null)
    {
        var t = new Entity("pas_iniciativa");
        if (estado.HasValue) t["pas_estado"] = new OptionSetValue(estado.Value);
        return t;
    }

    private static Entity PreImageWith(int estado)
    {
        var pi = new Entity("pas_iniciativa");
        pi["pas_estado"] = new OptionSetValue(estado);
        return pi;
    }

    // === Create ===

    [Test]
    public void Create_SinEstado_OK()
    {
        IniciativaEstadoTransitionPlugin.ValidateCreate(NewTarget(estado: null), _tracing);
        // No throw = pass
        Assert.Pass();
    }

    [Test]
    public void Create_EstadoBorrador_OK()
    {
        IniciativaEstadoTransitionPlugin.ValidateCreate(NewTarget(EstadoIniciativa.Borrador), _tracing);
        Assert.Pass();
    }

    [TestCase(EstadoIniciativa.RevisionInicialPmo)]
    [TestCase(EstadoIniciativa.Aprobada)]
    [TestCase(EstadoIniciativa.EstimacionDesarrollo)]
    public void Create_EstadoNoBorrador_Lanza(int estadoInicial)
    {
        Assert.That(() => IniciativaEstadoTransitionPlugin.ValidateCreate(NewTarget(estadoInicial), _tracing),
            Throws.TypeOf<InvalidPluginExecutionException>()
                .With.Message.Contains("Borrador"));
    }

    // === Update ===

    [Test]
    public void Update_TargetSinEstado_OK()
    {
        // El target no cambia estado, no debemos validar
        IniciativaEstadoTransitionPlugin.ValidateUpdate(NewTarget(estado: null),
            PreImageWith(EstadoIniciativa.Borrador), _tracing);
        Assert.Pass();
    }

    [Test]
    public void Update_TargetConEstadoNull_Lanza()
    {
        var target = new Entity("pas_iniciativa");
        target["pas_estado"] = null;  // explicito null
        Assert.That(() => IniciativaEstadoTransitionPlugin.ValidateUpdate(target,
            PreImageWith(EstadoIniciativa.Borrador), _tracing),
            Throws.TypeOf<InvalidPluginExecutionException>()
                .With.Message.Contains("null"));
    }

    [Test]
    public void Update_TransicionPermitida_OK()
    {
        IniciativaEstadoTransitionPlugin.ValidateUpdate(
            NewTarget(EstadoIniciativa.RevisionInicialPmo),
            PreImageWith(EstadoIniciativa.Borrador),
            _tracing);
        Assert.That(_tracing.Traces.Count, Is.GreaterThan(0));
    }

    [Test]
    public void Update_TransicionBloqueada_LanzaConMensajeClaro()
    {
        var ex = Assert.Throws<InvalidPluginExecutionException>(() =>
            IniciativaEstadoTransitionPlugin.ValidateUpdate(
                NewTarget(EstadoIniciativa.Aprobada),
                PreImageWith(EstadoIniciativa.Borrador),
                _tracing));

        Assert.That(ex!.Message, Does.Contain("Borrador"));
        Assert.That(ex.Message, Does.Contain("Aprobada"));
        Assert.That(ex.Message, Does.Contain("Revision inicial PMO"));  // sugerencia de permitidos
    }

    [Test]
    public void Update_DesdeCancelada_SiempreLanza()
    {
        Assert.That(() => IniciativaEstadoTransitionPlugin.ValidateUpdate(
            NewTarget(EstadoIniciativa.Borrador),
            PreImageWith(EstadoIniciativa.Cancelada),
            _tracing),
            Throws.TypeOf<InvalidPluginExecutionException>());
    }

    [Test]
    public void Update_ACancelada_SiempreOK_ExceptoDesdeCancelada()
    {
        IniciativaEstadoTransitionPlugin.ValidateUpdate(
            NewTarget(EstadoIniciativa.Cancelada),
            PreImageWith(EstadoIniciativa.RevisionGerenciaNegocio),
            _tracing);
        Assert.Pass();
    }

    [Test]
    public void Update_AprobadaACancelada_OK()
    {
        IniciativaEstadoTransitionPlugin.ValidateUpdate(
            NewTarget(EstadoIniciativa.Cancelada),
            PreImageWith(EstadoIniciativa.Aprobada),
            _tracing);
        Assert.Pass();
    }

    [Test]
    public void Update_PreImageAusente_Lanza()
    {
        Assert.That(() => IniciativaEstadoTransitionPlugin.ValidateUpdate(
            NewTarget(EstadoIniciativa.Borrador),
            preImage: null,
            _tracing),
            Throws.TypeOf<InvalidPluginExecutionException>()
                .With.Message.Contains("PreImage"));
    }

    // === Inputs invalidos ===

    [Test]
    public void ValidateCreate_TargetNull_Lanza()
    {
        Assert.That(() => IniciativaEstadoTransitionPlugin.ValidateCreate(null!, _tracing),
            Throws.ArgumentNullException);
    }

    [Test]
    public void ValidateUpdate_TracingNull_Lanza()
    {
        Assert.That(() => IniciativaEstadoTransitionPlugin.ValidateUpdate(
            NewTarget(EstadoIniciativa.RevisionInicialPmo),
            PreImageWith(EstadoIniciativa.Borrador),
            null!),
            Throws.ArgumentNullException);
    }
}
