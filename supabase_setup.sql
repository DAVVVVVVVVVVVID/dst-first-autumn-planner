-- 在 Supabase 项目的 SQL Editor 里执行一次即可
-- https://supabase.com/dashboard/project/tldmpaumprctfpqzbgga/sql

create table if not exists task_state (
  room text not null,
  task_id text not null,
  checked boolean not null default false,
  checked_by text,
  updated_at timestamptz not null default now(),
  primary key (room, task_id)
);

alter table task_state enable row level security;

-- 房间内不做账号区分,朋友间共享读写(仅够小范围使用,不要放敏感数据)
create policy "anyone can read task_state" on task_state
  for select using (true);

create policy "anyone can upsert task_state" on task_state
  for insert with check (true);

create policy "anyone can update task_state" on task_state
  for update using (true) with check (true);

-- 开启 Realtime 广播
alter publication supabase_realtime add table task_state;
