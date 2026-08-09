-- 增量迁移(v3):新增全局共享的 templates 表
-- 你已经建过 categories / tasks 表,只需要执行这一个文件,不用重跑 supabase_setup.sql
-- (里面的 create policy 不是幂等的,重复执行会报错)
--
-- https://supabase.com/dashboard/project/tldmpaumprctfpqzbgga/sql

create table if not exists templates (
  id uuid primary key default gen_random_uuid(),
  icon text not null default '📋',
  name text not null,
  description text,
  created_by text,
  data jsonb not null,
  created_at timestamptz not null default now()
);

alter table templates enable row level security;

-- 模板不分房间,所有人可读可写(和其他表一样的信任模型:仅供小范围朋友使用)
create policy "anyone can read templates" on templates for select using (true);
create policy "anyone can insert templates" on templates for insert with check (true);

alter publication supabase_realtime add table templates;

-- 预置内建的「第一个秋天」模板(如果还没有同名模板才插入,避免重复插入)
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
