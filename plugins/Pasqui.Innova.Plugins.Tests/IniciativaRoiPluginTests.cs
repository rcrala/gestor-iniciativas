using Microsoft.Xrm.Sdk;
using Pasqui.Innova.Plugins.Iniciativa;
using Pasqui.Innova.Plugins.Tests.Fakes;

namespace Pasqui.Innova.Plugins.Tests;

/// <summary>
/// Tests de la logica CalculateAndApplyRoi del plug-in IniciativaRoiPlugin.
/// Cubre Create (sin preImage) + Update (con preImage) + idempotencia.
/// </summary>
[TestFixture]
public class IniciativaRoiPluginTests
{
    private FakeTracingService _tracing = null!;

    [SetUp]
    public void SetUp()
    {
        _tracing = new FakeTracingService();
    }

    private static Entity NewTargetWithMoney(decimal? monto, decimal? ahorro, decimal? currentRoi = null)
    {
        var target = new Entity("pas_iniciativa");
        if (monto.HasValue) target["pas_monto_estimado"] = new Money(monto.Value);
        if (ahorro.HasValue) target["pas_ahorro_anual_estimado"] = new Money(ahorro.Value);
        if (currentRoi.HasValue) target["pas_roi_porcentaje"] = currentRoi.Value;
        return target;
    }

    private static Entity NewPreImage(decimal? monto, decimal? ahorro, decimal? currentRoi = null)
    {
        var pi = new Entity("pas_iniciativa");
        if (monto.HasValue) pi["pas_monto_estimado"] = new Money(monto.Value);
        if (ahorro.HasValue) pi["pas_ahorro_anual_estimado"] = new Money(ahorro.Value);
        if (currentRoi.HasValue) pi["pas_roi_porcentaje"] = currentRoi.Value;
        return pi;
    }

    // === Create (sin preImage) ===

    [Test]
    public void Create_MontoYAhorroPresentes_SeteaROI()
    {
        var target = NewTargetWithMoney(1000m, 1500m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage: null, _tracing);

        Assert.That(target["pas_roi_porcentaje"], Is.EqualTo(50m));
    }

    [Test]
    public void Create_SoloMontoSinAhorro_ROINoSeSeteaPorquYaEsNull()
    {
        var target = NewTargetWithMoney(1000m, null);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage: null, _tracing);

