using Pasqui.Innova.Plugins.Common;

namespace Pasqui.Innova.Plugins.Tests;

/// <summary>
/// Unit tests del formatter puro (sin Dataverse). Cubre los 6 casos del runbook
/// (numeracion-consecutivos.md seccion "Pruebas minimas") y validaciones de input.
/// </summary>
[TestFixture]
public class ConsecutivoFormatterTests
{
    // === Happy paths del runbook ===

    [Test]
    public void Format_PrimeraIniciativaEmpresaA_2026()
    {
        Assert.That(ConsecutivoFormatter.Format("COA", 2026, 1), Is.EqualTo("COA-2026-001"));
    }

    [Test]
    public void Format_SegundaIniciativaEmpresaA_2026()
    {
        Assert.That(ConsecutivoFormatter.Format("COA", 2026, 2), Is.EqualTo("COA-2026-002"));
    }

    [Test]
    public void Format_PrimeraIniciativaEmpresaB_2026_NoInterfiereConA()
    {
        Assert.That(ConsecutivoFormatter.Format("PSI", 2026, 1), Is.EqualTo("PSI-2026-001"));
    }

    [Test]
    public void Format_PrimeraIniciativaEmpresaA_2027_ReinicioPorAnio()
    {
        Assert.That(ConsecutivoFormatter.Format("COA", 2027, 1), Is.EqualTo("COA-2027-001"));
    }

    [Test]
    public void Format_Secuencia999_PaddingCorrecto()
    {
        Assert.That(ConsecutivoFormatter.Format("COA", 2026, 999), Is.EqualTo("COA-2026-999"));
    }

    [Test]
    public void Format_Secuencia42_Padding3Digitos()
    {
        Assert.That(ConsecutivoFormatter.Format("COA", 2026, 42), Is.EqualTo("COA-2026-042"));
    }

    // === Validaciones de codigoCorto ===

    [Test]
    public void Format_CodigoCortoNull_Lanza()
    {
        Assert.That(() => ConsecutivoFormatter.Format(null!, 2026, 1), Throws.ArgumentException);
    }

    [TestCase("")]
    [TestCase("  ")]
    public void Format_CodigoCortoVacio_Lanza(string codigo)
    {
        Assert.That(() => ConsecutivoFormatter.Format(codigo, 2026, 1), Throws.ArgumentException);
    }

    [TestCase("AB")]      // 2 chars
    [TestCase("ABCD")]    // 4 chars
    [TestCase("abc")]     // lowercase
    [TestCase("Abc")]     // mixed case
    [TestCase("AB1")]     // numero
    [TestCase("A-B")]     // simbolo
    [TestCase("A B")]     // espacio
    [TestCase("AÑO")]     // unicode non-ASCII
    public void Format_CodigoCortoInvalido_Lanza(string codigo)
    {
        Assert.That(() => ConsecutivoFormatter.Format(codigo, 2026, 1), Throws.ArgumentException);
    }

    // === Validaciones de anio ===

    [TestCase(2023)]
    [TestCase(2101)]
    [TestCase(0)]
    [TestCase(-1)]
    public void Format_AnioFueraDeRango_Lanza(int anio)
    {
        Assert.That(() => ConsecutivoFormatter.Format("COA", anio, 1),
            Throws.TypeOf<ArgumentOutOfRangeException>());
    }

    [TestCase(2024)]   // limite inferior
    [TestCase(2100)]   // limite superior
    [TestCase(2050)]   // medio
    public void Format_AnioEnRango_NoLanza(int anio)
    {
        Assert.DoesNotThrow(() => ConsecutivoFormatter.Format("COA", anio, 1));
    }

    // === Validaciones de secuencia ===

    [TestCase(0)]
    [TestCase(1000)]
    [TestCase(-1)]
    public void Format_SecuenciaFueraDeRango_Lanza(int seq)
    {
        Assert.That(() => ConsecutivoFormatter.Format("COA", 2026, seq),
            Throws.TypeOf<ArgumentOutOfRangeException>());
    }

    [TestCase(1)]      // limite inferior
    [TestCase(999)]    // limite superior
    [TestCase(500)]
    public void Format_SecuenciaEnRango_NoLanza(int seq)
    {
        Assert.DoesNotThrow(() => ConsecutivoFormatter.Format("COA", 2026, seq));
    }
}
