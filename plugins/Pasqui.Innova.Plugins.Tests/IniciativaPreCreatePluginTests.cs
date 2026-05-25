using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;
using Pasqui.Innova.Plugins.Iniciativa;
using Pasqui.Innova.Plugins.Tests.Fakes;

namespace Pasqui.Innova.Plugins.Tests;

/// <summary>
/// Tests de la logica de asignacion de consecutivo (metodo estatico AssignConsecutivo).
/// Usa fakes manuales (NSubstitute/Castle no puede proxyar interfaces del Xrm.Sdk por custom attrs).
/// La plumbing de IPlugin (ExecuteInternal) se valida con smoke test integration en DEV post-deploy.
///
/// Cubre los 6 casos del runbook docs/architecture/numeracion-consecutivos.md + idempotencia + errores.
/// </summary>
[TestFixture]
public class IniciativaPreCreatePluginTests
{
    private FakeOrganizationService _service = null!;
    private FakeTracingService _tracing = null!;
    private Guid _empresaId;
    private DateTime _nowUtc;

    [SetUp]
    public void SetUp()
    {
        _empresaId = Guid.NewGuid();
        _nowUtc = new DateTime(2026, 3, 15, 10, 0, 0, DateTimeKind.Utc);
        _service = new FakeOrganizationService();
        _tracing = new FakeTracingService();
    }

    private Entity NewIniciativa(string? codigoEmpresa = "COA")
    {
        var iniciativa = new Entity("pas_iniciativa");
        iniciativa["pas_empresa"] = new EntityReference("pas_empresa", _empresaId) { Name = "Empresa Test" };
        iniciativa["pas_titulo"] = "Test iniciativa";

        // Configurar Retrieve handler para pas_empresa
        _service.RetrieveHandler = (entityName, id, _) =>
        {
            var empresa = new Entity(entityName, id);
            if (codigoEmpresa != null)
            {
                empresa["pas_codigo_corto"] = codigoEmpresa;
            }
            return empresa;
        };

        return iniciativa;
    }

    private void MockMaxSecuencia(int? maxSequenciaExistente)
    {
        _service.RetrieveMultipleHandler = _ =>
        {
            var ec = new EntityCollection();
            if (maxSequenciaExistente.HasValue)
            {
                var existing = new Entity("pas_iniciativa", Guid.NewGuid());
                existing["pas_consecutivo_secuencia"] = maxSequenciaExistente.Value;
                ec.Entities.Add(existing);
            }
            return ec;
        };
    }

    // === Happy paths del runbook ===

    [Test]
    public void AssignConsecutivo_PrimeraIniciativaEmpresaA_2026()
    {
        var iniciativa = NewIniciativa("COA");
        MockMaxSecuencia(null);

        IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc);

