-- 完整建表脚本(v3):全新 Supabase 项目从头执行这一个文件即可
-- https://supabase.com/dashboard/project/tldmpaumprctfpqzbgga/sql
--
-- 如果你是已经建过 categories/tasks 表的老用户,不要重复执行本文件
-- (create policy 不是幂等的,重复执行会因为策略已存在而报错),
-- 只需要执行 supabase_migration_add_templates.sql 补上新的 templates 表。

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

create table if not exists templates (
  id uuid primary key default gen_random_uuid(),
  icon text not null default '📋',
  name text not null,
  description text,
  created_by text,
  data jsonb not null,
  created_at timestamptz not null default now()
);

alter table categories enable row level security;
alter table tasks enable row level security;
alter table templates enable row level security;

-- 房间内不做账号区分,朋友间共享读写(仅够小范围使用,不要放敏感数据)
create policy "anyone can read categories" on categories for select using (true);
create policy "anyone can insert categories" on categories for insert with check (true);
create policy "anyone can update categories" on categories for update using (true) with check (true);
create policy "anyone can delete categories" on categories for delete using (true);

create policy "anyone can read tasks" on tasks for select using (true);
create policy "anyone can insert tasks" on tasks for insert with check (true);
create policy "anyone can update tasks" on tasks for update using (true) with check (true);
create policy "anyone can delete tasks" on tasks for delete using (true);

-- 模板不分房间,所有人可读可写
create policy "anyone can read templates" on templates for select using (true);
create policy "anyone can insert templates" on templates for insert with check (true);

-- 开启 Realtime 广播
alter publication supabase_realtime add table categories;
alter publication supabase_realtime add table tasks;
alter publication supabase_realtime add table templates;

-- 预置内建的「第一个秋天」模板
insert into templates (icon, name, description, created_by, data)
select
  '🍂',
  '第一个秋天',
  '新手团队建立基地、稳定食物、准备过冬的核心任务清单',
  '系统预置',
  '{
    "categories": [
      {"icon":"🗺️","name":"探索地图","required":["猪王","牛群","草原","蜘蛛巢","岩石区域","兔子区","发条怪物","海象平原","格罗姆"],"optional":["沼泽","墓地","蜂巢","洞穴"]},
      {"icon":"🌱","name":"资源移植","required":["浆果丛移植","树枝移植","种树","蜘蛛巢 ×3","猪人房 ×6","鸟笼"],"optional":["草移植(有草原可以不进行)","蜂箱","兔人房"]},
      {"icon":"🏠","name":"家具必需品","required":["火坑","晾肉架","一本科技","二本科技","烹饪锅 ×3","冰箱 ×3","帐篷","箱子及其分类"],"optional":["海上科技"]},
      {"icon":"⚔️","name":"装备","required":["猪皮头套"],"optional":["矿工帽","提灯"]},
      {"icon":"❄️","name":"过冬准备","required":["牛角帽 ×3","暖石 ×6","充足燃料"],"optional":[]}
    ]
  }'::jsonb
where not exists (select 1 from templates where name = '第一个秋天');
