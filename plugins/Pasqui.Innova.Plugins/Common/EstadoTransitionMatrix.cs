using System.Collections.Generic;

namespace Pasqui.Innova.Plugins.Common
{
    /// <summary>
    /// Matriz de transiciones permitidas para pas_iniciativa.pas_estado.
    /// Ver docs/architecture/estados-iniciativa.md para el diagrama completo.
    /// </summary>
    public static class EstadoTransitionMatrix
    {
        // Mapa: estado_origen -> set de estados destino permitidos.
        // Cancelada se agrega como destino permitido desde casi todos en BuildAllowed().
        private static readonly Dictionary<int, HashSet<int>> _allowed = BuildAllowed();

        private static Dictionary<int, HashSet<int>> BuildAllowed()
        {
            var m = new Dictionary<int, HashSet<int>>();

            void From(int origen, params int[] destinos)
            {
                if (!m.ContainsKey(origen)) m[origen] = new HashSet<int>();
                foreach (var d in destinos) m[origen].Add(d);
            }

            From(EstadoIniciativa.Borrador,
                 EstadoIniciativa.RevisionInicialPmo);

            From(EstadoIniciativa.RevisionInicialPmo,
                 EstadoIniciativa.EstimacionDesarrollo,
                 EstadoIniciativa.RevisionIniciativaJefatura);

            From(EstadoIniciativa.EstimacionDesarrollo,
                 EstadoIniciativa.RevisionEstimacionJefatura);

            From(EstadoIniciativa.RevisionEstimacionJefatura,
                 EstadoIniciativa.EstimacionAprobadaJefatura,
                 EstadoIniciativa.EstimacionDevueltaJefatura,
                 EstadoIniciativa.EstimacionRechazadaJefatura);

            From(EstadoIniciativa.EstimacionAprobadaJefatura,
                 EstadoIniciativa.RevisionIniciativaJefatura,
                 EstadoIniciativa.EnCotizacion);

            From(EstadoIniciativa.EstimacionDevueltaJefatura,
                 EstadoIniciativa.EstimacionDesarrollo);

            // EstimacionRechazadaJefatura: terminal, solo Cancelada

            From(EstadoIniciativa.RevisionIniciativaJefatura,
                 EstadoIniciativa.IniciativaDevueltaJefatura,
                 EstadoIniciativa.RevisionGerenciaNegocio);

            From(EstadoIniciativa.IniciativaDevueltaJefatura,
                 EstadoIniciativa.RevisionInicialPmo);

            From(EstadoIniciativa.EnCotizacion,
                 EstadoIniciativa.RevisionIniciativaJefatura);

            From(EstadoIniciativa.RevisionGerenciaNegocio,
                 EstadoIniciativa.AprobadaGerenciaNegocio,
                 EstadoIniciativa.RechazadaGerenciaNegocio,
                 EstadoIniciativa.RevisionComite);

            From(EstadoIniciativa.AprobadaGerenciaNegocio,
                 EstadoIniciativa.Aprobada,
                 EstadoIniciativa.RevisionComite);

            // RechazadaGerenciaNegocio: terminal, solo Cancelada

            From(EstadoIniciativa.RevisionComite,
                 EstadoIniciativa.Aprobada,
                 EstadoIniciativa.RechazoComite);

            // Aprobada: terminal, solo Cancelada
            // RechazoComite: terminal, solo Cancelada
            // Cancelada: terminal absoluto (sin Cancelada como destino)

            // Cancelada permitida desde TODO excepto desde si misma
            foreach (var origen in new[] {
                EstadoIniciativa.Borrador,
                EstadoIniciativa.RevisionInicialPmo,
                EstadoIniciativa.EstimacionDesarrollo,
                EstadoIniciativa.RevisionEstimacionJefatura,
                EstadoIniciativa.EstimacionAprobadaJefatura,
                EstadoIniciativa.EstimacionDevueltaJefatura,
                EstadoIniciativa.EstimacionRechazadaJefatura,
                EstadoIniciativa.RevisionIniciativaJefatura,
                EstadoIniciativa.IniciativaDevueltaJefatura,
                EstadoIniciativa.EnCotizacion,
                EstadoIniciativa.RevisionGerenciaNegocio,
                EstadoIniciativa.AprobadaGerenciaNegocio,
                EstadoIniciativa.RechazadaGerenciaNegocio,
                EstadoIniciativa.RevisionComite,
                EstadoIniciativa.Aprobada,
                EstadoIniciativa.RechazoComite
            })
            {
                From(origen, EstadoIniciativa.Cancelada);
            }

            return m;
        }

        /// <summary>
        /// True si la transicion origen -> destino esta permitida.
        /// origen == destino siempre es permitido (no es realmente un cambio).
        /// </summary>
        public static bool IsAllowed(int origen, int destino)
        {
            if (origen == destino) return true;
            return _allowed.TryGetValue(origen, out var set) && set.Contains(destino);
        }

        /// <summary>
        /// Lista de estados destino permitidos desde el origen indicado.
        /// </summary>
        public static IReadOnlyCollection<int> GetAllowedFrom(int origen)
        {
            if (_allowed.TryGetValue(origen, out var set)) return set;
            return new HashSet<int>();
        }
    }
}