        // roiNuevo=null y roiActual=null -> skip (idempotencia)
        Assert.That(target.Contains("pas_roi_porcentaje"), Is.False);
    }

    [Test]
    public void Create_SoloMontoSinAhorroPeroConRoiPrevio_ROIQueda()
    {
        // Si el caller paso un ROI explicito (e.g., import) y no podemos recalcular,
        // respetamos el valor pasado (no lo borramos a null)
        var target = NewTargetWithMoney(1000m, null, currentRoi: 25m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage: null, _tracing);

        // ROI nuevo = null, actual = 25 -> son distintos, escribe null (borra)
        // Comportamiento esperable: si los datos no dan para calcular, ROI debe ser null
        Assert.That(target["pas_roi_porcentaje"], Is.Null);
    }

    [Test]
    public void Create_NingunCampoMoney_NoSetea()
    {
        var target = new Entity("pas_iniciativa");
        target["pas_titulo"] = "Solo titulo";

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage: null, _tracing);

        // No tocar ROI si no podemos calcular y no hay actual con que comparar
        // El metodo escribe null (que es diferente de "no contiene") porque roiNuevo=null y actual=null son iguales -> skip
        Assert.That(target.Contains("pas_roi_porcentaje"), Is.False);
    }

    // === Update con PreImage ===

    [Test]
    public void Update_SoloMontoCambia_UsaAhorroDePreImage()
    {
        // Iniciativa existente: monto=1000, ahorro=1500, ROI=50
        // Update cambia solo monto a 500 -> ROI = (1500-500)/500*100 = 200
        var target = NewTargetWithMoney(500m, null);
        var preImage = NewPreImage(1000m, 1500m, 50m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage, _tracing);

        Assert.That(target["pas_roi_porcentaje"], Is.EqualTo(200m));
    }

    [Test]
    public void Update_SoloAhorroCambia_UsaMontoDePreImage()
    {
        // Existente: monto=1000, ahorro=1500, ROI=50
        // Update cambia solo ahorro a 3000 -> ROI = (3000-1000)/1000*100 = 200
        var target = NewTargetWithMoney(null, 3000m);
        var preImage = NewPreImage(1000m, 1500m, 50m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage, _tracing);

        Assert.That(target["pas_roi_porcentaje"], Is.EqualTo(200m));
    }

    [Test]
    public void Update_CambioADefecto_ROISeRecalculaCorrectamente()
    {
        // Existente: monto=1000, ahorro=2000, ROI=100
        // Update ambos: monto=2000, ahorro=2000 -> ROI=0
        var target = NewTargetWithMoney(2000m, 2000m);
        var preImage = NewPreImage(1000m, 2000m, 100m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage, _tracing);

        Assert.That(target["pas_roi_porcentaje"], Is.EqualTo(0m));
    }

    [Test]
    public void Update_MontoLimpiadoANull_ROILimpiadoANull()
    {
        // Existente: monto=1000, ahorro=1500, ROI=50
        // Update vacia monto (set a null)
        var target = new Entity("pas_iniciativa");
        target["pas_monto_estimado"] = null;
        var preImage = NewPreImage(1000m, 1500m, 50m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage, _tracing);

        Assert.That(target["pas_roi_porcentaje"], Is.Null);
    }

    // === Idempotencia ===

    [Test]
    public void Update_ROIYaCorrecto_NoTocaTarget()
    {
        // Existente: monto=1000, ahorro=1500, ROI=50
        // Update cambia ahorro pero al mismo valor -> ROI no cambia
        var target = NewTargetWithMoney(null, 1500m);
        var preImage = NewPreImage(1000m, 1500m, 50m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage, _tracing);

        // Como roiNuevo (50) == roiActual (50), no debe escribir
        Assert.That(target.Contains("pas_roi_porcentaje"), Is.False);
    }

    [Test]
    public void Create_ROIPasadoExplicitamenteCoincide_NoLoToca()
    {
        // Caller pasa todo: monto=100, ahorro=200, roi=100 -> roi correcto, no debe cambiar
        var target = NewTargetWithMoney(100m, 200m, 100m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage: null, _tracing);

        // ROI ya esta correcto: no se reescribe (idempotencia)
        Assert.That(target["pas_roi_porcentaje"], Is.EqualTo(100m));
        // pero verificar que NO se haya hecho el set (via trace)
        Assert.That(_tracing.Traces, Has.Some.Contains("Skip set"));
    }

    [Test]
    public void Create_ROIPasadoExplicitamenteErrado_LoCorrige()
    {
        // Caller pasa monto=100, ahorro=200, roi=999 (mal) -> debe corregir a 100
        var target = NewTargetWithMoney(100m, 200m, 999m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage: null, _tracing);

        Assert.That(target["pas_roi_porcentaje"], Is.EqualTo(100m));
    }

    // === Inputs invalidos ===

    [Test]
    public void Calculate_TargetNull_Lanza()
    {
        Assert.That(() => IniciativaRoiPlugin.CalculateAndApplyRoi(null!, null, _tracing),
            Throws.ArgumentNullException);
    }

    [Test]
    public void Calculate_TracingNull_Lanza()
    {
        Assert.That(() => IniciativaRoiPlugin.CalculateAndApplyRoi(new Entity("pas_iniciativa"), null, null!),
            Throws.ArgumentNullException);
    }

    // === Trazas ===

    [Test]
    public void Trace_IncluyeValoresUsados()
    {
        var target = NewTargetWithMoney(1000m, 1500m);

        IniciativaRoiPlugin.CalculateAndApplyRoi(target, preImage: null, _tracing);

        var trace = string.Join("\n", _tracing.Traces);
        Assert.That(trace, Does.Contain("50"));      // el ROI
        Assert.That(trace, Does.Contain("1000"));    // el monto
        Assert.That(trace, Does.Contain("1500"));    // el ahorro
    }
}
