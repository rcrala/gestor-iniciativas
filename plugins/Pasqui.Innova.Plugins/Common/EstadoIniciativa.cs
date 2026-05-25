namespace Pasqui.Innova.Plugins.Common
{
    /// <summary>
    /// Codigos de la option set pas_iniciativa_estado. Mantener sincronizado con DEV.
    /// Ver docs/architecture/estados-iniciativa.md para el detalle del flujo.
    /// </summary>
    public static class EstadoIniciativa
    {
        public const int Borrador = 100000000;
        public const int RevisionInicialPmo = 100000001;
        public const int EstimacionDesarrollo = 100000002;
        public const int RevisionEstimacionJefatura = 100000003;
        public const int EstimacionAprobadaJefatura = 100000004;
        public const int EstimacionDevueltaJefatura = 100000005;
        public const int EstimacionRechazadaJefatura = 100000006;
        public const int RevisionIniciativaJefatura = 100000007;
        public const int IniciativaDevueltaJefatura = 100000008;
        public const int EnCotizacion = 100000009;
        public const int RevisionGerenciaNegocio = 100000010;
        public const int AprobadaGerenciaNegocio = 100000011;
        public const int RechazadaGerenciaNegocio = 100000012;
        public const int RevisionComite = 100000013;
        public const int Aprobada = 100000014;
        public const int RechazoComite = 100000015;
        public const int Cancelada = 100000016;

        public static string GetLabel(int value)
        {
            switch (value)
            {
                case Borrador: return "Borrador";
                case RevisionInicialPmo: return "Revision inicial PMO";
                case EstimacionDesarrollo: return "Estimacion Desarrollo";
                case RevisionEstimacionJefatura: return "Revision Estimacion de la Jefatura";
                case EstimacionAprobadaJefatura: return "Estimacion Aprobada por Jefatura";
                case EstimacionDevueltaJefatura: return "Estimacion Devuelta por Jefatura";
                case EstimacionRechazadaJefatura: return "Estimacion Rechazada por Jefatura";
                case RevisionIniciativaJefatura: return "Revision Iniciativa Jefatura";
                case IniciativaDevueltaJefatura: return "Iniciativa Devuelta por Jefatura";
                case EnCotizacion: return "En Cotizacion";
                case RevisionGerenciaNegocio: return "Revision Gerencia de Negocio";
                case AprobadaGerenciaNegocio: return "Aprobada por Gerencia General de Negocio";
                case RechazadaGerenciaNegocio: return "Rechazada por Gerencia General de Negocio";
                case RevisionComite: return "Revision Comite de Proyectos";
                case Aprobada: return "Aprobada";
                case RechazoComite: return "Rechazo del Comite";
                case Cancelada: return "Cancelada";
                default: return "Estado desconocido (" + value + ")";
            }
        }
    }
}
