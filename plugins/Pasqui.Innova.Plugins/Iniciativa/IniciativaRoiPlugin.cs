using System;
using Microsoft.Xrm.Sdk;
using Pasqui.Innova.Plugins.Common;

namespace Pasqui.Innova.Plugins.Iniciativa
{
    /// <summary>
    /// Pre-operation Create/Update de pas_iniciativa: calcula automaticamente pas_roi_porcentaje
    /// basado en pas_monto_estimado y pas_ahorro_anual_estimado.
    ///
    /// Stage:   20 (PreOperation, transactional)
    /// Mensajes: Create + Update
    /// Entidad: pas_iniciativa
    /// Modo:    Synchronous
    /// Filter (Update): pas_monto_estimado,pas_ahorro_anual_estimado (solo dispara
    ///                  si alguno de los dos campos esta siendo modificado)
    /// PreImage (Update only): "PreImage" con attributes pas_monto_estimado,
    ///                         pas_ahorro_anual_estimado, pas_roi_porcentaje
    ///                         para resolver el otro campo cuando solo uno cambia.
    /// </summary>
    public class IniciativaRoiPlugin : PluginBase
    {
        public const string EntityName = "pas_iniciativa";
        public const string MontoField = "pas_monto_estimado";
        public const string AhorroField = "pas_ahorro_anual_estimado";
        public const string RoiField = "pas_roi_porcentaje";
        public const string PreImageName = "PreImage";

        protected override void ExecuteInternal(LocalPluginContext context)
        {
            var pec = context.PluginExecutionContext;
            var trace = context.TracingService;

            if (pec.MessageName != "Create" && pec.MessageName != "Update")
            {
                trace.Trace("Mensaje '{0}' no es Create/Update. Skip.", pec.MessageName);
                return;
            }

            if (!pec.InputParameters.Contains("Target") || !(pec.InputParameters["Target"] is Entity target))
            {
                trace.Trace("InputParameters['Target'] ausente o no Entity. Skip.");
                return;
            }

            if (target.LogicalName != EntityName)
            {
                trace.Trace("LogicalName '{0}' no es {1}. Skip.", target.LogicalName, EntityName);
                return;
            }

            // Pre-image solo existe en Update. Pasamos null en Create.
            Entity preImage = null;
            if (pec.MessageName == "Update" && pec.PreEntityImages.Contains(PreImageName))
            {
                preImage = pec.PreEntityImages[PreImageName];
            }

            CalculateAndApplyRoi(target, preImage, trace);
        }

        /// <summary>
        /// Logica pura, testeable. Lee monto y ahorro mergeando target con preImage,
        /// calcula ROI, y lo aplica al target solo si difiere del actual.
        /// </summary>
        public static void CalculateAndApplyRoi(Entity target, Entity preImage, ITracingService trace)
        {
            if (target == null) throw new ArgumentNullException("target");
            if (trace == null) throw new ArgumentNullException("trace");

            // Resolver valores efectivos: target gana, preImage como fallback
            var monto = GetMoneyValue(target, preImage, MontoField);
            var ahorro = GetMoneyValue(target, preImage, AhorroField);
            var roiNuevo = RoiCalculator.Calculate(monto, ahorro);

            // ROI actual: preImage para Update, sino lo que ya este en target (caso Create donde el usuario lo paso)
            var roiActual = GetDecimalValue(target, preImage, RoiField);

            if (roiNuevo == roiActual)
            {
                trace.Trace("ROI calculado ({0}) coincide con actual. Skip set.",
                    roiNuevo.HasValue ? roiNuevo.Value.ToString() : "null");
                return;
            }

            target[RoiField] = roiNuevo;
            trace.Trace("ROI actualizado: {0}% (monto={1}, ahorro={2})",
                roiNuevo.HasValue ? roiNuevo.Value.ToString() : "null",
                monto.HasValue ? monto.Value.ToString() : "null",
                ahorro.HasValue ? ahorro.Value.ToString() : "null");
        }

        private static decimal? GetMoneyValue(Entity target, Entity preImage, string field)
        {
            if (target.Contains(field))
            {
                var money = target.GetAttributeValue<Money>(field);
                return money != null ? money.Value : (decimal?)null;
            }
            if (preImage != null && preImage.Contains(field))
            {
                var money = preImage.GetAttributeValue<Money>(field);
                return money != null ? money.Value : (decimal?)null;
            }
            return null;
        }

        private static decimal? GetDecimalValue(Entity target, Entity preImage, string field)
        {
            if (target.Contains(field))
            {
                var v = target[field];
                if (v == null) return null;
                if (v is decimal d) return d;
                return Convert.ToDecimal(v);
            }
            if (preImage != null && preImage.Contains(field))
            {
                var v = preImage[field];
                if (v == null) return null;
                if (v is decimal d) return d;
                return Convert.ToDecimal(v);
            }
            return null;
        }
    }
}
