<!--
Antes de abrir el PR:
- Confirma que tu branch fue creado desde main actualizado y se llama issue-<id>-<stream>-<topic>
- Cada commit lleva Refs #<id> en el cuerpo; el commit del PR lleva Closes #<id>
- Revisa el checklist al final
- Si el PR es bootstrap/spike/hotfix, indicalo en "Riesgos" y referencia la excepcion del apendice de github-workflow.md
-->

## Resumen técnico

<!-- Que hace este PR y por que. 2-5 oraciones. -->

## Issues relacionados

<!-- Closes #<id>  ← cierra automaticamente el issue al merge
     Refs #<id>    ← referencia sin cerrar -->

Closes #
Refs #

## Evidencia de tests / validación

<!-- Smoke tests ejecutados, screenshots, run-ids de flows, output de pac solution check, etc. -->

- [ ] Smoke test:
- [ ] Solution check:
- [ ] Lint Power Fx / TypeScript / .NET:
- [ ] Otros:

## Riesgos

<!-- Efectos colaterales posibles, deuda tecnica introducida, dependencias rotas. -->

## Checklist (de la directriz §9)

- [ ] Branch creado desde `main` actualizado y nombrado `issue-<id>-<stream>-<topic>`
- [ ] Issue existente con criterios de aceptación definidos
- [ ] Implementación acotada al scope del issue (sin scope creep)
- [ ] Tests/smoke tests relevantes ejecutados y pasando
- [ ] Commits con mensaje estructurado y `Refs #<id>` en el cuerpo
- [ ] PR description incluye resumen, issues, evidencia de tests y riesgos
- [ ] Sin archivos temporales ni credenciales en el diff
- [ ] Solutions de Dataverse exportadas y unpacked si el cambio toca `solutions/`
- [ ] `CHANGELOG.md` actualizado si el cambio afecta comportamiento observable
- [ ] Tras el merge: eliminar el branch local y remoto

---

<!-- Si el PR fue asistido por IA, agrega:
🤖 Generated with [Claude Code](https://claude.com/claude-code)
-->
