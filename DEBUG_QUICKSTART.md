# Debug Quickstart

目的：快速理解项目并以高效率方式定位与修复问题。

1) 快速启动（本地、最少依赖）
- 创建并激活虚拟环境：
  ```bash
  python3 -m venv .venv
  source .venv/bin/activate
  python -m pip install -r requirements.txt
  ```
- 启动开发服务器（脚本已封装依赖）：
  ```bash
  ./scripts/run_dev.sh --no-worker
  ```

2) 使用 Docker（隔离依赖，推荐复现环境相关错误）
```bash
docker compose up --build -d db redis
docker compose run --rm web flask db upgrade
docker compose up -d web worker
docker compose logs -f web
```

3) 常用诊断命令
- 检查是否能导入 app：
  ```bash
  python - <<'PY'
  import importlib,traceback
  try: importlib.import_module('microblog'); print('OK')
  except Exception: traceback.print_exc()
  PY
  ```
- 语法检查： `python -m py_compile microblog.py`
- 检查端口占用： `lsof -i :5000` 或 `ss -ltnp | grep :5000`

4) 日志与位置
- Flask / app 日志： `logs/microblog.log`（脚本会写入）
- worker 日志： `logs/rq_worker.log`
- systemd 日志： `journalctl -u microblog.service -f`

5) 重现并调试后台任务
- 在 `flask shell` 中入队任务：
  ```bash
  export FLASK_APP=microblog.py
  flask shell
  # shell:
  from app.models import User
  u = db.session.scalar(sa.select(User))
  u.launch_task('export_posts', 'Exporting...')
  ```
- 在前台运行 worker 以观察执行：
  ```bash
  rq worker microblog-tasks
  ```

6) 使用 debugpy 远程/本地断点（推荐用 VS Code attach）
- 安装并在 web/worker 前台启动：
  ```bash
  python -m pip install debugpy
  # Web: 等待编辑器 attach
  python -m debugpy --listen 0.0.0.0:5678 --wait-for-client -m flask run
  # Worker:
  python -m debugpy --listen 0.0.0.0:5679 --wait-for-client -m rq worker microblog-tasks
  ```
- VS Code: 连接到端口 5678（web）或 5679（worker）。

7) 快速定位常见问题
- 数据库连接错误 -> 检查 `DATABASE_URL`（如果使用 docker-compose，务必在容器网络里运行迁移或使用 `localhost` 指向本机 Postgres）。
- 导入错误 -> 用上面的 import 测试得到 traceback。重点查看 `app/__init__.py`、`microblog.py`、`config.py`。
- 任务不执行 -> 检查 Redis 是否可达，worker 是否在运行，查看 `Task.get_rq_job()` 和 `rq` 日志。

8) 测试
- 运行测试套件： `pytest -q`
- 为修复添加小的单元/集成测试以防回归。

9) 额外建议
- 将常用调试命令写入 `Makefile` 或 `scripts/` 下小脚本，便于团队复用。
- 对长任务在 `app/tasks.py` 中添加更多日志/进度更新，便于 worker 端问题定位。

保存在仓库根： `DEBUG_QUICKSTART.md`。需要我把其中某段扩展成可执行脚本或 VS Code launch.json 配置吗？


