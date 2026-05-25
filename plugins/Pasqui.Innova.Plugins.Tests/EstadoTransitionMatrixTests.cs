using Pasqui.Innova.Plugins.Common;

namespace Pasqui.Innova.Plugins.Tests;

[TestFixture]
public class EstadoTransitionMatrixTests
{
    // === Transiciones forward del happy path ===

    [TestCase(EstadoIniciativa.Borrador, EstadoIniciativa.RevisionInicialPmo)]
    [TestCase(EstadoIniciativa.RevisionInicialPmo, EstadoIniciativa.EstimacionDesarrollo)]
    [TestCase(EstadoIniciativa.RevisionInicialPmo, EstadoIniciativa.RevisionIniciativaJefatura)]
    [TestCase(EstadoIniciativa.EstimacionDesarrollo, EstadoIniciativa.RevisionEstimacionJefatura)]
    [TestCase(EstadoIniciativa.RevisionEstimacionJefatura, EstadoIniciativa.EstimacionAprobadaJefatura)]
    [TestCase(EstadoIniciativa.RevisionEstimacionJefatura, EstadoIniciativa.EstimacionDevueltaJefatura)]
    [TestCase(EstadoIniciativa.RevisionEstimacionJefatura, EstadoIniciativa.EstimacionRechazadaJefatura)]
    [TestCase(EstadoIniciativa.EstimacionAprobadaJefatura, EstadoIniciativa.EnCotizacion)]
    [TestCase(EstadoIniciativa.EstimacionAprobadaJefatura, EstadoIniciativa.RevisionIniciativaJefatura)]
    [TestCase(EstadoIniciativa.EnCotizacion, EstadoIniciativa.RevisionIniciativaJefatura)]
    [TestCase(EstadoIniciativa.RevisionIniciativaJefatura, EstadoIniciativa.RevisionGerenciaNegocio)]
    [TestCase(EstadoIniciativa.RevisionIniciativaJefatura, EstadoIniciativa.IniciativaDevueltaJefatura)]
    [TestCase(EstadoIniciativa.IniciativaDevueltaJefatura, EstadoIniciativa.RevisionInicialPmo)]
    [TestCase(EstadoIniciativa.EstimacionDevueltaJefatura, EstadoIniciativa.EstimacionDesarrollo)]
    [TestCase(EstadoIniciativa.RevisionGerenciaNegocio, EstadoIniciativa.AprobadaGerenciaNegocio)]
    [TestCase(EstadoIniciativa.RevisionGerenciaNegocio, EstadoIniciativa.RechazadaGerenciaNegocio)]
    [TestCase(EstadoIniciativa.RevisionGerenciaNegocio, EstadoIniciativa.RevisionComite)]
    [TestCase(EstadoIniciativa.AprobadaGerenciaNegocio, EstadoIniciativa.Aprobada)]
    [TestCase(EstadoIniciativa.AprobadaGerenciaNegocio, EstadoIniciativa.RevisionComite)]
    [TestCase(EstadoIniciativa.RevisionComite, EstadoIniciativa.Aprobada)]
    [TestCase(EstadoIniciativa.RevisionComite, EstadoIniciativa.RechazoComite)]
    public void IsAllowed_TransicionesPermitidas(int origen, int destino)
    {
        Assert.That(EstadoTransitionMatrix.IsAllowed(origen, destino), Is.True);
    }

    // === Cancelada permitida desde cualquier estado no-terminal ===

    [TestCase(EstadoIniciativa.Borrador)]
    [TestCase(EstadoIniciativa.RevisionInicialPmo)]
    [TestCase(EstadoIniciativa.EstimacionDesarrollo)]
    [TestCase(EstadoIniciativa.RevisionEstimacionJefatura)]
    [TestCase(EstadoIniciativa.EstimacionAprobadaJefatura)]
    [TestCase(EstadoIniciativa.EstimacionDevueltaJefatura)]
    [TestCase(EstadoIniciativa.EstimacionRechazadaJefatura)]
    [TestCase(EstadoIniciativa.RevisionIniciativaJefatura)]
    [TestCase(EstadoIniciativa.IniciativaDevueltaJefatura)]
    [TestCase(EstadoIniciativa.EnCotizacion)]
    [TestCase(EstadoIniciativa.RevisionGerenciaNegocio)]
    [TestCase(EstadoIniciativa.AprobadaGerenciaNegocio)]
    [TestCase(EstadoIniciativa.RechazadaGerenciaNegocio)]
    [TestCase(EstadoIniciativa.RevisionComite)]
    [TestCase(EstadoIniciativa.Aprobada)]
    [TestCase(EstadoIniciativa.RechazoComite)]
    public void IsAllowed_DesdeNoCancelada_ACancelada_OK(int origen)
    {
        Assert.That(EstadoTransitionMatrix.IsAllowed(origen, EstadoIniciativa.Cancelada), Is.True);
    }

