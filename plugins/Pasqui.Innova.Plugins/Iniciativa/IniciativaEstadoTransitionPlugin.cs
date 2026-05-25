using System;
using System.Linq;
using Microsoft.Xrm.Sdk;
using Pasqui.Innova.Plugins.Common;

namespace Pasqui.Innova.Plugins.Iniciativa
{
    /// <summary>
    /// Valida transiciones de pas_iniciativa.pas_estado en Create + Update.
    /// Lanza InvalidPluginExecutionException con mensaje claro cuando la transicion
    /// no esta permitida en la matriz definida en EstadoTransitionMatrix.
    ///
    /// Steps:
    ///   - Create stage 20 sync (filter: ninguno; el plug-in chequea estado inicial)
    ///   - Update stage 20 sync, FilteringAttributes=pas_estado, PreImage con pas_estado
    /// </summary>
    public class IniciativaEstadoTransitionPlugin : PluginBase
    {
        public const string EntityName = "pas_iniciativa";
        public const string EstadoField = "pas_estado";
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

            if (pec.MessageName == "Create")
            {
                ValidateCreate(target, trace);
                return;
            }

            // Update: requiere PreImage para comparar
            Entity preImage = null;
            if (pec.PreEntityImages.Contains(PreImageName))
            {
                preImage = pec.PreEntityImages[PreImageName];
            }

            ValidateUpdate(target, preImage, trace);
        }

        public static void ValidateCreate(Entity target, ITracingService trace)
        {
            if (target == null) throw new ArgumentNullException("target");
            if (trace == null) throw new ArgumentNullException("trace");

            if (!target.Contains(EstadoField)) return;  // sin estado explicito = default Borrador

            var estadoOpt = target.GetAttributeValue<OptionSetValue>(EstadoField);
            if (estadoOpt == null) return;

            if (estadoOpt.Value != EstadoIniciativa.Borrador)
            {
                throw new InvalidPluginExecutionException(string.Format(
                    "Estado inicial invalido: '{0}'. Las iniciativas solo pueden crearse en estado 'Borrador'. " +
                    "Si necesitas migrar data en otro estado, hacelo via import con bypass del plug-in.",
                    EstadoIniciativa.GetLabel(estadoOpt.Value)));
            }

            trace.Trace("Create: estado inicial '{0}' OK", EstadoIniciativa.GetLabel(estadoOpt.Value));
        }

        public static void ValidateUpdate(Entity target, Entity preImage, ITracingService trace)
        {
            if (target == null) throw new ArgumentNullException("target");
            if (trace == null) throw new ArgumentNullException("trace");

            if (!target.Contains(EstadoField)) return;  // estado no esta cambiando

            var estadoNuevoOpt = target.GetAttributeValue<OptionSetValue>(EstadoField);
            if (estadoNuevoOpt == null)
            {
                throw new InvalidPluginExecutionException("pas_estado no puede ponerse en null. Use 'Cancelada' para descartar la iniciativa.");
            }

            if (preImage == null || !preImage.Contains(EstadoField))
            {
                throw new InvalidPluginExecutionException(
                    "PreImage 'PreImage' con pas_estado no esta disponible. Verificar registro del step.");
            }

            var estadoActualOpt = preImage.GetAttributeValue<OptionSetValue>(EstadoField);
            if (estadoActualOpt == null) return;  // estado actual NULL, cualquier valor es valido

            var origen = estadoActualOpt.Value;
            var destino = estadoNuevoOpt.Value;

            if (EstadoTransitionMatrix.IsAllowed(origen, destino))
            {
                trace.Trace("Update: transicion '{0}' -> '{1}' OK",
                    EstadoIniciativa.GetLabel(origen),
                    EstadoIniciativa.GetLabel(destino));
                return;
            }

            var permitidos = EstadoTransitionMatrix.GetAllowedFrom(origen);
            var listado = permitidos.Count > 0
                ? string.Join(", ", permitidos.Select(EstadoIniciativa.GetLabel))
                : "(ninguno - estado terminal)";

            throw new InvalidPluginExecutionException(string.Format(
                "Transicion no permitida: '{0}' -> '{1}'. Desde '{0}' los estados permitidos son: {2}.",
                EstadoIniciativa.GetLabel(origen),
                EstadoIniciativa.GetLabel(destino),
                listado));
        }
    }
}
