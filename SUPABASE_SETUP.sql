-- TABELA DE PERFIS (Extende os usuários do Auth)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT CHECK (role IN ('SUPER_ADMIN', 'TREINADOR', 'PROPRIETARIO_EMPRESA', 'ALUNO_GRADUADO', 'ALUNO')) DEFAULT 'ALUNO',
  avatar_url TEXT,
  onboarding_completed_at TIMESTAMP WITH TIME ZONE,
  disabled_at TIMESTAMP WITH TIME ZONE,
  monitor_limit INTEGER CHECK (monitor_limit IS NULL OR monitor_limit >= 0),
  habit_reminder_enabled BOOLEAN DEFAULT FALSE,
  habit_reminder_time TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS e criar políticas básicas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Profiles are viewable by everyone logged in" ON profiles;
CREATE POLICY "Profiles are viewable by everyone logged in" ON profiles FOR SELECT USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Super admins can update profiles" ON profiles;
CREATE POLICY "Super admins can update profiles" ON profiles FOR UPDATE USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'SUPER_ADMIN'
  )
) WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'SUPER_ADMIN'
  )
);

-- TABELA DE PROGRAMAS
CREATE TABLE IF NOT EXISTS programs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived')),
  archived_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABELA DE TURMAS
CREATE TABLE IF NOT EXISTS turmas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  program_id UUID REFERENCES programs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  treinador_id UUID REFERENCES profiles(id),
  fechamento_dia INTEGER NOT NULL, -- 0-6
  fechamento_hora TEXT NOT NULL, -- "HH:mm"
  weeks_count INTEGER DEFAULT 12,
  start_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABELA DE CICLOS (12WY)
CREATE TABLE IF NOT EXISTS cycles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  aluno_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  turma_id UUID REFERENCES turmas(id) ON DELETE CASCADE,
  number INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'archived')) DEFAULT 'active',
  start_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABELA DE OBJETIVOS
CREATE TABLE IF NOT EXISTS goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cycle_id UUID REFERENCES cycles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  indicator TEXT,
  deadline DATE,
  "order" INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABELA DE TÁTICAS
