-- 在 Supabase 项目的 SQL Editor 里执行
-- https://supabase.com/dashboard/project/tldmpaumprctfpqzbgga/sql
--
-- 这是 v2 版本:用 categories + tasks 两张表替换旧的 task_state,
-- 支持分类和任务的增删改查。如果你已经执行过旧版 SQL,直接执行本文件即可
-- (会先删除旧的 task_state 表)。

drop table if exists task_state;

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  room text not null,
  icon text not null default '📋',
  name text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  room text not null,
  category_id uuid not null references categories(id) on delete cascade,
  grp text not null check (grp in ('required', 'optional')),
  label text not null,
  checked boolean not null default false,
  checked_by text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table categories enable row level security;
alter table tasks enable row level security;

-- 房间内不做账号区分,朋友间共享读写(仅够小范围使用,不要放敏感数据)
create policy "anyone can read categories" on categories for select using (true);
create policy "anyone can insert categories" on categories for insert with check (true);
create policy "anyone can update categories" on categories for update using (true) with check (true);
create policy "anyone can delete categories" on categories for delete using (true);

create policy "anyone can read tasks" on tasks for select using (true);
create policy "anyone can insert tasks" on tasks for insert with check (true);
create policy "anyone can update tasks" on tasks for update using (true) with check (true);
create policy "anyone can delete tasks" on tasks for delete using (true);

-- 开启 Realtime 广播
alter publication supabase_realtime add table categories;
alter publication supabase_realtime add table tasks;
