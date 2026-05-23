# ADR-0002: Adopción de Claude Code para desarrollo

- **Status**: Aceptado (pendiente validación en spike de Sprint 0)
- **Fecha**: 2026-05-23
- **Decisores**: Tech Lead, Arquitecto, PM

## Contexto

El proyecto debe completarse en 3 meses con un equipo reducido. Microsoft mantiene desde 2026 un repositorio público de plugins oficiales para Claude Code (`microsoft/power-platform-skills`) que cubre Power Pages, Model-Driven Apps, Code Apps y Canvas Apps. Existen además MCP servers maduros para SharePoint vía Microsoft Graph.

Estimaciones internas y casos comparables indican que la aceleración promedio sobre Power Platform es:

- Tareas code-first (DAX, M, schemas, plug-ins): 45-60%
- Tareas low-code visuales: 25-40%
- Tareas humanas (descubrimiento, UAT): 0-15%

Promedio ponderado sobre el WBS de INNOVA: **38%**, llevando el proyecto de 1.340 a aproximadamente 835 horas.

## Decisión

Adoptaremos Claude Code con los plugins oficiales de Microsoft desde Sprint 0:

- `canvas-apps@power-platform-skills`
- `model-apps@power-platform-skills`
- `code-apps@power-platform-skills`
- MCP server para SharePoint (a evaluar en Sprint 0)

Se mantendrá un archivo `CLAUDE.md` en la raíz del repo con el contexto del proyecto. Cada sub-proyecto (PCF, plug-ins) puede tener su propio `CLAUDE.md` con instrucciones adicionales si es necesario.

## Consecuencias

### Positivas
- Reducción estimada del esfuerzo total a 835 horas
- Generación rápida de boilerplate, scripts, modelos Dataverse, DAX, plantillas de correo
- Code review asistido
- Mejor calidad y consistencia de la documentación

### Negativas
- Dependencia de servicios externos (Anthropic + plugins de Microsoft)
- Costo de licencias de Claude Code
- Curva de adopción de 2-3 semanas inicial
- Riesgo de over-engineering sin disciplina de revisión

### Neutrales
- `CLAUDE.md` requiere mantenimiento continuo (esfuerzo bajo)
- Algunos flujos visuales seguirán siendo más rápidos en el maker portal que como código

## Validación

Spike de 3-5 días en Sprint 0:

1. Instalar todos los plugins
2. Construir la pantalla de Catálogos completa con Claude Code
3. Medir el tiempo real vs. el tiempo estimado sin Claude Code
4. Si la aceleración medida es ≥ 25%, ratificar la decisión
5. Si la aceleración medida es < 25%, replanificar al Escenario 2 sin Claude Code o reducir alcance

## Alternativas consideradas

### Alternativa 1: GitHub Copilot
**Por qué no**: Menor cobertura específica de Power Platform. Los plugins oficiales de Microsoft están optimizados para Claude Code.

### Alternativa 2: Sin asistente AI
**Por qué no**: Cierra la posibilidad del Escenario 1 (1 FT + 1 HT + 1 QT) que es la opción más económica del roadmap, y reduce el margen de cualquier escenario.