CREATE TABLE IF NOT EXISTS tactics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  goal_id UUID REFERENCES goals(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  "order" INTEGER NOT NULL,
  frequency TEXT,
  progress NUMERIC(5,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABELA DE TAREFAS
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tactic_id UUID REFERENCES tactics(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  frequency TEXT NOT NULL DEFAULT 'daily' CHECK (frequency IN ('daily', 'specific_days', 'weekly')),
  specific_days INTEGER[] DEFAULT '{}'::INTEGER[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABELA DE CHECK-INS DE TAREFAS
CREATE TABLE IF NOT EXISTS task_checkins (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('done', 'not_done')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(task_id, date)
);

-- TABELA DE HÁBITOS
CREATE TABLE IF NOT EXISTS habits (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  aluno_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT CHECK (type IN ('build', 'abandon')),
  frequency TEXT DEFAULT 'daily',
  specific_days INTEGER[] DEFAULT '{}'::INTEGER[],
  target_days INTEGER DEFAULT 7,
  weekly_target INTEGER,
  is_paused BOOLEAN DEFAULT FALSE,
  streak_reset_on DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABELA DE CHECK-INS DE HÁBITOS
CREATE TABLE IF NOT EXISTS habit_checkins (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  habit_id UUID REFERENCES habits(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status BOOLEAN NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(habit_id, date)
);

-- TABELA DE ROI BASELINE
CREATE TABLE IF NOT EXISTS roi_baselines (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  aluno_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  program_id UUID REFERENCES programs(id) ON DELETE CASCADE,
  cycle_id UUID REFERENCES cycles(id) ON DELETE CASCADE,
  baseline_income NUMERIC(15,2) DEFAULT 0,
  investment NUMERIC(15,2) DEFAULT 0,
  goal_income NUMERIC(15,2),
  initial_revenue NUMERIC(15,2),
  target_revenue NUMERIC(15,2),
  goal_status TEXT CHECK (goal_status IN ('draft', 'proposed', 'approved', 'rejected')) DEFAULT 'draft',
  goal_note TEXT,
  goal_proposed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  goal_proposed_at TIMESTAMP WITH TIME ZONE,
  goal_approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  goal_approved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABELA DE RESULTADOS ROI
CREATE TABLE IF NOT EXISTS roi_results (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  aluno_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  baseline_id UUID REFERENCES roi_baselines(id) ON DELETE CASCADE,
  program_id UUID REFERENCES programs(id) ON DELETE CASCADE,
  cycle_id UUID REFERENCES cycles(id) ON DELETE CASCADE,
  amount NUMERIC(15,2) NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS habit_reminder_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS habit_reminder_time TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS disabled_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS monitor_limit INTEGER;
ALTER TABLE habits ADD COLUMN IF NOT EXISTS specific_days INTEGER[] DEFAULT '{}'::INTEGER[];
ALTER TABLE habits ADD COLUMN IF NOT EXISTS streak_reset_on DATE;
ALTER TABLE programs ADD COLUMN IF NOT EXISTS archived_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE roi_baselines ADD COLUMN IF NOT EXISTS cycle_id UUID REFERENCES cycles(id) ON DELETE CASCADE;
ALTER TABLE roi_baselines ADD COLUMN IF NOT EXISTS goal_status TEXT DEFAULT 'draft';
ALTER TABLE roi_baselines ADD COLUMN IF NOT EXISTS goal_note TEXT;
ALTER TABLE roi_baselines ADD COLUMN IF NOT EXISTS goal_proposed_by UUID REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE roi_baselines ADD COLUMN IF NOT EXISTS goal_proposed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE roi_baselines ADD COLUMN IF NOT EXISTS goal_approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE roi_baselines ADD COLUMN IF NOT EXISTS goal_approved_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE roi_results ADD COLUMN IF NOT EXISTS baseline_id UUID REFERENCES roi_baselines(id) ON DELETE CASCADE;
ALTER TABLE roi_results ADD COLUMN IF NOT EXISTS cycle_id UUID REFERENCES cycles(id) ON DELETE CASCADE;

-- SINCRONIZAÇÃO DE CAMPOS COMPATÍVEIS
CREATE OR REPLACE FUNCTION public.sync_habit_target_fields()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.weekly_target IS NOT NULL THEN
    NEW.target_days := NEW.weekly_target;
  ELSIF NEW.target_days IS NOT NULL THEN
    NEW.weekly_target := NEW.target_days;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_habit_target_fields ON habits;
CREATE TRIGGER sync_habit_target_fields
  BEFORE INSERT OR UPDATE ON habits
  FOR EACH ROW EXECUTE PROCEDURE public.sync_habit_target_fields();

CREATE OR REPLACE FUNCTION public.sync_roi_baseline_fields()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.initial_revenue IS NOT NULL THEN
    NEW.baseline_income := NEW.initial_revenue;
  ELSIF NEW.baseline_income IS NOT NULL THEN
    NEW.initial_revenue := NEW.baseline_income;
  END IF;

  IF NEW.target_revenue IS NOT NULL THEN
    NEW.goal_income := NEW.target_revenue;
  ELSIF NEW.goal_income IS NOT NULL THEN
    NEW.target_revenue := NEW.goal_income;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_roi_baseline_fields ON roi_baselines;
CREATE TRIGGER sync_roi_baseline_fields
  BEFORE INSERT OR UPDATE ON roi_baselines
  FOR EACH ROW EXECUTE PROCEDURE public.sync_roi_baseline_fields();

CREATE OR REPLACE FUNCTION public.sync_roi_result_context()
RETURNS TRIGGER AS $$
DECLARE
  v_baseline roi_baselines%ROWTYPE;
BEGIN
  IF NEW.baseline_id IS NOT NULL THEN
    SELECT * INTO v_baseline
    FROM roi_baselines
    WHERE id = NEW.baseline_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Baseline de ROI não encontrada.';
    END IF;

    NEW.aluno_id := COALESCE(NEW.aluno_id, v_baseline.aluno_id);
    NEW.program_id := COALESCE(NEW.program_id, v_baseline.program_id);
    NEW.cycle_id := COALESCE(NEW.cycle_id, v_baseline.cycle_id);
  END IF;

  IF NEW.aluno_id IS NULL THEN
    NEW.aluno_id := auth.uid();
  END IF;

  IF NEW.baseline_id IS NULL THEN
    RAISE EXCEPTION 'O resultado precisa estar vinculado a uma baseline de ROI.';
  END IF;

  IF NEW.program_id IS NULL OR NEW.cycle_id IS NULL THEN
    RAISE EXCEPTION 'O resultado precisa estar vinculado ao programa e ciclo corretos.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_roi_result_context ON roi_results;
CREATE TRIGGER sync_roi_result_context
  BEFORE INSERT OR UPDATE ON roi_results
  FOR EACH ROW EXECUTE PROCEDURE public.sync_roi_result_context();

-- TRIGGER PARA CRIAR PERFIL AUTOMATICAMENTE NO SIGNUP
-- (Opcional, mas recomendado)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- GAMIFICAÇÃO: BADGES
CREATE TABLE IF NOT EXISTS badges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT, -- Lucide icon name
  secret_code TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS user_badges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, badge_id)
);

-- MATRÍCULAS (ALUNO -> TURMA)
CREATE TABLE IF NOT EXISTS enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  aluno_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  turma_id UUID REFERENCES turmas(id) ON DELETE CASCADE,
  monitor_id UUID REFERENCES profiles(id), -- Aluno Graduado
  status TEXT CHECK (status IN ('active', 'inactive', 'concluded')) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(aluno_id, turma_id)
);

-- CONVITES DE TURMA
CREATE TABLE IF NOT EXISTS turma_invites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  turma_id UUID REFERENCES turmas(id) ON DELETE CASCADE NOT NULL,
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  email TEXT,
  token TEXT UNIQUE NOT NULL,
  invite_type TEXT CHECK (invite_type IN ('email', 'link')) DEFAULT 'link',
  status TEXT CHECK (status IN ('pending', 'accepted', 'expired')) DEFAULT 'pending',
  expires_at TIMESTAMP WITH TIME ZONE,
  used_at TIMESTAMP WITH TIME ZONE,
  accepted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE turma_invites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Turma invites created by staff" ON turma_invites;
CREATE POLICY "Turma invites created by staff" ON turma_invites
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('SUPER_ADMIN', 'TREINADOR')
    )
    AND created_by = auth.uid()
  );
DROP POLICY IF EXISTS "Turma invites are viewable by creator" ON turma_invites;
CREATE POLICY "Turma invites are viewable by creator" ON turma_invites
  FOR SELECT
  USING (created_by = auth.uid());

CREATE OR REPLACE FUNCTION public.get_turma_invite_by_token(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite turma_invites%ROWTYPE;
  v_turma turmas%ROWTYPE;
BEGIN
  SELECT * INTO v_invite
  FROM turma_invites
  WHERE token = p_token
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_turma
  FROM turmas
  WHERE id = v_invite.turma_id;

  RETURN jsonb_build_object(
    'id', v_invite.id,
    'turma_id', v_invite.turma_id,
    'created_by', v_invite.created_by,
    'email', v_invite.email,
    'token', v_invite.token,
    'invite_type', v_invite.invite_type,
    'status', v_invite.status,
    'expires_at', v_invite.expires_at,
    'used_at', v_invite.used_at,
    'accepted_by', v_invite.accepted_by,
    'created_at', v_invite.created_at,
    'turma_name', v_turma.name,
    'fechamento_dia', v_turma.fechamento_dia,
    'fechamento_hora', v_turma.fechamento_hora
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_turma_invite(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite turma_invites%ROWTYPE;
  v_email TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado.';
  END IF;

  SELECT * INTO v_invite
  FROM turma_invites
  WHERE token = p_token
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Convite inválido.';
  END IF;

  IF v_invite.status <> 'pending' THEN
    RAISE EXCEPTION 'Convite já foi utilizado ou expirou.';
  END IF;

  IF v_invite.expires_at IS NOT NULL AND v_invite.expires_at < timezone('utc'::text, now()) THEN
    UPDATE turma_invites SET status = 'expired' WHERE id = v_invite.id;
    RAISE EXCEPTION 'Convite expirado.';
  END IF;

  SELECT email INTO v_email
  FROM profiles
  WHERE id = auth.uid();

  IF v_invite.email IS NOT NULL AND lower(v_invite.email) <> lower(COALESCE(v_email, '')) THEN
    RAISE EXCEPTION 'Convite vinculado a outro e-mail.';
  END IF;

  INSERT INTO enrollments (aluno_id, turma_id, status)
  VALUES (auth.uid(), v_invite.turma_id, 'active')
  ON CONFLICT (aluno_id, turma_id)
  DO UPDATE SET status = 'active';

  UPDATE turma_invites
  SET
    status = 'accepted',
    used_at = timezone('utc'::text, now()),
    accepted_by = auth.uid()
  WHERE id = v_invite.id;

  RETURN jsonb_build_object(
    'invite_id', v_invite.id,
    'turma_id', v_invite.turma_id,
    'status', 'accepted'
  );
END;
$$;

-- CONVITES DE USUÁRIO / ACESSO
CREATE TABLE IF NOT EXISTS user_invites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('SUPER_ADMIN', 'TREINADOR', 'PROPRIETARIO_EMPRESA', 'ALUNO_GRADUADO', 'ALUNO')),
  monitor_limit INTEGER CHECK (monitor_limit IS NULL OR monitor_limit >= 0),
  token TEXT UNIQUE NOT NULL,
  invite_type TEXT CHECK (invite_type IN ('email', 'link')) DEFAULT 'email',
  status TEXT CHECK (status IN ('pending', 'accepted', 'expired')) DEFAULT 'pending',
  expires_at TIMESTAMP WITH TIME ZONE,
  used_at TIMESTAMP WITH TIME ZONE,
  accepted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE user_invites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "User invites are viewable by super admin" ON user_invites;
CREATE POLICY "User invites are viewable by super admin" ON user_invites
  FOR SELECT
  USING (public.is_super_admin());

DROP POLICY IF EXISTS "User invites are creatable by super admin" ON user_invites;
CREATE POLICY "User invites are creatable by super admin" ON user_invites
  FOR INSERT
  WITH CHECK (public.is_super_admin() AND created_by = auth.uid());

DROP POLICY IF EXISTS "User invites are updatable by super admin" ON user_invites;
CREATE POLICY "User invites are updatable by super admin" ON user_invites
  FOR UPDATE
  USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());

CREATE OR REPLACE FUNCTION public.create_user_invite(
  p_email TEXT DEFAULT NULL,
  p_full_name TEXT DEFAULT NULL,
  p_role TEXT DEFAULT 'ALUNO',
  p_monitor_limit INTEGER DEFAULT NULL,
  p_invite_type TEXT DEFAULT NULL,
  p_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS user_invites
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite user_invites%ROWTYPE;
  v_token TEXT := replace(gen_random_uuid()::text, '-', '');
  v_role TEXT := COALESCE(NULLIF(p_role, ''), 'ALUNO');
  v_invite_type TEXT := COALESCE(
    NULLIF(p_invite_type, ''),
    CASE
      WHEN p_email IS NULL THEN 'link'
      ELSE 'email'
    END
  );
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Sem permissao para criar convites de usuario.';
  END IF;

  INSERT INTO user_invites (
    email,
    full_name,
    role,
    monitor_limit,
    token,
    invite_type,
    status,
    expires_at,
    created_by
  )
  VALUES (
    p_email,
    p_full_name,
    v_role,
    CASE WHEN v_role = 'ALUNO_GRADUADO' THEN p_monitor_limit ELSE NULL END,
    v_token,
    v_invite_type,
    'pending',
    p_expires_at,
    auth.uid()
  )
  RETURNING * INTO v_invite;

  RETURN v_invite;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_invite_by_token(p_token TEXT)
RETURNS user_invites
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite user_invites%ROWTYPE;
BEGIN
  SELECT * INTO v_invite
  FROM user_invites
  WHERE token = p_token
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN v_invite;
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_user_invite(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite user_invites%ROWTYPE;
  v_profile profiles%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado.';
  END IF;

  SELECT * INTO v_invite
  FROM user_invites
  WHERE token = p_token
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Convite inválido.';
  END IF;

  IF v_invite.status <> 'pending' THEN
    RAISE EXCEPTION 'Convite já foi utilizado ou expirou.';
  END IF;

  IF v_invite.expires_at IS NOT NULL AND v_invite.expires_at < timezone('utc'::text, now()) THEN
    UPDATE user_invites SET status = 'expired' WHERE id = v_invite.id;
    RAISE EXCEPTION 'Convite expirado.';
  END IF;

  SELECT * INTO v_profile
  FROM profiles
  WHERE id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Perfil não encontrado para o usuário autenticado.';
  END IF;

  IF v_invite.email IS NOT NULL AND lower(v_profile.email) <> lower(v_invite.email) THEN
    RAISE EXCEPTION 'Convite vinculado a outro e-mail.';
  END IF;

  UPDATE profiles
  SET
    role = v_invite.role,
    full_name = COALESCE(NULLIF(v_invite.full_name, ''), full_name),
    disabled_at = NULL,
    monitor_limit = CASE
      WHEN v_invite.role = 'ALUNO_GRADUADO' THEN COALESCE(v_invite.monitor_limit, monitor_limit)
      ELSE NULL
    END
  WHERE id = auth.uid();

  UPDATE user_invites
  SET
    status = 'accepted',
    used_at = timezone('utc'::text, now()),
    accepted_by = auth.uid()
  WHERE id = v_invite.id;

  RETURN jsonb_build_object(
    'invite_id', v_invite.id,
    'profile_id', auth.uid(),
    'status', 'accepted',
    'role', v_invite.role
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.assign_monitor_to_enrollment(
  p_enrollment_id UUID,
  p_monitor_id UUID
)
RETURNS enrollments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_monitor profiles%ROWTYPE;
  v_active_count INTEGER := 0;
  v_result enrollments%ROWTYPE;
BEGIN
  IF NOT public.is_internal_staff() THEN
    RAISE EXCEPTION 'Sem permissao para atribuir monitor.';
  END IF;

  IF p_monitor_id IS NULL THEN
    UPDATE enrollments
    SET monitor_id = NULL
    WHERE id = p_enrollment_id
    RETURNING * INTO v_result;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Matricula nao encontrada.';
    END IF;

    RETURN v_result;
  END IF;

  SELECT * INTO v_monitor
  FROM profiles
  WHERE id = p_monitor_id;

  IF NOT FOUND OR v_monitor.role <> 'ALUNO_GRADUADO' THEN
    RAISE EXCEPTION 'O monitor precisa ser um aluno graduado.';
  END IF;

  IF v_monitor.disabled_at IS NOT NULL THEN
    RAISE EXCEPTION 'Nao e possivel atribuir um monitor desativado.';
  END IF;

  SELECT COUNT(*)
  INTO v_active_count
  FROM enrollments e
  WHERE e.monitor_id = p_monitor_id
    AND e.status = 'active'
    AND e.id <> p_enrollment_id;

  IF v_monitor.monitor_limit IS NOT NULL AND v_active_count >= v_monitor.monitor_limit THEN
    RAISE EXCEPTION 'Limite de alunos por monitor atingido.';
  END IF;

  UPDATE enrollments
  SET monitor_id = p_monitor_id
  WHERE id = p_enrollment_id
  RETURNING * INTO v_result;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Matricula nao encontrada.';
  END IF;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_monitor_assignment_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_monitor profiles%ROWTYPE;
  v_active_count INTEGER := 0;
BEGIN
  IF NEW.monitor_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF COALESCE(NEW.status, 'active') <> 'active' THEN
    RAISE EXCEPTION 'Apenas matriculas ativas podem receber monitor.';
  END IF;

  SELECT *
  INTO v_monitor
  FROM profiles
  WHERE id = NEW.monitor_id;

  IF NOT FOUND OR v_monitor.role <> 'ALUNO_GRADUADO' THEN
    RAISE EXCEPTION 'O monitor precisa ser um aluno graduado.';
  END IF;

  IF v_monitor.disabled_at IS NOT NULL THEN
    RAISE EXCEPTION 'Nao e possivel atribuir um monitor desativado.';
  END IF;

  SELECT COUNT(*)
  INTO v_active_count
  FROM enrollments e
  WHERE e.monitor_id = NEW.monitor_id
    AND e.status = 'active'
    AND e.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID);

  IF v_monitor.monitor_limit IS NOT NULL AND v_active_count >= v_monitor.monitor_limit THEN
    RAISE EXCEPTION 'Limite de alunos por monitor atingido.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS validate_monitor_assignment_limit ON enrollments;
CREATE TRIGGER validate_monitor_assignment_limit
  BEFORE INSERT OR UPDATE ON enrollments
  FOR EACH ROW EXECUTE PROCEDURE public.validate_monitor_assignment_limit();

-- NOTAS PRIVADAS DO TREINADOR
CREATE TABLE IF NOT EXISTS coach_notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  treinador_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  aluno_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- SEED BADGES
INSERT INTO badges (name, description, icon, secret_code) VALUES
('Primeiro Passo', 'Completar o onboarding e criar o primeiro objetivo.', 'Target', 'FIRST_STEP'),
('Semana Perfeita', 'Score semanal de 100%.', 'Shield', 'PERFECT_WEEK'),
('Consistência de Aço', '4 semanas consecutivas com 85% ou mais.', 'Zap', 'CONSISTENCY'),
('Hábito Fundado', '21 dias consecutivos de check-in em um hábito.', 'Flame', 'HABITO_FUNDADO'),
('Hábito Enraizado', '66 dias consecutivos de check-in em um hábito.', 'TreePine', 'DEEP_HABIT'),
('Primeira Conquista', 'Primeiro lançamento de resultado de ROI.', 'TrendingUp', 'FIRST_ROI'),
('Dobrei o Investimento', 'ROI acumulado igual ou superior a 2x do valor pago.', 'DollarSign', 'DOUBLE_ROI'),
('Mentor Ativo', 'Aluno Graduado que enviou mensagem para todos os monitorados na semana.', 'MessageSquare', 'MENTOR_ATIVO'),
('Ciclo Completo', 'Concluir as 12 semanas com score acumulado acima de 70%.', 'Award', 'CICLO_COMPLETO')
ON CONFLICT (secret_code) DO NOTHING;

-- M2: PLANO 12WY (regras de banco)

ALTER TABLE cycles
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE cycles
  ADD COLUMN IF NOT EXISTS weeks_count INTEGER DEFAULT 12;

UPDATE cycles
SET end_date = start_date + ((COALESCE(weeks_count, 12) * 7) - 1)
WHERE end_date IS NULL;

CREATE TABLE IF NOT EXISTS weekly_scores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  aluno_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  cycle_id UUID REFERENCES cycles(id) ON DELETE CASCADE NOT NULL,
  week_number INTEGER NOT NULL CHECK (week_number > 0),
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  planned_tasks INTEGER NOT NULL DEFAULT 0 CHECK (planned_tasks >= 0),
  completed_tasks INTEGER NOT NULL DEFAULT 0 CHECK (completed_tasks >= 0),
  score NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (score >= 0 AND score <= 100),
  closed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  closed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(cycle_id, week_number),
  CHECK (week_end_date >= week_start_date),
  CHECK (completed_tasks <= planned_tasks)
);

CREATE INDEX IF NOT EXISTS idx_cycles_aluno_status ON cycles (aluno_id, status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_cycles_one_active_per_aluno ON cycles (aluno_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_goals_cycle_order ON goals (cycle_id, "order");
CREATE INDEX IF NOT EXISTS idx_tactics_goal_order ON tactics (goal_id, "order");
CREATE INDEX IF NOT EXISTS idx_tasks_tactic_created_at ON tasks (tactic_id, created_at);
CREATE INDEX IF NOT EXISTS idx_task_checkins_task_date ON task_checkins (task_id, date);
CREATE INDEX IF NOT EXISTS idx_habits_aluno_created_at ON habits (aluno_id, created_at);
CREATE INDEX IF NOT EXISTS idx_habit_checkins_habit_date ON habit_checkins (habit_id, date);
CREATE INDEX IF NOT EXISTS idx_weekly_scores_cycle_week ON weekly_scores (cycle_id, week_number);
CREATE INDEX IF NOT EXISTS idx_weekly_scores_cycle_created_at ON weekly_scores (cycle_id, created_at);
CREATE INDEX IF NOT EXISTS idx_profiles_role_disabled ON profiles (role, disabled_at);
CREATE INDEX IF NOT EXISTS idx_programs_status_archived_at ON programs (status, archived_at);
CREATE INDEX IF NOT EXISTS idx_enrollments_monitor_status ON enrollments (monitor_id, status);
CREATE INDEX IF NOT EXISTS idx_user_invites_status_created_at ON user_invites (status, created_at);

CREATE OR REPLACE FUNCTION public.sync_cycle_dates()
RETURNS TRIGGER AS $$
BEGIN
  NEW.weeks_count := COALESCE(NEW.weeks_count, 12);

  IF TG_OP = 'INSERT' THEN
    NEW.end_date := NEW.start_date + ((NEW.weeks_count * 7) - 1);
  ELSIF NEW.start_date IS DISTINCT FROM OLD.start_date
     OR NEW.weeks_count IS DISTINCT FROM OLD.weeks_count
     OR NEW.end_date IS NULL THEN
    NEW.end_date := NEW.start_date + ((NEW.weeks_count * 7) - 1);
  END IF;

  IF NEW.status = 'archived' AND NEW.archived_at IS NULL THEN
    NEW.archived_at := timezone('utc'::text, now());
  ELSIF NEW.status = 'active' THEN
    NEW.archived_at := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_cycle_dates ON cycles;
CREATE TRIGGER sync_cycle_dates
  BEFORE INSERT OR UPDATE ON cycles
  FOR EACH ROW EXECUTE PROCEDURE public.sync_cycle_dates();

CREATE OR REPLACE FUNCTION public.sync_program_archived_state()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.archived_at IS NOT NULL THEN
    NEW.status := 'archived';
  ELSIF NEW.status = 'archived' THEN
    NEW.archived_at := COALESCE(NEW.archived_at, timezone('utc'::text, now()));
  ELSE
    NEW.archived_at := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_program_archived_state ON programs;
CREATE TRIGGER sync_program_archived_state
  BEFORE INSERT OR UPDATE ON programs
  FOR EACH ROW EXECUTE PROCEDURE public.sync_program_archived_state();

CREATE OR REPLACE FUNCTION public.is_internal_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(auth.role() = 'service_role', FALSE)
    OR EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('SUPER_ADMIN', 'TREINADOR', 'admin', 'coach')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'SUPER_ADMIN'
  );
$$;

CREATE OR REPLACE FUNCTION public.set_program_archived_state(
  p_program_id UUID,
  p_archived BOOLEAN
)
RETURNS programs
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program programs%ROWTYPE;
BEGIN
  IF NOT public.is_internal_staff() THEN
    RAISE EXCEPTION 'Sem permissao para alterar programas.';
  END IF;

  UPDATE programs
  SET
    status = CASE WHEN p_archived THEN 'archived' ELSE 'active' END,
    archived_at = CASE
      WHEN p_archived THEN COALESCE(archived_at, timezone('utc'::text, now()))
      ELSE NULL
    END
  WHERE id = p_program_id
  RETURNING * INTO v_program;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Programa nao encontrado.';
  END IF;

  RETURN v_program;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_profile_role(
  p_profile_id UUID,
  p_role TEXT
)
RETURNS profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile profiles%ROWTYPE;
BEGIN
  IF NOT public.is_internal_staff() THEN
    RAISE EXCEPTION 'Sem permissao para alterar perfis.';
  END IF;

  UPDATE profiles
  SET
    role = p_role,
    monitor_limit = CASE
      WHEN p_role = 'ALUNO_GRADUADO' THEN monitor_limit
      ELSE NULL
    END
  WHERE id = p_profile_id
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Perfil nao encontrado.';
  END IF;

  RETURN v_profile;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_profile_disabled_state(
  p_profile_id UUID,
  p_disabled BOOLEAN
)
RETURNS profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile profiles%ROWTYPE;
BEGIN
  IF NOT public.is_internal_staff() THEN
    RAISE EXCEPTION 'Sem permissao para alterar perfis.';
  END IF;

  UPDATE profiles
  SET disabled_at = CASE WHEN p_disabled THEN timezone('utc'::text, now()) ELSE NULL END
  WHERE id = p_profile_id
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Perfil nao encontrado.';
  END IF;

  RETURN v_profile;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_profile_monitor_limit(
  p_profile_id UUID,
  p_monitor_limit INTEGER
)
RETURNS profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile profiles%ROWTYPE;
BEGIN
  IF NOT public.is_internal_staff() THEN
    RAISE EXCEPTION 'Sem permissao para alterar perfis.';
  END IF;

  UPDATE profiles
  SET monitor_limit = CASE
    WHEN p_monitor_limit IS NULL THEN NULL
    WHEN role = 'ALUNO_GRADUADO' THEN p_monitor_limit
    ELSE NULL
  END
  WHERE id = p_profile_id
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Perfil nao encontrado.';
  END IF;

  IF p_monitor_limit IS NOT NULL AND v_profile.role <> 'ALUNO_GRADUADO' THEN
    RAISE EXCEPTION 'Limite de monitor so pode ser definido para alunos graduados.';
  END IF;

  RETURN v_profile;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_monitor_assignment_summary()
RETURNS TABLE (
  monitor_id UUID,
  monitor_name TEXT,
  monitor_email TEXT,
  monitor_limit INTEGER,
  active_assignment_count INTEGER,
  remaining_slots INTEGER,
  is_disabled BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id AS monitor_id,
    p.full_name AS monitor_name,
    p.email AS monitor_email,
    p.monitor_limit,
    COUNT(e.id)::INTEGER AS active_assignment_count,
    CASE
      WHEN p.monitor_limit IS NULL THEN NULL
      ELSE GREATEST(p.monitor_limit - COUNT(e.id)::INTEGER, 0)
    END AS remaining_slots,
    p.disabled_at IS NOT NULL AS is_disabled
  FROM profiles p
  LEFT JOIN enrollments e
    ON e.monitor_id = p.id
   AND e.status = 'active'
  WHERE p.role = 'ALUNO_GRADUADO'
    AND public.is_internal_staff()
  GROUP BY p.id, p.full_name, p.email, p.monitor_limit, p.disabled_at
  ORDER BY p.full_name;
$$;

CREATE OR REPLACE FUNCTION public.can_access_cycle(p_cycle_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM cycles c
    WHERE c.id = p_cycle_id
      AND (c.aluno_id = auth.uid() OR public.is_internal_staff())
  );
$$;

CREATE OR REPLACE FUNCTION public.can_access_goal(p_goal_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM goals g
    JOIN cycles c ON c.id = g.cycle_id
    WHERE g.id = p_goal_id
      AND (c.aluno_id = auth.uid() OR public.is_internal_staff())
  );
$$;

CREATE OR REPLACE FUNCTION public.can_access_tactic(p_tactic_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM tactics t
    JOIN goals g ON g.id = t.goal_id
    JOIN cycles c ON c.id = g.cycle_id
    WHERE t.id = p_tactic_id
      AND (c.aluno_id = auth.uid() OR public.is_internal_staff())
  );
$$;

CREATE OR REPLACE FUNCTION public.can_access_task(p_task_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM tasks t
    JOIN tactics ta ON ta.id = t.tactic_id
    JOIN goals g ON g.id = ta.goal_id
    JOIN cycles c ON c.id = g.cycle_id
    WHERE t.id = p_task_id
      AND (c.aluno_id = auth.uid() OR public.is_internal_staff())
  );
$$;

CREATE OR REPLACE FUNCTION public.can_access_habit(p_habit_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM habits h
    WHERE h.id = p_habit_id
      AND (h.aluno_id = auth.uid() OR public.is_internal_staff())
  );
$$;

CREATE OR REPLACE FUNCTION public.can_view_financial_roi(p_aluno_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(auth.role() = 'service_role', FALSE)
    OR EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ALUNO', 'TREINADOR', 'SUPER_ADMIN', 'admin', 'coach')
    )
    AND (
      p_aluno_id = auth.uid()
      OR public.is_internal_staff()
    );
$$;

CREATE OR REPLACE FUNCTION public.can_access_roi_baseline(p_baseline_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM roi_baselines b
    WHERE b.id = p_baseline_id
      AND public.can_view_financial_roi(b.aluno_id)
  );
$$;

CREATE OR REPLACE FUNCTION public.can_access_roi_result(p_result_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM roi_results r
    WHERE r.id = p_result_id
      AND public.can_view_financial_roi(r.aluno_id)
  );
$$;

CREATE OR REPLACE FUNCTION public.task_due_on_date(p_task_id UUID, p_check_date DATE)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_frequency TEXT;
  v_specific_days INTEGER[];
  v_cycle_start DATE;
BEGIN
  SELECT
    COALESCE(t.frequency, 'daily'),
    COALESCE(t.specific_days, ARRAY[]::INTEGER[]),
    c.start_date
  INTO v_frequency, v_specific_days, v_cycle_start
  FROM tasks t
  JOIN tactics ta ON ta.id = t.tactic_id
  JOIN goals g ON g.id = ta.goal_id
  JOIN cycles c ON c.id = g.cycle_id
  WHERE t.id = p_task_id;

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  IF v_frequency = 'weekly' THEN
    RETURN EXTRACT(DOW FROM p_check_date)::INTEGER = EXTRACT(DOW FROM v_cycle_start)::INTEGER;
  ELSIF v_frequency = 'specific_days' THEN
    RETURN EXTRACT(DOW FROM p_check_date)::INTEGER = ANY(v_specific_days);
  END IF;

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_goal_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_goal_count INTEGER;
  v_cycle_status TEXT;
BEGIN
  SELECT status
  INTO v_cycle_status
  FROM cycles
  WHERE id = NEW.cycle_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ciclo nao encontrado.';
  END IF;

  IF v_cycle_status <> 'active' THEN
    RAISE EXCEPTION 'Nao e possivel criar ou alterar objetivos em ciclos arquivados.';
  END IF;

  SELECT COUNT(*)
  INTO v_goal_count
  FROM goals
  WHERE cycle_id = NEW.cycle_id
    AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID);

  IF v_goal_count >= 3 THEN
    RAISE EXCEPTION 'Cada ciclo ativo pode ter no maximo 3 objetivos.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.validate_tactic_parent_cycle_active()
RETURNS TRIGGER AS $$
DECLARE
  v_cycle_status TEXT;
BEGIN
  SELECT c.status
  INTO v_cycle_status
  FROM goals g
  JOIN cycles c ON c.id = g.cycle_id
  WHERE g.id = NEW.goal_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Objetivo nao encontrado.';
  END IF;

  IF v_cycle_status <> 'active' THEN
    RAISE EXCEPTION 'Nao e possivel criar ou alterar taticas em ciclos arquivados.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.validate_task_parent_cycle_active()
RETURNS TRIGGER AS $$
DECLARE
  v_cycle_status TEXT;
BEGIN
  SELECT c.status
  INTO v_cycle_status
  FROM tactics ta
  JOIN goals g ON g.id = ta.goal_id
  JOIN cycles c ON c.id = g.cycle_id
  WHERE ta.id = NEW.tactic_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tatica nao encontrada.';
  END IF;

  IF v_cycle_status <> 'active' THEN
    RAISE EXCEPTION 'Nao e possivel criar ou alterar tarefas em ciclos arquivados.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.validate_task_checkin_window()
RETURNS TRIGGER AS $$
DECLARE
  v_task_created_at TIMESTAMP WITH TIME ZONE;
  v_cycle_start DATE;
  v_cycle_end DATE;
  v_cycle_status TEXT;
BEGIN
  SELECT
    t.created_at,
    c.start_date,
    COALESCE(c.end_date, c.start_date + ((COALESCE(c.weeks_count, 12) * 7) - 1)),
    c.status
  INTO v_task_created_at, v_cycle_start, v_cycle_end, v_cycle_status
  FROM tasks t
  JOIN tactics ta ON ta.id = t.tactic_id
  JOIN goals g ON g.id = ta.goal_id
  JOIN cycles c ON c.id = g.cycle_id
  WHERE t.id = NEW.task_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tarefa nao encontrada.';
  END IF;

  IF v_cycle_status <> 'active' THEN
    RAISE EXCEPTION 'Check-ins so podem ser salvos em ciclos ativos.';
  END IF;

  IF NEW.date < v_cycle_start OR NEW.date > v_cycle_end THEN
    RAISE EXCEPTION 'Check-in fora da janela do ciclo.';
  END IF;

  IF NEW.date < v_task_created_at::DATE THEN
    RAISE EXCEPTION 'Check-in nao pode ser anterior a criacao da tarefa.';
  END IF;

  IF NOT public.task_due_on_date(NEW.task_id, NEW.date) THEN
    RAISE EXCEPTION 'Check-in fora do calendario previsto para esta tarefa.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS validate_goal_limit ON goals;
CREATE TRIGGER validate_goal_limit
  BEFORE INSERT OR UPDATE ON goals
  FOR EACH ROW EXECUTE PROCEDURE public.validate_goal_limit();

DROP TRIGGER IF EXISTS validate_tactic_parent_cycle_active ON tactics;
CREATE TRIGGER validate_tactic_parent_cycle_active
  BEFORE INSERT OR UPDATE ON tactics
  FOR EACH ROW EXECUTE PROCEDURE public.validate_tactic_parent_cycle_active();

DROP TRIGGER IF EXISTS validate_task_parent_cycle_active ON tasks;
CREATE TRIGGER validate_task_parent_cycle_active
  BEFORE INSERT OR UPDATE ON tasks
  FOR EACH ROW EXECUTE PROCEDURE public.validate_task_parent_cycle_active();

DROP TRIGGER IF EXISTS validate_task_checkin_window ON task_checkins;
CREATE TRIGGER validate_task_checkin_window
  BEFORE INSERT OR UPDATE ON task_checkins
  FOR EACH ROW EXECUTE PROCEDURE public.validate_task_checkin_window();

CREATE OR REPLACE FUNCTION public.close_cycle_week(
  p_cycle_id UUID,
  p_week_number INTEGER DEFAULT NULL,
  p_closed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
)
RETURNS weekly_scores
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cycle cycles%ROWTYPE;
  v_week_number INTEGER;
  v_week_start DATE;
  v_week_end DATE;
  v_planned INTEGER := 0;
  v_completed INTEGER := 0;
  v_score NUMERIC(5,2) := 0;
  v_result weekly_scores%ROWTYPE;
BEGIN
  IF NOT (
    public.is_internal_staff()
    OR EXISTS (
      SELECT 1
      FROM cycles c
      WHERE c.id = p_cycle_id
        AND c.aluno_id = auth.uid()
    )
  ) THEN
    RAISE EXCEPTION 'Sem permissao para fechar este ciclo.';
  END IF;

  SELECT *
  INTO v_cycle
  FROM cycles
  WHERE id = p_cycle_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ciclo nao encontrado.';
  END IF;

  IF p_closed_at::DATE < v_cycle.start_date THEN
    RAISE EXCEPTION 'Ciclo ainda nao iniciou.';
  END IF;

  IF p_week_number IS NULL THEN
    v_week_number := GREATEST(
      1,
      LEAST(
        COALESCE(v_cycle.weeks_count, 12),
        ((p_closed_at::DATE - v_cycle.start_date) / 7) + 1
      )
    );
  ELSE
    v_week_number := p_week_number;
  END IF;

  IF v_week_number < 1 THEN
    RAISE EXCEPTION 'Numero da semana invalido.';
  END IF;

  IF v_week_number > COALESCE(v_cycle.weeks_count, 12) THEN
    RAISE EXCEPTION 'Numero da semana excede a duracao do ciclo.';
  END IF;

  v_week_start := v_cycle.start_date + ((v_week_number - 1) * 7);
  v_week_end := LEAST(
    v_week_start + 6,
    COALESCE(v_cycle.end_date, v_cycle.start_date + ((COALESCE(v_cycle.weeks_count, 12) * 7) - 1))
  );

  WITH cycle_tasks AS (
    SELECT
      t.id AS task_id,
      COALESCE(t.frequency, 'daily') AS frequency,
      COALESCE(t.specific_days, ARRAY[]::INTEGER[]) AS specific_days,
      c.start_date AS cycle_start_date,
      t.created_at
    FROM tasks t
    JOIN tactics ta ON ta.id = t.tactic_id
    JOIN goals g ON g.id = ta.goal_id
    JOIN cycles c ON c.id = g.cycle_id
    WHERE c.id = p_cycle_id
      AND t.created_at <= p_closed_at
  ),
  days AS (
    SELECT generate_series(v_week_start, v_week_end, interval '1 day')::DATE AS day
  ),
  planned AS (
    SELECT COUNT(*)::INTEGER AS planned_count
    FROM cycle_tasks ct
    CROSS JOIN days d
    WHERE d.day >= ct.created_at::DATE
      AND CASE
        WHEN ct.frequency = 'weekly' THEN EXTRACT(DOW FROM d.day)::INTEGER = EXTRACT(DOW FROM ct.cycle_start_date)::INTEGER
        WHEN ct.frequency = 'specific_days' THEN EXTRACT(DOW FROM d.day)::INTEGER = ANY(ct.specific_days)
        ELSE TRUE
      END
  ),
  completed AS (
    SELECT COUNT(*)::INTEGER AS completed_count
    FROM task_checkins tc
    JOIN cycle_tasks ct ON ct.task_id = tc.task_id
    WHERE tc.status = 'done'
      AND tc.created_at <= p_closed_at
      AND tc.date BETWEEN v_week_start AND v_week_end
      AND tc.date >= ct.created_at::DATE
      AND CASE
        WHEN ct.frequency = 'weekly' THEN EXTRACT(DOW FROM tc.date)::INTEGER = EXTRACT(DOW FROM ct.cycle_start_date)::INTEGER
        WHEN ct.frequency = 'specific_days' THEN EXTRACT(DOW FROM tc.date)::INTEGER = ANY(ct.specific_days)
        ELSE TRUE
      END
  )
  SELECT planned_count, completed_count
  INTO v_planned, v_completed
  FROM planned, completed;

  v_score := CASE
    WHEN v_planned > 0 THEN ROUND((v_completed::NUMERIC / v_planned::NUMERIC) * 100, 2)
    ELSE 0
  END;

  INSERT INTO weekly_scores (
    aluno_id,
    cycle_id,
    week_number,
    week_start_date,
    week_end_date,
    planned_tasks,
    completed_tasks,
    score,
    closed_at,
    closed_by
  )
  VALUES (
    v_cycle.aluno_id,
    v_cycle.id,
    v_week_number,
    v_week_start,
    v_week_end,
    v_planned,
    v_completed,
    v_score,
    p_closed_at,
    auth.uid()
  )
  ON CONFLICT (cycle_id, week_number) DO UPDATE SET
    aluno_id = EXCLUDED.aluno_id,
    week_start_date = EXCLUDED.week_start_date,
    week_end_date = EXCLUDED.week_end_date,
    planned_tasks = EXCLUDED.planned_tasks,
    completed_tasks = EXCLUDED.completed_tasks,
    score = EXCLUDED.score,
    closed_at = EXCLUDED.closed_at,
    closed_by = EXCLUDED.closed_by
  RETURNING * INTO v_result;

  IF v_week_number = COALESCE(v_cycle.weeks_count, 12) THEN
    UPDATE cycles
    SET
      status = 'archived',
      archived_at = COALESCE(archived_at, p_closed_at)
    WHERE id = v_cycle.id;
  END IF;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.archive_cycle(p_cycle_id UUID)
RETURNS cycles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cycle cycles%ROWTYPE;
BEGIN
  IF NOT (
    public.is_internal_staff()
    OR EXISTS (
      SELECT 1
      FROM cycles c
      WHERE c.id = p_cycle_id
        AND c.aluno_id = auth.uid()
    )
  ) THEN
    RAISE EXCEPTION 'Sem permissao para arquivar este ciclo.';
  END IF;

  UPDATE cycles
  SET
    status = 'archived',
    archived_at = COALESCE(archived_at, timezone('utc'::text, now()))
  WHERE id = p_cycle_id
  RETURNING * INTO v_cycle;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ciclo nao encontrado.';
  END IF;

  RETURN v_cycle;
END;
$$;

ALTER TABLE cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE tactics ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE roi_baselines ENABLE ROW LEVEL SECURITY;
ALTER TABLE roi_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE roi_baselines FORCE ROW LEVEL SECURITY;
ALTER TABLE roi_results FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cycles are viewable by owner and staff" ON cycles;
CREATE POLICY "Cycles are viewable by owner and staff" ON cycles
  FOR SELECT
  USING (public.can_access_cycle(id));

DROP POLICY IF EXISTS "Cycles are editable by owner and staff" ON cycles;
CREATE POLICY "Cycles are editable by owner and staff" ON cycles
  FOR INSERT
  WITH CHECK (aluno_id = auth.uid() OR public.is_internal_staff());

DROP POLICY IF EXISTS "Cycles can be updated by owner and staff" ON cycles;
CREATE POLICY "Cycles can be updated by owner and staff" ON cycles
  FOR UPDATE
  USING (public.can_access_cycle(id))
  WITH CHECK (aluno_id = auth.uid() OR public.is_internal_staff());

DROP POLICY IF EXISTS "Goals are viewable by cycle owner and staff" ON goals;
CREATE POLICY "Goals are viewable by cycle owner and staff" ON goals
  FOR SELECT
  USING (public.can_access_goal(id));

DROP POLICY IF EXISTS "Goals are editable by cycle owner and staff" ON goals;
CREATE POLICY "Goals are editable by cycle owner and staff" ON goals
  FOR INSERT
  WITH CHECK (public.can_access_cycle(cycle_id));

DROP POLICY IF EXISTS "Goals can be updated by cycle owner and staff" ON goals;
CREATE POLICY "Goals can be updated by cycle owner and staff" ON goals
  FOR UPDATE
  USING (public.can_access_goal(id))
  WITH CHECK (public.can_access_cycle(cycle_id));

DROP POLICY IF EXISTS "Tactics are viewable by cycle owner and staff" ON tactics;
CREATE POLICY "Tactics are viewable by cycle owner and staff" ON tactics
  FOR SELECT
  USING (public.can_access_tactic(id));

DROP POLICY IF EXISTS "Tactics are editable by cycle owner and staff" ON tactics;
CREATE POLICY "Tactics are editable by cycle owner and staff" ON tactics
  FOR INSERT
  WITH CHECK (public.can_access_goal(goal_id));

DROP POLICY IF EXISTS "Tactics can be updated by cycle owner and staff" ON tactics;
CREATE POLICY "Tactics can be updated by cycle owner and staff" ON tactics
  FOR UPDATE
  USING (public.can_access_tactic(id))
  WITH CHECK (public.can_access_goal(goal_id));

DROP POLICY IF EXISTS "Tasks are viewable by cycle owner and staff" ON tasks;
CREATE POLICY "Tasks are viewable by cycle owner and staff" ON tasks
  FOR SELECT
  USING (public.can_access_task(id));

DROP POLICY IF EXISTS "Tasks are editable by cycle owner and staff" ON tasks;
CREATE POLICY "Tasks are editable by cycle owner and staff" ON tasks
  FOR INSERT
  WITH CHECK (public.can_access_tactic(tactic_id));

DROP POLICY IF EXISTS "Tasks can be updated by cycle owner and staff" ON tasks;
CREATE POLICY "Tasks can be updated by cycle owner and staff" ON tasks
  FOR UPDATE
  USING (public.can_access_task(id))
  WITH CHECK (public.can_access_tactic(tactic_id));

DROP POLICY IF EXISTS "Task checkins are viewable by cycle owner and staff" ON task_checkins;
CREATE POLICY "Task checkins are viewable by cycle owner and staff" ON task_checkins
  FOR SELECT
  USING (public.can_access_task(task_id));

DROP POLICY IF EXISTS "Task checkins are editable by cycle owner and staff" ON task_checkins;
CREATE POLICY "Task checkins are editable by cycle owner and staff" ON task_checkins
  FOR INSERT
  WITH CHECK (public.can_access_task(task_id));

DROP POLICY IF EXISTS "Task checkins can be updated by cycle owner and staff" ON task_checkins;
CREATE POLICY "Task checkins can be updated by cycle owner and staff" ON task_checkins
  FOR UPDATE
  USING (public.can_access_task(task_id))
  WITH CHECK (public.can_access_task(task_id));

DROP POLICY IF EXISTS "Habits are viewable by owner and staff" ON habits;
CREATE POLICY "Habits are viewable by owner and staff" ON habits
  FOR SELECT
  USING (public.can_access_habit(id));

DROP POLICY IF EXISTS "Habits are editable by owner and staff" ON habits;
CREATE POLICY "Habits are editable by owner and staff" ON habits
  FOR INSERT
  WITH CHECK (aluno_id = auth.uid() OR public.is_internal_staff());

DROP POLICY IF EXISTS "Habits can be updated by owner and staff" ON habits;
CREATE POLICY "Habits can be updated by owner and staff" ON habits
  FOR UPDATE
  USING (public.can_access_habit(id))
  WITH CHECK (aluno_id = auth.uid() OR public.is_internal_staff());

DROP POLICY IF EXISTS "Habits can be deleted by owner and staff" ON habits;
CREATE POLICY "Habits can be deleted by owner and staff" ON habits
  FOR DELETE
  USING (public.can_access_habit(id));

DROP POLICY IF EXISTS "Habit checkins are viewable by owner and staff" ON habit_checkins;
CREATE POLICY "Habit checkins are viewable by owner and staff" ON habit_checkins
  FOR SELECT
  USING (public.can_access_habit(habit_id));

DROP POLICY IF EXISTS "Habit checkins are editable by owner and staff" ON habit_checkins;
CREATE POLICY "Habit checkins are editable by owner and staff" ON habit_checkins
  FOR INSERT
  WITH CHECK (public.can_access_habit(habit_id));

DROP POLICY IF EXISTS "Habit checkins can be updated by owner and staff" ON habit_checkins;
CREATE POLICY "Habit checkins can be updated by owner and staff" ON habit_checkins
  FOR UPDATE
  USING (public.can_access_habit(habit_id))
  WITH CHECK (public.can_access_habit(habit_id));

DROP POLICY IF EXISTS "Habit checkins can be deleted by owner and staff" ON habit_checkins;
CREATE POLICY "Habit checkins can be deleted by owner and staff" ON habit_checkins
  FOR DELETE
  USING (public.can_access_habit(habit_id));

DROP POLICY IF EXISTS "Weekly scores are viewable by cycle owner and staff" ON weekly_scores;
CREATE POLICY "Weekly scores are viewable by cycle owner and staff" ON weekly_scores
  FOR SELECT
  USING (public.can_access_cycle(cycle_id));

DROP POLICY IF EXISTS "Weekly scores are editable by cycle owner and staff" ON weekly_scores;
CREATE POLICY "Weekly scores are editable by cycle owner and staff" ON weekly_scores
  FOR INSERT
  WITH CHECK (public.can_access_cycle(cycle_id));

DROP POLICY IF EXISTS "Weekly scores can be updated by cycle owner and staff" ON weekly_scores;
CREATE POLICY "Weekly scores can be updated by cycle owner and staff" ON weekly_scores
  FOR UPDATE
  USING (public.can_access_cycle(cycle_id))
  WITH CHECK (public.can_access_cycle(cycle_id));

DROP POLICY IF EXISTS "ROI baselines are viewable by owner and staff" ON roi_baselines;
CREATE POLICY "ROI baselines are viewable by owner and staff" ON roi_baselines
  FOR SELECT
  USING (public.can_access_roi_baseline(id));

DROP POLICY IF EXISTS "ROI baselines are editable by owner and staff" ON roi_baselines;
CREATE POLICY "ROI baselines are editable by owner and staff" ON roi_baselines
  FOR INSERT
  WITH CHECK (public.can_view_financial_roi(aluno_id));

DROP POLICY IF EXISTS "ROI baselines can be updated by owner and staff" ON roi_baselines;
CREATE POLICY "ROI baselines can be updated by owner and staff" ON roi_baselines
  FOR UPDATE
  USING (public.can_access_roi_baseline(id))
  WITH CHECK (public.can_view_financial_roi(aluno_id));

DROP POLICY IF EXISTS "ROI baselines can be deleted by owner and staff" ON roi_baselines;
CREATE POLICY "ROI baselines can be deleted by owner and staff" ON roi_baselines
  FOR DELETE
  USING (public.can_access_roi_baseline(id));

DROP POLICY IF EXISTS "ROI results are viewable by owner and staff" ON roi_results;
CREATE POLICY "ROI results are viewable by owner and staff" ON roi_results
  FOR SELECT
  USING (public.can_access_roi_result(id));

DROP POLICY IF EXISTS "ROI results are editable by owner and staff" ON roi_results;
CREATE POLICY "ROI results are editable by owner and staff" ON roi_results
  FOR INSERT
  WITH CHECK (
    baseline_id IS NOT NULL
    AND cycle_id IS NOT NULL
    AND public.can_view_financial_roi(aluno_id)
  );

DROP POLICY IF EXISTS "ROI results can be updated by owner and staff" ON roi_results;
CREATE POLICY "ROI results can be updated by owner and staff" ON roi_results
  FOR UPDATE
  USING (public.can_access_roi_result(id))
  WITH CHECK (
    baseline_id IS NOT NULL
    AND cycle_id IS NOT NULL
    AND public.can_view_financial_roi(aluno_id)
  );

DROP POLICY IF EXISTS "ROI results can be deleted by owner and staff" ON roi_results;
CREATE POLICY "ROI results can be deleted by owner and staff" ON roi_results
  FOR DELETE
  USING (public.can_access_roi_result(id));

GRANT SELECT ON weekly_scores TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON roi_baselines TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON roi_results TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_invites TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.close_cycle_week(UUID, INTEGER, TIMESTAMP WITH TIME ZONE) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.archive_cycle(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.create_user_invite(TEXT, TEXT, TEXT, INTEGER, TEXT, TIMESTAMP WITH TIME ZONE) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_user_invite_by_token(TEXT) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.accept_user_invite(TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.assign_monitor_to_enrollment(UUID, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.set_program_archived_state(UUID, BOOLEAN) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.set_profile_role(UUID, TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.set_profile_disabled_state(UUID, BOOLEAN) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.set_profile_monitor_limit(UUID, INTEGER) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_monitor_assignment_summary() TO authenticated, service_role;

-- RPC: Obter métricas consolidadas por turma (RF33)
CREATE OR REPLACE FUNCTION public.get_turma_metrics(p_turma_id UUID)
RETURNS TABLE (
  total_alunos INTEGER,
  average_score NUMERIC,
  risk_percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH turma_cycles AS (
    SELECT id, aluno_id
    FROM cycles
    WHERE turma_id = p_turma_id
  ),
  cycle_weekly_scores AS (
    SELECT
      ws.aluno_id,
      ws.score
    FROM weekly_scores ws
    INNER JOIN turma_cycles tc ON ws.cycle_id = tc.id
  ),
  aluno_avg_scores AS (
    SELECT
      aluno_id,
      AVG(score) as avg_score
    FROM cycle_weekly_scores
    GROUP BY aluno_id
  )
  SELECT
    (SELECT COUNT(DISTINCT aluno_id) FROM turma_cycles) as total_alunos,
    (SELECT COALESCE(AVG(score), 0) FROM cycle_weekly_scores) as average_score,
    (SELECT COALESCE(
      ROUND(
        (COUNT(*) FILTER (WHERE avg_score < 60)::NUMERIC /
        NULLIF(COUNT(*), 0)) * 100
      ), 0)
     FROM aluno_avg_scores) as risk_percentage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_turma_metrics(UUID) TO authenticated, service_role;
