using System;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;
using Pasqui.Innova.Plugins.Common;

namespace Pasqui.Innova.Plugins.Iniciativa
{
    /// <summary>
    /// Pre-operation Create de pas_iniciativa: asigna automaticamente pas_consecutivo,
    /// pas_consecutivo_secuencia y pas_anio basado en la empresa y el ano UTC actual.
    ///
    /// Stage:   20 (PreOperation, transactional)
    /// Mensaje: Create
    /// Entidad: pas_iniciativa
    /// Modo:    Synchronous
    /// Filter:  pas_empresa (solo dispara cuando la empresa esta presente)
    ///
    /// Race condition: ventana minima entre el Max() query y el Insert (mismo transaction).
    /// Para throughput &lt; 1/seg es aceptable. Para mas alto, agregar unique constraint en
    /// (pas_empresa, pas_anio, pas_consecutivo_secuencia) a nivel de entidad y agregar retry loop.
    /// </summary>
    public class IniciativaPreCreatePlugin : PluginBase
    {
        public const string EntityName = "pas_iniciativa";
        public const string EmpresaName = "pas_empresa";
        public const string EmpresaCodigoField = "pas_codigo_corto";
        public const string ConsecutivoField = "pas_consecutivo";
        public const string SecuenciaField = "pas_consecutivo_secuencia";
        public const string AnioField = "pas_anio";

        protected override void ExecuteInternal(LocalPluginContext context)
        {
            var pec = context.PluginExecutionContext;
            var trace = context.TracingService;

            // Plumbing / filter: solo Create sobre pas_iniciativa con Target Entity valido
            if (pec.MessageName != "Create")
            {
                trace.Trace("Mensaje '{0}' no es Create. Skip.", pec.MessageName);
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

            // Logica de negocio - extraida para que sea testeable sin mockear IPluginExecutionContext
            AssignConsecutivo(target, context.OrgService, trace, DateTime.UtcNow);
        }

        /// <summary>
        /// Logica de asignacion del consecutivo. Publica + testeable sin Dataverse SDK plumbing.
        /// Mutta el target (Pre-Create lo persiste en el mismo transaction).
        /// </summary>
        public static void AssignConsecutivo(Entity target, IOrganizationService svc, ITracingService trace, DateTime nowUtc)
        {
            if (target == null) throw new ArgumentNullException("target");
            if (svc == null) throw new ArgumentNullException("svc");
            if (trace == null) throw new ArgumentNullException("trace");

            // Idempotencia: si ya viene con consecutivo (e.g., import), respetarlo
            if (target.Contains(ConsecutivoField) && !string.IsNullOrWhiteSpace(target.GetAttributeValue<string>(ConsecutivoField)))
            {
                trace.Trace("Target ya trae {0}='{1}'. Skip asignacion automatica.",
                    ConsecutivoField, target.GetAttributeValue<string>(ConsecutivoField));
                return;
            }

            if (!target.Contains(EmpresaName))
            {
                throw new InvalidPluginExecutionException(
                    "pas_iniciativa requiere pas_empresa al crear (para generar el consecutivo)");
            }

            var empresaRef = target.GetAttributeValue<EntityReference>(EmpresaName);
            if (empresaRef == null || empresaRef.Id == Guid.Empty)
            {
                throw new InvalidPluginExecutionException("pas_empresa esta vacia o invalida");
            }

            var codigoCorto = GetEmpresaCodigoCorto(svc, empresaRef);
            var anio = nowUtc.Year;
            var siguienteSecuencia = CalcularSiguienteSecuencia(svc, empresaRef.Id, anio);

            if (siguienteSecuencia > ConsecutivoFormatter.SecuenciaMaxima)
            {
                throw new InvalidPluginExecutionException(string.Format(
                    "Empresa {0} alcanzo el limite de {1} iniciativas en {2}. Contactar Administrador.",
                    empresaRef.Name, ConsecutivoFormatter.SecuenciaMaxima, anio));
            }

            var consecutivo = ConsecutivoFormatter.Format(codigoCorto, anio, siguienteSecuencia);

            target[ConsecutivoField] = consecutivo;
            target[SecuenciaField] = siguienteSecuencia;
            target[AnioField] = anio;

            trace.Trace("Consecutivo asignado: {0} (empresa={1}, anio={2}, seq={3})",
                consecutivo, empresaRef.Id, anio, siguienteSecuencia);
        }

        private static readonly System.Text.RegularExpressions.Regex CodigoCortoPattern =
            new System.Text.RegularExpressions.Regex("^[A-Z]{3}$", System.Text.RegularExpressions.RegexOptions.Compiled);

        private static string GetEmpresaCodigoCorto(IOrganizationService svc, EntityReference empresaRef)
        {
            var empresa = svc.Retrieve(empresaRef.LogicalName, empresaRef.Id,
                new ColumnSet(EmpresaCodigoField));
            var codigo = empresa.GetAttributeValue<string>(EmpresaCodigoField);

            if (string.IsNullOrWhiteSpace(codigo))
            {
                throw new InvalidPluginExecutionException(string.Format(
                    "Empresa {0} (id {1}) no tiene {2} configurado. " +
                    "Configurarlo via M11 Admin antes de crear iniciativas.",
                    empresaRef.Name, empresaRef.Id, EmpresaCodigoField));
            }

            if (!CodigoCortoPattern.IsMatch(codigo))
            {
                throw new InvalidPluginExecutionException(string.Format(
                    "Empresa {0} tiene {1}='{2}' invalido. Debe ser exactamente 3 letras ASCII mayusculas (regex ^[A-Z]{{3}}$). " +
                    "Corregir via M11 Admin.",
                    empresaRef.Name, EmpresaCodigoField, codigo));
            }

            return codigo;
        }

        private static int CalcularSiguienteSecuencia(IOrganizationService svc, Guid empresaId, int anio)
        {
            // Query: SELECT TOP 1 pas_consecutivo_secuencia FROM pas_iniciativa
            //        WHERE pas_empresa = empresaId AND pas_anio = anio
            //          AND pas_consecutivo_secuencia IS NOT NULL
            //        ORDER BY pas_consecutivo_secuencia DESC
            var query = new QueryExpression(EntityName)
            {
                ColumnSet = new ColumnSet(SecuenciaField),
                TopCount = 1,
                NoLock = false
            };
            query.Criteria.AddCondition(EmpresaName, ConditionOperator.Equal, empresaId);
            query.Criteria.AddCondition(AnioField, ConditionOperator.Equal, anio);
            query.Criteria.AddCondition(SecuenciaField, ConditionOperator.NotNull);
            query.AddOrder(SecuenciaField, OrderType.Descending);

            var result = svc.RetrieveMultiple(query);
            if (result.Entities.Count == 0) return 1;
            return result.Entities[0].GetAttributeValue<int>(SecuenciaField) + 1;
        }
    }
}
