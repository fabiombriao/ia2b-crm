/**
 * EXEMPLOS DE USO DO SERVIÇO DE EXPORTAÇÃO PDF
 *
 * Este arquivo contém exemplos práticos de como utilizar as funções
 * generateStudentPDF e generateTurmaPDF no seu projeto.
 */

import { generateStudentPDF, generateTurmaPDF } from './pdfExport';
import type {
  Profile,
  PlanSummary,
  WeeklyScore,
  Habit,
  HabitCheckin,
  ROIBaseline,
  ROIResult,
  PlanGoal,
  Cycle,
  Enrollment,
  Turma,
  Program,
} from '../types';

// ============================================
// EXEMPLO 1: Exportar PDF Individual do Aluno
// ============================================

/**
 * Exemplo de como chamar a função generateStudentPDF
 * a partir de um componente React
 */
export async function exportStudentPDFExample() {
  // Suponha que você tenha esses dados disponíveis no seu componente
  const studentData = {
    profile: {
      id: '123',
      email: 'aluno@exemplo.com',
      full_name: 'João Silva',
      role: 'ALUNO',
      avatar_url: null,
      created_at: '2024-01-01',
    } as Profile,

    summary: {
      cycleProgress: 65,
      weeklyScore: 85,
      cycleScore: 78,
      currentWeek: 5,
      totalWeeks: 12,
      weekStart: '2024-01-22',
      weekEnd: '2024-01-28',
      completedToday: 3,
      tasksDueToday: 5,
      totalTasks: 25,
      totalGoals: 3,
      totalTactics: 8,
      goalLimitReached: false,
      remainingGoals: 2,
    } as PlanSummary,

    weeklyScores: [
      { id: '1', aluno_id: '123', cycle_id: '456', week_number: 1, score: 72, created_at: '2024-01-01' },
      { id: '2', aluno_id: '123', cycle_id: '456', week_number: 2, score: 78, created_at: '2024-01-08' },
      { id: '3', aluno_id: '123', cycle_id: '456', week_number: 3, score: 82, created_at: '2024-01-15' },
      { id: '4', aluno_id: '123', cycle_id: '456', week_number: 4, score: 85, created_at: '2024-01-22' },
      { id: '5', aluno_id: '123', cycle_id: '456', week_number: 5, score: 85, created_at: '2024-01-29' },
    ] as WeeklyScore[],

    habits: [
      {
        id: '1',
        aluno_id: '123',
        name: 'Meditação matinal',
        type: 'build',
        frequency: 'daily',
        is_paused: false,
        created_at: '2024-01-01',
        checkins: [
          { id: 'c1', habit_id: '1', date: '2024-01-22', status: true, created_at: '2024-01-22' },
          { id: 'c2', habit_id: '1', date: '2024-01-23', status: true, created_at: '2024-01-23' },
        ],
      } as Habit & { checkins: HabitCheckin[] },
    ],

    habitStats: {
      currentStreak: 12,
      avgPerformance: 85,
    },

    roiBaseline: {
      id: '1',
      aluno_id: '123',
      baseline_income: 10000,
      goal_income: 15000,
      created_at: '2024-01-01',
    } as ROIBaseline,

    roiResults: [
      { id: 'r1', aluno_id: '123', amount: 12000, date: '2024-01-15', description: 'Projeto X', created_at: '2024-01-15' },
    ] as ROIResult[],

    goals: [
      {
        id: 'g1',
        title: 'Aumentar receita mensal',
        description: 'Implementar estratégias de crescimento',
        progress: 65,
        order: 1,
        created_at: '2024-01-01',
      } as PlanGoal,
    ],

    activeCycle: {
      id: '456',
      aluno_id: '123',
      turma_id: '789',
      number: 1,
      status: 'active',
      start_date: '2024-01-01',
      created_at: '2024-01-01',
    } as Cycle,

    enrollment: {
      id: 'e1',
      aluno_id: '123',
      turma_id: '789',
      status: 'active',
      created_at: '2024-01-01',
      turmas: {
        id: '789',
        name: 'Turma Alpha 2024',
        program_id: 'p1',
        treinador_id: 't1',
        fechamento_dia: 5,
        fechamento_hora: '23:59',
        weeks_count: 12,
        start_date: '2024-01-01',
        created_at: '2024-01-01',
        program: {
          id: 'p1',
          name: 'Programa de Liderança',
          description: 'Programa avançado de liderança',
          created_at: '2024-01-01',
        },
      } as Turma & { program?: Program | null },
    } as Enrollment & { turmas?: Turma & { program?: Program | null } },
  };

  // Chamar a função de exportação
  await generateStudentPDF(studentData, 'relatorio-joao-silva.pdf');
}

// ============================================
// EXEMPLO 2: Integrar com hook useData
// ============================================

/**
 * Exemplo de como integrar a exportação PDF em um componente React
 * usando os hooks existentes useData
 */
