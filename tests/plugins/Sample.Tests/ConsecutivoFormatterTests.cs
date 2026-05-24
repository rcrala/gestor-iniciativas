// Sample test que demuestra el patron NUnit para plugins INNOVA.
// Cuando llegue el primer plugin de produccion (e.g., consecutivo en S0-8),
// replicar esta estructura: clase de produccion en /plugins/X, test en /plugins/X.Tests.
//
// Aqui usamos una clase inline ConsecutivoFormatter como sample (sin acoplar a Dataverse SDK).

namespace Innova.Sample.Tests;

internal static class ConsecutivoFormatter
{
    /// <summary>
    /// Formatea un consecutivo de iniciativa INNOVA: {codigoCorto}-{anio}-{secuencia:000}
    /// Ejemplo: ("EMA", 2026, 1) -> "EMA-2026-001"
    /// Ver docs/architecture/numeracion-consecutivos.md (G7, issue #34).
    /// </summary>
    public static string Format(string codigoCorto, int anio, int secuencia)
    {
        if (string.IsNullOrWhiteSpace(codigoCorto))
            throw new ArgumentException("codigoCorto no puede ser vacio", nameof(codigoCorto));
        if (codigoCorto.Length != 3 || !System.Text.RegularExpressions.Regex.IsMatch(codigoCorto, "^[A-Z]{3}$"))
            throw new ArgumentException("codigoCorto debe ser 3 letras ASCII en mayusculas", nameof(codigoCorto));
        if (anio < 2024 || anio > 2100)
            throw new ArgumentOutOfRangeException(nameof(anio), "Anio fuera de rango razonable [2024, 2100]");
        if (secuencia < 1 || secuencia > 999)
            throw new ArgumentOutOfRangeException(nameof(secuencia), "Secuencia fuera de rango [1, 999]");

        return $"{codigoCorto}-{anio}-{secuencia:000}";
    }
}

[TestFixture]
public class ConsecutivoFormatterTests
{
    [Test]
    public void Format_HappyPath_PrimeraIniciativaEmpresaA_2026()
    {
        // Arrange + Act
        var resultado = ConsecutivoFormatter.Format("EMA", 2026, 1);

        // Assert
        Assert.That(resultado, Is.EqualTo("EMA-2026-001"));
    }

    [Test]
    public void Format_HappyPath_Secuencia999_Cero3Padding()
    {
        var resultado = ConsecutivoFormatter.Format("EMB", 2026, 999);
        Assert.That(resultado, Is.EqualTo("EMB-2026-999"));
    }

    [Test]
    public void Format_CodigoCortoNull_Lanza()
    {
        Assert.That(
            () => ConsecutivoFormatter.Format(null!, 2026, 1),
            Throws.ArgumentException);
    }

    [TestCase("")]
    [TestCase("  ")]
    public void Format_CodigoCortoEmpty_Lanza(string codigo)
    {
        Assert.That(
            () => ConsecutivoFormatter.Format(codigo, 2026, 1),
            Throws.ArgumentException);
    }

    [TestCase("AB")]      // 2 chars
    [TestCase("ABCD")]    // 4 chars
    [TestCase("abc")]     // lowercase
    [TestCase("AB1")]     // numero
    [TestCase("A-B")]     // simbolo
    public void Format_CodigoCortoInvalido_Lanza(string codigo)
    {
        Assert.That(
            () => ConsecutivoFormatter.Format(codigo, 2026, 1),
            Throws.ArgumentException);
    }

    [TestCase(2023)]
    [TestCase(2101)]
    public void Format_AnioFueraDeRango_Lanza(int anio)
    {
        Assert.That(
            () => ConsecutivoFormatter.Format("EMA", anio, 1),
            Throws.TypeOf<ArgumentOutOfRangeException>());
    }

    [TestCase(0)]
    [TestCase(1000)]
    [TestCase(-1)]
    public void Format_SecuenciaFueraDeRango_Lanza(int seq)
    {
        Assert.That(
            () => ConsecutivoFormatter.Format("EMA", 2026, seq),
            Throws.TypeOf<ArgumentOutOfRangeException>());
    }
}