    // === Bloqueos: Cancelada es terminal absoluto ===

    [TestCase(EstadoIniciativa.Borrador)]
    [TestCase(EstadoIniciativa.RevisionInicialPmo)]
    [TestCase(EstadoIniciativa.Aprobada)]
    [TestCase(EstadoIniciativa.RevisionComite)]
    public void IsAllowed_CanceladaHaciaCualquiera_Bloqueado(int destino)
    {
        Assert.That(EstadoTransitionMatrix.IsAllowed(EstadoIniciativa.Cancelada, destino), Is.False);
    }

    // === Estados terminales (Aprobada / Rechazos / Estimacion Rechazada): solo Cancelada ===

    [TestCase(EstadoIniciativa.Aprobada, EstadoIniciativa.Borrador)]
    [TestCase(EstadoIniciativa.Aprobada, EstadoIniciativa.RevisionInicialPmo)]
    [TestCase(EstadoIniciativa.RechazoComite, EstadoIniciativa.RevisionComite)]
    [TestCase(EstadoIniciativa.EstimacionRechazadaJefatura, EstadoIniciativa.EstimacionDesarrollo)]
    [TestCase(EstadoIniciativa.RechazadaGerenciaNegocio, EstadoIniciativa.RevisionGerenciaNegocio)]
    public void IsAllowed_EstadoTerminal_SoloCanceladaPermitida(int origen, int destino)
    {
        Assert.That(EstadoTransitionMatrix.IsAllowed(origen, destino), Is.False);
        Assert.That(EstadoTransitionMatrix.IsAllowed(origen, EstadoIniciativa.Cancelada), Is.True);
    }

    // === Bloqueos especificos del workflow (saltos no permitidos) ===

    [TestCase(EstadoIniciativa.Borrador, EstadoIniciativa.Aprobada)]
    [TestCase(EstadoIniciativa.Borrador, EstadoIniciativa.RevisionComite)]
    [TestCase(EstadoIniciativa.Borrador, EstadoIniciativa.RevisionGerenciaNegocio)]
    [TestCase(EstadoIniciativa.RevisionInicialPmo, EstadoIniciativa.Aprobada)]
    [TestCase(EstadoIniciativa.EstimacionDesarrollo, EstadoIniciativa.EnCotizacion)]
    [TestCase(EstadoIniciativa.EstimacionDesarrollo, EstadoIniciativa.Aprobada)]
    [TestCase(EstadoIniciativa.EnCotizacion, EstadoIniciativa.RevisionGerenciaNegocio)]
    [TestCase(EstadoIniciativa.RevisionIniciativaJefatura, EstadoIniciativa.Aprobada)]
    public void IsAllowed_SaltosNoPermitidos_Bloqueados(int origen, int destino)
    {
        Assert.That(EstadoTransitionMatrix.IsAllowed(origen, destino), Is.False);
    }

    // === Identidad: estado == estado siempre permitido (no es un cambio) ===

    [TestCase(EstadoIniciativa.Borrador)]
    [TestCase(EstadoIniciativa.Aprobada)]
    [TestCase(EstadoIniciativa.Cancelada)]
    public void IsAllowed_MismoEstado_OK(int estado)
    {
        Assert.That(EstadoTransitionMatrix.IsAllowed(estado, estado), Is.True);
    }

    [Test]
    public void GetAllowedFrom_Borrador_Contiene_RevisionPmoYCancelada()
    {
        var permitidos = EstadoTransitionMatrix.GetAllowedFrom(EstadoIniciativa.Borrador);
        Assert.That(permitidos, Does.Contain(EstadoIniciativa.RevisionInicialPmo));
        Assert.That(permitidos, Does.Contain(EstadoIniciativa.Cancelada));
        Assert.That(permitidos.Count, Is.EqualTo(2));
    }

    [Test]
    public void GetAllowedFrom_Cancelada_Vacio()
    {
        var permitidos = EstadoTransitionMatrix.GetAllowedFrom(EstadoIniciativa.Cancelada);
        Assert.That(permitidos, Is.Empty);
    }
}
