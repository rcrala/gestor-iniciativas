using System;

namespace Pasqui.Innova.Plugins.Common
{
    /// <summary>
    /// Calculo de ROI (Return on Investment) en porcentaje para una iniciativa INNOVA.
    /// Formula (del glosario): ROI% = (AhorroAnual - Monto) / Monto * 100
    /// Redondeo: 2 decimales (hacia el par mas cercano - banker's rounding default de Math.Round).
    /// </summary>
    public static class RoiCalculator
    {
        /// <summary>
        /// Calcula ROI en porcentaje.
        /// </summary>
        /// <param name="monto">Monto estimado del proyecto. Si es 0, NULL, o NaN, retorna null.</param>
        /// <param name="ahorroAnual">Ahorro anual estimado. Si es NULL, retorna null.</param>
        /// <returns>ROI con 2 decimales, o null si no calculable.</returns>
        public static decimal? Calculate(decimal? monto, decimal? ahorroAnual)
        {
            if (!monto.HasValue || monto.Value == 0m) return null;
            if (!ahorroAnual.HasValue) return null;

            var roi = (ahorroAnual.Value - monto.Value) / monto.Value * 100m;
            return Math.Round(roi, 2, MidpointRounding.AwayFromZero);
        }
    }
}
