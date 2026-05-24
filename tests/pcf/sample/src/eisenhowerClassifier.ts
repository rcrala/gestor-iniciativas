// Sample TypeScript module que demuestra la cadena de build para tests PCF.
// Cuando llegue el primer PCF real (M-PRIO Phase 2), replicar este patron:
//   pcf/<NombreControl>/<source>.ts        - codigo de produccion
//   pcf/<NombreControl>/__tests__/*.test.ts - tests Jest

export type EisenhowerQuadrant = "DO_NOW" | "PLAN" | "DELEGATE" | "ELIMINATE";

/**
 * Clasifica una iniciativa en uno de los 4 cuadrantes Eisenhower.
 * Referencia: docs/01-Requeriments/20260524-Funcionalidad-Prioridades/analisis-priorizacion-vs-modelo.md (D4)
 *
 * @param urgency 1-5
 * @param importance 1-5
 * @throws si urgency o importance fuera de rango [1, 5]
 */
export function classifyEisenhower(
  urgency: number,
  importance: number
): EisenhowerQuadrant {
  if (!Number.isInteger(urgency) || urgency < 1 || urgency > 5) {
    throw new Error(`urgency debe ser entero en [1, 5], recibido: ${urgency}`);
  }
  if (!Number.isInteger(importance) || importance < 1 || importance > 5) {
    throw new Error(
      `importance debe ser entero en [1, 5], recibido: ${importance}`
    );
  }

  if (urgency >= 4 && importance >= 4) return "DO_NOW";
  if (urgency < 4 && importance >= 4) return "PLAN";
  if (urgency >= 4 && importance < 4) return "DELEGATE";
  return "ELIMINATE";
}
