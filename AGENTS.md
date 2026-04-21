# AGENTS

## Project Stage

当前项目处于快速推进阶段，改动策略要偏激进，优先把主链路做通，不优先做保守兼容。

## Implementation Rules

1. 不要主动加入兜底逻辑。
2. 不要为了“看起来能用”而补本地 mock、演示数据、静态假数据或静默降级。
3. 如果接口失败、字段缺失、权限不足或状态不满足，应该明确暴露问题，而不是偷偷回退到其他逻辑。
4. 新功能优先直接围绕真实接口实现，不做“临时版”和“过渡版”双轨并存。

## API Source of Truth

1. 所有已实现功能对应的接口，都必须先以 [API.md](./API.md) 为准。
2. 不要自行猜测接口路径、字段名、鉴权方式、响应结构或分页参数。
3. 如果 `API.md` 里没有对应接口：
   - 不要自行发明接口接入。
   - 先停下来说明缺口，再决定是否补文档或调整功能范围。
4. 联调时优先保证请求、鉴权、模型解析与 `API.md` 一致。

## Product Direction

1. 当前优先做真实服务器接入能力。
2. 页面结构、状态流转和数据展示要围绕真实媒体库、库内容、详情和播放链路展开。
3. 非必要情况下，不继续扩展与当前主目标无关的兼容层或历史包袱。

## Commit Convention

提交信息统一使用 Conventional Commits 风格，至少遵守下面这个格式：

```text
feat(scope): message
```

例如：

```text
feat(auth): add token login flow
feat(library): render server library list
feat(player): load media file playback header
```

补充规则：

1. `scope` 要尽量具体，直接对应功能域，例如 `auth`、`library`、`media`、`player`、`ui`、`api`。
2. 不要写含糊提交信息，例如 `update code`、`fix bugs`、`wip`。
3. 如果不是功能提交，也尽量保持同样风格，例如：

```text
fix(player): correct playback progress parsing
refactor(media): simplify library item loading
chore(project): normalize xcode project layout
```

## When in Doubt

如果实现方向与 `API.md`、当前产品阶段或提交规范冲突，优先服从这份文件。
