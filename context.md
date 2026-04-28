## Resumo Operacional

- App interno do Instituto Caminhos do Êxito para alunos, turmas, hábitos, ROI, ciclo 12WY, ranking e admin.
- Stack: React + Vite + Supabase.
- Dev ligado ao Supabase de `.env.dev`.

## Estado Atual

- M1 concluído no app e no banco de dev.
- M2 concluído no app e no Supabase de dev.
- Signup, recovery, first access, turma setup, convites e aceite já ligados às rotas e ao Supabase.
- Onboarding grava `onboarding_completed_at` e cria base inicial de programa, ciclo, objetivo, tática, tarefa, hábito e ROI baseline com `cycle_id` e meta negociada.
- `Dashboard` mostra hábitos, ROI, ciclo ativo, vínculos e badges reais, com ROI oculto para papéis sem acesso financeiro.
- M5 Dashboard do Aluno foi fechado no app com score da semana, tendência, streak, ROI acumulado, próximas tarefas, ação de hoje, ciclo resumido, feed de conquistas e atalhos para Plano, Hábitos, ROI e Turma.
- M6 Dashboard do Treinador foi fechado no app com visão consolidada por turma (RF33), lista ordenável de alunos com score/streak/ROI (RF34), dashboard detalhado do aluno (RF35), filtros por status (RF36), gráfico coletivo de scores semanais (RF37), exportação PDF individual e da turma (RF38-RF39), e fluxo completo de notas privadas com CRUD e tags (RF40).
- M7 Dashboard do Super Admin foi fechado no app e no schema local com visão global de programas, turmas e alunos ativos, métricas globais, gestão de programas arquiváveis, gestão de turmas, convites de usuário, desativação de perfis e limite de monitor por graduado.
- `Plano 12WY` agora cobre ciclo, objetivos, táticas, tarefas, check-ins, score semanal, score acumulado, histórico semanal, visão por dia e a modelagem/UX de objetivos, táticas e tarefas do RF08.
- `Hábitos` usa `type`, `frequency`, `specific_days`, `target_days`, `streak_reset_on` e `is_paused`.
- `ROI` usa `baseline_income`, `investment`, `goal_income`, `cycle_id` e `baseline_id`.
- `Ranking` calcula score real com hábitos, badges e ROI e respeita a visibilidade por papel.
- `AdminDashboard` usa papéis reais, notas privadas, programas/treinamentos, turmas, membros e governança de super admin.
- `Turma Setup` lista turmas e abre a página dedicada.
- `TurmaDetail` existe para membros, convites e resumo.
- `InviteAccept` mostra rótulo padronizado da turma, não o ID cru.
- M7 data contract e enforcement ficaram prontos no banco e no hook: `profiles.disabled_at`, `profiles.monitor_limit`, `programs.archived_at`, `user_invites`, RPCs de convite e de administração, resumo de monitores e bloqueio de limite por monitor em `enrollments`.
- PWA/offline scaffoldado.
- Build validado.
- `localhost` voltou e o crash em `/plano` foi corrigido.
- M4 ROI fechou no app e no schema: baseline/ciclo, gráfico semanal, bloqueio por papel e meta negociada já foram conectados e validados com smoke real.

## Melhorias Feitas

