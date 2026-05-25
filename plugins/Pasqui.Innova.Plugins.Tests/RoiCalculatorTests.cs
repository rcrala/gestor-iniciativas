using Pasqui.Innova.Plugins.Common;

namespace Pasqui.Innova.Plugins.Tests;

[TestFixture]
public class RoiCalculatorTests
{
    // === Happy paths ===

    [Test]
    public void Calculate_AhorroMayorQueMonto_ROIPositivo()
    {
        Assert.That(RoiCalculator.Calculate(100m, 150m), Is.EqualTo(50m));
    }

    [Test]
    public void Calculate_AhorroIgualAlMonto_ROICero()
    {
        Assert.That(RoiCalculator.Calculate(100m, 100m), Is.EqualTo(0m));
    }

    [Test]
    public void Calculate_AhorroMenorQueMonto_ROINegativo()
    {
        Assert.That(RoiCalculator.Calculate(100m, 50m), Is.EqualTo(-50m));
    }

    [Test]
    public void Calculate_AhorroDobleDelMonto_ROI100()
    {
        Assert.That(RoiCalculator.Calculate(1000m, 2000m), Is.EqualTo(100m));
    }

    [Test]
    public void Calculate_Redondea2DecimalesAwayFromZero()
    {
        // (133.33 - 100) / 100 * 100 = 33.33
        Assert.That(RoiCalculator.Calculate(100m, 133.33m), Is.EqualTo(33.33m));
        // (123.456 - 100) / 100 * 100 = 23.456 -> 23.46 (AwayFromZero)
        Assert.That(RoiCalculator.Calculate(100m, 123.456m), Is.EqualTo(23.46m));
        // Negativo: -23.456 -> -23.46
        Assert.That(RoiCalculator.Calculate(100m, 76.544m), Is.EqualTo(-23.46m));
    }

    [Test]
    public void Calculate_ProyectoRealistaInnova_ROI50()
    {
        // Proyecto CRC 10,000,000, ahorro anual CRC 15,000,000 -> ROI 50%
        Assert.That(RoiCalculator.Calculate(10000000m, 15000000m), Is.EqualTo(50m));
    }

    [Test]
    public void Calculate_ProyectoCaroAhorroModesto_ROINegativo()
    {
        Assert.That(RoiCalculator.Calculate(50000m, 5000m), Is.EqualTo(-90m));
    }

    // === Edge / nulls ===

    [Test]
    public void Calculate_MontoNull_Null()
    {
        Assert.That(RoiCalculator.Calculate(null, 100m), Is.Null);
    }

    [Test]
    public void Calculate_MontoCero_Null()
    {
        Assert.That(RoiCalculator.Calculate(0m, 100m), Is.Null);
    }

    [Test]
    public void Calculate_AhorroNull_Null()
    {
        Assert.That(RoiCalculator.Calculate(100m, null), Is.Null);
    }

    [Test]
    public void Calculate_AmbosNull_Null()
    {
        Assert.That(RoiCalculator.Calculate(null, null), Is.Null);
    }

    [Test]
    public void Calculate_AhorroCero_ROIMinus100()
    {
        Assert.That(RoiCalculator.Calculate(100m, 0m), Is.EqualTo(-100m));
    }

    [Test]
    public void Calculate_PrecisionDecimal()
    {
        // 1 / 3 * 100 = 33.333... -> 33.33
        Assert.That(RoiCalculator.Calculate(3m, 4m), Is.EqualTo(33.33m));
    }
}