        Assert.Multiple(() =>
        {
            Assert.That(iniciativa["pas_consecutivo"], Is.EqualTo("COA-2026-001"));
            Assert.That(iniciativa["pas_consecutivo_secuencia"], Is.EqualTo(1));
            Assert.That(iniciativa["pas_anio"], Is.EqualTo(2026));
        });
    }

    [Test]
    public void AssignConsecutivo_SegundaIniciativaEmpresaA_2026()
    {
        var iniciativa = NewIniciativa("COA");
        MockMaxSecuencia(1);

        IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc);

        Assert.That(iniciativa["pas_consecutivo"], Is.EqualTo("COA-2026-002"));
        Assert.That(iniciativa["pas_consecutivo_secuencia"], Is.EqualTo(2));
    }

    [Test]
    public void AssignConsecutivo_PrimeraIniciativaEmpresaB_2026_NoInterfiereConA()
    {
        var iniciativa = NewIniciativa("PSI");
        MockMaxSecuencia(null);

        IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc);

        Assert.That(iniciativa["pas_consecutivo"], Is.EqualTo("PSI-2026-001"));
    }

    [Test]
    public void AssignConsecutivo_PrimeraIniciativaEmpresaA_2027_ReinicioPorAnio()
    {
        var iniciativa = NewIniciativa("COA");
        MockMaxSecuencia(null);
        var nowEn2027 = new DateTime(2027, 1, 10, 0, 0, 0, DateTimeKind.Utc);

        IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, nowEn2027);

        Assert.That(iniciativa["pas_consecutivo"], Is.EqualTo("COA-2027-001"));
        Assert.That(iniciativa["pas_anio"], Is.EqualTo(2027));
    }

    [Test]
    public void AssignConsecutivo_Secuencia42Existente_AsignaSecuencia43()
    {
        var iniciativa = NewIniciativa("COA");
        MockMaxSecuencia(42);

        IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc);

        Assert.That(iniciativa["pas_consecutivo"], Is.EqualTo("COA-2026-043"));
    }

    // === Idempotencia ===

    [Test]
    public void AssignConsecutivo_TargetTraeConsecutivoExplicito_NoLoSobreescribe()
    {
        var iniciativa = NewIniciativa("COA");
        iniciativa["pas_consecutivo"] = "MANUAL-2024-099";

        IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc);

        Assert.That(iniciativa["pas_consecutivo"], Is.EqualTo("MANUAL-2024-099"));
        Assert.That(iniciativa.Contains("pas_consecutivo_secuencia"), Is.False);
        Assert.That(_service.RetrieveMultipleCallCount, Is.EqualTo(0), "no debe haber query de max si ya viene consecutivo");
    }

    [Test]
    public void AssignConsecutivo_TargetTraeConsecutivoVacio_LoReemplaza()
    {
        var iniciativa = NewIniciativa("COA");
        iniciativa["pas_consecutivo"] = "";
        MockMaxSecuencia(null);

        IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc);

        Assert.That(iniciativa["pas_consecutivo"], Is.EqualTo("COA-2026-001"));
    }

    // === Errores ===

    [Test]
    public void AssignConsecutivo_SinEmpresa_Lanza()
    {
        var iniciativa = new Entity("pas_iniciativa");
        iniciativa["pas_titulo"] = "Sin empresa";

        Assert.That(() => IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc),
            Throws.TypeOf<InvalidPluginExecutionException>()
                .With.Message.Contain("pas_empresa"));
    }

    [Test]
    public void AssignConsecutivo_EmpresaSinCodigoCorto_Lanza()
    {
        var iniciativa = NewIniciativa(null);  // empresa sin codigo corto

        Assert.That(() => IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc),
            Throws.TypeOf<InvalidPluginExecutionException>()
                .With.Message.Contain("pas_codigo_corto"));
    }

    [Test]
    public void AssignConsecutivo_CodigoCortoInvalido_Lanza()
    {
        var iniciativa = NewIniciativa("ab");  // lowercase, 2 chars
        MockMaxSecuencia(null);

        Assert.That(() => IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc),
            Throws.TypeOf<InvalidPluginExecutionException>());
    }

    [Test]
    public void AssignConsecutivo_LimiteSecuencia999Alcanzado_Lanza()
    {
        var iniciativa = NewIniciativa("COA");
        MockMaxSecuencia(999);  // siguiente seria 1000 -> excede limite

        Assert.That(() => IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc),
            Throws.TypeOf<InvalidPluginExecutionException>()
                .With.Message.Contains("limite"));
    }

    [Test]
    public void AssignConsecutivo_EmpresaRefVacia_Lanza()
    {
        var iniciativa = new Entity("pas_iniciativa");
        iniciativa["pas_empresa"] = new EntityReference("pas_empresa", Guid.Empty);

        Assert.That(() => IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc),
            Throws.TypeOf<InvalidPluginExecutionException>()
                .With.Message.Contains("vacia"));
    }

    // === Validaciones de input ===

    [Test]
    public void AssignConsecutivo_TargetNull_Lanza()
    {
        Assert.That(() => IniciativaPreCreatePlugin.AssignConsecutivo(null!, _service, _tracing, _nowUtc),
            Throws.ArgumentNullException);
    }

    [Test]
    public void AssignConsecutivo_ServiceNull_Lanza()
    {
        Assert.That(() => IniciativaPreCreatePlugin.AssignConsecutivo(new Entity("pas_iniciativa"), null!, _tracing, _nowUtc),
            Throws.ArgumentNullException);
    }

    // === Verificacion de query construida ===

    [Test]
    public void AssignConsecutivo_QueryConstruida_FiltraPorEmpresaYAnioYNotNull()
    {
        var iniciativa = NewIniciativa("COA");
        MockMaxSecuencia(null);

        IniciativaPreCreatePlugin.AssignConsecutivo(iniciativa, _service, _tracing, _nowUtc);

        var query = _service.LastQuery as QueryExpression;
        Assert.That(query, Is.Not.Null);
        Assert.That(query!.EntityName, Is.EqualTo("pas_iniciativa"));
        Assert.That(query.TopCount, Is.EqualTo(1));

        var conditions = query.Criteria.Conditions;
        Assert.That(conditions.Count, Is.EqualTo(3));
        Assert.That(conditions[0].AttributeName, Is.EqualTo("pas_empresa"));
        Assert.That(conditions[0].Values[0], Is.EqualTo(_empresaId));
        Assert.That(conditions[1].AttributeName, Is.EqualTo("pas_anio"));
        Assert.That(conditions[1].Values[0], Is.EqualTo(2026));
        Assert.That(conditions[2].AttributeName, Is.EqualTo("pas_consecutivo_secuencia"));
        Assert.That(conditions[2].Operator, Is.EqualTo(ConditionOperator.NotNull));
    }
}