/*
export function ExportStudentButton({ alunoId }: { alunoId: string }) {
  const { profile } = useAuth();
  const [isExporting, setIsExporting] = useState(false);

  const handleExport = async () => {
    setIsExporting(true);
    try {
      // Buscar dados do aluno usando suas funções existentes
      const studentData = await fetchStudentData(alunoId);

      await generateStudentPDF(studentData);
    } catch (error) {
      console.error('Erro ao exportar PDF:', error);
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <button
      onClick={handleExport}
      disabled={isExporting}
      className="flex items-center gap-2 px-4 py-2 bg-brand-green text-black rounded-lg"
    >
      {isExporting ? 'Exportando...' : 'Exportar PDF'}
    </button>
  );
}
*/

// ============================================
// EXEMPLO 3: Exportar PDF da Turma
// ============================================

/**
 * Exemplo de como chamar a função generateTurmaPDF
 */
export async function exportTurmaPDFExample() {
  // Suponha que você tenha esses dados disponíveis
  const turmaData = {
    turma: {
      id: '789',
      name: 'Turma Alpha 2024',
      program_id: 'p1',
      treinador_id: 't1',
      fechamento_dia: 5,
      fechamento_hora: '23:59',
      weeks_count: 12,
      start_date: '2024-01-01',
      created_at: '2024-01-01',
    } as Turma,

    program: {
      id: 'p1',
      name: 'Programa de Liderança',
      description: 'Programa avançado de liderança',
      created_at: '2024-01-01',
    } as Program,

    trainer: {
      id: 't1',
      email: 'treinador@exemplo.com',
      full_name: 'Maria Santos',
      role: 'TREINADOR',
      avatar_url: null,
      created_at: '2024-01-01',
    } as Profile,

    members: [
      {
        enrollment: {
          id: 'e1',
          aluno_id: '123',
          turma_id: '789',
          status: 'active',
          created_at: '2024-01-01',
        } as Enrollment,
        profile: {
          id: '123',
          email: 'aluno@exemplo.com',
          full_name: 'João Silva',
          role: 'ALUNO',
          avatar_url: null,
          created_at: '2024-01-01',
        } as Profile,
        cycle: {
          id: '456',
          aluno_id: '123',
          turma_id: '789',
          number: 1,
          status: 'active',
          start_date: '2024-01-01',
          created_at: '2024-01-01',
        } as Cycle,
        weeklyScores: [
          { id: '1', aluno_id: '123', cycle_id: '456', week_number: 1, score: 85, created_at: '2024-01-01' },
        ] as WeeklyScore[],
        habitStats: { currentStreak: 12, avgPerformance: 85 },
      },
    ],

    turmaMetrics: {
      avgScore: 78.5,
      activeMembers: 20,
      atRiskMembers: 3,
      onTrackMembers: 17,
      avgStreak: 10.2,
    },
  };

  // Chamar a função de exportação
  await generateTurmaPDF(turmaData, 'relatorio-turma-alpha.pdf');
}

// ============================================
// EXEMPLO 4: Adicionar botão de exportação no Dashboard
// ============================================

/**
 * Exemplo de como adicionar um botão de exportação no Dashboard do aluno
 */
/*
export function DashboardExportButton() {
  const { profile } = useAuth();
  const { summary, weeklyScores, habits, habitStats, roiBaseline, roiResults, goals, activeCycle, enrollments } = usePlan12WY();

  const handleExportPDF = async () => {
    if (!profile) return;

    const studentData = {
      profile,
      summary,
      weeklyScores,
      habits,
      habitStats,
      roiBaseline,
      roiResults,
      goals,
      activeCycle,
      enrollment: enrollments.find((e: any) => e.status === 'active'),
    };

    await generateStudentPDF(studentData);
  };

  return (
    <button
      onClick={handleExportPDF}
      className="fixed bottom-6 right-6 flex items-center gap-2 px-6 py-3 rounded-full bg-brand-green text-black font-bold uppercase text-xs tracking-wider hover:bg-brand-green/90 transition-all shadow-lg"
    >
      <Download className="w-4 h-4" />
      Exportar Relatório
    </button>
  );
}
*/

// ============================================
// EXEMPLO 5: Adicionar botão de exportação na página da turma
// ============================================

/**
 * Exemplo de como adicionar um botão de exportação na página de detalhes da turma
 */
/*
export function TurmaExportButton({ turmaId }: { turmaId: string }) {
  const [isExporting, setIsExporting] = useState(false);

  const handleExportPDF = async () => {
    setIsExporting(true);
    try {
      // Buscar dados da turma
      const turmaData = await fetchTurmaData(turmaId);

      await generateTurmaPDF(turmaData);
    } catch (error) {
      console.error('Erro ao exportar PDF:', error);
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <button
      onClick={handleExportPDF}
      disabled={isExporting}
      className="flex items-center gap-2 px-4 py-2 rounded-lg border border-brand-green/20 bg-brand-green/10 text-brand-green hover:bg-brand-green/20 transition-all"
    >
      {isExporting ? (
        <>
          <Loader2 className="w-4 h-4 animate-spin" />
          Exportando...
        </>
      ) : (
        <>
          <Download className="w-4 h-4" />
          Exportar Relatório da Turma
        </>
      )}
    </button>
  );
}
*/
