# Maquina de estados de pas_iniciativa — INNOVA

> **Estado**: Implementada como Plug-in C# (`IniciativaEstadoTransitionPlugin`). Stage 20 PreOperation Update con FilteringAttributes=`pas_estado` + PreImage.
>
> **Implementacion**: [`plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs`](../../plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs) + [`Common/EstadoTransitionMatrix.cs`](../../plugins/Pasqui.Innova.Plugins/Common/EstadoTransitionMatrix.cs)

## Codigos de estado (option set `pas_iniciativa_estado`)

| Value | Label |
|-------|-------|
| 100000000 | Borrador |
| 100000001 | Revision inicial PMO |
| 100000002 | Estimacion Desarrollo |
| 100000003 | Revision Estimacion de la Jefatura |
| 100000004 | Estimacion Aprobada por Jefatura |
| 100000005 | Estimacion Devuelta por Jefatura |
| 100000006 | Estimacion Rechazada por Jefatura |
| 100000007 | Revision Iniciativa Jefatura |
| 100000008 | Iniciativa Devuelta por Jefatura |
| 100000009 | En Cotizacion |
| 100000010 | Revision Gerencia de Negocio |
| 100000011 | Aprobada por Gerencia General de Negocio |
| 100000012 | Rechazada por Gerencia General de Negocio |
| 100000013 | Revision Comite de Proyectos |
| 100000014 | Aprobada |
| 100000015 | Rechazo del Comite |
| 100000016 | Cancelada |

## Matriz de transiciones

Cada celda indica si la transicion `Origen -> Destino` es **permitida**. Vacio = bloqueada. El plug-in lanza `InvalidPluginExecutionException` cuando se intenta una transicion bloqueada.

| Desde \ Hacia                            | Borrador | RevPMO | EstDes | RevEstJef | EstAprJef | EstDevJef | EstRechJef | RevIniJef | IniDevJef | EnCot | RevGer | AprGer | RechGer | RevCom | Aprobada | RechCom | Cancelada |
|------------------------------------------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Borrador                                 |    | OK |    |    |    |    |    |    |    |    |    |    |    |    |    |    | OK |
| Revision inicial PMO                     |    |    | OK |    |    |    |    | OK |    |    |    |    |    |    |    |    | OK |
| Estimacion Desarrollo                    |    |    |    | OK |    |    |    |    |    |    |    |    |    |    |    |    | OK |
| Revision Estimacion de la Jefatura       |    |    |    |    | OK | OK | OK |    |    |    |    |    |    |    |    |    | OK |
| Estimacion Aprobada por Jefatura         |    |    |    |    |    |    |    | OK |    | OK |    |    |    |    |    |    | OK |
| Estimacion Devuelta por Jefatura         |    |    | OK |    |    |    |    |    |    |    |    |    |    |    |    |    | OK |
| Estimacion Rechazada por Jefatura        |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    | OK |
| Revision Iniciativa Jefatura             |    |    |    |    |    |    |    |    | OK |    | OK |    |    |    |    |    | OK |
| Iniciativa Devuelta por Jefatura         |    | OK |    |    |    |    |    |    |    |    |    |    |    |    |    |    | OK |
| En Cotizacion                            |    |    |    |    |    |    |    | OK |    |    |    |    |    |    |    |    | OK |
| Revision Gerencia de Negocio             |    |    |    |    |    |    |    |    |    |    |    | OK | OK | OK |    |    | OK |
| Aprobada por Gerencia General de Negocio |    |    |    |    |    |    |    |    |    |    |    |    |    | OK | OK |    | OK |
| Rechazada por Gerencia General de Negocio|    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    | OK |
| Revision Comite de Proyectos             |    |    |    |    |    |    |    |    |    |    |    |    |    |    | OK | OK | OK |
| Aprobada                                 |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    | OK |
| Rechazo del Comite                       |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    | OK |
| Cancelada                                |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |

## Reglas implementadas

1. **Cancelada es estado terminal**: nadie sale de Cancelada (ni para "reactivar"). Si se necesita reactivar, crear iniciativa nueva. Aplica el principio de soft-delete preservando historia.
2. **Aprobada y RechazoComite son terminales**: solo permiten Cancelada (escape admin).
3. **EstimacionRechazada / RechazadaGerencia son terminales**: solo Cancelada.
4. **Cancelada es siempre permitida desde cualquier otro estado** (admin escape).
5. **Devoluciones**: Devuelta por Jefatura puede volver a Revision PMO; Devuelta de Estimacion puede volver a Estimacion Desarrollo.
6. **Bypass del Comite**: Aprobada por Gerencia puede ir directo a Aprobada (sin pasar por Comite) si NO supera el umbral economico (definido por parametro `pas_parametro.umbral_escalamiento_comite_usd`). El plug-in NO valida el umbral — esa logica vive en el flow que decide a que estado mover.

## Reglas NO implementadas (futuras)

Las siguientes validaciones quedan diferidas a futuros plug-ins o flows porque dependen de logica adicional:

- **Validacion de rol del usuario**: que solo PMO puede mover de "Revision inicial PMO" hacia adelante. Requiere consultar `systemuserroles`. Diferido.
- **Validacion de campos requeridos al cambiar de estado**: por ejemplo, al mover a "Estimacion Aprobada por Jefatura" debe existir `pas_decision_jefatura_comentario`. Diferido a un plug-in de validacion de campos.
- **Validacion del umbral del Comite**: que si monto >= umbral, debe pasar por Comite. Diferido a un flow.

## Estados iniciales (Create)

Al crear una iniciativa, el unico estado valido inicial es **Borrador** (100000000). Si no se especifica, Dataverse usa el default (Borrador). El plug-in no permite Create con otro estado.

## Smoke tests

Ver [`scripts/plugins/smoke-test-estados.ps1`](../../scripts/plugins/smoke-test-estados.ps1):
1. CREATE con estado=Borrador (OK)
2. CREATE con estado=Aprobada (BLOCK)
3. UPDATE Borrador -> Revision PMO (OK)
4. UPDATE Borrador -> Aprobada (BLOCK)
5. UPDATE Aprobada -> Cancelada (OK, escape admin)
6. UPDATE Cancelada -> cualquier cosa (BLOCK)