- Front, types e banco alinhados ao schema real do Supabase de dev.
- Tabelas criadas: `badges`, `user_badges`, `enrollments`, `coach_notes`, `turma_invites`.
- `profiles.onboarding_completed_at` adicionado.
- RPCs de convite: `get_turma_invite_by_token` e `accept_turma_invite`.
- Rotas em `src/App.tsx`: `/verify-email`, `/forgot-password`, `/reset-password`, `/invite/:token`, `/onboarding`, `/turma/setup`, `/turma/:turmaId`.
- `refreshProfile()` adicionado no auth context.
- `Database` generic removido do client Supabase.
- Seed de badges normalizada.
- Links quebrados, loaders presos e contratos antigos ajustados.
- RLS de onboarding/turma ajustado; recursão entre `turmas` e `enrollments` corrigida.
- `npm run lint`, `npm run build` e smoke tests no Supabase de dev validados.
- M2 fechado com `weekly_scores`, RPCs `close_cycle_week` e `archive_cycle`, limite de 3 objetivos, histórico semanal persistido, score acumulado e modelagem/UX do RF08.
- `src/hooks/useData.ts` separa ciclo ativo/arquivado e usa atualização otimista no `createCycle`.
- `src/pages/Plan12WY.tsx` bloqueia o 4º objetivo, suporta ciclo arquivado, histórico semanal, score acumulado e visão por dia.
- `src/lib/supabase.ts` ganhou timeout anti-spinner infinito.
- `src/context/AuthContext.tsx` deixou de segurar lock de auth no `onAuthStateChange`.
- `src/hooks/useData.ts` ganhou helpers tipados de admin e CRUD via RPC para programa arquivado, desativação/reativação de perfil, limite de monitor, convites de usuário e atribuição de monitor.
- Dados smoke/example removidos do Supabase; ficou só `fabiomoralesbriao@gmail.com`.
- `src/lib/turmaLabel.ts` padroniza nome de turma/convite.
- `src/pages/TurmaDetail.tsx` e rota `/turma/:turmaId` criadas.
- Centro de Comando e `Turma Setup` agora exibem programas/treinamentos, turmas e membros.
- M3 fechado no app com check-in único, streak por hábito, heatmap estilo GitHub, hábito de abandono, pausa com reset de streak e lembrete diário configurável.
- Lembrete diário ficou persistido em `profiles.habit_reminder_enabled` e `profiles.habit_reminder_time`, com scheduler local no `Shell` e plumbing de `push` no `public/sw.js`.
- `src/hooks/useData.ts` agora centraliza `isHabitDueOnDate`, `calculateHabitStreak`, heatmap e consistência por hábito.
- `npm run build` passou; `npm run lint` ainda acusa um erro preexistente em `src/pages/Ranking.tsx` (`TS2347`); localhost voltou em `http://127.0.0.1:3000`.

## Ainda Falta

- M3 Hábitos: fechado no app; smoke real no Supabase de dev ainda opcional.
- M4 ROI: concluído no app, no schema e com smoke real validado no Supabase de dev.
- M6 Dashboard do Treinador fechado no app.
- M7 Dashboard do Super Admin fechado no app e no schema local; falta apenas smoke real no Supabase de dev.
- M7 backend já fechou o contrato e a enforcement layer; falta só a UI do super admin e a integração final do worker responsável.
- M8 Aluno Graduado ainda incompleto.
- Automatizar desbloqueio de badges por regra.
- Expandir gestão de programas e turmas.
- Adicionar notificações, LGPD/auditoria e governança.

## Bem Encaminhado

- Login/sessão, recovery, verificação de e-mail e shell de navegação.
- Onboarding guiado com tooltips da primeira semana.
- Criação/configuração de turma e convites.
- Dashboard, Plano 12WY, Hábitos, ROI, Ranking, AdminDashboard, Turma Setup e TurmaDetail.
- Hábitos já com fluxo simples de check-in, streak/reset e lembrete diário configurável.
- Integração com Supabase de dev.
- BadgesGrid e scaffold de PWA/offline.
- Banco de dev alinhado com boa parte do contrato.
- Dados smoke/example removidos do banco.

## Pendências Por Módulo

- Módulo 2 - Plano 12 Week Year: RF07-RF14 fechados.
- Módulo 3 - Hábitos: fechado no app; smoke real no Supabase de dev ainda opcional.
- Módulo 4 - ROI: concluído no app, no schema e com smoke real validado no Supabase de dev.
- Módulo 5 - Dashboard do Aluno: RF28-RF32 fechados.
- Módulo 6 - Dashboard do Treinador: RF33-RF40 fechados.
- Módulo 7 - Dashboard do Super Admin: RF41-RF46 fechados no app e no schema local; smoke real no Supabase de dev ainda pendente.
- Módulo 8 - Aluno Graduado: RF47-RF51 pendentes.
- Módulo 9 - Gamificação: RF52 parcial; RF54-RF56 pendentes; RF53 fechado.
- Módulo 10 - Notificações: RF57-RF63 pendentes.

## Gaps Transversais

- LGPD e auditoria de dados sensíveis ainda faltam.
- Logs de acesso ao ROI ainda faltam.
- Backup e confiabilidade operacional ainda faltam.
- Offline real com sync posterior ainda falta.
- PWA scaffold existe, mas push/offline robustos ainda não.
- Performance e limites do PRD ainda não foram validados ponta a ponta.
