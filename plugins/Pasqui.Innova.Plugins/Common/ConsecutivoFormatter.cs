using System;
using System.Text.RegularExpressions;

namespace Pasqui.Innova.Plugins.Common
{
    /// <summary>
    /// Formatea consecutivos de iniciativas INNOVA con el patron {codigoCorto}-{anio}-{secuencia:000}.
    /// Ejemplo: ("COA", 2026, 1) -> "COA-2026-001"
    /// Ver docs/architecture/numeracion-consecutivos.md (G7, issue #34).
    /// </summary>
    public static class ConsecutivoFormatter
    {
        private static readonly Regex CodigoCortoPattern = new Regex("^[A-Z]{3}$", RegexOptions.Compiled);

        public const int AnioMinimo = 2024;
        public const int AnioMaximo = 2100;
        public const int SecuenciaMinima = 1;
        public const int SecuenciaMaxima = 999;

        public static string Format(string codigoCorto, int anio, int secuencia)
        {
            if (string.IsNullOrWhiteSpace(codigoCorto))
                throw new ArgumentException("codigoCorto no puede ser vacio", "codigoCorto");

            if (!CodigoCortoPattern.IsMatch(codigoCorto))
                throw new ArgumentException(
                    "codigoCorto debe ser exactamente 3 letras ASCII en mayusculas (regex ^[A-Z]{3}$)",
                    "codigoCorto");

            if (anio < AnioMinimo || anio > AnioMaximo)
                throw new ArgumentOutOfRangeException(
                    "anio",
                    string.Format("Anio {0} fuera de rango [{1}, {2}]", anio, AnioMinimo, AnioMaximo));

            if (secuencia < SecuenciaMinima || secuencia > SecuenciaMaxima)
                throw new ArgumentOutOfRangeException(
                    "secuencia",
                    string.Format("Secuencia {0} fuera de rango [{1}, {2}]", secuencia, SecuenciaMinima, SecuenciaMaxima));

            return string.Format("{0}-{1:0000}-{2:000}", codigoCorto, anio, secuencia);
        }
    }
}
